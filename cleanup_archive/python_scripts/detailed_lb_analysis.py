from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

# Get sabo1 tournament
tournaments = supabase.table('tournaments').select('id, title').eq('title', 'sabo1').execute()
tournament_id = tournaments.data[0]['id']

print('🔍 DETAILED LB ROUND 1 ANALYSIS')
print('=' * 50)

# Check LB Round 1 matches in detail
lb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).order('match_number').execute()

print(f'📋 LB ROUND 1 MATCHES (Round {101}):')
for match in lb_r1_matches.data:
    p1_id = match['player1_id']
    p2_id = match['player2_id']
    status = match['status']
    winner_id = match['winner_id']
    
    p1_display = p1_id[:8] if p1_id else 'EMPTY'
    p2_display = p2_id[:8] if p2_id else 'EMPTY'
    winner_display = winner_id[:8] if winner_id else 'None'
    
    print(f'   Match {match["match_number"]}: {p1_display} vs {p2_display} | Status: {status} | Winner: {winner_display}')

print()
print('🔍 CHECKING OTHER LB ROUNDS:')

# Check all LB rounds
all_lb_rounds = supabase.table('matches').select('round_number, match_number, player1_id, player2_id, status').eq('tournament_id', tournament_id).gte('round_number', 101).order('round_number, match_number').execute()

rounds_data = {}
for match in all_lb_rounds.data:
    round_num = match['round_number']
    if round_num not in rounds_data:
        rounds_data[round_num] = []
    rounds_data[round_num].append(match)

for round_num in sorted(rounds_data.keys()):
    matches = rounds_data[round_num]
    filled_count = 0
    playable_count = 0
    
    print(f'📋 LB ROUND {round_num}:')
    for match in matches:
        p1_id = match['player1_id']
        p2_id = match['player2_id']
        status = match['status']
        
        has_p1 = bool(p1_id)
        has_p2 = bool(p2_id)
        
        if has_p1:
            filled_count += 1
        if has_p1 and has_p2:
            playable_count += 1
            
        p1_display = p1_id[:8] if p1_id else 'EMPTY'
        p2_display = p2_id[:8] if p2_id else 'EMPTY'
        
        print(f'   Match {match["match_number"]}: {p1_display} vs {p2_display} | Status: {status}')
    
    print(f'   📊 Summary: {playable_count}/{len(matches)} matches ready to play')
    print()

print('💡 CONCLUSION:')
if lb_r1_matches.data:
    ready_matches = sum(1 for m in lb_r1_matches.data if m['player1_id'] and m['player2_id'])
    total_matches = len(lb_r1_matches.data)
    
    if ready_matches == total_matches:
        print('   ✅ LB Round 1 is FULLY POPULATED!')
        print('   ✅ All matches have both players assigned')
        print('   ➡️  Issue might be in Flutter UI display')
        print('   ➡️  Try refreshing the bracket view')
    elif ready_matches > 0:
        print(f'   ⚠️  LB Round 1 is PARTIALLY POPULATED: {ready_matches}/{total_matches}')
        print('   ➡️  Some matches still need players')
    else:
        print('   ❌ LB Round 1 is EMPTY')
        print('   ➡️  Match progression is not working')
else:
    print('   ❌ No LB Round 1 matches found')

print()
print('🎯 RECOMMENDATIONS:')
print('   1. Refresh Flutter app bracket view')
print('   2. Check if LB matches are visible in UI')
print('   3. Verify bracket round numbering in Flutter')
print('   4. Test completing one LB match to see progression')