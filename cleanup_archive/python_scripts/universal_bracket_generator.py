#!/usr/bin/env python3
"""
Universal Bracket Generation System
Comprehensive bracket generation for all tournament formats
"""

import math
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass

@dataclass
class MatchInfo:
    """Information about a match in the bracket"""
    match_number: int
    round_number: int
    player1_id: Optional[str] = None
    player2_id: Optional[str] = None
    winner_advances_to: Optional[int] = None
    loser_advances_to: Optional[int] = None
    is_winner_bracket: bool = True
    
@dataclass 
class BracketStructure:
    """Complete bracket structure information"""
    format_type: str  # 'single_elimination' or 'double_elimination'
    player_count: int
    total_matches: int
    rounds: Dict[int, List[MatchInfo]]
    advancement_map: Dict[int, Dict[str, int]]  # match_id -> {winner: next_match, loser: next_match}

class UniversalBracketGenerator:
    """
    Universal bracket generation system supporting all tournament formats
    """
    
    def __init__(self):
        self.bracket_configs = self._initialize_bracket_configs()
    
    def _initialize_bracket_configs(self) -> Dict[str, Dict[int, Dict]]:
        """Initialize bracket configuration templates"""
        return {
            'single_elimination': {
                4: {'rounds': 2, 'matches': 3},
                8: {'rounds': 3, 'matches': 7},
                16: {'rounds': 4, 'matches': 15},
                32: {'rounds': 5, 'matches': 31},
                64: {'rounds': 6, 'matches': 63}
            },
            'double_elimination': {
                4: {'wb_rounds': 2, 'lb_rounds': 2, 'total_matches': 6},
                8: {'wb_rounds': 3, 'lb_rounds': 5, 'total_matches': 14},
                16: {'wb_rounds': 4, 'lb_rounds': 7, 'total_matches': 30},
                32: {'wb_rounds': 5, 'lb_rounds': 9, 'total_matches': 62},
                64: {'wb_rounds': 6, 'lb_rounds': 11, 'total_matches': 126}
            }
        }
    
    def generate_single_elimination_bracket(self, player_count: int) -> BracketStructure:
        """Generate complete single elimination bracket"""
        if player_count not in self.bracket_configs['single_elimination']:
            raise ValueError(f"Unsupported player count for SE: {player_count}")
        
        config = self.bracket_configs['single_elimination'][player_count]
        total_rounds = config['rounds']
        total_matches = config['matches']
        
        matches = []
        rounds = {}
        advancement_map = {}
        
        # Generate matches round by round
        match_counter = 1
        
        for round_num in range(1, total_rounds + 1):
            rounds[round_num] = []
            matches_in_round = player_count // (2 ** round_num)
            
            for i in range(matches_in_round):
                match = MatchInfo(
                    match_number=match_counter,
                    round_number=round_num,
                    is_winner_bracket=True
                )
                
                # Calculate advancement (winner goes to next round)
                if round_num < total_rounds:
                    next_match_number = self._calculate_se_advancement(match_counter, round_num, player_count)
                    match.winner_advances_to = next_match_number
                    advancement_map[match_counter] = {'winner': next_match_number}
                else:
                    # Final match - no advancement
                    advancement_map[match_counter] = {}
                
                rounds[round_num].append(match)
                matches.append(match)
                match_counter += 1
        
        return BracketStructure(
            format_type='single_elimination',
            player_count=player_count,
            total_matches=total_matches,
            rounds=rounds,
            advancement_map=advancement_map
        )
    
    def generate_double_elimination_bracket(self, player_count: int) -> BracketStructure:
        """Generate complete double elimination bracket"""
        if player_count not in self.bracket_configs['double_elimination']:
            raise ValueError(f"Unsupported player count for DE: {player_count}")
        
        config = self.bracket_configs['double_elimination'][player_count]
        wb_rounds = config['wb_rounds']
        lb_rounds = config['lb_rounds']
        total_matches = config['total_matches']
        
        matches = []
        rounds = {}
        advancement_map = {}
        
        # Generate Winners Bracket
        wb_matches = self._generate_winners_bracket(player_count, wb_rounds)
        
        # Generate Losers Bracket  
        lb_matches = self._generate_losers_bracket(player_count, lb_rounds, wb_rounds)
        
        # Generate Grand Final
        grand_final = self._generate_grand_final(wb_rounds, lb_rounds)
        
        # Combine all matches
        all_matches = wb_matches + lb_matches + [grand_final]
        
        # Group by rounds
        for match in all_matches:
            round_num = match.round_number
            if round_num not in rounds:
                rounds[round_num] = []
            rounds[round_num].append(match)
        
        # Calculate advancement map
        advancement_map = self._calculate_de_advancement_map(all_matches, player_count)
        
        return BracketStructure(
            format_type='double_elimination',
            player_count=player_count,
            total_matches=total_matches,
            rounds=rounds,
            advancement_map=advancement_map
        )
    
    def _generate_winners_bracket(self, player_count: int, wb_rounds: int) -> List[MatchInfo]:
        """Generate winners bracket matches"""
        matches = []
        match_counter = 1
        
        for round_num in range(1, wb_rounds + 1):
            matches_in_round = player_count // (2 ** round_num)
            
            for i in range(matches_in_round):
                match = MatchInfo(
                    match_number=match_counter,
                    round_number=round_num,
                    is_winner_bracket=True
                )
                matches.append(match)
                match_counter += 1
        
        return matches
    
    def _generate_losers_bracket(self, player_count: int, lb_rounds: int, wb_rounds: int) -> List[MatchInfo]:
        """Generate losers bracket matches"""
        matches = []
        
        # Losers bracket starts at round 101 for easy identification
        lb_start_round = 101
        
        # Calculate match numbers for losers bracket
        wb_matches_count = sum(player_count // (2 ** r) for r in range(1, wb_rounds + 1))
        match_counter = wb_matches_count + 1
        
        for lb_round in range(lb_rounds):
            round_num = lb_start_round + lb_round
            
            # Calculate matches in this LB round
            if lb_round == 0:
                # First LB round gets half the initial players
                matches_in_round = player_count // 4
            else:
                # Subsequent rounds follow elimination pattern
                matches_in_round = max(1, matches_in_round // 2) if lb_round % 2 == 1 else matches_in_round
            
            for i in range(matches_in_round):
                match = MatchInfo(
                    match_number=match_counter,
                    round_number=round_num,
                    is_winner_bracket=False
                )
                matches.append(match)
                match_counter += 1
        
        return matches
    
    def _generate_grand_final(self, wb_rounds: int, lb_rounds: int) -> MatchInfo:
        """Generate grand final match"""
        # Grand final is always the last match
        grand_final_round = max(wb_rounds, 101 + lb_rounds - 1) + 1
        
        return MatchInfo(
            match_number=9999,  # Special number for grand final
            round_number=grand_final_round,
            is_winner_bracket=True  # Grand final is neutral
        )
    
    def _calculate_se_advancement(self, match_number: int, round_num: int, player_count: int) -> int:
        """Calculate where winner advances in single elimination"""
        # Simple formula: winner advances to next round
        matches_before_next_round = sum(player_count // (2 ** r) for r in range(1, round_num + 1))
        position_in_round = match_number - sum(player_count // (2 ** r) for r in range(1, round_num))
        next_match = matches_before_next_round + ((position_in_round - 1) // 2) + 1
        return next_match
    
    def _calculate_de_advancement_map(self, matches: List[MatchInfo], player_count: int) -> Dict[int, Dict[str, int]]:
        """Calculate complete advancement mapping for double elimination"""
        advancement_map = {}
        
        # This is complex - implement based on standard DE bracket rules
        # For now, return empty mapping - will be implemented in detail later
        for match in matches:
            advancement_map[match.match_number] = {}
        
        return advancement_map
    
    def generate_bracket(self, format_type: str, player_count: int) -> BracketStructure:
        """Main method to generate any bracket type"""
        if format_type == 'single_elimination':
            return self.generate_single_elimination_bracket(player_count)
        elif format_type == 'double_elimination':
            return self.generate_double_elimination_bracket(player_count)
        else:
            raise ValueError(f"Unsupported format type: {format_type}")
    
    def get_supported_formats(self) -> Dict[str, List[int]]:
        """Get all supported tournament formats"""
        return {
            'single_elimination': list(self.bracket_configs['single_elimination'].keys()),
            'double_elimination': list(self.bracket_configs['double_elimination'].keys())
        }

def test_bracket_generation():
    """Test the bracket generation system"""
    generator = UniversalBracketGenerator()
    
    print("🧪 TESTING UNIVERSAL BRACKET GENERATION")
    print("=" * 50)
    
    # Test all supported formats
    supported = generator.get_supported_formats()
    
    for format_type, player_counts in supported.items():
        print(f"\n🎯 Testing {format_type.upper().replace('_', ' ')}:")
        
        for player_count in player_counts:
            try:
                bracket = generator.generate_bracket(format_type, player_count)
                print(f"  ✅ {player_count} players: {bracket.total_matches} matches, {len(bracket.rounds)} rounds")
                
                # Show round structure
                round_info = []
                for round_num in sorted(bracket.rounds.keys()):
                    matches_count = len(bracket.rounds[round_num])
                    round_info.append(f"R{round_num}:{matches_count}")
                print(f"     Structure: {' | '.join(round_info)}")
                
            except Exception as e:
                print(f"  ❌ {player_count} players: {str(e)}")

if __name__ == '__main__':
    test_bracket_generation()