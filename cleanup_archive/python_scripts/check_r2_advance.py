from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

tournament_id = 'f7d7484c-b8fe-4d1d-8bf9-fa46e989de61'

print('🔍 CHECKING R2 AUTO-ADVANCE STATUS...')
print('=' * 50)

# Check R2 matches
r2_matches = supabase.table('matches').select('round_number, match_number, player1_id, player2_id, status').eq('tournament_id', tournament_id).eq('round_number', 2).execute()

print('📊 R2 MATCHES STATUS:')
if r2_matches.data:
    for match in r2_matches.data:
        p1 = 'YES' if match['player1_id'] else 'TBD'
        p2 = 'YES' if match['player2_id'] else 'TBD' 
        print(f'   R2M{match["match_number"]}: P1={p1}, P2={p2}, Status={match["status"]}')
else:
    print('   No R2 matches found')

# Check R1 completed matches
r1_completed = supabase.table('matches').select('round_number, match_number, status, winner_id').eq('tournament_id', tournament_id).eq('round_number', 1).eq('status', 'completed').execute()

print(f'\n📈 R1 COMPLETED: {len(r1_completed.data) if r1_completed.data else 0} matches')
if r1_completed.data:
    for match in r1_completed.data:
        winner = 'YES' if match['winner_id'] else 'NO'
        print(f'   R1M{match["match_number"]}: Status={match["status"]}, Winner={winner}')

# Check LB-A matches (R101)
lba_matches = supabase.table('matches').select('round_number, match_number, player1_id, player2_id, status').eq('tournament_id', tournament_id).eq('round_number', 101).execute()

print(f'\n📊 LB-A (R101) MATCHES STATUS:')
if lba_matches.data:
    for match in lba_matches.data:
        p1 = 'YES' if match['player1_id'] else 'TBD'
        p2 = 'YES' if match['player2_id'] else 'TBD'
        print(f'   R101M{match["match_number"]}: P1={p1}, P2={p2}, Status={match["status"]}')
else:
    print('   No LB-A matches found')

print('\n🚨 DIAGNOSIS:')
if r2_matches.data:
    r2_with_players = sum(1 for m in r2_matches.data if m['player1_id'] or m['player2_id'])
    print(f'   R2 matches with players: {r2_with_players}/{len(r2_matches.data)}')
    
    if r2_with_players == 0:
        print('   ❌ PROBLEM: No players advanced to R2 despite R1 completions')
        print('   🔧 SOLUTION: Check auto-advance logic in CompleteSaboDE16Service')
    elif r2_with_players < len(r2_matches.data):
        print('   ⚠️ PARTIAL: Some players advanced, but not all')
        print('   🔧 SOLUTION: Complete more R1 matches or check pair-based logic')
    else:
        print('   ✅ SUCCESS: All R2 matches have players')