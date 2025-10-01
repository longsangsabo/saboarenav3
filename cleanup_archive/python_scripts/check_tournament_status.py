from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 TOURNAMENT STATUS CHECK')
print('=' * 40)

tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

# Check tournament details
tournament = supabase.table('tournaments').select('*').eq('id', tournament_id).single().execute()
print('📋 TOURNAMENT INFO:')
print(f'   Title: {tournament.data["title"]}')
print(f'   Status: {tournament.data["status"]}')
print(f'   Format: {tournament.data["bracket_format"]}')
print(f'   Max Participants: {tournament.data["max_participants"]}')
print(f'   Current Participants: {tournament.data["current_participants"]}')

# Check total matches for this tournament
all_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
print('')
print('📊 MATCHES OVERVIEW:')
print(f'   Total matches: {len(all_matches.data)}')

if all_matches.data:
    # Group by round_number
    rounds = {}
    for match in all_matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    print(f'   Rounds found: {sorted(rounds.keys())}')
    
    for round_num in sorted(rounds.keys()):
        matches = rounds[round_num]
        completed = sum(1 for m in matches if m['status'] == 'completed')
        pending = sum(1 for m in matches if m['status'] == 'pending')
        
        if round_num < 100:
            round_type = 'WB'
        else:
            round_type = 'LB'
            
        print(f'   {round_type} Round {round_num}: {len(matches)} matches ({completed} completed, {pending} pending)')
        
        # Show first few matches details for debugging
        if round_num in [1, 101]:  # WB R1 and LB R1
            print(f'     Match details:')
            for match in matches[:3]:  # Show first 3 matches
                p1 = match['player1_id'][:8] if match['player1_id'] else 'Empty'
                p2 = match['player2_id'][:8] if match['player2_id'] else 'Empty'
                winner = match['winner_id'][:8] if match['winner_id'] else 'None'
                print(f'       Match {match["match_number"]}: {match["status"]} - P1:{p1} vs P2:{p2} - Winner:{winner}')
else:
    print('   ❌ NO MATCHES FOUND!')
    print('')
    print('   💡 THIS IS THE ISSUE!')
    print('   Tournament exists but no bracket generated yet')
    print('   Need to generate matches first')

# Check participants
participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
print('')
print('👥 PARTICIPANTS:')
print(f'   Registered: {len(participants.data)}')

if len(participants.data) > 0:
    print('   Participant IDs:')
    for i, p in enumerate(participants.data[:5]):  # Show first 5
        print(f'     {i+1}. {p["user_id"][:8]}...')
    if len(participants.data) > 5:
        print(f'     ... and {len(participants.data) - 5} more')

# Check if tournament needs bracket generation
print('')
print('🔧 DIAGNOSIS:')
if len(all_matches.data) == 0:
    print('   ❌ NO BRACKET GENERATED')
    print('   ➡️  Need to generate tournament bracket first')
    print('   ➡️  Once bracket is generated, matches will appear')
    print('   ➡️  Then match progression will work normally')
elif len(participants.data) == 0:
    print('   ❌ NO PARTICIPANTS')
    print('   ➡️  Need participants to generate bracket')
else:
    print('   ✅ Tournament has participants and matches')
    print('   ➡️  Check why progression is not working')