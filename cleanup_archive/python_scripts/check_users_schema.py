from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(url, key)

print("=== CHECKING USERS TABLE ===")
try:
    result = supabase.from('users').select('*').limit(1).execute()
    if result.data:
        print('Users table columns:')
        for key in sorted(result.data[0].keys()):
            print(f'- {key}: {type(result.data[0][key]).__name__} = {result.data[0][key]}')
    else:
        print('No users found')
except Exception as e:
    print(f'Error: {e}')

print("\n=== CHECKING TOURNAMENT PARTICIPANTS ===")
try:
    result = supabase.from('tournament_participants').select('*, users(*)').limit(1).execute()
    if result.data:
        print('Tournament participants data structure:')
        participant = result.data[0]
        print(f"Participant keys: {list(participant.keys())}")
        if 'users' in participant and participant['users']:
            user = participant['users']
            print(f"User data keys: {list(user.keys())}")
            print("User data values:")
            for key in sorted(user.keys()):
                print(f"  {key}: {user[key]}")
    else:
        print('No tournament participants found')
except Exception as e:
    print(f'Error: {e}')