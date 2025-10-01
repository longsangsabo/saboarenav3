#!/usr/bin/env python3
"""
Universal Advancement Logic System
Handles automatic player progression for all tournament formats
"""

from supabase import create_client
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
import uuid
from datetime import datetime

@dataclass
class AdvancementRule:
    """Rule for player advancement in tournaments"""
    match_number: int
    winner_advances_to: Optional[int]  # Match number winner advances to
    loser_advances_to: Optional[int]   # Match number loser advances to (DE only)
    round_number: int
    is_winner_bracket: bool
    requires_completion: List[int] = None  # Other matches that must complete first

class UniversalAdvancementSystem:
    """
    Universal system for handling player advancement in all tournament formats
    """
    
    def __init__(self):
        # Initialize Supabase
        self.SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
        self.SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
        self.supabase = create_client(self.SUPABASE_URL, self.SERVICE_KEY)
        
        # Cache advancement rules for performance
        self.advancement_cache = {}
    
    def calculate_advancement_rules(self, tournament_id: str) -> Dict[int, AdvancementRule]:
        """
        Calculate advancement rules for a tournament based on its format and structure
        """
        if tournament_id in self.advancement_cache:
            return self.advancement_cache[tournament_id]
        
        # Get tournament info
        tournament = self.supabase.table('tournaments').select(
            'bracket_format, max_participants'
        ).eq('id', tournament_id).execute()
        
        if not tournament.data:
            raise ValueError(f"Tournament {tournament_id} not found")
        
        format_type = tournament.data[0]['bracket_format']
        max_participants = tournament.data[0]['max_participants']
        
        # Get all matches for this tournament
        matches = self.supabase.table('matches').select(
            'match_number, round_number'
        ).eq('tournament_id', tournament_id).order('match_number').execute()
        
        if format_type == 'single_elimination':
            rules = self._calculate_single_elimination_rules(matches.data, max_participants)
        elif format_type == 'double_elimination':
            rules = self._calculate_double_elimination_rules(matches.data, max_participants)
        else:
            raise ValueError(f"Unsupported format: {format_type}")
        
        # Cache the rules
        self.advancement_cache[tournament_id] = rules
        return rules
    
    def _calculate_single_elimination_rules(self, matches: List[Dict], max_participants: int) -> Dict[int, AdvancementRule]:
        """Calculate advancement rules for single elimination"""
        rules = {}
        
        # Group matches by round
        rounds = {}
        for match in matches:
            round_num = match['round_number']
            if round_num not in rounds:
                rounds[round_num] = []
            rounds[round_num].append(match['match_number'])
        
        # Calculate advancement for each match
        for match in matches:
            match_number = match['match_number']
            round_number = match['round_number']
            
            # Find next match (winner advances)
            winner_advances_to = None
            if round_number < max(rounds.keys()):
                # Not final round - winner advances
                next_round = round_number + 1
                next_round_matches = sorted(rounds[next_round])
                
                # Calculate which match in next round
                position_in_round = sorted(rounds[round_number]).index(match_number)
                next_match_index = position_in_round // 2
                winner_advances_to = next_round_matches[next_match_index]
            
            rules[match_number] = AdvancementRule(
                match_number=match_number,
                winner_advances_to=winner_advances_to,
                loser_advances_to=None,  # No loser advancement in SE
                round_number=round_number,
                is_winner_bracket=True
            )
        
        return rules
    
    def _calculate_double_elimination_rules(self, matches: List[Dict], max_participants: int) -> Dict[int, AdvancementRule]:
        """Calculate advancement rules for double elimination"""
        rules = {}
        
        # Separate WB and LB matches
        wb_matches = [m for m in matches if m['round_number'] < 100]
        lb_matches = [m for m in matches if m['round_number'] >= 101]
        
        # Calculate WB advancement rules
        wb_rules = self._calculate_wb_advancement(wb_matches, lb_matches, max_participants)
        rules.update(wb_rules)
        
        # Calculate LB advancement rules
        lb_rules = self._calculate_lb_advancement(lb_matches, max_participants)
        rules.update(lb_rules)
        
        return rules
    
    def _calculate_wb_advancement(self, wb_matches: List[Dict], lb_matches: List[Dict], max_participants: int) -> Dict[int, AdvancementRule]:
        """Calculate Winners Bracket advancement rules"""
        rules = {}
        
        # Group WB matches by round
        wb_rounds = {}
        for match in wb_matches:
            round_num = match['round_number']
            if round_num not in wb_rounds:
                wb_rounds[round_num] = []
            wb_rounds[round_num].append(match['match_number'])
        
        # Group LB matches by round for loser destinations
        lb_rounds = {}
        for match in lb_matches:
            round_num = match['round_number']
            if round_num not in lb_rounds:
                lb_rounds[round_num] = []
            lb_rounds[round_num].append(match['match_number'])
        
        for match in wb_matches:
            match_number = match['match_number']
            round_number = match['round_number']
            
            # Winner advancement (next WB round)
            winner_advances_to = None
            if round_number < max(wb_rounds.keys()):
                next_round = round_number + 1
                next_round_matches = sorted(wb_rounds[next_round])
                position_in_round = sorted(wb_rounds[round_number]).index(match_number)
                next_match_index = position_in_round // 2
                winner_advances_to = next_round_matches[next_match_index]
            
            # Loser advancement (to appropriate LB round)
            loser_advances_to = None
            if lb_rounds:
                # Calculate which LB round losers go to
                lb_round = self._calculate_loser_destination_round(round_number, max_participants)
                if lb_round in lb_rounds:
                    # Simple mapping for now - can be refined
                    lb_matches_in_round = sorted(lb_rounds[lb_round])
                    if lb_matches_in_round:
                        position_in_round = sorted(wb_rounds[round_number]).index(match_number)
                        lb_match_index = position_in_round % len(lb_matches_in_round)
                        loser_advances_to = lb_matches_in_round[lb_match_index]
            
            rules[match_number] = AdvancementRule(
                match_number=match_number,
                winner_advances_to=winner_advances_to,
                loser_advances_to=loser_advances_to,
                round_number=round_number,
                is_winner_bracket=True
            )
        
        return rules
    
    def _calculate_lb_advancement(self, lb_matches: List[Dict], max_participants: int) -> Dict[int, AdvancementRule]:
        """Calculate Losers Bracket advancement rules"""
        rules = {}
        
        # Group LB matches by round
        lb_rounds = {}
        for match in lb_matches:
            round_num = match['round_number']
            if round_num not in lb_rounds:
                lb_rounds[round_num] = []
            lb_rounds[round_num].append(match['match_number'])
        
        for match in lb_matches:
            match_number = match['match_number']
            round_number = match['round_number']
            
            # Winner advancement (next LB round or Grand Final)
            winner_advances_to = None
            if round_number < max(lb_rounds.keys()):
                next_round = round_number + 1
                if next_round in lb_rounds:
                    next_round_matches = sorted(lb_rounds[next_round])
                    position_in_round = sorted(lb_rounds[round_number]).index(match_number)
                    # LB advancement can be complex - simplified for now
                    next_match_index = position_in_round // 2 if len(next_round_matches) < len(lb_rounds[round_number]) else position_in_round
                    winner_advances_to = next_round_matches[min(next_match_index, len(next_round_matches) - 1)]
            
            rules[match_number] = AdvancementRule(
                match_number=match_number,
                winner_advances_to=winner_advances_to,
                loser_advances_to=None,  # Losers are eliminated in LB
                round_number=round_number,
                is_winner_bracket=False
            )
        
        return rules
    
    def _calculate_loser_destination_round(self, wb_round: int, max_participants: int) -> int:
        """Calculate which LB round WB losers go to"""
        # Standard DE mapping - WB Round 1 losers go to LB Round 1 (101)
        if wb_round == 1:
            return 101
        elif wb_round == 2:
            return 102
        elif wb_round == 3:
            return 104  # Skip rounds where LB internal matches happen
        elif wb_round == 4:
            return 106
        else:
            return 101 + (wb_round - 1) * 2  # Simplified mapping
    
    def advance_players(self, tournament_id: str, completed_match_id: str, winner_id: str) -> Dict:
        """
        Automatically advance players after a match completion
        
        Args:
            tournament_id: Tournament UUID
            completed_match_id: ID of the completed match
            winner_id: UUID of the winning player
        
        Returns:
            Dict with advancement results
        """
        try:
            # Get the completed match details
            match_result = self.supabase.table('matches').select(
                'match_number, player1_id, player2_id, round_number'
            ).eq('id', completed_match_id).execute()
            
            if not match_result.data:
                return {'error': f'Match {completed_match_id} not found'}
            
            completed_match = match_result.data[0]
            match_number = completed_match['match_number']
            player1_id = completed_match['player1_id']
            player2_id = completed_match['player2_id']
            
            # Determine loser
            loser_id = player1_id if winner_id == player2_id else player2_id
            
            # Get advancement rules
            rules = self.calculate_advancement_rules(tournament_id)
            
            if match_number not in rules:
                return {'error': f'No advancement rule found for match {match_number}'}
            
            rule = rules[match_number]
            advancements = []
            
            # Advance winner
            if rule.winner_advances_to:
                winner_advancement = self._advance_player(
                    tournament_id, winner_id, rule.winner_advances_to, 'winner'
                )
                advancements.append(winner_advancement)
            
            # Advance loser (DE only)
            if rule.loser_advances_to:
                loser_advancement = self._advance_player(
                    tournament_id, loser_id, rule.loser_advances_to, 'loser'
                )
                advancements.append(loser_advancement)
            
            return {
                'success': True,
                'tournament_id': tournament_id,
                'completed_match': match_number,
                'winner_id': winner_id,
                'loser_id': loser_id,
                'advancements': advancements
            }
            
        except Exception as e:
            return {'error': f'Failed to advance players: {str(e)}'}
    
    def _advance_player(self, tournament_id: str, player_id: str, target_match_number: int, advancement_type: str) -> Dict:
        """Advance a single player to target match"""
        try:
            # Get target match
            target_match = self.supabase.table('matches').select(
                'id, player1_id, player2_id, match_number, round_number'
            ).eq('tournament_id', tournament_id).eq('match_number', target_match_number).execute()
            
            if not target_match.data:
                return {'error': f'Target match {target_match_number} not found'}
            
            match = target_match.data[0]
            
            # Determine which slot to fill
            update_data = {}
            if not match['player1_id']:
                update_data['player1_id'] = player_id
                slot = 'player1'
            elif not match['player2_id']:
                update_data['player2_id'] = player_id
                slot = 'player2'
            else:
                return {'error': f'Match {target_match_number} is already full'}
            
            # Update the match
            self.supabase.table('matches').update(update_data).eq('id', match['id']).execute()
            
            return {
                'player_id': player_id,
                'advanced_to_match': target_match_number,
                'advanced_to_round': match['round_number'],
                'slot': slot,
                'advancement_type': advancement_type
            }
            
        except Exception as e:
            return {'error': f'Failed to advance player: {str(e)}'}
    
    def check_immediate_advancement_ready(self, tournament_id: str, match_number: int) -> bool:
        """
        Check if a match is ready for immediate advancement
        (i.e., doesn't need to wait for other matches in the round)
        """
        rules = self.calculate_advancement_rules(tournament_id)
        
        if match_number not in rules:
            return False
        
        rule = rules[match_number]
        
        # If no advancement targets, no advancement needed
        if not rule.winner_advances_to and not rule.loser_advances_to:
            return False
        
        # Check if advancement targets have available slots
        if rule.winner_advances_to:
            target_match = self.supabase.table('matches').select(
                'player1_id, player2_id'
            ).eq('tournament_id', tournament_id).eq('match_number', rule.winner_advances_to).execute()
            
            if target_match.data:
                match = target_match.data[0]
                if match['player1_id'] and match['player2_id']:
                    return False  # Target match is full
        
        return True  # Ready for immediate advancement

def test_advancement_system():
    """Test the advancement system"""
    system = UniversalAdvancementSystem()
    
    print('🧪 TESTING UNIVERSAL ADVANCEMENT SYSTEM')
    print('=' * 50)
    
    # Test with sabo1 tournament
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    print(f'\\n🎯 Testing advancement rules for sabo1...')
    try:
        rules = system.calculate_advancement_rules(sabo1_id)
        print(f'✅ Successfully calculated {len(rules)} advancement rules')
        
        # Show sample rules
        print('\\nSample advancement rules:')
        for match_num in sorted(list(rules.keys())[:5]):  # First 5 matches
            rule = rules[match_num]
            print(f'  Match {match_num} (R{rule.round_number}):')
            print(f'    Winner → Match {rule.winner_advances_to}')
            if rule.loser_advances_to:
                print(f'    Loser → Match {rule.loser_advances_to}')
        
        # Test immediate advancement check
        print('\\n🔍 Checking immediate advancement readiness:')
        for match_num in [1, 2, 10, 11]:  # Test some specific matches
            ready = system.check_immediate_advancement_ready(sabo1_id, match_num)
            print(f'  Match {match_num}: {"✅ Ready" if ready else "⏳ Not ready"}')
            
    except Exception as e:
        print(f'❌ Error: {str(e)}')

if __name__ == '__main__':
    test_advancement_system()