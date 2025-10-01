from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 DEBUGGING TOURNAMENT FORMAT DETECTION...')
print('=' * 50)

# Check SABO1 tournament
tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
print(f'Tournament ID: {tournament_id}')

# Get tournament data
result = supabase.table('tournaments').select('*').eq('id', tournament_id).execute()

if result.data:
    tournament = result.data[0]
    print('✅ TOURNAMENT FOUND:')
    print(f'   Title: {tournament.get("title", "N/A")}')
    print(f'   Bracket Format: "{tournament.get("bracket_format", "N/A")}"')
    print(f'   Game Format: "{tournament.get("game_format", "N/A")}"')
    print(f'   Format Type: {type(tournament.get("bracket_format", "N/A"))}')
    
    # Check what the format detection logic should do
    format_val = tournament.get('bracket_format', 'double_elimination')
    print(f'\n🧠 FORMAT LOGIC TEST:')
    print(f'   Raw format: "{format_val}"')
    print(f'   Lowercase: "{format_val.lower()}"')
    
    if format_val.lower() in ['sabo_de16', 'sabo_double_elimination']:
        print('   ✅ Should use CompleteSaboDE16Service.getRoundTabMapping()')
        
        # Test the mapping
        mapping = {
            1: "WB-VÒNG 1",
            2: "WB-VÒNG 2", 
            3: "WB-BÁN KẾT",
            101: "LB-A-R1",
            102: "LB-A-R2",
            103: "LB-A-R3",
            201: "LB-B-R1",
            202: "LB-B-R2",
            250: "SEMI FINAL 1",
            251: "SEMI FINAL 2",
            300: "FINAL"
        }
        print('   ✅ SABO DE16 mapping available')
        
        # Show sample mappings
        for round_num in [1, 101, 201, 250, 300]:
            if round_num in mapping:
                print(f'      Round {round_num} → "{mapping[round_num]}"')
                
    else:
        print('   ❌ Will use DoubleElimination16Service.getRoundTabMapping()')
        print('   ❌ This is the problem!')
        
    # Check matches
    matches_result = supabase.table('matches').select('round_number').eq('tournament_id', tournament_id).execute()
    if matches_result.data:
        rounds = sorted(set(m['round_number'] for m in matches_result.data))
        print(f'\n📊 ACTUAL ROUNDS IN DB: {rounds}')
    else:
        print('\n📋 No matches found')
        
else:
    print('❌ TOURNAMENT NOT FOUND!')
    
    # List all tournaments to see what we have
    all_tournaments = supabase.table('tournaments').select('id, title, bracket_format').execute()
    if all_tournaments.data:
        print('\n📋 AVAILABLE TOURNAMENTS:')
        for t in all_tournaments.data:
            print(f'   {t["id"][:8]}... - {t["title"]} - {t["bracket_format"]}')
    else:
        print('\n📋 No tournaments found in database')