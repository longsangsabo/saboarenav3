#!/usr/bin/env python3
"""
Quick test to check if duplicate issue is fixed
"""

from supabase import create_client

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def quick_duplicate_check():
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'  # Correct sabo1 tournament ID
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()

    print('🔍 QUICK DUPLICATE CHECK')
    print('='*50)
    print(f'📊 Total matches found: {len(matches.data) if matches.data else 0}')

    if matches.data:
        duplicates_found = []
        for match in matches.data:
            p1 = match.get('player1_id')
            p2 = match.get('player2_id')
            if p1 and p2 and p1 == p2:
                duplicates_found.append({
                    'round': match['round_number'],
                    'match': match['match_number'],
                    'player': p1[:8]
                })
        
        if duplicates_found:
            print('❌ DUPLICATES FOUND:')
            for dup in duplicates_found:
                print(f'   🚫 Round {dup["round"]} Match {dup["match"]}: Same player in both slots')
        else:
            print('✅ NO SAME-PLAYER-BOTH-SLOTS DUPLICATES!')
            
        # Check WB Round 2 specifically  
        wb_r2 = [m for m in matches.data if m['round_number'] == 2]
        print(f'\n🎯 WB Round 2 Analysis: {len(wb_r2)} matches')
        for match in wb_r2:
            p1 = match.get('player1_id', 'None')[:8] if match.get('player1_id') else 'None'
            p2 = match.get('player2_id', 'None')[:8] if match.get('player2_id') else 'None'
            print(f'   M{match["match_number"]}: {p1} vs {p2}')
            
        return len(duplicates_found) == 0
    else:
        print('❌ No matches found!')
        return False

if __name__ == "__main__":
    success = quick_duplicate_check()
    print('\n' + '='*50)
    if success:
        print('🎉 SUCCESS: Duplicate fix is working!')
    else:
        print('💥 FAILED: Duplicates still exist!')
    print('='*50)