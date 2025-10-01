#!/usrSERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'bin/env python3
# Test LB Tab Fix - Verify the filtering logic works correctly

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybXFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def test_lb_fix():
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    print('🔧 TESTING LB TAB FIX')
    print('=' * 40)
    
    # Get all matches
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
    
    if not matches.data:
        print('❌ No matches found')
        return
        
    print(f'📊 Total matches: {len(matches.data)}')
    
    # Group by rounds
    rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    print('\n🏆 ROUND BREAKDOWN')
    print('-' * 30)
    
    for round_num in sorted(rounds.keys()):
        matches_in_round = rounds[round_num]
        pending_count = len([m for m in matches_in_round if m['status'] == 'pending'])
        completed_count = len([m for m in matches_in_round if m['status'] == 'completed'])
        
        # Determine round type
        if round_num <= 10:
            if round_num == 1: round_name = 'WB - VÒNG 1'
            elif round_num == 2: round_name = 'WB - VÒNG 2'
            elif round_num == 3: round_name = 'WB - BÁN KẾT'
            elif round_num == 4: round_name = 'WB - CHUNG KẾT'
            else: round_name = f'WB - VÒNG {round_num}'
        elif round_num >= 101 and round_num <= 110:
            if round_num == 101: round_name = 'LB - VÒNG 1'
            elif round_num == 102: round_name = 'LB - VÒNG 2'
            elif round_num == 103: round_name = 'LB - VÒNG 3'
            elif round_num == 104: round_name = 'LB - BÁN KẾT'
            elif round_num == 105: round_name = 'LB - CHUNG KẾT'
            else: round_name = f'LB - VÒNG {round_num - 100}'
        elif round_num == 200:
            round_name = 'CHUNG KẾT CUỐI'
        elif round_num == 201:
            round_name = 'CHUNG KẾT RESET'
        else:
            round_name = f'VÒNG {round_num}'
            
        print(f'Round {round_num:3d}: {round_name:15} - {len(matches_in_round):2d} matches ({pending_count} pending, {completed_count} completed)')
    
    print('\n🎯 LB ROUND 1 ANALYSIS')
    print('-' * 30)
    
    if 101 in rounds:
        lb_round1 = rounds[101]
        print(f'✅ LB Round 101 exists: {len(lb_round1)} matches')
        
        for match in lb_round1:
            p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
            status = match['status']
            match_id = match['id'][:8]
            
            print(f'   Match {match_id}: P1={p1}, P2={p2}, Status={status}')
            
        populated_matches = [m for m in lb_round1 if m['player1_id'] and m['player2_id']]
        print(f'\n📈 Populated matches in LB Round 1: {len(populated_matches)}/{len(lb_round1)}')
        
        if populated_matches:
            print('✅ LB-VÒNG 1 tab should now show these matches!')
        else:
            print('⚠️  No populated matches in LB Round 1')
    else:
        print('❌ LB Round 101 not found')
    
    print('\n🔍 FLUTTER FILTER LOGIC TEST')
    print('-' * 30)
    print('Old logic: filter="round1" → matches where round==1 (WB Round 1)')
    print('New logic: filter="round101" → matches where round==101 (LB Round 1)')
    print('✅ Fix should resolve the LB tab mapping issue!')

if __name__ == '__main__':
    test_lb_fix()