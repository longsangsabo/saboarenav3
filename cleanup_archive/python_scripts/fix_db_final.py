from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔧 PROPER DATABASE FIELD MAPPING...')
print('Setting correct values:')
print('  format = tournament elimination format (single_elimination, double_elimination)')
print('  tournament_type = game type (8-ball, 9-ball, 10-ball)')
print()

# Get all tournaments
result = supabase.table('tournaments').select('id, title, format, tournament_type').execute()

if result.data:
    print(f'Found {len(result.data)} tournaments to fix:')
    
    fixed_count = 0
    for tournament in result.data:
        tid = tournament['id']
        current_format = tournament.get('format', '')
        current_tournament_type = tournament.get('tournament_type', '')
        
        print(f'\nTournament: {tournament.get("title", "No title")}')
        print(f'  Current format: {current_format}')
        print(f'  Current tournament_type: {current_tournament_type}')
        
        # Normalize format field to tournament elimination format
        if current_format in ['8-ball', '8-Ball', '9-ball', '9-Ball', '10-ball', '10-Ball']:
            # It's a game type, set default tournament format
            new_format = 'single_elimination'
            new_tournament_type = current_format.lower().replace('-', '_')  # normalize to 8_ball format
        elif current_format in ['single_elimination', 'double_elimination', 'round_robin', 'swiss']:
            # It's already a tournament format, keep it
            new_format = current_format
            # Determine game type from tournament_type or default
            if current_tournament_type in ['8-ball', '8-Ball', '9-ball', '9-Ball', '10-ball', '10-Ball']:
                new_tournament_type = current_tournament_type.lower().replace('-', '_')
            else:
                new_tournament_type = '8_ball'  # default
        else:
            # Unknown format, set defaults
            new_format = 'single_elimination'
            new_tournament_type = '8_ball'
        
        print(f'  Setting to:')
        print(f'    format: {new_format} (tournament format)')
        print(f'    tournament_type: {new_tournament_type} (game type)')
        
        try:
            update_result = supabase.table('tournaments').update({
                'format': new_format,
                'tournament_type': new_tournament_type
            }).eq('id', tid).execute()
            
            print(f'  ✅ Fixed!')
            fixed_count += 1
        except Exception as e:
            print(f'  ❌ Error: {e}')
    
    print(f'\n✅ Fixed {fixed_count}/{len(result.data)} tournaments')
    
    # Verify the fix
    print('\n🔍 FINAL VERIFICATION...')
    verify_result = supabase.table('tournaments').select('id, title, format, tournament_type').limit(5).execute()
    for tournament in verify_result.data:
        print(f'Tournament: {tournament.get("title", "No title")}')
        print(f'  format: {tournament.get("format", "NULL")} (tournament format)')
        print(f'  tournament_type: {tournament.get("tournament_type", "NULL")} (game type)')
        print()
        
else:
    print('No tournaments found.')