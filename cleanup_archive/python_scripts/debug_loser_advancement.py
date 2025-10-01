#!/usr/bin/env python3
"""
Debug script to check loser advancement issues in Double Elimination bracket
"""

from supabase import create_client

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
TOURNAMENT_ID = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

def check_loser_advancement():
    print("=== LOSER ADVANCEMENT DEBUG ===")
    
    try:
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        print("✅ Connected to Supabase")
        
        # Get all completed WB Round 1 matches
        wb_round1 = supabase.table('matches').select('id, player1_id, player2_id, winner_id, status').eq('tournament_id', TOURNAMENT_ID).eq('round_number', 1).execute()
        
        print(f"\n📊 Winner Bracket Round 1: {len(wb_round1.data)} matches")
        
        completed_matches = [m for m in wb_round1.data if m['status'] == 'completed' and m['winner_id']]
        print(f"✅ Completed matches: {len(completed_matches)}")
        
        # For each completed match, identify the loser
        print("\n🔍 ANALYZING COMPLETED MATCHES:")
        expected_losers = []
        
        for i, match in enumerate(completed_matches):
            winner_id = match['winner_id']
            player1_id = match['player1_id'] 
            player2_id = match['player2_id']
            
            # Determine loser
            loser_id = player2_id if winner_id == player1_id else player1_id
            expected_losers.append(loser_id)
            
            print(f"  Match {i+1}: Winner={winner_id[:8] if winner_id else 'None'}, Loser={loser_id[:8] if loser_id else 'None'}")
        
        print(f"\n🎯 Expected {len(expected_losers)} losers to be in LB Round 101")
        
        # Check LB Round 101
        lb_round101 = supabase.table('matches').select('id, player1_id, player2_id, status').eq('tournament_id', TOURNAMENT_ID).eq('round_number', 101).execute()
        
        print(f"\n📊 Loser Bracket Round 101: {len(lb_round101.data)} matches")
        
        # Check which losers are actually placed
        placed_losers = []
        for i, match in enumerate(lb_round101.data):
            p1_id = match['player1_id']
            p2_id = match['player2_id']
            
            match_losers = []
            if p1_id:
                match_losers.append(p1_id)
                placed_losers.append(p1_id)
            if p2_id:
                match_losers.append(p2_id)
                placed_losers.append(p2_id)
                
            players_str = ', '.join([pid[:8] if pid else 'Empty' for pid in match_losers]) or 'Empty'
            print(f"  LB Match {i+1}: [{players_str}] Status={match['status']}")
        
        print(f"\n🎯 Analysis:")
        print(f"Expected losers: {len(expected_losers)}")
        print(f"Placed losers: {len(placed_losers)}")
        print(f"Missing losers: {len(expected_losers) - len(placed_losers)}")
        
        # Check for duplicates
        if len(placed_losers) != len(set(placed_losers)):
            print("❌ DUPLICATE LOSERS FOUND!")
            duplicates = [x for x in set(placed_losers) if placed_losers.count(x) > 1]
            print(f"Duplicated loser IDs: {[d[:8] for d in duplicates]}")
        
        # Check if expected losers are placed
        missing_losers = [l for l in expected_losers if l not in placed_losers]
        if missing_losers:
            print(f"❌ Missing losers: {[l[:8] for l in missing_losers]}")
        else:
            print("✅ All expected losers are placed")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_loser_advancement()