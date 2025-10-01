#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

print('🔍 CHECKING MATCHES')
print('=' * 30)

matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
print(f'Found {len(matches.data) if matches.data else 0} matches for tournament')

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
    
    # Check WB Round 3 and LB Round 103, 104
    print('\n🎯 KEY ROUNDS CHECK:')
    
    if 3 in rounds:
        wb_r3 = rounds[3]
        print(f'   WB Round 3: {len(wb_r3)} matches')
        for match in wb_r3:
            match_num = match['match_number']
            p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
            print(f'     M{match_num}: P1={p1}, P2={p2}')
    
    if 103 in rounds:
        lb_r103 = rounds[103]
        print(f'   LB Round 103: {len(lb_r103)} matches')
        for match in lb_r103:
            match_num = match['match_number']
            p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
            print(f'     M{match_num}: P1={p1}, P2={p2}')
    
    if 104 in rounds:
        lb_r104 = rounds[104]
        print(f'   LB Round 104: {len(lb_r104)} matches')
        for match in lb_r104:
            match_num = match['match_number']
            p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
            p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
            print(f'     M{match_num}: P1={p1}, P2={p2}')
    
    # Check for duplicates in same rounds
    print('\n🚨 DUPLICATE CHECK:')
    player_appearances = {}
    for match in matches.data:
        round_num = match['round_number']
        match_num = match['match_number']
        
        for slot in ['player1_id', 'player2_id']:
            player_id = match[slot]
            if player_id:
                if player_id not in player_appearances:
                    player_appearances[player_id] = []
                player_appearances[player_id].append(f'R{round_num} M{match_num}')
    
    duplicates_found = False
    for player_id, appearances in player_appearances.items():
        if len(appearances) > 1:
            # Check if same round
            rounds_appeared = set()
            for app in appearances:
                round_part = app.split()[0]
                rounds_appeared.add(round_part)
            
            if len(rounds_appeared) < len(appearances):
                print(f'   ❌ Player {player_id[:8]} duplicate: {appearances}')
                duplicates_found = True
    
    if not duplicates_found:
        print('   ✅ No duplicates found!')

else:
    print('❌ No matches found!')
    # Check tournaments
    tournaments = supabase.table('tournaments').select('id, name').execute()
    print('\nAvailable tournaments:')
    for t in tournaments.data[:3]:
        t_id = t['id'][:8]
        t_name = t.get('name', 'No name')
        print(f'   {t_id}: {t_name}')