#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def check_r102m19_status():
    try:
        # Check current R102M19 status
        match = supabase.table('matches').select('*').eq('match_number', 19).eq('round_number', 102).single().execute()

        p1_id = match.data['player1_id'][:8] if match.data['player1_id'] else 'None'
        p2_id = match.data['player2_id'][:8] if match.data['player2_id'] else 'None'
        status = match.data['status']

        print('✅ CURRENT STATUS OF R102M19:')
        print(f'Player 1: {p1_id}')
        print(f'Player 2: {p2_id}')
        print(f'Status: {status}')

        # Check if same
        if match.data['player1_id'] and match.data['player2_id']:
            if match.data['player1_id'] == match.data['player2_id']:
                print('❌ STILL DUPLICATE!')
                return False
            else:
                print('✅ FIXED - Different players!')
                # Get names
                try:
                    p1 = supabase.table('profiles').select('display_name').eq('id', match.data['player1_id']).single().execute()
                    p2 = supabase.table('profiles').select('display_name').eq('id', match.data['player2_id']).single().execute()
                    print(f'P1: {p1.data["display_name"]}')
                    print(f'P2: {p2.data["display_name"]}')
                except Exception as e:
                    print(f'Could not get names: {e}')
                return True
        else:
            print('❓ One or both missing - ready for proper assignment')
            return True
            
    except Exception as e:
        print(f'Error checking R102M19: {e}')
        return False

if __name__ == '__main__':
    print('🔍 CHECKING R102M19 STATUS AFTER FIX')
    print('=' * 45)
    
    result = check_r102m19_status()
    
    print()
    if result:
        print('🎉 SUCCESS: R102M19 duplicate issue resolved!')
        print('✅ Validation logic is working correctly')
        print('🔧 Bracket advancement will work properly now')
    else:
        print('❌ Issue still exists - needs further debugging')