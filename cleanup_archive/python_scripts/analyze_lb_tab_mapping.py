from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 ANALYZING LB TAB LOGIC ISSUE')
print('=' * 50)

# Get sabo1 tournament
tournaments = supabase.table('tournaments').select('id, title').eq('title', 'sabo1').execute()
tournament_id = tournaments.data[0]['id']
print(f'✅ Analyzing tournament: {tournament_id}')

print()
print('📊 ALL LB MATCHES BY ROUND NUMBER:')

# Get all LB matches (round_number >= 101)
all_lb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).gte('round_number', 101).order('round_number, match_number').execute()

# Group by round number
rounds_data = {}
for match in all_lb_matches.data:
    round_num = match['round_number']
    if round_num not in rounds_data:
        rounds_data[round_num] = []
    rounds_data[round_num].append(match)

# Display each round
for round_num in sorted(rounds_data.keys()):
    matches = rounds_data[round_num]
    print()
    print(f'🎯 LB ROUND {round_num}: ({len(matches)} matches)')
    
    for match in matches:
        match_id = match['id']
        match_number = match['match_number'] 
        p1_id = match['player1_id']
        p2_id = match['player2_id']
        status = match['status']
        
        p1_display = p1_id[:8] if p1_id else 'TBD'
        p2_display = p2_id[:8] if p2_id else 'TBD'
        
        # This is what UI should display
        display_id = f'R{round_num}M{match_number}'
        
        print(f'   {display_id}: {p1_display} vs {p2_display} | Status: {status}')
    print()

print('🎯 TAB MAPPING ANALYSIS:')
print('Based on UI screenshot, tabs should map to:')
print('   LB-VÒNG 1 = LB Round 101 (first LB round)')
print('   LB-VÒNG 2 = LB Round 102 (second LB round)')  
print('   LB-VÒNG 3 = LB Round 103 (third LB round)')
print('   LB-BÁN KẾT = LB Round 104 or 105 (semi-final)')
print('   LB-CHUNG KẾT = LB Round 200/201 (final)')

print()
print('❌ ISSUE DETECTED:')
print('UI is showing R201M27 in LB-VÒNG 1 tab')
print('This suggests Flutter UI is incorrectly mapping:')
print('   - Round 201 (final) matches to LB-VÒNG 1 tab')
print('   - Should show Round 101 matches instead')

print()
print('🔧 FLUTTER UI MAPPING ISSUE:')
print('The bracket widget logic is probably:')
print('1. Incorrectly filtering matches by round number')
print('2. Wrong tab-to-round mapping in Flutter code')
print('3. Displaying final matches in first tab')

print()
print('💡 SOLUTION NEEDED:')
print('Check Flutter bracket widget files:')
print('   - visual_tournament_bracket_widget.dart')
print('   - production_bracket_widget.dart')
print('   - bracket_visualization_service.dart')
print('Fix the round-to-tab mapping logic to:')
print('   Tab 1 (LB-VÒNG 1) → Round 101')
print('   Tab 2 (LB-VÒNG 2) → Round 102')
print('   Tab 3 (LB-VÒNG 3) → Round 103')
print('   Tab 4 (LB-BÁN KẾT) → Round 104/105')
print('   Tab 5 (LB-CHUNG KẾT) → Round 200/201')