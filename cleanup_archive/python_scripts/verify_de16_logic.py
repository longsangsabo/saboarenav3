#!/usr/bin/env python3
"""
🔍 VERIFY DE16 LOGIC AFTER APP TEST
Kiểm tra logic DE16 sau khi test trong app
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def verify_de16_logic():
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    print('🔍 VERIFYING DE16 LOGIC')
    print('=' * 50)
    
    # Get all matches
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number', desc=False).order('match_number', desc=False).execute()
    
    if not matches.data:
        print('❌ No matches found. Create bracket first!')
        return
    
    print(f'✅ Found {len(matches.data)} matches')
    print()
    
    # Group by rounds
    rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    # Check WB structure
    print('🎯 WINNERS BRACKET:')
    wb_rounds = [1, 2, 3, 4]
    expected_wb_counts = [8, 4, 2, 1]
    
    for i, round_num in enumerate(wb_rounds):
        if round_num in rounds:
            count = len(rounds[round_num])
            expected = expected_wb_counts[i]
            status = '✅' if count == expected else '❌'
            print(f'   WB R{round_num}: {count} matches {status} (expected {expected})')
        else:
            print(f'   WB R{round_num}: 0 matches ❌ (expected {expected_wb_counts[i]})')
    
    print()
    
    # Check LB structure
    print('💀 LOSERS BRACKET:')
    lb_rounds = [101, 102, 103, 104, 105, 106, 107]
    expected_lb_counts = [4, 4, 2, 2, 1, 1, 1]
    
    for i, round_num in enumerate(lb_rounds):
        if round_num in rounds:
            count = len(rounds[round_num])
            expected = expected_lb_counts[i]
            status = '✅' if count == expected else '❌'
            print(f'   LB R{round_num}: {count} matches {status} (expected {expected})')
        else:
            print(f'   LB R{round_num}: 0 matches ❌ (expected {expected_lb_counts[i]})')
    
    print()
    
    # Check Grand Final
    print('🏆 GRAND FINAL:')
    if 200 in rounds:
        count = len(rounds[200])
        status = '✅' if count == 1 else '❌'
        print(f'   GF R200: {count} match {status} (expected 1)')
    else:
        print('   GF R200: 0 matches ❌ (expected 1)')
    
    print()
    
    # Check for duplicates
    print('🚨 DUPLICATE CHECK:')
    player_appearances = {}
    
    for match in matches.data:
        round_name = f"R{match['round_number']}"
        match_name = f"M{match['match_number']}"
        
        for player_slot in ['player1_id', 'player2_id']:
            player_id = match[player_slot]
            if player_id:
                if player_id not in player_appearances:
                    player_appearances[player_id] = []
                player_appearances[player_id].append(f"{round_name} {match_name}")
    
    duplicates_found = False
    for player_id, appearances in player_appearances.items():
        if len(appearances) > 1:
            # Check if appearances are in same round
            rounds_appeared = set()
            for appearance in appearances:
                round_part = appearance.split()[0]
                rounds_appeared.add(round_part)
            
            if len(rounds_appeared) < len(appearances):
                print(f'   ❌ Player {player_id[:8]} appears multiple times in same round: {appearances}')
                duplicates_found = True
    
    if not duplicates_found:
        print('   ✅ No duplicate players found in same rounds!')
    
    print()
    
    # Specific DE16 logic checks
    print('🎯 DE16 SPECIFIC LOGIC:')
    
    # Check LB R103 gets LB R102 winners only
    if 103 in rounds:
        lb_r103_matches = rounds[103]
        print(f'   ✅ LB R103 has {len(lb_r103_matches)} matches (should be 2)')
        print('   📋 LB R103 should get winners from LB R102 M20,M21,M22,M23')
    
    # Check LB R104 gets LB R103 winners + WB R3 losers  
    if 104 in rounds:
        lb_r104_matches = rounds[104]
        print(f'   ✅ LB R104 has {len(lb_r104_matches)} matches (should be 2)')
        print('   📋 LB R104 should get LB R103 winners + WB R3 losers (M13,M14)')
    
    print()
    print('🚀 DE16 LOGIC VERIFICATION COMPLETE!')

if __name__ == '__main__':
    verify_de16_logic()