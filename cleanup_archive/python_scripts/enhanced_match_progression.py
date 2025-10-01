#!/usr/bin/env python3
"""
Enhanced Match Progression Service Integration
Integrates Universal Advancement System with existing Flutter service
"""

from supabase import create_client
from universal_advancement_system import UniversalAdvancementSystem
from typing import Dict, List, Optional
import json

class EnhancedMatchProgressionService:
    """
    Enhanced version of MatchProgressionService that uses Universal Advancement System
    """
    
    def __init__(self):
        # Initialize Supabase
        self.SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
        self.SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
        self.supabase = create_client(self.SUPABASE_URL, self.SERVICE_KEY)
        self.advancement_system = UniversalAdvancementSystem()
    
    def update_match_result_with_immediate_advancement(
        self,
        match_id: str,
        tournament_id: str,
        winner_id: str,
        loser_id: str,
        scores: Dict[str, int],
        notes: str = None
    ) -> Dict:
        """
        Update match result and immediately advance players if possible
        
        This is the enhanced version that provides immediate advancement
        without waiting for full round completion
        """
        try:
            print(f'🎯 Starting enhanced match progression for match {match_id[:8]}')
            
            # 1. Update match result in database
            self._update_match_in_database(match_id, winner_id, scores, notes)
            print('✅ Match updated in database')
            
            # 2. Get tournament format to determine if immediate advancement is supported
            tournament = self.supabase.table('tournaments').select(
                'bracket_format, game_format, title'
            ).eq('id', tournament_id).execute()
            
            if not tournament.data:
                return {'error': f'Tournament {tournament_id} not found'}
            
            tournament_info = tournament.data[0]
            bracket_format = tournament_info['bracket_format']
            
            print(f'🏆 Tournament: {tournament_info["title"]} ({bracket_format})')
            
            # 3. Check if immediate advancement is possible
            match_details = self.supabase.table('matches').select(
                'match_number, round_number'
            ).eq('id', match_id).execute()
            
            if not match_details.data:
                return {'error': f'Match {match_id} not found'}
            
            match_number = match_details.data[0]['match_number']
            
            # 4. Perform immediate advancement
            advancement_result = self.advancement_system.advance_players(
                tournament_id=tournament_id,
                completed_match_id=match_id,
                winner_id=winner_id
            )
            
            if 'error' in advancement_result:
                return advancement_result
            
            print(f'🚀 Immediate advancement completed!')
            print(f'   Winner advanced: {len([a for a in advancement_result["advancements"] if a.get("advancement_type") == "winner"])}')
            print(f'   Loser advanced: {len([a for a in advancement_result["advancements"] if a.get("advancement_type") == "loser"])}')
            
            # 5. Check tournament completion
            is_complete = self._check_tournament_completion(tournament_id)
            
            # 6. Prepare response
            return {
                'success': True,
                'match_updated': True,
                'immediate_advancement': True,
                'progression_completed': len(advancement_result['advancements']) > 0,
                'tournament_complete': is_complete,
                'advancement_details': advancement_result['advancements'],
                'next_matches': self._get_next_ready_matches(tournament_id),
                'message': f'Match completed with immediate advancement! {len(advancement_result["advancements"])} players advanced.'
            }
        
        except Exception as e:
            print(f'❌ Error in enhanced match progression: {str(e)}')
            return {
                'success': False,
                'error': str(e),
                'message': 'Failed to process match with immediate advancement'
            }
    
    def _update_match_in_database(self, match_id: str, winner_id: str, scores: Dict[str, int], notes: str = None):
        """Update match result in database"""
        update_data = {
            'winner_id': winner_id,
            'player1_score': scores.get('player1', 0),
            'player2_score': scores.get('player2', 0),
            'status': 'completed',
            'end_time': 'now()'
        }
        
        if notes:
            update_data['notes'] = notes
        
        self.supabase.table('matches').update(update_data).eq('id', match_id).execute()
    
    def _check_tournament_completion(self, tournament_id: str) -> bool:
        """Check if tournament is complete"""
        # Get all matches
        matches = self.supabase.table('matches').select('status').eq('tournament_id', tournament_id).execute()
        
        if not matches.data:
            return False
        
        # Tournament is complete if all matches are completed
        completed_matches = [m for m in matches.data if m['status'] == 'completed']
        return len(completed_matches) == len(matches.data)
    
    def _get_next_ready_matches(self, tournament_id: str) -> List[Dict]:
        """Get matches that are ready to be played (have both players assigned)"""
        matches = self.supabase.table('matches').select(
            'id, match_number, round_number, player1_id, player2_id, status'
        ).eq('tournament_id', tournament_id).eq('status', 'pending').execute()
        
        ready_matches = []
        for match in matches.data:
            if match['player1_id'] and match['player2_id']:
                ready_matches.append({
                    'id': match['id'],
                    'match_number': match['match_number'],
                    'round_number': match['round_number']
                })
        
        return ready_matches
    
    def get_tournament_bracket_status(self, tournament_id: str) -> Dict:
        """Get complete tournament bracket status"""
        try:
            # Get tournament info
            tournament = self.supabase.table('tournaments').select(
                'title, bracket_format, game_format, max_participants, status'
            ).eq('id', tournament_id).execute()
            
            if not tournament.data:
                return {'error': f'Tournament {tournament_id} not found'}
            
            tournament_info = tournament.data[0]
            
            # Get all matches
            matches = self.supabase.table('matches').select(
                'id, match_number, round_number, player1_id, player2_id, winner_id, status'
            ).eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
            
            # Analyze bracket status
            total_matches = len(matches.data)
            completed_matches = len([m for m in matches.data if m['status'] == 'completed'])
            ready_matches = len([m for m in matches.data if m['player1_id'] and m['player2_id'] and m['status'] == 'pending'])
            
            # Group matches by round
            rounds = {}
            for match in matches.data:
                round_num = match['round_number']
                if round_num not in rounds:
                    rounds[round_num] = []
                rounds[round_num].append(match)
            
            return {
                'tournament': tournament_info,
                'total_matches': total_matches,
                'completed_matches': completed_matches,
                'ready_matches': ready_matches,
                'progress_percentage': round((completed_matches / total_matches) * 100, 1) if total_matches > 0 else 0,
                'rounds': {str(k): len(v) for k, v in rounds.items()},
                'immediate_advancement_enabled': True,
                'next_ready_matches': self._get_next_ready_matches(tournament_id)
            }
        
        except Exception as e:
            return {'error': f'Failed to get bracket status: {str(e)}'}

def test_enhanced_progression():
    """Test the enhanced match progression system"""
    service = EnhancedMatchProgressionService()
    
    print('🧪 TESTING ENHANCED MATCH PROGRESSION')
    print('=' * 50)
    
    # Test with sabo1 tournament
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Get bracket status
    print('\\n📊 Getting tournament bracket status...')
    status = service.get_tournament_bracket_status(sabo1_id)
    
    if 'error' in status:
        print(f'❌ Error: {status["error"]}')
        return
    
    print(f'🏆 Tournament: {status["tournament"]["title"]}')
    print(f'   Format: {status["tournament"]["bracket_format"]}')
    print(f'   Progress: {status["completed_matches"]}/{status["total_matches"]} matches ({status["progress_percentage"]}%)')
    print(f'   Ready to play: {status["ready_matches"]} matches')
    print(f'   Immediate advancement: {"✅ Enabled" if status["immediate_advancement_enabled"] else "❌ Disabled"}')
    
    print(f'\\n🏗️  Round structure:')
    for round_num, match_count in status['rounds'].items():
        round_type = 'Winners Bracket' if int(round_num) < 100 else 'Losers Bracket'
        if int(round_num) >= 108:
            round_type = 'Grand Final'
        print(f'   Round {round_num}: {match_count} matches ({round_type})')
    
    if status['next_ready_matches']:
        print(f'\\n⚡ Next ready matches:')
        for match in status['next_ready_matches'][:3]:  # Show first 3
            print(f'   Match {match["match_number"]} (Round {match["round_number"]})')

def simulate_match_completion():
    """Simulate completing a match to test immediate advancement"""
    service = EnhancedMatchProgressionService()
    
    print('\\n🎮 SIMULATING MATCH COMPLETION WITH IMMEDIATE ADVANCEMENT')
    print('=' * 60)
    
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Find a ready match to simulate
    ready_matches = service._get_next_ready_matches(sabo1_id)
    
    if not ready_matches:
        print('❌ No ready matches found for simulation')
        return
    
    # Get match details for simulation
    match_to_complete = ready_matches[0]
    match_details = service.supabase.table('matches').select(
        'id, match_number, player1_id, player2_id'
    ).eq('id', match_to_complete['id']).execute()
    
    if not match_details.data:
        print('❌ Could not get match details')
        return
    
    match_info = match_details.data[0]
    
    print(f'🎯 Simulating completion of Match {match_info["match_number"]}')
    print(f'   Players: {match_info["player1_id"][:8]} vs {match_info["player2_id"][:8]}')
    
    # Simulate match result (player1 wins)
    result = service.update_match_result_with_immediate_advancement(
        match_id=match_info['id'],
        tournament_id=sabo1_id,
        winner_id=match_info['player1_id'],
        loser_id=match_info['player2_id'],
        scores={'player1': 9, 'player2': 4}
    )
    
    if 'error' in result:
        print(f'❌ Simulation failed: {result["error"]}')
        return
    
    print(f'✅ Simulation successful!')
    print(f'   Immediate advancement: {"✅ Yes" if result["immediate_advancement"] else "❌ No"}')
    print(f'   Players advanced: {len(result["advancement_details"])}')
    
    for advancement in result['advancement_details']:
        if 'error' not in advancement:
            print(f'     {advancement["advancement_type"].title()}: Advanced to Match {advancement["advanced_to_match"]} (Round {advancement["advanced_to_round"]})')

if __name__ == '__main__':
    # Test enhanced progression
    test_enhanced_progression()
    
    # Simulate match completion
    simulate_match_completion()