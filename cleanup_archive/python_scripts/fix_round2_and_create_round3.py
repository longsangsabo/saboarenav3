#!/usr/bin/env python3
"""
Fix Round 2 winner_ids and test automatic Round 3 creation
"""

from supabase import create_client
import uuid

def main():
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    supabase = create_client(url, key)

    tournament_id = '509b243f-1d15-46ae-b02b-aec4039b3c94'
    
    print("Step 1: Fix Round 2 winner_ids...")
    
    # Get Round 2 matches
    result = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 2).execute()
    
    round2_winners = []
    
    for match in result.data:
        if match['status'] == 'completed' and not match.get('winner_id'):
            p1_score = match.get('player1_score', 0) or 0
            p2_score = match.get('player2_score', 0) or 0
            
            if p1_score > p2_score:
                winner_id = match['player1_id']
            elif p2_score > p1_score:
                winner_id = match['player2_id']
            else:
                print(f"  R2M{match.get('match_number', '?')}: Tie, no winner")
                continue
                
            # Update winner_id
            supabase.table('matches').update({'winner_id': winner_id}).eq('id', match['id']).execute()
            match_num = match.get('match_number', '?')
            player_num = '1' if winner_id == match['player1_id'] else '2'
            print(f"  R2M{match_num}: Winner set to player {player_num}")
            
            round2_winners.append(winner_id)
    
    print(f"Fixed {len(round2_winners)} Round 2 matches")
    
    # Step 2: Check if we need Round 3
    if len(round2_winners) >= 2:
        print(f"\\nStep 2: Creating Round 3 with {len(round2_winners)} winners...")
        
        # Check if Round 3 already exists
        round3_check = supabase.table('matches').select('id').eq('tournament_id', tournament_id).eq('round_number', 3).execute()
        
        if round3_check.data:
            print(f"Round 3 already exists with {len(round3_check.data)} matches")
            return
            
        # Create Round 3 matches
        round3_matches = []
        for i in range(0, len(round2_winners), 2):
            if i + 1 < len(round2_winners):
                match_data = {
                    'id': str(uuid.uuid4()),
                    'tournament_id': tournament_id,
                    'round_number': 3,
                    'match_number': (i // 2) + 1,
                    'player1_id': round2_winners[i],
                    'player2_id': round2_winners[i + 1],
                    'status': 'pending',
                    'player1_score': 0,
                    'player2_score': 0,
                    'winner_id': None
                }
                round3_matches.append(match_data)
        
        if round3_matches:
            supabase.table('matches').insert(round3_matches).execute()
            print(f"Created {len(round3_matches)} Round 3 matches")
            
            for i, match in enumerate(round3_matches):
                print(f"  R3M{i+1}: {match['player1_id'][:8]} vs {match['player2_id'][:8]}")
        else:
            print("No Round 3 matches to create")
    else:
        print(f"Not enough winners ({len(round2_winners)}) for Round 3")

if __name__ == "__main__":
    main()