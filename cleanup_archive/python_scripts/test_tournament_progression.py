#!/usr/bin/env python3
"""
Test automatic tournament progression by simulating score entry
"""

from supabase import create_client

def main():
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    supabase = create_client(url, key)

    tournament_id = '509b243f-1d15-46ae-b02b-aec4039b3c94'
    
    # Get Round 2 matches
    result = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 2).eq('status', 'completed').execute()
    
    print(f"Found {len(result.data)} completed Round 2 matches")
    
    if len(result.data) >= 2:
        print("Round 2 has completed matches - checking for Round 3...")
        
        # Check if Round 3 exists
        round3_result = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 3).execute()
        
        if round3_result.data:
            print(f"✅ Round 3 already exists with {len(round3_result.data)} matches")
            for match in round3_result.data:
                print(f"  R3M{match.get('match_number', '?')}: {match['status']}")
        else:
            print("❌ Round 3 does NOT exist - automatic progression failed")
            
            # Get Round 2 winners to manually create Round 3
            round2_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 2).execute()
            
            print("\nRound 2 status:")
            for match in round2_matches.data:
                status = match['status']
                winner = '✓' if match.get('winner_id') else '✗'
                print(f"  R2M{match.get('match_number', '?')}: {status} | Winner: {winner}")
    
    else:
        print("Round 2 not completed yet - need to complete matches first")

if __name__ == "__main__":
    main()