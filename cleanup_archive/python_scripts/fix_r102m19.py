#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def fix_r102m19_manually():
    print('🔧 MANUAL FIX FOR R102M19 DUPLICATE ISSUE')
    print('=' * 50)

    try:
        # Get M15 and M16 winners
        m15 = supabase.table('matches').select('*').eq('match_number', 15).eq('round_number', 101).single().execute()
        m16 = supabase.table('matches').select('*').eq('match_number', 16).eq('round_number', 101).single().execute()

        m15_winner = m15.data['winner_id']
        m16_winner = m16.data['winner_id']

        print(f'M15 winner: {m15_winner[:8] if m15_winner else "None"}')
        print(f'M16 winner: {m16_winner[:8] if m16_winner else "None"}')

        if m15_winner and m16_winner and m15_winner != m16_winner:
            print('✅ Found 2 different winners - fixing R102M19...')
            
            # Fix R102M19 with correct players
            result = supabase.table('matches').update({
                'player1_id': m15_winner,
                'player2_id': m16_winner,
                'status': 'pending',
                'winner_id': None,
                'player1_score': 0,
                'player2_score': 0
            }).eq('match_number', 19).eq('round_number', 102).execute()
            
            print('✅ R102M19 fixed with correct players!')
            print(f'   Player 1: {m15_winner[:8]} (from M15)')
            print(f'   Player 2: {m16_winner[:8]} (from M16)')
            
            # Get player names
            try:
                p1_name = supabase.table('profiles').select('display_name').eq('id', m15_winner).single().execute()
                p2_name = supabase.table('profiles').select('display_name').eq('id', m16_winner).single().execute()
                print(f'   P1 Name: {p1_name.data["display_name"]}')
                print(f'   P2 Name: {p2_name.data["display_name"]}')
            except:
                pass
                
            return True
            
        elif m15_winner == m16_winner:
            print('❌ PROBLEM: Same player won both M15 and M16!')
            print('This should not happen in proper bracket setup.')
            print('Need to check initial tournament seeding.')
            return False
        else:
            print('❌ Missing winners - matches not completed yet')
            return False
            
    except Exception as e:
        print(f'Error: {e}')
        return False

if __name__ == '__main__':
    success = fix_r102m19_manually()
    
    if success:
        print('\n🎉 SUCCESS!')
        print('✅ R102M19 duplicate issue has been manually resolved')
        print('🔧 The match now has correct different players')
        print('📱 You can now continue with the tournament in the app')
    else:
        print('\n❌ FAILED')
        print('Issue requires deeper investigation into bracket generation logic')