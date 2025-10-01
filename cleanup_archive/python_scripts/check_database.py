#!/usr/bin/env python3
"""
Script to check Supabase database connection and Loser Bracket matches
"""

from supabase import create_client
import sys

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
TOURNAMENT_ID = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'

def main():
    print("=== SUPABASE CONNECTION TEST ===")
    
    try:
        # Initialize Supabase client
        supabase = create_client(SUPABASE_URL, SERVICE_KEY)
        print("✅ Supabase client initialized successfully")
        
        # Test connection by counting tournaments
        tournaments = supabase.table('tournaments').select('id').limit(1).execute()
        print(f"✅ Database connection successful - found {len(tournaments.data)} tournament(s)")
        
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)
    
    print("\n=== CHECKING LOSER BRACKET MATCHES ===")
    
    try:
        # Check LB Round 101 matches
        lb_matches = supabase.table('matches').select('id, player1_id, player2_id, status').eq('tournament_id', TOURNAMENT_ID).eq('round_number', 101).execute()
        
        if not lb_matches.data:
            print("❌ No LB Round 101 matches found")
            return
            
        print(f"📊 Found {len(lb_matches.data)} LB Round 101 matches")
        
        # Count matches with players
        matches_with_players = 0
        for i, match in enumerate(lb_matches.data):
            has_p1 = match['player1_id'] is not None
            has_p2 = match['player2_id'] is not None
            
            if has_p1 or has_p2:
                matches_with_players += 1
                
            print(f"  Match {i+1}: P1={'✅' if has_p1 else '❌'} P2={'✅' if has_p2 else '❌'} Status={match['status']}")
        
        print(f"\n📈 Summary: {matches_with_players}/{len(lb_matches.data)} matches have players assigned")
        
        if matches_with_players == 0:
            print("❌ ISSUE: No players assigned to Loser Bracket matches!")
        else:
            print("✅ Some players are assigned to Loser Bracket")
            
    except Exception as e:
        print(f"❌ Error checking matches: {e}")
    
    print("\n=== CHECKING WINNER BRACKET FOR COMPARISON ===")
    
    try:
        # Check WB Round 1 matches
        wb_matches = supabase.table('matches').select('id, player1_id, player2_id, status').eq('tournament_id', TOURNAMENT_ID).eq('round_number', 1).execute()
        
        if wb_matches.data:
            print(f"📊 Found {len(wb_matches.data)} WB Round 1 matches")
            
            matches_with_players = 0
            for i, match in enumerate(wb_matches.data[:3]):  # Show first 3
                has_p1 = match['player1_id'] is not None
                has_p2 = match['player2_id'] is not None
                
                if has_p1 or has_p2:
                    matches_with_players += 1
                    
                print(f"  Match {i+1}: P1={'✅' if has_p1 else '❌'} P2={'✅' if has_p2 else '❌'} Status={match['status']}")
            
            if len(wb_matches.data) > 3:
                print(f"  ... and {len(wb_matches.data) - 3} more matches")
                
        else:
            print("❌ No WB Round 1 matches found")
            
    except Exception as e:
        print(f"❌ Error checking WB matches: {e}")

if __name__ == "__main__":
    main()