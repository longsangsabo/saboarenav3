from supabase import create_client

# Database connection
url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(url, key)

print("=== CHECKING MATCHES TABLE ===")
try:
    result = supabase.from('matches').select('*').limit(1).execute()
    if result.data:
        print('Matches table columns:')
        for key in sorted(result.data[0].keys()):
            print(f'- {key}: {result.data[0][key]}')
    else:
        print('No matches found')
        
    print("\n=== TESTING INSERT WITH FORMAT COLUMN ===")
    # Test if we can insert with format column
    test_data = {
        'tournament_id': '00000000-0000-0000-0000-000000000000',  # dummy UUID
        'round_number': 1,
        'match_number': 1,
        'format': 'single_elimination',  # This should fail if column doesn't exist
        'status': 'pending'
    }
    
    result = supabase.from('matches').insert(test_data).execute()
    print("✅ Insert test successful - format column exists")
    
    # Clean up test data
    supabase.from('matches').delete().eq('tournament_id', '00000000-0000-0000-0000-000000000000').execute()
    
except Exception as e:
    print(f'❌ Error: {e}')
    print("\n=== NEED TO ADD FORMAT COLUMN ===")