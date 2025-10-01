#!/usr/bin/env python3
"""
Create Test Tournament with Real Players
Sets up a tournament with actual players for testing immediate advancement
"""

from supabase import create_client
import uuid

# Initialize Supabase
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def create_test_players(count=16):
    """Create test players for tournament"""
    print(f'👥 Creating {count} test players...')
    
    players = []
    for i in range(1, count + 1):
        player_id = str(uuid.uuid4())
        player_data = {
            'id': player_id,
            'username': f'TestPlayer{i:02d}',
            'full_name': f'Test Player {i}',
            'email': f'testplayer{i}@sabo.com',
            'skill_level': 'intermediate',
            'total_matches': 0,
            'wins': 0,
            'losses': 0,
            'spa_points': 1000
        }
        players.append(player_data)
    
    # Insert players
    result = supabase.table('users').upsert(players).execute()
    print(f'✅ Created {len(result.data)} test players')
    
    return [p['id'] for p in players]

def assign_players_to_tournament(tournament_id, player_ids):
    """Assign players to first round matches"""
    print(f'🎯 Assigning {len(player_ids)} players to tournament matches...')
    
    # Get first round matches (Round 1 - Winners Bracket)
    first_round_matches = supabase.table('matches').select(
        'id, match_number'
    ).eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()
    
    if not first_round_matches.data:
        print('❌ No first round matches found')
        return False
    
    print(f'📋 Found {len(first_round_matches.data)} first round matches')
    
    # Assign players to matches (2 players per match)
    assignments = []
    for i, match in enumerate(first_round_matches.data):
        if i * 2 < len(player_ids) and i * 2 + 1 < len(player_ids):
            player1_id = player_ids[i * 2]
            player2_id = player_ids[i * 2 + 1]
            
            # Update match with players
            supabase.table('matches').update({
                'player1_id': player1_id,
                'player2_id': player2_id,
                'status': 'pending'
            }).eq('id', match['id']).execute()
            
            assignments.append({
                'match_number': match['match_number'],
                'player1': player1_id[:8],
                'player2': player2_id[:8]
            })
    
    print(f'✅ Assigned players to {len(assignments)} matches:')
    for assignment in assignments:
        print(f'   Match {assignment["match_number"]}: {assignment["player1"]} vs {assignment["player2"]}')
    
    return True

def setup_test_tournament():
    """Set up complete test tournament with players"""
    print('🏗️  SETTING UP TEST TOURNAMENT FOR IMMEDIATE ADVANCEMENT')
    print('=' * 60)
    
    # Use sabo1 tournament
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Create test players
    player_ids = create_test_players(16)
    
    # Assign players to tournament
    success = assign_players_to_tournament(sabo1_id, player_ids)
    
    if success:
        print('\\n🎉 TEST TOURNAMENT SETUP COMPLETE!')
        print('   - 16 test players created')
        print('   - Players assigned to first round matches')
        print('   - Tournament ready for immediate advancement testing')
        
        # Show current status
        ready_matches = supabase.table('matches').select(
            'match_number, player1_id, player2_id'
        ).eq('tournament_id', sabo1_id).eq('round_number', 1).not_.is_('player1_id', None).not_.is_('player2_id', None).execute()
        
        print(f'\\n⚡ {len(ready_matches.data)} matches ready to play:')
        for match in ready_matches.data:
            print(f'   Match {match["match_number"]}: {match["player1_id"][:8]} vs {match["player2_id"][:8]}')
    
    else:
        print('❌ Failed to set up test tournament')

def clean_test_data():
    """Clean up test data"""
    print('🧹 CLEANING UP TEST DATA')
    print('=' * 30)
    
    # Delete test players
    result = supabase.table('users').delete().like('username', 'TestPlayer%').execute()
    print(f'🗑️  Deleted {len(result.data)} test players')

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == 'clean':
        clean_test_data()
    else:
        setup_test_tournament()