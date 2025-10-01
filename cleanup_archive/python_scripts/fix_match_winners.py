from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'

print('=== ANALYZING MATCH WINNERS ===')
matches = supabase.table('matches').select('id, round_number, match_number, status, winner_id, player1_score, player2_score, player1_id, player2_id').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

# Find completed matches without winners
problems = []
for match in matches.data:
    if match['status'] == 'completed' and not match['winner_id']:
        p1_score = match.get('player1_score', 0) or 0
        p2_score = match.get('player2_score', 0) or 0
        
        if p1_score > p2_score:
            winner_id = match['player1_id']
        elif p2_score > p1_score:
            winner_id = match['player2_id']
        else:
            winner_id = None  # Tie
        
        problems.append({
            'match_id': match['id'],
            'round': match['round_number'],
            'match_num': match['match_number'],
            'p1_score': p1_score,
            'p2_score': p2_score,
            'suggested_winner': winner_id
        })

print(f'Found {len(problems)} completed matches without winner_id:')
for p in problems:
    print(f"  R{p['round']}M{p['match_num']}: {p['p1_score']}-{p['p2_score']} -> Winner: {p['suggested_winner']}")

# Fix the winners
if problems:
    print('\n=== FIXING WINNERS ===')
    for p in problems:
        if p['suggested_winner']:
            try:
                result = supabase.table('matches').update({
                    'winner_id': p['suggested_winner']
                }).eq('id', p['match_id']).execute()
                print(f"✅ Fixed R{p['round']}M{p['match_num']} winner: {p['suggested_winner']}")
            except Exception as e:
                print(f"❌ Failed to fix R{p['round']}M{p['match_num']}: {e}")
        else:
            print(f"⚠️  R{p['round']}M{p['match_num']} is a tie - needs manual resolution")

print('\n=== CHECKING TRIGGER FOR NEXT ROUND ===')
# After fixing winners, check if we need to create next round
r1_matches = [m for m in matches.data if m['round_number'] == 1]
r1_with_winners = len([m for m in r1_matches if m['winner_id']])
r1_total = len(r1_matches)

print(f'Round 1: {r1_with_winners}/{r1_total} matches have winners')

if r1_with_winners == r1_total:
    # Check if Round 2 exists
    r2_matches = [m for m in matches.data if m['round_number'] == 2]
    if len(r2_matches) == 0:
        print('⚠️  Round 1 complete but Round 2 not created - trigger not working!')
        # We should create Round 2 matches manually
        print('Need to create Round 2 matches manually...')
    else:
        print(f'Round 2 already exists with {len(r2_matches)} matches')