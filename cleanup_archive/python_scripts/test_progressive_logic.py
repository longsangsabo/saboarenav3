from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

# Test current tournament with progressive logic
tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'

print('=== Testing Progressive Bracket Creation Logic ===')
print(f'Tournament ID: {tournament_id}')

# Get all matches for this tournament
result = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

if not result.data:
    print('❌ No matches found for this tournament')
    exit()

# Group matches by round
rounds = {}
for match in result.data:
    rnd = match['round_number']
    if rnd not in rounds:
        rounds[rnd] = []
    rounds[rnd].append(match)

print('\n=== Current Tournament State ===')
for round_num in sorted(rounds.keys()):
    matches = rounds[round_num]
    completed = sum(1 for m in matches if m['status'] == 'completed')
    with_winner = sum(1 for m in matches if m['winner_id'])
    total = len(matches)
    print(f'Round {round_num}: {total} matches, {completed} completed, {with_winner} with winners')
    
    # Show match details for Round 1
    if round_num == 1:
        print('  Round 1 Details:')
        for match in sorted(matches, key=lambda x: x['match_number']):
            winner_status = '✅' if match['winner_id'] else '❌'
            print(f'    R1M{match["match_number"]}: {match["status"]} {match["player1_score"]}-{match["player2_score"]} {winner_status}')
        
        # Calculate progressive creation potential
        possible_r2_matches = with_winner // 2
        print(f'  → Progressive Logic: Can create {possible_r2_matches} R2 matches from {with_winner} winners')

# Check current R2 matches
r2_matches = [m for m in result.data if m['round_number'] == 2]
print(f'\n=== Round 2 Status ===')
print(f'Current R2 matches: {len(r2_matches)}')

if r2_matches:
    print('R2 Match Details:')
    for match in sorted(r2_matches, key=lambda x: x['match_number']):
        winner_status = '✅' if match['winner_id'] else '❌'
        print(f'  R2M{match["match_number"]}: {match["status"]} {match["player1_score"]}-{match["player2_score"]} {winner_status}')

# Test if progressive creation should trigger
r1_matches = rounds.get(1, [])
r1_winners = [m for m in r1_matches if m['winner_id']]
pairs_available = len(r1_winners) // 2
existing_r2 = len(r2_matches)

print(f'\n=== Progressive Creation Test ===')
print(f'R1 winners available: {len(r1_winners)}')
print(f'Pairs that can form R2 matches: {pairs_available}')
print(f'Existing R2 matches: {existing_r2}')
print(f'New R2 matches that should be created: {pairs_available - existing_r2}')

if pairs_available > existing_r2:
    print('✅ Progressive creation should trigger!')
    print('Winners ready for pairing:')
    for i, match in enumerate(r1_winners):
        print(f'  Winner {i+1}: {match["winner_id"][:8]}... (from R1M{match["match_number"]})')
else:
    print('⏳ Not enough new winners to create additional R2 matches')