from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 CHECKING SABO3 TOURNAMENT MATCHES...')
print('=' * 50)

tournament_id = 'f7d7484c-b8fe-4d1d-8bf9-fa46e989de61'

# Get matches
matches_result = supabase.table('matches').select('round_number, match_number, player1_id, player2_id, status').eq('tournament_id', tournament_id).order('round_number, match_number').execute()

if not matches_result.data:
    print('❌ No matches found!')
    exit()

matches = matches_result.data
print(f'✅ Found {len(matches)} matches')

# Count matches with players
matches_with_players = 0
empty_matches = []

print('\n📊 MATCH PLAYER STATUS:')
for match in matches:
    round_num = match['round_number']
    match_num = match['match_number']
    p1 = match['player1_id']
    p2 = match['player2_id']
    status = match['status']
    
    has_p1 = '✅' if p1 else '❌'
    has_p2 = '✅' if p2 else '❌'
    
    if p1 or p2:
        matches_with_players += 1
    else:
        empty_matches.append(f'R{round_num}M{match_num}')
    
    print(f'   R{round_num}M{match_num}: P1={has_p1} P2={has_p2} Status={status}')

print(f'\n📈 SUMMARY:')
print(f'   Total matches: {len(matches)}')
print(f'   Matches with players: {matches_with_players}')
print(f'   Empty matches: {len(empty_matches)}')

if empty_matches:
    print(f'\n❌ EMPTY MATCHES: {", ".join(empty_matches[:10])}')
    if len(empty_matches) > 10:
        print(f'   ... and {len(empty_matches) - 10} more')

# Check if we have participants registered
participants_result = supabase.table('tournament_participants').select('user_id').eq('tournament_id', tournament_id).execute()
participants_count = len(participants_result.data) if participants_result.data else 0

print(f'\n👥 PARTICIPANTS:')
print(f'   Registered participants: {participants_count}')

if participants_count > 0 and matches_with_players == 0:
    print('\n🚨 PROBLEM DETECTED:')
    print('   - Participants are registered')
    print('   - Matches were created')
    print('   - But NO players assigned to matches!')
    print('   - This suggests bracket generation incomplete')