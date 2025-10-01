from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

print('=== COMPLETE TOURNAMENT ANALYSIS ===')
print()

# Check tournament 6c0658f7 (current active tournament)
tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'
result = supabase.table('matches').select('id, round_number, match_number, player1_id, player2_id, status, player1_score, player2_score, winner_id').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

matches_by_round = {}
for match in result.data:
    round_num = match.get('round_number', 0)
    if round_num not in matches_by_round:
        matches_by_round[round_num] = []
    matches_by_round[round_num].append(match)

print(f'Tournament: {tournament_id[:8]}...')
print(f'Total matches: {len(result.data)}')
print()

for round_num in sorted(matches_by_round.keys()):
    matches = matches_by_round[round_num]
    completed = sum(1 for m in matches if m['status'] == 'completed')
    with_winner = sum(1 for m in matches if m.get('winner_id'))
    has_players = sum(1 for m in matches if m.get('player1_id') and m.get('player2_id'))
    
    print(f'🏆 ROUND {round_num}: {len(matches)} matches')
    print(f'   ✅ Completed: {completed}/{len(matches)}')
    print(f'   🏅 With winner: {with_winner}/{len(matches)}')  
    print(f'   👥 With players: {has_players}/{len(matches)}')
    
    for match in matches:
        p1_id = match.get('player1_id', 'NULL')
        p2_id = match.get('player2_id', 'NULL')
        p1_short = p1_id[:8] + '...' if p1_id and p1_id != 'NULL' else 'NULL'
        p2_short = p2_id[:8] + '...' if p2_id and p2_id != 'NULL' else 'NULL'
        
        status_icon = '✅' if match['status'] == 'completed' else '⏳'
        winner_icon = '🏆' if match.get('winner_id') else '❓'
        
        score_display = f"{match.get('player1_score', 0)}-{match.get('player2_score', 0)}"
        
        print(f'      R{round_num}M{match.get("match_number", "?")}: {status_icon} {p1_short} vs {p2_short} | {score_display} {winner_icon}')
    print()

# Check what's needed for next round progression
print('🔮 PROGRESSION ANALYSIS:')
if 1 in matches_by_round:
    r1_completed = sum(1 for m in matches_by_round[1] if m['status'] == 'completed' and m.get('winner_id'))
    r1_total = len(matches_by_round[1])
    print(f'   R1 → R2: {r1_completed}/{r1_total} matches completed with winners')
    if r1_completed == r1_total:
        print('   🟢 R1 complete, R2 should be available')
    else:
        print(f'   🟡 Need {r1_total - r1_completed} more R1 matches to complete')

if 2 in matches_by_round:
    r2_completed = sum(1 for m in matches_by_round[2] if m['status'] == 'completed' and m.get('winner_id'))
    r2_total = len(matches_by_round[2])
    print(f'   R2 → R3: {r2_completed}/{r2_total} matches completed with winners')
    if r2_completed == r2_total:
        print('   🟢 R2 complete, R3 should be available')
    else:
        print(f'   🟡 Need {r2_total - r2_completed} more R2 matches to complete')

if 3 in matches_by_round:
    r3_completed = sum(1 for m in matches_by_round[3] if m['status'] == 'completed' and m.get('winner_id'))
    r3_total = len(matches_by_round[3])
    print(f'   R3 → FINAL: {r3_completed}/{r3_total} matches completed with winners')
    if r3_completed == r3_total:
        print('   🏆 TOURNAMENT COMPLETE!')
    else:
        print(f'   🟡 Need {r3_total - r3_completed} more R3 matches to complete')

print()
print('📝 RECOMMENDATIONS:')
print('1. Test player name display (should show full names instead of TBD)')
print('2. Complete remaining matches in order: R1 → R2 → R3')
print('3. Test +/- score input buttons')
print('4. Verify automatic bracket progression')
print('5. Test cache system performance')