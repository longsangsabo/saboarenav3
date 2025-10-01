#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

# Correct tournament ID (sabo1) 
tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'

print('🔍 CHECKING SABO1 TOURNAMENT')
print('=' * 40)

matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
print(f'Found {len(matches.data) if matches.data else 0} matches')

if matches.data:
    # Group by rounds
    rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    print('\n📊 ROUNDS BREAKDOWN:')
    for round_num in sorted(rounds.keys()):
        count = len(rounds[round_num])
        print(f'   Round {round_num}: {count} matches')
    
    # Check specific problematic rounds
    print('\n🎯 CRITICAL ROUNDS:')
    
    # LB Round 103
    if 103 in rounds:
        print(f'   LB Round 103: {len(rounds[103])} matches')
        for match in rounds[103]:
            match_num = match['match_number']
            p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
            print(f'     M{match_num}: P1={p1}, P2={p2}')
    
    # LB Round 104  
    if 104 in rounds:
        print(f'   LB Round 104: {len(rounds[104])} matches')
        for match in rounds[104]:
            match_num = match['match_number']
            p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
            print(f'     M{match_num}: P1={p1}, P2={p2}')
    
    # Check for duplicate players in same rounds
    print('\n🚨 DUPLICATE CHECK:')
    
    player_in_rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        match_num = match['match_number']
        
        for slot in ['player1_id', 'player2_id']:
            player_id = match[slot]
            if player_id:
                if player_id not in player_in_rounds:
                    player_in_rounds[player_id] = {}
                
                if round_num not in player_in_rounds[player_id]:
                    player_in_rounds[player_id][round_num] = []
                
                player_in_rounds[player_id][round_num].append(f'M{match_num}')
    
    duplicates_found = False
    for player_id, rounds_data in player_in_rounds.items():
        for round_num, matches_in_round in rounds_data.items():
            if len(matches_in_round) > 1:
                print(f'   ❌ Player {player_id[:8]} appears {len(matches_in_round)} times in Round {round_num}: {matches_in_round}')
                duplicates_found = True
    
    if not duplicates_found:
        print('   ✅ No duplicate players in same rounds!')
    
    print('\n💡 ANALYSIS:')
    print('IF you see duplicates in LB Round 103 or 104, the hard-coded mapping logic is still wrong!')

else:
    print('❌ No matches found for sabo1 tournament!')
    print('Try creating bracket in app first!')