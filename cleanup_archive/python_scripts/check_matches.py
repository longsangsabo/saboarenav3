from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

matches = supabase.table('matches').select('round, player1_id, player2_id, status').order('round').execute()
print(f'Current matches: {len(matches.data)}')

if matches.data:
    for m in matches.data:
        p1 = "P1" if m["player1_id"] else "NULL"
        p2 = "P2" if m["player2_id"] else "NULL"
        print(f'R{m["round"]}: {p1} vs {p2} - {m["status"]}')
else:
    print('No matches found')