#!/usr/bin/env python3
"""
Comprehensive bracket analysis
"""

from supabase import create_client

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def comprehensive_analysis():
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()

    print('🔍 COMPREHENSIVE BRACKET ANALYSIS')
    print('='*60)
    print(f'📊 Total matches: {len(matches.data)}')

    if not matches.data:
        print('❌ No matches found!')
        return False

    # Organize by rounds
    rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)

    # Analysis
    wb_rounds = [r for r in rounds.keys() if r <= 4]
    lb_rounds = [r for r in rounds.keys() if r >= 101 and r <= 107]
    gf_rounds = [r for r in rounds.keys() if r >= 200]

    print(f'WB Rounds: {sorted(wb_rounds)}')
    print(f'LB Rounds: {sorted(lb_rounds)}') 
    print(f'GF Rounds: {sorted(gf_rounds)}')

    # Check each WB round in detail
    print('\n📈 WB ROUNDS DETAILED:')
    for round_num in sorted(wb_rounds):
        matches_in_round = rounds[round_num]
        print(f'   Round {round_num}: {len(matches_in_round)} matches')
        for match in sorted(matches_in_round, key=lambda x: x['match_number']):
            p1 = match.get('player1_id', 'None')[:8] if match.get('player1_id') else 'None'
            p2 = match.get('player2_id', 'None')[:8] if match.get('player2_id') else 'None'
            status = match.get('status', 'unknown')
            match_num = match['match_number']
            print(f'      M{match_num}: {p1} vs {p2} ({status})')

    # Check duplicate players across all rounds
    print('\n🔍 DUPLICATE ANALYSIS:')
    all_players = {}
    duplicate_issues = []

    for match in matches.data:
        round_num = match['round_number']
        match_num = match['match_number']
        p1 = match.get('player1_id')
        p2 = match.get('player2_id')
        
        # Same player in both slots
        if p1 and p2 and p1 == p2:
            duplicate_issues.append(f'R{round_num} M{match_num}: Same player in both slots ({p1[:8]})')
        
        # Track player appearances
        for player in [p1, p2]:
            if player:
                if player not in all_players:
                    all_players[player] = []
                all_players[player].append(f'R{round_num} M{match_num}')

    # Find players appearing in multiple places in same round
    for player, appearances in all_players.items():
        round_appearances = {}
        for appearance in appearances:
            round_part = appearance.split(' ')[0]  # R1, R2, etc
            if round_part not in round_appearances:
                round_appearances[round_part] = []
            round_appearances[round_part].append(appearance)
        
        for round_key, round_apps in round_appearances.items():
            if len(round_apps) > 1:
                duplicate_issues.append(f'{round_key}: Player {player[:8]} appears multiple times: {round_apps}')

    if duplicate_issues:
        print('❌ DUPLICATE ISSUES FOUND:')
        for issue in duplicate_issues:
            print(f'   🚫 {issue}')
        return False
    else:
        print('✅ NO DUPLICATE ISSUES FOUND!')

    print(f'\n📊 STATISTICS:')
    print(f'   Unique players: {len(all_players)}')
    total_slots = sum(len(apps) for apps in all_players.values())
    print(f'   Total player slots filled: {total_slots}')
    
    # Expected structure verification
    expected_wb_structure = {1: 8, 2: 4, 3: 2, 4: 1}  # WB rounds
    expected_lb_structure = {101: 4, 102: 4, 103: 2, 104: 2, 105: 1, 106: 1, 107: 1}  # LB rounds
    expected_gf_structure = {200: 1}  # GF
    
    print('\n🎯 STRUCTURE VERIFICATION:')
    structure_ok = True
    
    # Check WB structure
    for round_num, expected_count in expected_wb_structure.items():
        actual_count = len(rounds.get(round_num, []))
        if actual_count != expected_count:
            print(f'   ❌ WB R{round_num}: Expected {expected_count}, got {actual_count}')
            structure_ok = False
        else:
            print(f'   ✅ WB R{round_num}: {actual_count} matches')
    
    # Check LB structure
    for round_num, expected_count in expected_lb_structure.items():
        actual_count = len(rounds.get(round_num, []))
        if actual_count != expected_count:
            print(f'   ❌ LB R{round_num}: Expected {expected_count}, got {actual_count}')
            structure_ok = False
        else:
            print(f'   ✅ LB R{round_num}: {actual_count} matches')
    
    # Check GF structure
    for round_num, expected_count in expected_gf_structure.items():
        actual_count = len(rounds.get(round_num, []))
        if actual_count != expected_count:
            print(f'   ❌ GF R{round_num}: Expected {expected_count}, got {actual_count}')
            structure_ok = False
        else:
            print(f'   ✅ GF R{round_num}: {actual_count} matches')
    
    return len(duplicate_issues) == 0 and structure_ok

if __name__ == "__main__":
    print('🧪 RUNNING COMPREHENSIVE BRACKET ANALYSIS')
    print('='*60)
    
    success = comprehensive_analysis()
    
    print('\n' + '='*60)
    if success:
        print('🎉 PERFECT! Bracket structure and logic are 100% correct!')
    else:
        print('💥 Issues found that need to be addressed!')
    print('='*60)