#!/usr/bin/env python3
"""
Fix winner IDs for completed matches and create next round matches
"""

from supabase import create_client
import uuid

def main():
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    supabase = create_client(url, key)

    # Step 1: Fix winner_ids for completed matches
    print("Step 1: Fixing winner IDs...")
    result = supabase.table('matches').select('id, player1_score, player2_score, winner_id, player1_id, player2_id, status').execute()

    fixed_count = 0
    round_1_winners = []
    
    for match in result.data:
        if match['status'] == 'completed' and not match['winner_id']:
            p1_score = match.get('player1_score', 0) or 0
            p2_score = match.get('player2_score', 0) or 0
            
            if p1_score > p2_score:
                winner_id = match['player1_id']
            elif p2_score > p1_score:
                winner_id = match['player2_id']
            else:
                winner_id = None  # Tie
                
            if winner_id:
                # Update the winner_id
                update_result = supabase.table('matches').update({'winner_id': winner_id}).eq('id', match['id']).execute()
                match_short = match['id'][:8]
                player_num = '1' if winner_id == match['player1_id'] else '2'
                print(f'  Fixed match {match_short}: Winner set to player {player_num}')
                fixed_count += 1
                
                # Collect round 1 winners
                round_1_winners.append(winner_id)
            else:
                print(f'  Match {match["id"][:8]}: Tie, no winner')

    print(f"Fixed {fixed_count} matches")
    
    # Step 2: Create Round 2 matches if we have enough winners
    if len(round_1_winners) >= 4:
        print(f"\nStep 2: Creating Round 2 matches with {len(round_1_winners)} winners...")
        
        # Check if Round 2 already exists
        round_2_check = supabase.table('matches').select('id').eq('round_number', 2).execute()
        if len(round_2_check.data) > 0:
            print(f"Round 2 already exists with {len(round_2_check.data)} matches")
            return
        
        # Create Round 2 matches (pair up winners)
        round_2_matches = []
        for i in range(0, len(round_1_winners), 2):
            if i + 1 < len(round_1_winners):
                match_id = str(uuid.uuid4())
                match_data = {
                    'id': match_id,
                    'tournament_id': '509b243f-1d15-46ae-b02b-aec4039b3c94',  # Use the tournament ID
                    'round_number': 2,
                    'match_number': (i // 2) + 1,
                    'player1_id': round_1_winners[i],
                    'player2_id': round_1_winners[i + 1],
                    'status': 'pending',
                    'player1_score': 0,
                    'player2_score': 0,
                    'winner_id': None
                }
                round_2_matches.append(match_data)
        
        if round_2_matches:
            # Insert Round 2 matches
            insert_result = supabase.table('matches').insert(round_2_matches).execute()
            print(f"Created {len(round_2_matches)} Round 2 matches")
            
            for i, match in enumerate(round_2_matches):
                print(f"  R2M{i+1}: {match['player1_id'][:8]} vs {match['player2_id'][:8]}")
        else:
            print("No Round 2 matches to create")
    else:
        print(f"Not enough winners ({len(round_1_winners)}) to create Round 2")

if __name__ == "__main__":
    main()