from supabase import create_client
import uuid

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

def test_tournament_progression():
    """Test and demonstrate the tournament progression issue"""
    print("=== TOURNAMENT PROGRESSION ANALYSIS ===\n")
    
    tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'
    
    # Get all matches for this tournament
    matches_response = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
    matches = matches_response.data
    
    if not matches:
        print("❌ No matches found for tournament")
        return
    
    # Group by rounds
    rounds = {}
    for match in matches:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    print("📊 Current Tournament State:")
    for round_num in sorted(rounds.keys()):
        round_matches = rounds[round_num]
        total = len(round_matches)
        completed = len([m for m in round_matches if m['winner_id'] is not None])
        completed_status = len([m for m in round_matches if m['status'] == 'completed'])
        
        status = "✅ COMPLETE" if completed == total else f"⏳ {completed}/{total} complete"
        print(f"  Round {round_num}: {total} matches, {status}")
        
        # Show match details
        for i, match in enumerate(round_matches):
            winner_info = f"Winner: {match['winner_id'][:8]}..." if match['winner_id'] else "No winner"
            print(f"    Match {match['match_number']}: {match['status']} - {winner_info}")
    
    # Check if we should create next round
    print(f"\n🔍 Analysis:")
    last_round = max(rounds.keys())
    last_round_matches = rounds[last_round]
    last_round_complete = all(m['winner_id'] is not None for m in last_round_matches)
    
    if last_round_complete and len(last_round_matches) == 1:
        print(f"🏆 Tournament is COMPLETE! Round {last_round} has 1 match with winner.")
        winner_match = last_round_matches[0]
        if winner_match['winner_id']:
            print(f"🥇 Champion: {winner_match['winner_id']}")
    elif last_round_complete and len(last_round_matches) > 1:
        print(f"🚀 Round {last_round} is complete with {len(last_round_matches)} matches.")
        print(f"📝 Should create Round {last_round + 1} with {len(last_round_matches) // 2} matches")
        
        # Simulate creating next round
        winners = [m['winner_id'] for m in last_round_matches if m['winner_id']]
        print(f"🏆 Winners to advance: {len(winners)} players")
        
        if len(winners) >= 2:
            next_matches = len(winners) // 2
            print(f"🎯 Should create {next_matches} matches for Round {last_round + 1}")
            
            # Check if next round already exists
            next_round_response = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', last_round + 1).execute()
            if next_round_response.data:
                print(f"⚠️ Round {last_round + 1} already exists!")
            else:
                print(f"✅ Ready to create Round {last_round + 1}")
        else:
            print("❌ Not enough winners to create next round")
    else:
        print(f"⏳ Round {last_round} is not complete yet")

def manually_create_next_round():
    """Manually create the next round if needed"""
    print("\n=== MANUAL TOURNAMENT PROGRESSION ===\n")
    
    tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'
    
    # This is a test of what the trigger should do
    # For this specific tournament that's stuck
    
    # Get current tournament state
    matches_response = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
    matches = matches_response.data
    
    # Find the last completed round
    rounds = {}
    for match in matches:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    # Check each round for completion
    for round_num in sorted(rounds.keys(), reverse=True):
        round_matches = rounds[round_num]
        all_complete = all(m['winner_id'] is not None for m in round_matches)
        
        if all_complete and len(round_matches) > 1:
            # This round is complete and has more than 1 match
            # Check if next round exists
            next_round_num = round_num + 1
            next_round_exists = next_round_num in rounds
            
            if not next_round_exists:
                print(f"🚀 Creating Round {next_round_num} from Round {round_num} winners...")
                
                # Get winners
                winners = [m['winner_id'] for m in round_matches if m['winner_id']]
                print(f"🏆 Found {len(winners)} winners")
                
                # Create next round matches
                next_matches = []
                for i in range(0, len(winners), 2):
                    if i + 1 < len(winners):
                        match_data = {
                            'id': str(uuid.uuid4()),
                            'tournament_id': tournament_id,
                            'round_number': next_round_num,
                            'match_number': (i // 2) + 1,
                            'player1_id': winners[i],
                            'player2_id': winners[i + 1],
                            'status': 'pending',
                            'player1_score': 0,
                            'player2_score': 0
                        }
                        next_matches.append(match_data)
                
                if next_matches:
                    print(f"📝 Creating {len(next_matches)} matches for Round {next_round_num}")
                    
                    # Insert matches
                    try:
                        result = supabase.table('matches').insert(next_matches).execute()
                        print(f"✅ Successfully created {len(result.data)} matches!")
                        
                        # Show created matches
                        for match in result.data:
                            print(f"  Created: Round {match['round_number']} Match {match['match_number']}")
                        
                    except Exception as e:
                        print(f"❌ Error creating matches: {e}")
                else:
                    print("❌ No matches to create")
                
                break
            else:
                print(f"⚠️ Round {next_round_num} already exists")
        elif all_complete and len(round_matches) == 1:
            print(f"🏆 Tournament completed at Round {round_num}!")
            break

if __name__ == "__main__":
    test_tournament_progression()
    
    # Ask user if they want to manually progress
    print("\n" + "="*50)
    response = input("Do you want to manually create the next round? (y/n): ")
    if response.lower() == 'y':
        manually_create_next_round()