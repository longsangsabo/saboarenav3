#!/usr/bin/env python3
"""
🎯 SABO ARENA - Tournament Match Factory System
Format-specific match generation based on Flutter demo system patterns
"""

import math
import uuid
from datetime import datetime
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional

class TournamentMatchFactory(ABC):
    """Abstract base class for tournament match generation"""
    
    def __init__(self, tournament_id: str, participants: List[Dict[str, Any]]):
        self.tournament_id = tournament_id
        self.participants = participants
        self.participant_count = len(participants)
        
    @abstractmethod
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate matches for this tournament format"""
        pass
    
    @abstractmethod
    def get_total_rounds(self) -> int:
        """Calculate total number of rounds for this format"""
        pass
        
    def _create_match(self, round_number: int, match_number: int, 
                     player1_id: Optional[str] = None, player2_id: Optional[str] = None,
                     status: str = 'pending', round_name: Optional[str] = None) -> Dict[str, Any]:
        """Create a standard match object with round naming (compatible with current schema)"""
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': self.tournament_id,
            'player1_id': player1_id,
            'player2_id': player2_id,
            'round_number': round_number,
            'match_number': match_number,
            'status': status,
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        
        # Add round name in notes field temporarily (until round_name column is added)
        if round_name:
            match['notes'] = f"Round: {round_name}"
            
        return match

class SingleEliminationFactory(TournamentMatchFactory):
    """Single Elimination tournament format - ported from demo system logic"""
    
    def get_total_rounds(self) -> int:
        """Calculate total rounds: log2(participants) rounded up"""
        return math.ceil(math.log2(self.participant_count))
    
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate Single Elimination bracket matches with proper round naming"""
        matches = []
        total_rounds = self.get_total_rounds()
        
        print(f"   🎯 Single Elimination: {self.participant_count} players → {total_rounds} rounds")
        
        # Round 1: Pair up all participants  
        round_1_matches = self._create_round_1_matches()
        matches.extend(round_1_matches)
        
        # Subsequent rounds: Create placeholder matches with proper names
        for round_num in range(2, total_rounds + 1):
            round_name = self.get_round_name(round_num)
            round_matches = self._create_placeholder_round(round_num, round_name)
            matches.extend(round_matches)
            
        return matches
    
    def _create_round_1_matches(self) -> List[Dict[str, Any]]:
        """Create first round matches with actual participants"""
        matches = []
        round_name = self.get_round_name(1)
        
        for i in range(0, self.participant_count, 2):
            player1 = self.participants[i]
            player2 = self.participants[i + 1] if i + 1 < self.participant_count else None
            
            match = self._create_match(
                round_number=1,
                match_number=(i // 2) + 1,
                player1_id=player1['user_id'],
                player2_id=player2['user_id'] if player2 else None,
                round_name=round_name
            )
            
            # Handle bye (odd number of participants)
            if player2 is None:
                match.update({
                    'winner_id': player1['user_id'],
                    'status': 'completed',
                    'player1_score': 2,
                    'player2_score': 0
                })
            
            matches.append(match)
        
        print(f"   📋 {round_name}: {len(matches)} matches created")
        return matches
    
    def _create_placeholder_round(self, round_num: int, round_name: str) -> List[Dict[str, Any]]:
        """Create placeholder matches for future rounds"""
        matches_in_round = self._calculate_matches_in_round(round_num)
        matches = []
        
        for match_num in range(1, matches_in_round + 1):
            match = self._create_match(
                round_number=round_num,
                match_number=match_num,
                round_name=round_name
            )
            matches.append(match)
        
        print(f"   📋 {round_name}: {matches_in_round} placeholder matches")
        return matches
    
    def _calculate_matches_in_round(self, round_num: int) -> int:
        """Calculate number of matches in a specific round"""
        if round_num == 1:
            return math.ceil(self.participant_count / 2)
        
        # For subsequent rounds, each round has half the matches of previous round
        previous_matches = self._calculate_matches_in_round(round_num - 1)
        return max(1, previous_matches // 2)
    
    def get_round_name(self, round_num: int) -> str:
        """Get display name for round based on participant count"""
        total_rounds = self.get_total_rounds()
        
        if round_num == total_rounds:
            return "CHUNG KẾT"
        elif round_num == total_rounds - 1:
            return "BÁN KẾT"
        elif round_num == total_rounds - 2:
            return "TỨ KẾT"
        else:
            # Calculate remaining players in this round
            remaining_players = self.participant_count // (2 ** (round_num - 1))
            next_round_players = remaining_players // 2
            return f"VÒNG 1/{next_round_players}"

class DoubleEliminationFactory(TournamentMatchFactory):
    """Traditional Double Elimination tournament format - based on demo system"""
    
    def get_total_rounds(self) -> int:
        """Calculate total rounds for double elimination"""
        winners_rounds = math.ceil(math.log2(self.participant_count))
        losers_rounds = (winners_rounds - 1) * 2
        return winners_rounds + losers_rounds + 1  # +1 for grand final
    
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate Traditional Double Elimination bracket matches"""
        matches = []
        
        print(f"   🏆 Traditional Double Elimination: {self.participant_count} players")
        
        # Winners Bracket
        winners_matches = self._create_winners_bracket()
        matches.extend(winners_matches)
        
        # Losers Bracket  
        losers_matches = self._create_losers_bracket()
        matches.extend(losers_matches)
        
        # Grand Final
        grand_final_matches = self._create_grand_final()
        matches.extend(grand_final_matches)
        
        return matches
    
    def _create_winners_bracket(self) -> List[Dict[str, Any]]:
        """Create winners bracket matches (same as single elimination)"""
        print("   🎯 Creating Winners Bracket...")
        single_elim = SingleEliminationFactory(self.tournament_id, self.participants)
        return single_elim.generate_matches()
    
    def _create_losers_bracket(self) -> List[Dict[str, Any]]:
        """Create traditional losers bracket matches (complex elimination flow)"""
        print("   🔥 Creating Losers Bracket...")
        matches = []
        winners_rounds = math.ceil(math.log2(self.participant_count))
        
        # Implement basic losers bracket structure
        # This is simplified - full implementation would be more complex
        for round_num in range(1, winners_rounds):
            players_in_round = self.participant_count // (2 ** round_num)
            matches_in_round = max(1, players_in_round // 2)
            
            for match_num in range(1, matches_in_round + 1):
                match = self._create_match(
                    round_number=100 + round_num,  # Losers bracket rounds
                    match_number=match_num,
                    round_name=f"Losers Round {round_num}"
                )
                matches.append(match)
            
            print(f"   🔥 Losers Round {round_num}: {matches_in_round} matches")
        
        return matches
    
    def _create_grand_final(self) -> List[Dict[str, Any]]:
        """Create grand final match(es)"""
        print("   👑 Creating Grand Final...")
        matches = []
        
        # Grand Final Set 1
        gf1 = self._create_match(
            round_number=999,  # Special round number for grand final
            match_number=1,
            round_name="Grand Final"
        )
        matches.append(gf1)
        
        # Grand Final Set 2 (if needed - bracket reset)
        gf2 = self._create_match(
            round_number=999,
            match_number=2,
            round_name="Grand Final Reset"
        )
        matches.append(gf2)
        
        return matches

class SaboDE16Factory(TournamentMatchFactory):
    """SABO Double Elimination DE16 format - specialized for 16 players"""
    
    def __init__(self, tournament_id: str, participants: List[Dict[str, Any]]):
        if len(participants) != 16:
            raise ValueError(f"SABO DE16 requires exactly 16 participants, got {len(participants)}")
        super().__init__(tournament_id, participants)
        
    def get_total_rounds(self) -> int:
        """SABO DE16 has specific round structure"""
        return 10  # WR1-3, LAR101-103, LBR201-202, SABO Finals 250-251-300
    
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate SABO DE16 bracket matches (27 total matches)"""
        matches = []
        
        print(f"   🎯 SABO DE16: {self.participant_count} players → 27 matches")
        
        # Winners Bracket: 14 matches (8+4+2)
        winners_matches = self._create_sabo_winners_bracket()
        matches.extend(winners_matches)
        
        # Losers Branch A: 7 matches (4+2+1)
        losers_a_matches = self._create_losers_branch_a()
        matches.extend(losers_a_matches)
        
        # Losers Branch B: 3 matches (2+1)
        losers_b_matches = self._create_losers_branch_b()
        matches.extend(losers_b_matches)
        
        # SABO Finals: 3 matches (2 semis + 1 final)
        sabo_finals_matches = self._create_sabo_finals()
        matches.extend(sabo_finals_matches)
        
        print(f"   ✅ Total SABO DE16 matches created: {len(matches)}")
        return matches
    
    def _create_sabo_winners_bracket(self) -> List[Dict[str, Any]]:
        """Create SABO Winners Bracket (stops at 2 players)"""
        matches = []
        
        # WR1: 16 → 8 (8 matches)
        for i in range(8):
            match = self._create_match(
                round_number=1,
                match_number=i + 1,
                player1_id=self.participants[i * 2]['user_id'],
                player2_id=self.participants[i * 2 + 1]['user_id'],
                round_name="Winners Round 1"
            )
            matches.append(match)
        
        # WR2: 8 → 4 (4 matches)  
        for i in range(4):
            match = self._create_match(
                round_number=2,
                match_number=i + 1,
                round_name="Winners Round 2"
            )
            matches.append(match)
        
        # WR3: 4 → 2 (2 matches) - SEMIFINALS
        for i in range(2):
            match = self._create_match(
                round_number=3,
                match_number=i + 1,
                round_name="Winners Semifinals"
            )
            matches.append(match)
        
        print(f"   🏆 SABO Winners Bracket: {len(matches)} matches (8+4+2)")
        return matches
    
    def _create_losers_branch_a(self) -> List[Dict[str, Any]]:
        """Create SABO Losers Branch A (for WR1 losers)"""
        matches = []
        
        # LAR101: 8 → 4 (4 matches)
        for i in range(4):
            match = self._create_match(
                round_number=101,
                match_number=i + 1,
                round_name="Losers Branch A R1"
            )
            matches.append(match)
        
        # LAR102: 4 → 2 (2 matches)
        for i in range(2):
            match = self._create_match(
                round_number=102,
                match_number=i + 1,
                round_name="Losers Branch A R2"
            )
            matches.append(match)
        
        # LAR103: 2 → 1 (1 match)
        match = self._create_match(
            round_number=103,
            match_number=1,
            round_name="Losers Branch A Final"
        )
        matches.append(match)
        
        print(f"   🥈 SABO Losers Branch A: {len(matches)} matches (4+2+1)")
        return matches
    
    def _create_losers_branch_b(self) -> List[Dict[str, Any]]:
        """Create SABO Losers Branch B (for WR2 losers)"""
        matches = []
        
        # LBR201: 4 → 2 (2 matches)
        for i in range(2):
            match = self._create_match(
                round_number=201,
                match_number=i + 1,
                round_name="Losers Branch B R1"
            )
            matches.append(match)
        
        # LBR202: 2 → 1 (1 match)
        match = self._create_match(
            round_number=202,
            match_number=1,
            round_name="Losers Branch B Final"
        )
        matches.append(match)
        
        print(f"   🥉 SABO Losers Branch B: {len(matches)} matches (2+1)")
        return matches
    
    def _create_sabo_finals(self) -> List[Dict[str, Any]]:
        """Create SABO Finals (4 players: 2 WB + 1 LA + 1 LB)"""
        matches = []
        
        # SABO Semifinal 1
        semi1 = self._create_match(
            round_number=250,
            match_number=1,
            round_name="SABO Semifinal 1"
        )
        matches.append(semi1)
        
        # SABO Semifinal 2
        semi2 = self._create_match(
            round_number=251,
            match_number=1,
            round_name="SABO Semifinal 2"
        )
        matches.append(semi2)
        
        # SABO Final
        final = self._create_match(
            round_number=300,
            match_number=1,
            round_name="SABO Final"
        )
        matches.append(final)
        
        print(f"   🏅 SABO Finals: {len(matches)} matches (2 semis + 1 final)")
        return matches

class SaboDE32Factory(TournamentMatchFactory):
    """SABO Double Elimination DE32 format - specialized for 32 players"""
    
    def __init__(self, tournament_id: str, participants: List[Dict[str, Any]]):
        if len(participants) != 32:
            raise ValueError(f"SABO DE32 requires exactly 32 participants, got {len(participants)}")
        super().__init__(tournament_id, participants)
        
    def get_total_rounds(self) -> int:
        """SABO DE32 has specific round structure"""
        return 15  # Complex bracket with 2 groups + cross bracket
    
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate SABO DE32 bracket matches (2 groups of 16 + cross bracket)"""
        matches = []
        
        print(f"   🎯 SABO DE32: {self.participant_count} players → 2 Groups + Cross Bracket")
        
        # Group A: 16 players (first half)
        group_a_participants = self.participants[:16]
        group_a_matches = self._create_group_bracket(group_a_participants, "A", 1000)
        matches.extend(group_a_matches)
        
        # Group B: 16 players (second half)
        group_b_participants = self.participants[16:]
        group_b_matches = self._create_group_bracket(group_b_participants, "B", 2000)
        matches.extend(group_b_matches)
        
        # Cross Bracket Finals
        cross_bracket_matches = self._create_cross_bracket()
        matches.extend(cross_bracket_matches)
        
        print(f"   ✅ Total SABO DE32 matches created: {len(matches)}")
        return matches
    
    def _create_group_bracket(self, group_participants: List[Dict[str, Any]], group_name: str, round_offset: int) -> List[Dict[str, Any]]:
        """Create bracket for one group (16 players)"""
        matches = []
        
        # Use SABO DE16 logic for each group
        temp_factory = SaboDE16Factory(self.tournament_id, group_participants)
        group_matches = temp_factory.generate_matches()
        
        # Adjust round numbers with offset and add group prefix
        for match in group_matches:
            match['round_number'] += round_offset
            
            # Update notes field with group prefix
            if match.get('notes'):
                original_round_name = match['notes'].replace('Round: ', '')
                match['notes'] = f"Round: Group {group_name} {original_round_name}"
        
        matches.extend(group_matches)
        print(f"   📊 Group {group_name}: {len(matches)} matches")
        return matches
    
    def _create_cross_bracket(self) -> List[Dict[str, Any]]:
        """Create cross bracket finals (Group A winner vs Group B winner, etc.)"""
        matches = []
        
        # Cross Semifinal 1: Group A Winner vs Group B Winner
        semi1 = self._create_match(
            round_number=9000,
            match_number=1,
            round_name="Cross Semifinal 1"
        )
        matches.append(semi1)
        
        # Cross Semifinal 2: Other qualifiers
        semi2 = self._create_match(
            round_number=9001,
            match_number=1,
            round_name="Cross Semifinal 2"
        )
        matches.append(semi2)
        
        # Cross Final
        final = self._create_match(
            round_number=9999,
            match_number=1,
            round_name="Cross Final"
        )
        matches.append(final)
        
        print(f"   🏆 Cross Bracket: {len(matches)} matches")
        return matches

class RoundRobinFactory(TournamentMatchFactory):
    """Round Robin tournament format - everyone plays everyone"""
    
    def get_total_rounds(self) -> int:
        """Round robin typically has 1 round with all matches"""
        return 1
    
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate round robin matches (every player vs every player)"""
        matches = []
        match_number = 1
        
        print(f"   🔄 Round Robin: {self.participant_count} players")
        
        for i in range(self.participant_count):
            for j in range(i + 1, self.participant_count):
                match = self._create_match(
                    round_number=1,
                    match_number=match_number,
                    player1_id=self.participants[i]['user_id'],
                    player2_id=self.participants[j]['user_id']
                )
                matches.append(match)
                match_number += 1
        
        total_matches = len(matches)
        expected_matches = (self.participant_count * (self.participant_count - 1)) // 2
        
        print(f"   📋 Created {total_matches} matches (expected: {expected_matches})")
        return matches

class SwissSystemFactory(TournamentMatchFactory):
    """Swiss System tournament format - based on rankings"""
    
    def get_total_rounds(self) -> int:
        """Swiss system typically uses log2(participants) rounds"""
        return math.ceil(math.log2(self.participant_count))
    
    def generate_matches(self) -> List[Dict[str, Any]]:
        """Generate Swiss system tournament structure"""
        matches = []
        total_rounds = self.get_total_rounds()
        
        print(f"   🇨🇭 Swiss System: {self.participant_count} players → {total_rounds} rounds")
        
        # Create placeholder structure for all rounds
        for round_num in range(1, total_rounds + 1):
            round_matches = self._create_swiss_round(round_num)
            matches.extend(round_matches)
            
        return matches
    
    def _create_swiss_round(self, round_num: int) -> List[Dict[str, Any]]:
        """Create matches for a Swiss system round"""
        matches_in_round = self.participant_count // 2
        matches = []
        
        for match_num in range(1, matches_in_round + 1):
            if round_num == 1:
                # First round: pair randomly or by seed
                if (match_num - 1) * 2 + 1 < self.participant_count:
                    player1 = self.participants[(match_num - 1) * 2]
                    player2 = self.participants[(match_num - 1) * 2 + 1] if (match_num - 1) * 2 + 1 < self.participant_count else None
                    
                    match = self._create_match(
                        round_number=round_num,
                        match_number=match_num,
                        player1_id=player1['user_id'],
                        player2_id=player2['user_id'] if player2 else None
                    )
                else:
                    match = self._create_match(round_num, match_num)
            else:
                # Subsequent rounds: pair by ranking (placeholder for now)
                match = self._create_match(round_num, match_num)
            
            matches.append(match)
        
        print(f"   📋 Swiss Round {round_num}: {len(matches)} matches")
        return matches

def create_tournament_matches_factory(tournament_format: str, tournament_id: str, participants: List[Dict[str, Any]]) -> TournamentMatchFactory:
    """Factory function to create appropriate tournament format"""
    format_lower = tournament_format.lower().replace('_', '').replace('-', '').replace(' ', '')
    participant_count = len(participants)
    
    # SABO specialized formats
    if format_lower in ['sabode16', 'de16', 'sabodouble16'] and participant_count == 16:
        print(f"   🎯 Using SABO DE16 specialized format")
        return SaboDE16Factory(tournament_id, participants)
    elif format_lower in ['sabode32', 'de32', 'sabodouble32'] and participant_count == 32:
        print(f"   🎯 Using SABO DE32 specialized format")
        return SaboDE32Factory(tournament_id, participants)
    
    # Standard tournament formats
    elif format_lower in ['singleelimination', 'single', 'elimination']:
        return SingleEliminationFactory(tournament_id, participants)
    elif format_lower in ['doubleelimination', 'double']:
        return DoubleEliminationFactory(tournament_id, participants)
    elif format_lower in ['roundrobin', 'round', 'robin']:
        return RoundRobinFactory(tournament_id, participants)
    elif format_lower in ['swisssystem', 'swiss']:
        return SwissSystemFactory(tournament_id, participants)
    
    # Game format mappings - check for SABO DE first
    elif format_lower in ['8ball', '9ball', '10ball', 'straight', 'one-pocket', 'onepocket']:
        # Auto-detect SABO format based on participant count
        if participant_count == 16:
            print(f"   🎱 Game format '{tournament_format}' with 16 players → SABO DE16")
            return SaboDE16Factory(tournament_id, participants)
        elif participant_count == 32:
            print(f"   🎱 Game format '{tournament_format}' with 32 players → SABO DE32")
            return SaboDE32Factory(tournament_id, participants)
        else:
            print(f"   🎱 Game format '{tournament_format}' → Single Elimination")
            return SingleEliminationFactory(tournament_id, participants)
    else:
        print(f"   ⚠️ Unknown format '{tournament_format}', defaulting to Single Elimination")
        return SingleEliminationFactory(tournament_id, participants)

if __name__ == "__main__":
    # Test factory system with different player counts and SABO formats
    print("🧪 Testing Tournament Match Factory System with SABO Formats")
    
    test_cases = [
        (8, "8 players", "single_elimination"),
        (16, "16 players", "single_elimination"), 
        (16, "16 players", "SABO_DE16"),
        (32, "32 players", "single_elimination"),
        (32, "32 players", "SABO_DE32")
    ]
    
    for player_count, description, format_name in test_cases:
        print(f"\n🎯 Testing {description.upper()} - {format_name}:")
        print("-" * 60)
        
        # Mock participants
        test_participants = [
            {'user_id': f'player_{i}', 'name': f'Player {i}'} 
            for i in range(1, player_count + 1)
        ]
        
        try:
            factory = create_tournament_matches_factory(format_name, 'test_tournament', test_participants)
            matches = factory.generate_matches()
            
            print(f"✅ Generated {len(matches)} matches")
            print(f"📊 Total rounds: {factory.get_total_rounds()}")
            
            # Show specialized round structure for SABO
            if 'sabo' in format_name.lower() or 'de16' in format_name.lower() or 'de32' in format_name.lower():
                print(f"🎯 SABO Format Structure:")
                round_counts = {}
                for match in matches:
                    round_num = match['round_number']
                    round_name = match.get('round_name', f'Round {round_num}')
                    if round_name not in round_counts:
                        round_counts[round_name] = 0
                    round_counts[round_name] += 1
                
                for round_name, count in round_counts.items():
                    print(f"   {round_name}: {count} matches")
        
        except Exception as e:
            print(f"❌ Error: {e}")
        
    # Test game format auto-detection
    print(f"\n🎯 Testing GAME FORMAT AUTO-DETECTION:")
    print("-" * 60)
    
    game_formats = ['8-Ball', '9-Ball']
    player_counts = [16, 32]
    
    for game_format in game_formats:
        for player_count in player_counts:
            print(f"\n📋 {game_format} with {player_count} players:")
            test_participants = [
                {'user_id': f'player_{i}', 'name': f'Player {i}'} 
                for i in range(1, player_count + 1)
            ]
            
            factory = create_tournament_matches_factory(game_format, 'test_tournament', test_participants)
            matches = factory.generate_matches()
            print(f"   Generated {len(matches)} matches")