from supabase import create_client
import uuid

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔄 ULTRA SIMPLE RESET FOR IMMEDIATE ADVANCEMENT TEST')
print('=' * 60)

tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

# Step 1: Clear existing matches
print('🗑️ Clearing existing matches...')
result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
print('   ✅ Cleared')

# Step 2: Set tournament to ongoing
print('🔧 Setting tournament to ongoing...')
supabase.table('tournaments').update({'status': 'ongoing'}).eq('id', tournament_id).execute()
print('   ✅ Status = ongoing')

# Step 3: Get 4 real users
print('👥 Getting users...')
users = supabase.table('users').select('id').limit(4).execute()
user_ids = [user['id'] for user in users.data[:4]]
print(f'   ✅ Found {len(user_ids)} users')

# Step 4: Create minimal matches
print('🏆 Creating test matches...')

# Just create 2 simple matches for testing
matches_to_create = [
    {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'player1_id': user_ids[0],
        'player2_id': user_ids[1],
        'status': 'pending',
        'round_number': 1,
        'match_number': 1,
    },
    {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'player1_id': user_ids[2],
        'player2_id': user_ids[3],
        'status': 'pending',
        'round_number': 1,
        'match_number': 2,
    }
]

for i, match_data in enumerate(matches_to_create):
    supabase.table('matches').insert(match_data).execute()
    print(f'   ✅ Match {i+1}: Created')

# Step 5: Create advancement slots
print('🎯 Creating advancement slots...')

advancement_slots = [
    {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'status': 'pending',
        'round_number': 2,
        'match_number': 10,
    },
    {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'status': 'pending',
        'round_number': 101,  # Loser bracket
        'match_number': 11,
    }
]

for i, slot_data in enumerate(advancement_slots):
    supabase.table('matches').insert(slot_data).execute()
    print(f'   ✅ Advancement slot {i+1}: Created')

print('\n✅ ULTRA SIMPLE RESET COMPLETE!')
print('🎯 sabo1 tournament ready!')
print('📱 NOW START FLUTTER APP AND TEST!')
print('🏆 Complete Match 1 or 2 → Should trigger immediate advancement!')
print('🚀 Winner advances to Match 10, Loser to Match 11!')