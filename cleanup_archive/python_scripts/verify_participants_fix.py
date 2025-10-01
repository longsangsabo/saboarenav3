#!/usr/bin/env python3
"""
🎯 VERIFY PARTICIPANTS FIX
Kiểm tra sau khi tạo bracket xem WB Round 1 có real participants không
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def verify_participants_fix():
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'
    
    print('🎯 VERIFYING PARTICIPANTS FIX')
    print('=' * 50)
    
    # Get WB Round 1 matches
    wb_r1 = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()
    
    if not wb_r1.data:
        print('❌ No WB Round 1 matches found!')
        print('   Create bracket in app first!')
        return
    
    print(f'✅ Found {len(wb_r1.data)} WB Round 1 matches')
    print()
    
    # Check participants
    real_participants = 0
    null_participants = 0
    
    print('🔍 WB ROUND 1 PARTICIPANTS:')
    for match in wb_r1.data:
        match_num = match['match_number']
        p1_id = match['player1_id']
        p2_id = match['player2_id']
        
        p1_display = p1_id[:8] if p1_id else 'NULL'
        p2_display = p2_id[:8] if p2_id else 'NULL'
        
        print(f'   M{match_num}: P1={p1_display}, P2={p2_display}')
        
        if p1_id and p2_id:
            real_participants += 1
        else:
            null_participants += 1
    
    print()
    print('📊 RESULTS:')
    print(f'   ✅ Matches with REAL participants: {real_participants}/8')
    print(f'   ❌ Matches with NULL participants: {null_participants}/8')
    
    if real_participants == 8:
        print()
        print('🎉 SUCCESS! ALL MATCHES HAVE REAL PARTICIPANTS!')
        print('   Fix worked: player[\'user_id\'] instead of player[\'id\']')
        print('   UI should now show real names instead of TBD!')
    elif real_participants > 0:
        print()
        print('⚠️  PARTIAL SUCCESS - Some matches have participants')
        print('   Check if participant data format is consistent')
    else:
        print()
        print('❌ FAILED - All matches still have NULL participants')
        print('   Problem may be:')
        print('   1. Participant data structure different than expected')
        print('   2. Database insert failed')
        print('   3. Wrong tournament ID')
    
    # Get total bracket structure  
    all_matches = supabase.table('matches').select('round_number').eq('tournament_id', tournament_id).execute()
    
    if all_matches.data:
        rounds = {}
        for match in all_matches.data:
            round_num = match['round_number']
            rounds[round_num] = rounds.get(round_num, 0) + 1
        
        print()
        print('🏆 BRACKET STRUCTURE:')
        for round_num in sorted(rounds.keys()):
            round_type = 'WB' if round_num < 100 else 'LB' if round_num < 200 else 'GF'
            print(f'   {round_type} R{round_num}: {rounds[round_num]} matches')
    
    return real_participants == 8

if __name__ == '__main__':
    verify_participants_fix()