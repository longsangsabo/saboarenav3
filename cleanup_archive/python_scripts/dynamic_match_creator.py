#!/usr/bin/env python3
"""
Dynamic Match Creation System
Automatically generates complete tournament brackets in database
"""

from supabase import create_client
from universal_bracket_generator import UniversalBracketGenerator, BracketStructure
from typing import List, Dict, Optional
import uuid
from datetime import datetime

class DynamicMatchCreator:
    """
    Creates complete tournament brackets in the database
    """
    
    def __init__(self):
        # Initialize Supabase
        self.SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
        self.SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
        self.supabase = create_client(self.SUPABASE_URL, self.SERVICE_KEY)
        self.bracket_generator = UniversalBracketGenerator()
    
    def create_tournament_matches(self, tournament_id: str, players: List[str] = None, force_recreate: bool = False) -> Dict:
        """
        Create complete tournament bracket with all matches
        
        Args:
            tournament_id: Tournament UUID
            players: Optional list of player IDs for seeding
            force_recreate: If True, delete existing matches and recreate
        
        Returns:
            Dict with creation status and statistics
        """
        try:
            # Get tournament information
            tournament_result = self.supabase.table('tournaments').select(
                'id, title, bracket_format, max_participants, status'
            ).eq('id', tournament_id).execute()
            
            if not tournament_result.data:
                return {'error': f'Tournament {tournament_id} not found'}
            
            tournament = tournament_result.data[0]
            format_type = tournament['bracket_format']
            max_participants = tournament['max_participants']
            
            print(f'🏆 Creating matches for: {tournament["title"]}')
            print(f'   Format: {format_type}')
            print(f'   Players: {max_participants}')
            
            # Check if matches already exist
            existing_matches = self.supabase.table('matches').select('id').eq('tournament_id', tournament_id).execute()
            
            if existing_matches.data and not force_recreate:
                return {
                    'error': f'Tournament already has {len(existing_matches.data)} matches. Use force_recreate=True to recreate.'
                }
            
            # Delete existing matches if force recreate
            if existing_matches.data and force_recreate:
                print(f'🗑️  Deleting {len(existing_matches.data)} existing matches...')
                self.supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
            
            # Generate bracket structure
            bracket = self.bracket_generator.generate_bracket(format_type, max_participants)
            
            # Create matches in database
            matches_created = self._create_matches_in_database(tournament_id, bracket, players)
            
            # Update tournament status to ongoing (matches created)
            self.supabase.table('tournaments').update({
                'status': 'ongoing',
                'updated_at': datetime.utcnow().isoformat()
            }).eq('id', tournament_id).execute()
            
            return {
                'success': True,
                'tournament_id': tournament_id,
                'tournament_title': tournament['title'],
                'format': format_type,
                'total_matches': len(matches_created),
                'rounds': len(bracket.rounds),
                'bracket_structure': self._get_round_summary(bracket),
                'matches_created': matches_created
            }
            
        except Exception as e:
            return {'error': f'Failed to create tournament matches: {str(e)}'}
    
    def _create_matches_in_database(self, tournament_id: str, bracket: BracketStructure, players: List[str] = None) -> List[Dict]:
        """Create all matches in the database"""
        matches_to_insert = []
        created_matches = []
        
        # Prepare player assignments
        player_assignments = self._prepare_player_seeding(players, bracket.player_count) if players else {}
        
        # Create matches for each round
        for round_number, matches_in_round in bracket.rounds.items():
            for match_info in matches_in_round:
                
                # Determine player assignments for first round
                player1_id = None
                player2_id = None
                
                if round_number == 1 and players:  # First round of Winners Bracket
                    player1_id, player2_id = self._get_first_round_players(match_info.match_number, player_assignments)
                
                match_data = {
                    'id': str(uuid.uuid4()),
                    'tournament_id': tournament_id,
                    'round_number': round_number,
                    'match_number': match_info.match_number,
                    'player1_id': player1_id,
                    'player2_id': player2_id,
                    'status': 'pending',
                    'winner_id': None,
                    'player1_score': 0,
                    'player2_score': 0,
                    'scheduled_time': None,
                    'created_at': datetime.utcnow().isoformat(),
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                matches_to_insert.append(match_data)
                created_matches.append({
                    'match_number': match_info.match_number,
                    'round_number': round_number,
                    'is_winner_bracket': match_info.is_winner_bracket
                })
        
        # Batch insert matches
        if matches_to_insert:
            print(f'📝 Inserting {len(matches_to_insert)} matches into database...')
            result = self.supabase.table('matches').insert(matches_to_insert).execute()
            print(f'✅ Successfully created {len(result.data)} matches')
        
        return created_matches
    
    def _prepare_player_seeding(self, players: List[str], total_slots: int) -> Dict[int, str]:
        """Prepare player seeding for bracket positions"""
        if not players:
            return {}
        
        # Standard seeding for tournaments
        seeding_order = self._calculate_seeding_order(total_slots)
        player_assignments = {}
        
        for i, player_id in enumerate(players[:total_slots]):
            bracket_position = seeding_order[i] if i < len(seeding_order) else i + 1
            player_assignments[bracket_position] = player_id
        
        return player_assignments
    
    def _calculate_seeding_order(self, total_slots: int) -> List[int]:
        """Calculate standard tournament seeding order"""
        # Standard seeding: 1 vs lowest, 2 vs second lowest, etc.
        if total_slots == 4:
            return [1, 4, 2, 3]
        elif total_slots == 8:
            return [1, 8, 4, 5, 2, 7, 3, 6]
        elif total_slots == 16:
            return [1, 16, 8, 9, 4, 13, 5, 12, 2, 15, 7, 10, 3, 14, 6, 11]
        elif total_slots == 32:
            # Simplified for now - can be expanded
            return list(range(1, 33))
        else:
            return list(range(1, total_slots + 1))
    
    def _get_first_round_players(self, match_number: int, player_assignments: Dict[int, str]) -> tuple:
        """Get player IDs for first round matches based on seeding"""
        # Simple mapping for now - can be made more sophisticated
        position1 = (match_number - 1) * 2 + 1
        position2 = (match_number - 1) * 2 + 2
        
        player1 = player_assignments.get(position1)
        player2 = player_assignments.get(position2)
        
        return player1, player2
    
    def _get_round_summary(self, bracket: BracketStructure) -> Dict[int, int]:
        """Get summary of matches per round"""
        return {round_num: len(matches) for round_num, matches in bracket.rounds.items()}
    
    def create_all_missing_tournaments(self) -> Dict:
        """Create matches for all tournaments that don't have any"""
        print('🔍 Finding tournaments without matches...')
        
        # Get all tournaments
        tournaments = self.supabase.table('tournaments').select('id, title, bracket_format, max_participants').execute()
        
        results = []
        
        for tournament in tournaments.data:
            tournament_id = tournament['id']
            
            # Check if tournament has matches
            matches = self.supabase.table('matches').select('id').eq('tournament_id', tournament_id).execute()
            
            if not matches.data:  # No matches exist
                print(f'\\n🏗️  Creating matches for: {tournament["title"]}')
                result = self.create_tournament_matches(tournament_id)
                results.append(result)
            else:
                print(f'✅ {tournament["title"]}: Already has {len(matches.data)} matches')
        
        return {
            'tournaments_processed': len(results),
            'results': results
        }

def test_match_creation():
    """Test the dynamic match creation system"""
    creator = DynamicMatchCreator()
    
    print('🧪 TESTING DYNAMIC MATCH CREATION')
    print('=' * 50)
    
    # Test with sabo1 tournament (force recreate to test)
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    print('\\n🎯 Testing match creation for sabo1 tournament...')
    result = creator.create_tournament_matches(sabo1_id, force_recreate=True)
    
    if 'error' in result:
        print(f'❌ Error: {result["error"]}')
    else:
        print(f'✅ Success!')
        print(f'   Tournament: {result["tournament_title"]}')
        print(f'   Format: {result["format"]}')
        print(f'   Total Matches: {result["total_matches"]}')
        print(f'   Rounds: {result["rounds"]}')
        print(f'   Structure: {result["bracket_structure"]}')

def create_all_missing():
    """Create matches for all tournaments missing them"""
    creator = DynamicMatchCreator()
    
    print('🚀 CREATING ALL MISSING TOURNAMENT MATCHES')
    print('=' * 50)
    
    result = creator.create_all_missing_tournaments()
    print(f'\\nProcessed {result["tournaments_processed"]} tournaments')
    
    for r in result['results']:
        if 'error' in r:
            print(f'❌ Error: {r["error"]}')
        else:
            print(f'✅ {r["tournament_title"]}: {r["total_matches"]} matches created')

if __name__ == '__main__':
    # Test individual tournament
    test_match_creation()
    
    print('\\n' + '=' * 60)
    
    # Create all missing
    create_all_missing()