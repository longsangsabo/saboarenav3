from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 CHECKING ALL TOURNAMENTS IN DATABASE')
print('=' * 50)

# Get all tournaments
tournaments = supabase.table('tournaments').select('id, title, status, bracket_format, max_participants, current_participants').execute()

print(f'📊 Total tournaments: {len(tournaments.data)}')
print()

if tournaments.data:
    for i, t in enumerate(tournaments.data, 1):
        title = t["title"]
        tournament_id = t["id"]
        status = t["status"]
        bracket_format = t["bracket_format"]
        current_participants = t["current_participants"]
        max_participants = t["max_participants"]
        
        print(f'{i}. {title} (ID: {tournament_id[:8]}...)')
        print(f'   Status: {status}')
        print(f'   Format: {bracket_format}')
        print(f'   Participants: {current_participants}/{max_participants}')
        print()
        
        # Check matches for this tournament
        matches = supabase.table('matches').select('round_number, status').eq('tournament_id', tournament_id).execute()
        if matches.data:
            rounds = {}
            for match in matches.data:
                round_num = match['round_number']
                if round_num not in rounds:
                    rounds[round_num] = {'total': 0, 'completed': 0}
                rounds[round_num]['total'] += 1
                if match['status'] == 'completed':
                    rounds[round_num]['completed'] += 1
            
            print('   📋 Matches by round:')
            for round_num in sorted(rounds.keys()):
                r = rounds[round_num]
                round_type = 'WB' if round_num < 100 else 'LB'
                print(f'     {round_type} R{round_num}: {r["completed"]}/{r["total"]} completed')
                
            # Check specific issue: WB completed but LB empty
            if 1 in rounds and 101 in rounds:
                wb_r1 = rounds[1]
                lb_r1 = rounds[101]
                if wb_r1['completed'] > 0 and lb_r1['completed'] == 0:
                    print(f'   🚨 ISSUE FOUND: WB R1 completed but LB R1 empty!')
                    print(f'   ➡️  This tournament has the progression problem!')
                    
        else:
            print('   ❌ No matches generated yet')
        print('-' * 40)
        
else:
    print('❌ No tournaments found in database!')

print()
print('💡 ISSUE ANALYSIS:')
print('If tournament ID 95cee835-9265-4b08-95b1-a5f9a67c1ec8 not found:')
print('1. Tournament might have been deleted during testing')
print('2. Wrong tournament ID')  
print('3. Need to create a new tournament to test')
print()
print('🎯 NEXT STEPS:')
print('1. Use one of the existing tournaments above')
print('2. Or create a new SABO DE16 tournament in Flutter app')
print('3. Then test the match progression issue')