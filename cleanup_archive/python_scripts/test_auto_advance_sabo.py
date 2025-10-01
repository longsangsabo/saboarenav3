"""
Test SABO DE16 Auto-Advance Behavior
Check if individual match completion triggers immediate advancement
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def test_auto_advance_logic():
    """Test the auto-advance behavior based on completed matches"""
    
    tournament_id = 'f7d7484c-b8fe-4d1d-8bf9-fa46e989de61'  # sabo3
    
    print('🧪 TESTING AUTO-ADVANCE LOGIC...')
    print('=' * 50)
    
    # Get all matches
    all_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number, match_number').execute()
    
    if not all_matches.data:
        print('❌ No matches found - need to generate bracket first')
        return
        
    matches = all_matches.data
    print(f'✅ Found {len(matches)} total matches')
    
    # Analyze by rounds
    rounds_data = {}
    for match in matches:
        round_num = match['round_number']
        if round_num not in rounds_data:
            rounds_data[round_num] = []
        rounds_data[round_num].append(match)
    
    print('\n📊 ROUND ANALYSIS:')
    for round_num in sorted(rounds_data.keys()):
        matches_in_round = rounds_data[round_num]
        completed = [m for m in matches_in_round if m['status'] == 'completed']
        with_players = [m for m in matches_in_round if m['player1_id'] or m['player2_id']]
        
        print(f'   R{round_num}: {len(matches_in_round)} matches, {len(completed)} completed, {len(with_players)} have players')
        
        # Show first few matches details
        for i, match in enumerate(matches_in_round[:3]):
            p1 = 'YES' if match['player1_id'] else 'TBD'
            p2 = 'YES' if match['player2_id'] else 'TBD'
            winner = 'YES' if match['winner_id'] else 'NO'
            print(f'      M{match["match_number"]}: P1={p1}, P2={p2}, Winner={winner}, Status={match["status"]}')
    
    # Check advancement logic
    print('\n🔍 AUTO-ADVANCE ANALYSIS:')
    
    # R1 → R2 advancement
    r1_matches = rounds_data.get(1, [])
    r2_matches = rounds_data.get(2, [])
    
    if r1_matches and r2_matches:
        r1_completed = [m for m in r1_matches if m['status'] == 'completed']
        r2_with_players = [m for m in r2_matches if m['player1_id'] or m['player2_id']]
        
        print(f'   R1 completed: {len(r1_completed)} matches')
        print(f'   R2 with players: {len(r2_with_players)} matches')
        
        if len(r1_completed) >= 2 and len(r2_with_players) < 1:
            print('   🚨 ISSUE: R1 pairs completed but R2 still empty!')
            print('   📋 Expected: Each R1 pair (M1+M2, M3+M4, etc.) → fills one R2 match')
        elif len(r1_completed) > 0 and len(r2_with_players) > 0:
            print('   ✅ GOOD: Some R1 completions → R2 advancement working')
        else:
            print('   ⚠️ No R1 completions to test auto-advance yet')
    
    print('\n🎯 RECOMMENDATION:')
    if len(matches) == 27:
        print('   ✅ Correct structure (27 matches)')
        if any(m['player1_id'] or m['player2_id'] for m in matches):
            print('   ✅ Some matches have players (bracket partially populated)')
        else:
            print('   ❌ No matches have players (need to populate R1)')
    else:
        print(f'   ❌ Wrong structure ({len(matches)} matches, should be 27)')

if __name__ == '__main__':
    test_auto_advance_logic()