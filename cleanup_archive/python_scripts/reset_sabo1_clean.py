from supabase import create_client
import uuid

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔄 RESETTING SABO1 TOURNAMENT FOR IMMEDIATE ADVANCEMENT TEST')
print('=' * 60)

tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

# Step 1: Clear existing matches
print('🗑️ Step 1: Clearing existing matches...')
result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
print('   ✅ Cleared existing matches')

# Step 2: Clear existing participants
print('🗑️ Step 2: Clearing existing participants...')
result = supabase.table('tournament_participants').delete().eq('tournament_id', tournament_id).execute()
print('   ✅ Cleared existing participants')

# Step 3: Reset tournament status
print('🔧 Step 3: Resetting tournament status...')
supabase.table('tournaments').update({
    'status': 'upcoming',
    'current_participants': 0
}).eq('id', tournament_id).execute()
print('   ✅ Tournament status reset to upcoming')

# Step 4: Add test participants (8 players for clean double elimination)
print('👥 Step 4: Adding 8 test participants...')
test_user_ids = []

for i in range(1, 9):
    user_id = str(uuid.uuid4())
    test_user_ids.append(user_id)
    
    participant_data = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'user_id': user_id,
        'seed_number': i,
        'status': 'confirmed',
        'payment_status': 'paid',
        'registered_at': '2025-01-15T10:00:00Z',
        'notes': f'Player {chr(64+i)} - Test participant for immediate advancement'
    }
    supabase.table('tournament_participants').insert(participant_data).execute()
    print(f'   ✅ Added Player {chr(64+i)} (Seed #{i})')

# Step 5: Update tournament participant count
print('📊 Step 5: Updating participant count...')
supabase.table('tournaments').update({
    'current_participants': 8,
    'status': 'ongoing'
}).eq('id', tournament_id).execute()
print('   ✅ Tournament updated: 8 participants, status = ongoing')

# Step 6: Create initial bracket (Winner Bracket Round 1)
print('🏆 Step 6: Creating Winner Bracket Round 1 matches...')

# WB Round 1 - 4 matches (8 players)
wb_matches = [
    {'match_number': 1, 'player1_id': test_user_ids[0], 'player2_id': test_user_ids[7], 'player1': 'Player A', 'player2': 'Player H'},
    {'match_number': 2, 'player1_id': test_user_ids[1], 'player2_id': test_user_ids[6], 'player1': 'Player B', 'player2': 'Player G'},
    {'match_number': 3, 'player1_id': test_user_ids[2], 'player2_id': test_user_ids[5], 'player1': 'Player C', 'player2': 'Player F'},
    {'match_number': 4, 'player1_id': test_user_ids[3], 'player2_id': test_user_ids[4], 'player1': 'Player D', 'player2': 'Player E'}
]

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
    print(f'   ✅ WB Match {match["match_number"]}: {match["player1"]} vs {match["player2"]}')

# Step 7: Create empty slots for WB Round 2
print('🏆 Step 7: Creating Winner Bracket Round 2 empty slots...')
for i in range(1, 3):  # 2 matches in WB Round 2
    match_data = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 2,  # WB Round 2
        'match_number': i + 4,  # Match 5, 6
        'player1_id': None,
        'player2_id': None,
        'status': 'pending',
        'player1_score': 0,
        'player2_score': 0,
        'scheduled_at': '2025-01-15T16:00:00Z',
        'created_at': '2025-01-15T10:00:00Z'
    }
    supabase.table('matches').insert(match_data).execute()
    print(f'   ✅ WB Match {i + 4}: Empty slot (awaiting WB R1 winners)')

# Step 8: Create Loser Bracket Round 1 empty slots
print('🥈 Step 8: Creating Loser Bracket Round 1 empty slots...')
for i in range(1, 3):  # 2 matches in LB Round 1
    match_data = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 101,  # LB Round 1 (101-series)
        'match_number': i + 10,  # Match 11, 12
        'player1_id': None,
        'player2_id': None,
        'status': 'pending',
        'player1_score': 0,
        'player2_score': 0,
        'scheduled_at': '2025-01-15T18:00:00Z',
        'created_at': '2025-01-15T10:00:00Z'
    }
    supabase.table('matches').insert(match_data).execute()
    print(f'   ✅ LB Match {i + 10}: Empty slot (awaiting WB R1 losers)')

print('\n✅ RESET COMPLETE!')
print('🎯 sabo1 tournament ready for immediate advancement testing!')
print('🏆 Winner Bracket: 4 pending matches')
print('🥈 Loser Bracket: Empty slots ready for losers')
print('\n🚀 NEXT STEPS:')
print('1. Start Flutter app')
print('2. Navigate to sabo1 tournament')
print('3. Complete any WB Round 1 match')
print('4. Watch immediate advancement happen!')
print('   - Winner advances to WB Round 2')
print('   - Loser drops to LB Round 1')
print('   - No waiting for full round completion!')