from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔧 FIXING MATCH PROGRESSION ISSUE')
print('=' * 50)

# Use the problematic tournament
tournament_id = 'cf969300'  # sabo1 tournament prefix

# Get full tournament ID
tournaments = supabase.table('tournaments').select('id').like('id', f'{tournament_id}%').execute()
if tournaments.data:
    full_tournament_id = tournaments.data[0]['id']
    print(f'✅ Found tournament: {full_tournament_id}')
else:
    print('❌ Tournament not found')
    exit()

print()
print('1️⃣ ANALYZING WB ROUND 1 COMPLETED MATCHES:')
wb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', full_tournament_id).eq('round_number', 1).eq('status', 'completed').execute()

losers_from_wb_r1 = []
for match in wb_r1_matches.data:
    p1_id = match['player1_id']
    p2_id = match['player2_id'] 
    winner_id = match['winner_id']
    
    # Determine loser
    if winner_id == p1_id:
        loser_id = p2_id
    else:
        loser_id = p1_id
        
    if loser_id:
        losers_from_wb_r1.append(loser_id)
        
    print(f'   Match {match["match_number"]}: Winner {winner_id[:8]} - Loser {loser_id[:8]}')

print()
print(f'   📊 Total losers to move to LB: {len(losers_from_wb_r1)}')

print()
print('2️⃣ CHECKING LB ROUND 1 EMPTY SLOTS:')
lb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', full_tournament_id).eq('round_number', 101).execute()

empty_lb_slots = []
for match in lb_r1_matches.data:
    p1_empty = not match['player1_id']
    p2_empty = not match['player2_id']
    
    if p1_empty:
        empty_lb_slots.append({'match_id': match['id'], 'match_number': match['match_number'], 'slot': 'player1_id'})
    if p2_empty:
        empty_lb_slots.append({'match_id': match['id'], 'match_number': match['match_number'], 'slot': 'player2_id'})
    
    p1_status = "Empty" if p1_empty else "Filled"
    p2_status = "Empty" if p2_empty else "Filled"
    print(f'   LB Match {match["match_number"]}: P1={p1_status} P2={p2_status}')

print()
print(f'   📊 Total empty LB slots: {len(empty_lb_slots)}')

print()
print('3️⃣ AUTOMATIC PROGRESSION FIX:')
if len(losers_from_wb_r1) > 0 and len(empty_lb_slots) > 0:
    print('   🚀 Moving losers to Loser Bracket...')
    
    moves_made = 0
    for i, loser_id in enumerate(losers_from_wb_r1):
        if i < len(empty_lb_slots):
            slot = empty_lb_slots[i]
            
            try:
                # Move loser to empty LB slot
                supabase.table('matches').update({
                    slot['slot']: loser_id
                }).eq('id', slot['match_id']).execute()
                
                print(f'   ✅ Moved loser {loser_id[:8]} to LB Match {slot["match_number"]} {slot["slot"]}')
                moves_made += 1
                
            except Exception as e:
                print(f'   ❌ Failed to move loser {loser_id[:8]}: {e}')
    
    print(f')
    print(f'   📊 Successfully moved {moves_made} losers to LB')
    
    # Verify the fix
    print()
    print('4️⃣ VERIFICATION:')
    lb_r1_after = supabase.table('matches').select('*').eq('tournament_id', full_tournament_id).eq('round_number', 101).execute()
    
    filled_matches = 0
    for match in lb_r1_after.data:
        has_both_players = match['player1_id'] and match['player2_id']
        if has_both_players:
            filled_matches += 1
            print(f'   ✅ LB Match {match["match_number"]}: Ready to play')
        else:
            p1_status = 'Filled' if match['player1_id'] else 'Empty'
            p2_status = 'Filled' if match['player2_id'] else 'Empty'
            print(f'   ⏳ LB Match {match["match_number"]}: P1={p1_status} P2={p2_status}')
    
    print(f')
    print(f'   📊 LB matches ready to play: {filled_matches}/{len(lb_r1_after.data)}')
    
    if filled_matches > 0:
        print('   🎉 SUCCESS! Loser Bracket Round 1 now has players!')
        print('   ➡️  Players can now compete in LB matches')
    else:
        print('   ⚠️  Some LB matches still need more players')
        
else:
    print('   ❌ Cannot fix: either no losers or no empty LB slots')

print()
print('💡 ROOT CAUSE ANALYSIS:')
print('   The issue is that Flutter app completed WB matches')
print('   but did not trigger automatic progression to LB')
print('   This suggests UniversalMatchProgressionService')
print('   is not working or not enabled')
print()
print('🔧 PERMANENT SOLUTION:')
print('   1. Check immediate advancement settings')
print('   2. Ensure match completion triggers progression')  
print('   3. Add database triggers for automatic progression')
print('   4. Test match completion in Flutter app')