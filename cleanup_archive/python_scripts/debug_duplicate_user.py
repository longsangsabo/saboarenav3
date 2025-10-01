#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def debug_duplicate_user():
    print('🔍 CHECKING DUPLICATE USER ISSUE IN R102M19')
    print('=' * 50)

    # Find the problematic match
    matches = supabase.table('matches').select('*').eq('match_number', 19).eq('round_number', 102).execute()

    if matches.data:
        match = matches.data[0]
        match_id = match['id'][:8] if match['id'] else 'None'
        tournament_id = match['tournament_id'][:8] if match['tournament_id'] else 'None'
        player1_id = match['player1_id'][:8] if match['player1_id'] else 'None'
        player2_id = match['player2_id'][:8] if match['player2_id'] else 'None'
        
        print(f'Match ID: {match_id}')
        print(f'Tournament ID: {tournament_id}')
        print(f'Round: {match["round_number"]} (R102)')
        print(f'Match Number: {match["match_number"]} (M19)')
        print(f'Player 1 ID: {player1_id}')
        print(f'Player 2 ID: {player2_id}')
        print(f'Status: {match["status"]}')
        print()
        
        if match['player1_id'] and match['player2_id']:
            if match['player1_id'] == match['player2_id']:
                print('❌ SAME PLAYER ID ASSIGNED TO BOTH SLOTS!')
                print('This is a bracket generation logic error.')
                print()
                
                # Get user name
                user = supabase.table('user_profiles').select('display_name').eq('id', match['player1_id']).execute()
                if user.data:
                    print(f'User: {user.data[0]["display_name"]}')
                    
                return 'SAME_PLAYER_ID'
                
            else:
                print('✅ Different player IDs - checking names...')
                
                # Get user names
                p1 = supabase.table('user_profiles').select('display_name').eq('id', match['player1_id']).execute()
                p2 = supabase.table('user_profiles').select('display_name').eq('id', match['player2_id']).execute()
                
                if p1.data and p2.data:
                    print(f'Player 1: {p1.data[0]["display_name"]}')
                    print(f'Player 2: {p2.data[0]["display_name"]}')
                    
                    if p1.data[0]['display_name'] == p2.data[0]['display_name']:
                        print('❌ SAME DISPLAY NAME BUT DIFFERENT IDs!')
                        print('This might be duplicate user accounts.')
                        return 'DUPLICATE_NAMES'
                    else:
                        print('✅ Different users')
                        return 'OK'
        else:
            print(f'❓ Missing players: P1={player1_id}, P2={player2_id}')
            return 'MISSING_PLAYERS'
            
    else:
        print('❌ Match R102M19 not found')
        return 'NOT_FOUND'

def check_all_r102_matches():
    print('\n🔍 CHECKING ALL R102 MATCHES FOR DUPLICATES')
    print('=' * 50)
    
    matches = supabase.table('matches').select('*').eq('round_number', 102).execute()
    
    for match in matches.data:
        match_num = match['match_number']
        p1_id = match['player1_id']
        p2_id = match['player2_id']
        
        print(f'R102M{match_num}: P1={p1_id[:8] if p1_id else "None"}, P2={p2_id[:8] if p2_id else "None"}', end='')
        
        if p1_id and p2_id and p1_id == p2_id:
            print(' ❌ DUPLICATE!')
        elif not p1_id or not p2_id:
            print(' ❓ MISSING')
        else:
            print(' ✅ OK')

if __name__ == '__main__':
    result = debug_duplicate_user()
    check_all_r102_matches()
    
    if result == 'SAME_PLAYER_ID':
        print('\n🔧 RECOMMENDED FIX:')
        print('- Check bracket generation logic in CompleteSaboDE16Service')
        print('- Ensure different players are assigned to each match slot')
        print('- Verify loser advancement logic from R101 to R102')