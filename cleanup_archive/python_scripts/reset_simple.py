from supabase import create_client
import uuid

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔄 SIMPLIFIED RESET FOR IMMEDIATE ADVANCEMENT TEST')
print('=' * 60)

tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

# Step 1: Clear existing matches
print('🗑️ Step 1: Clearing existing matches...')
result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
print('   ✅ Cleared existing matches')

# Step 2: Set tournament to ongoing
print('🔧 Step 2: Setting tournament to ongoing...')
supabase.table('tournaments').update({
    'status': 'ongoing'
}).eq('id', tournament_id).execute()
print('   ✅ Tournament status = ongoing')

# Step 3: Get existing real users for matches
print('👥 Step 3: Getting existing users...')
users = supabase.table('users').select('id, display_name').limit(8).execute()
if len(users.data) < 4:
    print(f'   ⚠️ Only {len(users.data)} users found, creating simplified test matches')
    user_ids = [user['id'] for user in users.data[:4]]
else:
    user_ids = [user['id'] for user in users.data[:8]]
    print(f'   ✅ Found {len(user_ids)} users for matches')

# Step 4: Create Winner Bracket Round 1 matches
print('🏆 Step 4: Creating Winner Bracket Round 1 matches...')

if len(user_ids) >= 4:
    # Create 2 matches with real users
    wb_matches = [
        {'match_number': 1, 'player1_id': user_ids[0], 'player2_id': user_ids[1]},
        {'match_number': 2, 'player1_id': user_ids[2], 'player2_id': user_ids[3]}
    ]
    
    if len(user_ids) >= 8:
        # Add 2 more matches if we have 8 users
        wb_matches.extend([
            {'match_number': 3, 'player1_id': user_ids[4], 'player2_id': user_ids[5]},
            {'match_number': 4, 'player1_id': user_ids[6], 'player2_id': user_ids[7]}
        ])

    for match in wb_matches:
        match_data = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 1,  # WB Round 1
            'match_number': match['match_number'],
            'player1_id': match['player1_id'],
            'player2_id': match['player2_id'],
            'status': 'pending',
            'player1_score': 0,
            'player2_score': 0,
            'scheduled_at': '2025-01-15T14:00:00Z',
            'created_at': '2025-01-15T10:00:00Z'
        }
        supabase.table('matches').insert(match_data).execute()
        print(f'   ✅ WB Match {match["match_number"]}: Created with real users')

# Step 5: Create empty advancement slots
print('🏆 Step 5: Creating advancement slots...')

# WB Round 2 slots
for i in range(1, 3):
    match_data = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 2,  # WB Round 2
        'match_number': i + 10,  # Match 11, 12
        'player1_id': None,
        'player2_id': None,
        'status': 'pending',
        'player1_score': 0,
        'player2_score': 0,
        'scheduled_at': '2025-01-15T16:00:00Z',
        'created_at': '2025-01-15T10:00:00Z'
    }
    supabase.table('matches').insert(match_data).execute()
    print(f'   ✅ WB Match {i + 10}: Empty slot for winners')

# LB Round 1 slots
for i in range(1, 3):
    match_data = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 101,  # LB Round 1
        'match_number': i + 20,  # Match 21, 22
        'player1_id': None,
        'player2_id': None,
        'status': 'pending',
        'player1_score': 0,
        'player2_score': 0,
        'scheduled_at': '2025-01-15T18:00:00Z',
        'created_at': '2025-01-15T10:00:00Z'
    }
    supabase.table('matches').insert(match_data).execute()
    print(f'   ✅ LB Match {i + 20}: Empty slot for losers')

print('\n✅ SIMPLIFIED RESET COMPLETE!')
print('🎯 sabo1 tournament ready for immediate advancement testing!')
print(f'🏆 Created {len(wb_matches) if "wb_matches" in locals() else 0} pending WB matches with real users')
print('🥈 Created empty advancement slots for winners and losers')
print('\n🚀 IMMEDIATE ADVANCEMENT TEST:')
print('1. Start Flutter app')
print('2. Navigate to sabo1 tournament')
print('3. Complete any pending match')
print('4. Winner should immediately advance to next empty slot!')
print('5. Loser should immediately drop to LB empty slot!')
print('6. NO WAITING for round completion!')