from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

# Check tournament 6c0658f7 matches
print('=== Tournament 6c0658f7 matches (current display) ===')
result = supabase.table('matches').select('id, round_number, match_number, player1_id, player2_id, status').eq('tournament_id', '6c0658f7-bf94-44a0-82b1-de117ec9ea29').order('round_number').order('match_number').execute()

for i, match in enumerate(result.data[:5]):  # Show first 5
    p1_id = match.get('player1_id', 'NULL')
    p2_id = match.get('player2_id', 'NULL')
    p1_short = p1_id[:8] + '...' if p1_id and p1_id != 'NULL' else 'NULL'
    p2_short = p2_id[:8] + '...' if p2_id and p2_id != 'NULL' else 'NULL'
    
    print(f'  R{match.get("round_number", "?")}M{match.get("match_number", "?")}: P1={p1_short} P2={p2_short} Status={match["status"]}')

print('\n=== Checking if players exist in user_profiles ===')
user_result = supabase.table('user_profiles').select('id, username, full_name').limit(5).execute()
print(f'Found {len(user_result.data)} users in user_profiles table')
for user in user_result.data[:3]:
    user_short = user['id'][:8] + '...' if user['id'] else 'N/A'
    print(f'  {user_short}: {user.get("username", "N/A")} - {user.get("full_name", "N/A")}')

print('\n=== Tournament with player data (20e4493c) ===')
result2 = supabase.table('matches').select('id, round_number, match_number, player1_id, player2_id, status').eq('tournament_id', '20e4493c-c163-43c3-9d4d-58a5d7f59ec6').limit(3).execute()

for match in result2.data:
    p1_id = match.get('player1_id', 'NULL')
    p2_id = match.get('player2_id', 'NULL')
    p1_short = p1_id[:8] + '...' if p1_id and p1_id != 'NULL' else 'NULL'
    p2_short = p2_id[:8] + '...' if p2_id and p2_id != 'NULL' else 'NULL'
    
    print(f'  R{match.get("round_number", "?")}M{match.get("match_number", "?")}: P1={p1_short} P2={p2_short} Status={match["status"]}')