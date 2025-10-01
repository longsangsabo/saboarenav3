from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🏆 Checking tournaments table fields...')
result = supabase.table('tournaments').select('id, title, format, tournament_type').limit(3).execute()
print(f'Sample data: {result.data}')
print()
if result.data:
    for tournament in result.data:
        print(f'Tournament: {tournament.get("title", "No title")}')
        print(f'  format: {tournament.get("format", "NULL")}')
        print(f'  tournament_type: {tournament.get("tournament_type", "NULL")}')
        print()
else:
    print('No tournaments found.')