from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔄 FIXING DATABASE FIELD MAPPING...')
print('Current data has INCORRECT mapping:')
print('  format = game type (should be tournament format)')
print('  tournament_type = tournament format (should be game type)')
print()

# Get all tournaments
result = supabase.table('tournaments').select('id, title, format, tournament_type').execute()

if result.data:
    print(f'Found {len(result.data)} tournaments to fix:')
    
    fixed_count = 0
    for tournament in result.data:
        tid = tournament['id']
        current_format = tournament.get('format', '')  # Currently game type
        current_tournament_type = tournament.get('tournament_type', '')  # Currently tournament format
        
        print(f'\nTournament: {tournament.get("title", "No title")}')
        print(f'  Current format: {current_format} (should be tournament format)')
        print(f'  Current tournament_type: {current_tournament_type} (should be game type)')
        
        # Swap the values to correct mapping
        new_format = current_tournament_type if current_tournament_type else 'single_elimination'
        new_tournament_type = current_format if current_format else '8-ball'
        
        print(f'  Fixing to:')
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
    print('\n🔍 VERIFYING FIX...')
    verify_result = supabase.table('tournaments').select('id, title, format, tournament_type').limit(3).execute()
    for tournament in verify_result.data:
        print(f'Tournament: {tournament.get("title", "No title")}')
        print(f'  format: {tournament.get("format", "NULL")} (tournament format)')
        print(f'  tournament_type: {tournament.get("tournament_type", "NULL")} (game type)')
        print()
        
else:
    print('No tournaments found.')