from supabase import create_client

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'

print('=== TOURNAMENT LOGIC ANALYSIS ===')
print()

# Get tournament details
tournament = supabase.table('tournaments').select('*').eq('id', tournament_id).single().execute()
if tournament.data:
    print('Tournament:', tournament.data.get('name', 'N/A'))
    print('Format:', tournament.data.get('format', 'N/A'))
    print('Max participants:', tournament.data.get('max_participants', 'N/A'))

# Get participants
participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
participant_count = len(participants.data)
print('Actual participants:', participant_count)

# Get matches by round
matches = supabase.table('matches').select('id, round_number, match_number, status, winner_id').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()

matches_by_round = {}
for match in matches.data:
    round_num = match.get('round_number', 0)
    if round_num not in matches_by_round:
        matches_by_round[round_num] = []
    matches_by_round[round_num].append(match)

print()
print('=== BRACKET STRUCTURE ANALYSIS ===')
total_matches = 0
for round_num in sorted(matches_by_round.keys()):
    count = len(matches_by_round[round_num])
    total_matches += count
    print(f'Round {round_num}: {count} matches')

print('TOTAL MATCHES:', total_matches)

print()
print('=== SINGLE ELIMINATION MATH CHECK ===')
if participant_count > 0:
    # Single elimination: n-1 matches for n participants
    expected_matches = participant_count - 1
    print('Participants:', participant_count)
    print('Expected matches (n-1):', expected_matches)
    print('Actual matches:', total_matches)
    
    if total_matches != expected_matches:
        print('❌ BRACKET LOGIC ERROR!')
        print(f'   Có {total_matches - expected_matches} matches thừa!')
    else:
        print('✅ Bracket logic correct')
    
    # Check round structure
    print()
    print('Expected round structure:')
    temp_players = participant_count
    round_num = 1
    while temp_players > 1:
        matches_needed = temp_players // 2
        print(f'   Round {round_num}: {matches_needed} matches ({temp_players} → {temp_players // 2} players)')
        temp_players = temp_players // 2
        round_num += 1
        
    print()
    print('Actual round structure:')
    for round_num in sorted(matches_by_round.keys()):
        count = len(matches_by_round[round_num])
        print(f'   Round {round_num}: {count} matches')
        
print()
print('🚨 DIAGNOSIS:')
print('Single elimination với 8 người cần 7 trận (8-1=7)')
print('Round 1: 4 trận (8→4)')
print('Round 2: 2 trận (4→2) ')
print('Round 3: 1 trận (2→1)')
print('TOTAL: 7 trận, KHÔNG PHẢI 11 trận!')