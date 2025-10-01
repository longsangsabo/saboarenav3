#!/usr/bin/env python3
"""
Setup Test Tournament Using Existing Users
Assigns existing users to tournament matches for testing
"""

from supabase import create_client

# Initialize Supabase
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def get_existing_users(limit=16):
    """Get existing users from database"""
    print(f'👥 Finding existing users...')
    
    users = supabase.table('users').select('id, username, full_name').limit(limit).execute()
    
    print(f'✅ Found {len(users.data)} existing users:')
    for user in users.data[:5]:  # Show first 5
        username = user.get('username', 'No username')
        full_name = user.get('full_name', 'No name')
        print(f'   {user["id"][:8]}: {username} ({full_name})')
    
    if len(users.data) > 5:
        print(f'   ... and {len(users.data) - 5} more')
    
    return [user['id'] for user in users.data]

def assign_users_to_tournament(tournament_id, user_ids):
    """Assign existing users to first round matches"""
    print(f'\\n🎯 Assigning {len(user_ids)} users to tournament matches...')
    
    # Get first round matches (Round 1 - Winners Bracket)
    first_round_matches = supabase.table('matches').select(
        'id, match_number'
    ).eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()
    
    if not first_round_matches.data:
        print('❌ No first round matches found')
        return False
    
    print(f'📋 Found {len(first_round_matches.data)} first round matches')
    
    # Clear existing assignments first
    supabase.table('matches').update({
        'player1_id': None,
        'player2_id': None,
        'status': 'pending'
    }).eq('tournament_id', tournament_id).execute()
    
    print('🧹 Cleared existing player assignments')
    
    # Assign users to matches (2 users per match, reuse users if needed)
    assignments = []
    user_index = 0
    
    for i, match in enumerate(first_round_matches.data):
        # Get two users (cycle through list if we run out)
        player1_id = user_ids[user_index % len(user_ids)]
        user_index += 1
        player2_id = user_ids[user_index % len(user_ids)]
        user_index += 1
        
        # Make sure players are different
        if player1_id == player2_id and len(user_ids) > 1:
            player2_id = user_ids[(user_index) % len(user_ids)]
            user_index += 1
        
        # Update match with users
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
    
    print(f'✅ Assigned users to {len(assignments)} matches:')
    for assignment in assignments:
        print(f'   Match {assignment["match_number"]}: {assignment["player1"]} vs {assignment["player2"]}')
    
    return True

def setup_simple_test():
    """Set up simple test tournament using existing users"""
    print('🏗️  SETTING UP SIMPLE TEST TOURNAMENT')
    print('=' * 40)
    
    # Use sabo1 tournament
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Get existing users
    user_ids = get_existing_users(16)
    
    if len(user_ids) < 2:
        print('❌ Need at least 2 users for testing')
        return
    
    # Assign users to tournament
    success = assign_users_to_tournament(sabo1_id, user_ids)
    
    if success:
        print('\\n🎉 SIMPLE TEST TOURNAMENT SETUP COMPLETE!')
        print(f'   - {len(user_ids)} existing users assigned')
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

def show_tournament_status(tournament_id):
    """Show current tournament status"""
    print('\\n📊 CURRENT TOURNAMENT STATUS')
    print('=' * 35)
    
    # Get tournament info
    tournament = supabase.table('tournaments').select('title, bracket_format').eq('id', tournament_id).execute()
    if tournament.data:
        print(f'🏆 {tournament.data[0]["title"]} ({tournament.data[0]["bracket_format"]})')
    
    # Get matches by status
    all_matches = supabase.table('matches').select('status, round_number').eq('tournament_id', tournament_id).execute()
    
    if not all_matches.data:
        print('❌ No matches found')
        return
    
    # Count by status
    status_counts = {}
    for match in all_matches.data:
        status = match['status']
        if status not in status_counts:
            status_counts[status] = 0
        status_counts[status] += 1
    
    print('\\nMatch status:')
    for status, count in status_counts.items():
        print(f'  {status}: {count} matches')
    
    # Count ready matches
    ready_matches = supabase.table('matches').select('match_number').eq('tournament_id', tournament_id).eq('status', 'pending').not_.is_('player1_id', None).not_.is_('player2_id', None).execute()
    
    print(f'\\n⚡ {len(ready_matches.data)} matches ready to play')

if __name__ == '__main__':
    sabo1_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Setup test
    setup_simple_test()
    
    # Show status
    show_tournament_status(sabo1_id)