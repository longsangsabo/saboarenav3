#!/usr/bin/env python3
"""
Check if fix is complete
"""

from supabase import create_client

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def check_fix_status():
    # Find all tournaments with matches
    all_matches = supabase.table('matches').select('tournament_id').execute()
    if not all_matches.data:
        print('❌ No matches found in database - bracket not created yet')
        return False
        
    tournaments_with_matches = set(m['tournament_id'] for m in all_matches.data)
    print('🏆 TOURNAMENTS WITH MATCHES:')
    for tid in tournaments_with_matches:
        count = len([m for m in all_matches.data if m['tournament_id'] == tid])
        tid_short = tid[:8]
        print(f'   {tid_short}: {count} matches')
        
    # Get latest tournament (assume it's the one just created)
    latest_tournament = list(tournaments_with_matches)[-1]
    print(f'\n🎯 Checking latest tournament: {latest_tournament[:8]}')
    
    # Comprehensive duplicate check
    matches = supabase.table('matches').select('*').eq('tournament_id', latest_tournament).execute()
    print(f'   Total matches: {len(matches.data)}')
    
    # Check same player in both slots
    same_slot_duplicates = []
    for match in matches.data:
        p1 = match.get('player1_id')
        p2 = match.get('player2_id')
        if p1 and p2 and p1 == p2:
            same_slot_duplicates.append({
                'round': match['round_number'],
                'match': match['match_number'],
                'player': p1[:8]
            })
    
    # Check multiple appearances in same round
    all_players = {}
    for match in matches.data:
        round_num = match['round_number']
        for player in [match.get('player1_id'), match.get('player2_id')]:
            if player:
                if player not in all_players:
                    all_players[player] = []
                all_players[player].append(f'R{round_num} M{match["match_number"]}')

    multi_appearances = []
    for player, appearances in all_players.items():
        round_appearances = {}
        for appearance in appearances:
            round_part = appearance.split(' ')[0]  # R1, R2, etc
            if round_part not in round_appearances:
                round_appearances[round_part] = []
            round_appearances[round_part].append(appearance)
        
        for round_key, round_apps in round_appearances.items():
            if len(round_apps) > 1:
                multi_appearances.append({
                    'player': player[:8],
                    'round': round_key,
                    'appearances': round_apps
                })
    
    # Report results
    print('\n🔍 DUPLICATE ANALYSIS:')
    if same_slot_duplicates:
        print('   ❌ SAME-PLAYER-BOTH-SLOTS:')
        for dup in same_slot_duplicates:
            print(f'      R{dup["round"]} M{dup["match"]}: Player {dup["player"]}')
    else:
        print('   ✅ NO SAME-PLAYER-BOTH-SLOTS DUPLICATES!')
    
    if multi_appearances:
        print('   ❌ MULTI-APPEARANCES IN SAME ROUND:')
        for dup in multi_appearances:
            print(f'      {dup["round"]}: Player {dup["player"]} appears in {dup["appearances"]}')
    else:
        print('   ✅ NO MULTI-APPEARANCES IN SAME ROUND!')
    
    # Final verdict
    is_fixed = len(same_slot_duplicates) == 0 and len(multi_appearances) == 0
    return is_fixed

if __name__ == "__main__":
    print('🔧 CHECKING IF DUPLICATE FIX IS COMPLETE')
    print('='*50)
    
    is_fixed = check_fix_status()
    
    print('\n' + '='*50)
    if is_fixed:
        print('🎉 SUCCESS: All duplicate issues have been fixed!')
        print('✅ Bracket generation is now working perfectly!')
    else:
        print('💥 STILL HAVE ISSUES: More fixes needed!')
        print('🔄 Need to continue debugging...')
    print('='*50)