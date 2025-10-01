from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

def create_next_round_matches(tournament_id, current_round):
    """Create next round matches from current round winners"""
    
    print(f"=== CREATING ROUND {current_round + 1} MATCHES ===")
    
    # Get all winners from current round
    current_matches = supabase.table('matches').select('match_number, winner_id').eq('tournament_id', tournament_id).eq('round_number', current_round).order('match_number').execute()
    
    winners = []
    for match in current_matches.data:
        if match['winner_id']:
            winners.append(match['winner_id'])
    
    print(f"Found {len(winners)} winners from Round {current_round}")
    
    if len(winners) < 2:
        print("Not enough winners to create next round")
        return False
    
    # Check if next round already exists
    existing_next = supabase.table('matches').select('id').eq('tournament_id', tournament_id).eq('round_number', current_round + 1).execute()
    
    if len(existing_next.data) > 0:
        print(f"Round {current_round + 1} already exists")
        return False
    
    # Create next round matches by pairing winners
    matches_to_create = []
    match_number = 1
    
    for i in range(0, len(winners), 2):
        if i + 1 < len(winners):
            match_data = {
                'tournament_id': tournament_id,
                'round_number': current_round + 1,
                'match_number': match_number,
                'player1_id': winners[i],
                'player2_id': winners[i + 1],
                'status': 'pending',
                'player1_score': 0,
                'player2_score': 0
            }
            matches_to_create.append(match_data)
            match_number += 1
    
    # Insert new matches
    if matches_to_create:
        result = supabase.table('matches').insert(matches_to_create).execute()
        print(f"✅ Created {len(matches_to_create)} matches for Round {current_round + 1}")
        return True
    
    return False

# Test with current tournament
tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'

print("=== CURRENT TOURNAMENT STATUS ===")
matches = supabase.table('matches').select('round_number, match_number, winner_id').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

round_stats = {}
for match in matches.data:
    rnd = match['round_number']
    if rnd not in round_stats:
        round_stats[rnd] = {'total': 0, 'with_winner': 0}
    round_stats[rnd]['total'] += 1
    if match['winner_id']:
        round_stats[rnd]['with_winner'] += 1

for rnd, stats in round_stats.items():
    total = stats['total']
    with_winner = stats['with_winner']
    print(f"Round {rnd}: {with_winner}/{total} matches have winners")
    
    # If all matches have winners, try to create next round
    if with_winner == total and total > 1:
        next_round = rnd + 1
        # Check if next round exists
        next_round_matches = [m for m in matches.data if m['round_number'] == next_round]
        if len(next_round_matches) == 0:
            print(f"  -> Should create Round {next_round}")
            create_next_round_matches(tournament_id, rnd)
        else:
            print(f"  -> Round {next_round} already exists")

print("\n=== FINAL STATUS ===")
# Refresh and show final status
matches = supabase.table('matches').select('round_number, match_number, winner_id, status').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

round_stats = {}
for match in matches.data:
    rnd = match['round_number']
    if rnd not in round_stats:
        round_stats[rnd] = {'total': 0, 'with_winner': 0}
    round_stats[rnd]['total'] += 1
    if match['winner_id']:
        round_stats[rnd]['with_winner'] += 1

for rnd, stats in round_stats.items():
    print(f"Round {rnd}: {stats['with_winner']}/{stats['total']} matches have winners")