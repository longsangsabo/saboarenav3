#!/usr/bin/env python3
"""
Simple debug script for loser advancement analysis
"""

from supabase import create_client

# Configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
TOURNAMENT_ID = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

def main():
    print("=== LOSER ADVANCEMENT ANALYSIS ===")
    
    try:
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        print("OK - Connected to Supabase")
        
        # Check completed WB Round 1 matches
        wb_matches = supabase.table('matches').select('id, player1_id, player2_id, winner_id, status').eq('tournament_id', TOURNAMENT_ID).eq('round_number', 1).execute()
        
        completed = [m for m in wb_matches.data if m['status'] == 'completed']
        print(f"WB Round 1: {len(completed)} completed matches out of {len(wb_matches.data)} total")
        
        # Expected losers
        expected_losers = []
        for match in completed:
            winner = match['winner_id']
            player1 = match['player1_id']
            player2 = match['player2_id']
            loser = player2 if winner == player1 else player1
            expected_losers.append(loser)
            print(f"  Match: Winner={winner[:8]}, Loser={loser[:8]}")
        
        print(f"Expected {len(expected_losers)} losers in LB Round 101")
        
        # Check LB Round 101
        lb_matches = supabase.table('matches').select('id, player1_id, player2_id, status').eq('tournament_id', TOURNAMENT_ID).eq('round_number', 101).execute()
        
        print(f"LB Round 101: {len(lb_matches.data)} matches")
        placed_count = 0
        for i, match in enumerate(lb_matches.data):
            p1 = match['player1_id']
            p2 = match['player2_id']
            if p1 or p2:
                placed_count += 1
                p1_short = p1[:8] if p1 else 'None'
                p2_short = p2[:8] if p2 else 'None'
                print(f"  LB Match {i+1}: P1={p1_short}, P2={p2_short}")
            else:
                print(f"  LB Match {i+1}: Empty")
        
        print(f"RESULT: {placed_count} losers placed, {len(expected_losers) - placed_count} missing")
        
        if placed_count < len(expected_losers):
            print("ISSUE: Not all losers were advanced to Loser Bracket!")
        else:
            print("OK: All losers successfully advanced")
            
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    main()