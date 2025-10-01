from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

# Get sabo1 tournament
tournaments = supabase.table('tournaments').select('id, title').eq('title', 'sabo1').execute()
if tournaments.data:
    tournament_id = tournaments.data[0]['id']
    print(f'✅ Found sabo1 tournament ID: {tournament_id}')
    
    # Now fix the progression issue with this tournament
    print()
    print('🔧 FIXING MATCH PROGRESSION ISSUE')
    print('=' * 50)
    
    print('1️⃣ ANALYZING WB ROUND 1 COMPLETED MATCHES:')
    wb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).eq('status', 'completed').execute()
    
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
            
        p1_short = p1_id[:8] if p1_id else 'None'
        p2_short = p2_id[:8] if p2_id else 'None'
        winner_short = winner_id[:8] if winner_id else 'None'
        loser_short = loser_id[:8] if loser_id else 'None'
        
        print(f'   Match {match["match_number"]}: {p1_short} vs {p2_short} → Winner: {winner_short}, Loser: {loser_short}')

    print()
    print(f'   📊 Total losers to move to LB: {len(losers_from_wb_r1)}')

    print()
    print('2️⃣ CHECKING LB ROUND 1 EMPTY SLOTS:')
    lb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()

    empty_lb_slots = []
    for match in lb_r1_matches.data:
        p1_empty = not match['player1_id']
        p2_empty = not match['player2_id']
        
        if p1_empty:
            empty_lb_slots.append({
                'match_id': match['id'], 
                'match_number': match['match_number'], 
                'slot': 'player1_id'
            })
        if p2_empty:
            empty_lb_slots.append({
                'match_id': match['id'], 
                'match_number': match['match_number'], 
                'slot': 'player2_id'
            })
        
        p1_status = "Empty" if p1_empty else "Filled"
        p2_status = "Empty" if p2_empty else "Filled"
        print(f'   LB Match {match["match_number"]}: P1={p1_status}, P2={p2_status}')

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
                    
                    loser_short = loser_id[:8]
                    print(f'   ✅ Moved loser {loser_short} to LB Match {slot["match_number"]} {slot["slot"]}')
                    moves_made += 1
                    
                except Exception as e:
                    loser_short = loser_id[:8] if loser_id else 'None'
                    print(f'   ❌ Failed to move loser {loser_short}: {e}')
        
        print()
        print(f'   📊 Successfully moved {moves_made} losers to LB')
        
        if moves_made > 0:
            print('   🎉 SUCCESS! Loser Bracket Round 1 now has players!')
            print('   ➡️  Players can now compete in LB matches')
            print('   ➡️  Check Flutter app - LB R1 should show players now!')
        
    else:
        print('   ❌ Cannot fix: either no losers or no empty LB slots')
    
else:
    print('❌ sabo1 tournament not found')
    # Show all tournaments
    all_tournaments = supabase.table('tournaments').select('id, title').execute()
    print('Available tournaments:')
    for t in all_tournaments.data:
        title = t["title"]
        tournament_id = t["id"]
        print(f'  - {title}: {tournament_id}')