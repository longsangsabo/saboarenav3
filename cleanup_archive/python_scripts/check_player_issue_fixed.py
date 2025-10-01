from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

# Check tournament 6c0658f7 matches
print('=== Tournament 6c0658f7 matches (current display) ===')
result = supabase.table('matches').select('id, round_number, match_number, player1_id, player2_id, status').eq('tournament_id', '6c0658f7-bf94-44a0-82b1-de117ec9ea29').order('round_number').order('match_number').limit(3).execute()

print(f'Found {len(result.data)} matches')
for i, match in enumerate(result.data):
    p1_id = match.get('player1_id', 'NULL')
    p2_id = match.get('player2_id', 'NULL')
    p1_short = p1_id[:8] + '...' if p1_id and p1_id != 'NULL' else 'NULL'
    p2_short = p2_id[:8] + '...' if p2_id and p2_id != 'NULL' else 'NULL'
    
    print(f'  R{match.get("round_number", "?")}M{match.get("match_number", "?")}: P1={p1_short} P2={p2_short} Status={match["status"]}')

print('\n=== Checking if players exist in users table ===')
try:
    user_result = supabase.table('users').select('id, username, full_name').limit(5).execute()
    print(f'Found {len(user_result.data)} users in users table')
    for user in user_result.data[:3]:
        user_short = user['id'][:8] + '...' if user['id'] else 'N/A'
        print(f'  {user_short}: {user.get("username", "N/A")} - {user.get("full_name", "N/A")}')
        
    # Check if one of our match players exists
    if result.data:
        first_player_id = result.data[0].get('player1_id')
        if first_player_id:
            player_check = supabase.table('users').select('*').eq('id', first_player_id).execute()
            if player_check.data:
                print(f'\n✅ Player {first_player_id[:8]}... found in users table')
                player = player_check.data[0]
                print(f'   Username: {player.get("username", "N/A")}')
                print(f'   Full name: {player.get("full_name", "N/A")}')
            else:
                print(f'\n❌ Player {first_player_id[:8]}... NOT found in users table')
        
except Exception as e:
    print(f'Error accessing users table: {e}')

print('\n=== Problem Analysis ===')
print('The issue is likely that the matches query in Flutter is NOT using joins to fetch player data.')
print('The matches table has player1_id and player2_id, but the query needs to join with users table.')