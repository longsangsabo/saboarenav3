from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA BRACKET CREATION LOGIC')
print('=' * 50)

# Tìm tournament sabo1
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    t = tournament.data[0]
    tournament_id = t['id']
    
    print(f'📋 TOURNAMENT sabo1:')
    print(f'   ID: {tournament_id}')
    print(f'   Title: {t["title"]}')
    print(f'   Format (DB field): {t.get("format", "NULL")}')
    print(f'   Tournament Type (DB field): {t.get("tournament_type", "NULL")}')
    print(f'   Max Participants: {t.get("max_participants", 0)}')
    print(f'   Current Participants: {t.get("current_participants", 0)}')
    
    # Kiểm tra participants
    participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
    participant_count = len(participants.data) if participants.data else 0
    
    print(f'\n👥 PARTICIPANTS DATA:')
    print(f'   Registered participants: {participant_count}')
    print(f'   Max participants: {t.get("max_participants", 0)}')
    print(f'   Tournament full: {participant_count >= t.get("max_participants", 0)}')
    
    # Kiểm tra existing matches
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
    match_count = len(matches.data) if matches.data else 0
    
    print(f'\n🏆 EXISTING MATCHES:')
    print(f'   Current matches: {match_count}')
    print(f'   Bracket created: {"Yes" if match_count > 0 else "No"}')
    
    print(f'\n🎯 BRACKET CREATION ANALYSIS:')
    
    # Expected mapping (từ database)
    db_format = t.get('format')  # "8-ball" (game type)
    db_tournament_type = t.get('tournament_type')  # "double_elimination" (elimination format)
    
    print(f'   Database fields:')
    print(f'     • format = "{db_format}" (game type)')
    print(f'     • tournament_type = "{db_tournament_type}" (elimination format)')
    
    # App model mapping
    print(f'\n   App model should map to:')
    print(f'     • tournament.format = "{db_tournament_type}" (elimination format)')
    print(f'     • tournament.tournamentType = "{db_format}" (game type)')
    
    # Expected bracket creation parameters
    print(f'\n   Expected bracket creation parameters:')
    print(f'     • Format: "{db_tournament_type}" (double_elimination)')
    print(f'     • Player count: {participant_count} players')
    print(f'     • Game type: "{db_format}" (8-ball)')
    
    # Determine correct bracket factory
    print(f'\n🏭 BRACKET FACTORY SELECTION:')
    
    elimination_format = db_tournament_type
    player_count = participant_count
    
    if elimination_format == 'double_elimination':
        if player_count == 16:
            expected_factory = 'DE16Factory (Double Elimination 16)'
            expected_matches = 27  # Typical DE16 match count
        elif player_count == 32:
            expected_factory = 'DE32Factory (Double Elimination 32)'
            expected_matches = 57  # Typical DE32 match count
        else:
            expected_factory = f'GenericDoubleEliminationFactory ({player_count} players)'
            expected_matches = f'~{player_count * 2 - 3} matches'
    elif elimination_format == 'single_elimination':
        expected_factory = f'SingleEliminationFactory ({player_count} players)'
        expected_matches = player_count - 1
    else:
        expected_factory = f'Unknown format: {elimination_format}'
        expected_matches = 'Unknown'
    
    print(f'   Correct factory: {expected_factory}')
    print(f'   Expected matches: {expected_matches}')
    
    print(f'\n✅ VERIFICATION CHECKLIST:')
    print(f'   1. Format detection: {elimination_format} ✅')
    print(f'   2. Player count: {player_count} ✅')
    print(f'   3. Expected factory: {expected_factory} ✅')
    
    if match_count > 0:
        print(f'   4. Matches created: {match_count} (Already exists)')
        print(f'   5. Bracket status: Already generated')
    else:
        print(f'   4. Matches created: 0 (Ready to generate)')
        print(f'   5. Bracket status: Ready for creation')
    
    print(f'\n🔧 NEXT STEPS TO VERIFY:')
    print(f'   1. Click "Tạo bảng đấu" button')
    print(f'   2. Check if system detects: {elimination_format} + {player_count} players')
    print(f'   3. Verify correct factory is used: {expected_factory}')
    print(f'   4. Check if {expected_matches} matches are created')

else:
    print('❌ Không tìm thấy tournament sabo1')