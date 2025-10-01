from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 ANALYZING MATCH PROGRESSION ISSUE')
print('=' * 50)

tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

# Check WB Round 1 status
print('1️⃣ WINNER BRACKET ROUND 1 STATUS:')
wb_r1 = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()

completed_wb_r1 = 0
pending_wb_r1 = 0
losers_from_wb_r1 = []

for match in wb_r1.data:
    match_num = match["match_number"]
    status = match["status"]
    winner_id = match["winner_id"][:8] if match["winner_id"] else "None"
    p1_id = match["player1_id"][:8] if match["player1_id"] else "None"
    p2_id = match["player2_id"][:8] if match["player2_id"] else "None"
    
    print(f'   Match {match_num}: {status} - Winner: {winner_id} - P1: {p1_id} vs P2: {p2_id}')
    
    if match['status'] == 'completed':
        completed_wb_r1 += 1
        # Identify the loser
        if match['winner_id'] == match['player1_id']:
            loser_id = match['player2_id']
        else:
            loser_id = match['player1_id']
        
        if loser_id:
            losers_from_wb_r1.append(loser_id)
    else:
        pending_wb_r1 += 1

print(f'   📊 Completed: {completed_wb_r1}, Pending: {pending_wb_r1}')
print(f'   👥 Losers from WB R1: {len(losers_from_wb_r1)} players')

# Check LB Round 1 status  
print('')
print('2️⃣ LOSER BRACKET ROUND 1 STATUS:')
lb_r1 = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).order('match_number').execute()

if lb_r1.data:
    empty_lb_matches = 0
    filled_lb_matches = 0
    
    for match in lb_r1.data:
        p1_status = 'Filled' if match['player1_id'] else 'Empty'
        p2_status = 'Filled' if match['player2_id'] else 'Empty'
        match_num = match['match_number']
        status = match['status']
        print(f'   LB Match {match_num}: {status} - P1: {p1_status} - P2: {p2_status}')
        
        if not match['player1_id'] or not match['player2_id']:
            empty_lb_matches += 1
        else:
            filled_lb_matches += 1
    
    print(f'   📊 Empty LB matches: {empty_lb_matches}, Filled: {filled_lb_matches}')
else:
    print('   ❌ No LB Round 1 matches found!')

# Check if there are any matches with round_number 101+ 
print('')
print('3️⃣ CHECKING ALL LB ROUNDS:')
all_lb = supabase.table('matches').select('round_number, match_number, status, player1_id, player2_id').eq('tournament_id', tournament_id).gte('round_number', 101).order('round_number, match_number').execute()

lb_rounds = {}
for match in all_lb.data:
    round_num = match['round_number']
    if round_num not in lb_rounds:
        lb_rounds[round_num] = []
    lb_rounds[round_num].append(match)

for round_num in sorted(lb_rounds.keys()):
    matches = lb_rounds[round_num]
    filled_count = sum(1 for m in matches if m['player1_id'] and m['player2_id'])
    total_count = len(matches)
    print(f'   LB Round {round_num}: {filled_count}/{total_count} matches filled')

# Analyze the problem
print('')
print('4️⃣ PROBLEM ANALYSIS:')
if len(losers_from_wb_r1) > 0:
    print(f'   🔍 We have {len(losers_from_wb_r1)} losers from WB R1')
    print(f'   🔍 Losers should automatically move to LB R1')
    print('')
    print('   💡 ISSUE: Match progression not working!')
    print('   💡 Losers are not being moved to Loser Bracket')
    print('')
    print('   🔧 POSSIBLE CAUSES:')
    print('   1. Immediate advancement disabled')
    print('   2. Match progression service not triggered')
    print('   3. Missing progression triggers in database')
    print('   4. Bug in match completion logic')
    
    print('')
    print('   🚀 TESTING MANUAL PROGRESSION:')
    print('   Let me try to manually move one loser to LB...')
    
    # Try to manually move first loser to first empty LB match
    if lb_r1.data and losers_from_wb_r1:
        first_loser = losers_from_wb_r1[0]
        
        # Find first empty LB match
        for lb_match in lb_r1.data:
            if not lb_match['player1_id']:
                # Move loser to player1_id position
                try:
                    supabase.table('matches').update({
                        'player1_id': first_loser
                    }).eq('id', lb_match['id']).execute()
                    
                    print(f'   ✅ Moved loser {first_loser[:8]} to LB Match {lb_match["match_number"]} P1')
                    break
                except Exception as e:
                    print(f'   ❌ Failed to move loser: {e}')
                    
else:
    print('   ❌ No completed WB matches or no losers found')

print('')
print('💡 RECOMMENDATION:')
print('   Check UniversalMatchProgressionService in Flutter')
print('   Ensure immediate advancement triggers are working')
print('   Test match completion to see if progression happens automatically')