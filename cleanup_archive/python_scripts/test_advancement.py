import os
import psycopg2
from supabase import create_client, Client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def test_match_completion():
    print("=== TESTING ENHANCED LOSER ADVANCEMENT LOGIC ===")
    
    # Find tournament
    tournaments = supabase.table('tournaments').select('*').eq('format', 'double_elimination').limit(1).execute()
    if not tournaments.data:
        print("No DE tournament found")
        return
    
    tournament_id = tournaments.data[0]['id']
    print(f"Testing with tournament: {tournament_id}")
    
    # Find a completed WB Round 1 match to reset and re-complete
    wb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).eq('status', 'completed').limit(1).execute()
    
    if not wb_matches.data:
        print("No completed WB Round 1 matches found")
        return
    
    test_match = wb_matches.data[0]
    match_id = test_match['id']
    print(f"\nResetting match {match_id} to test advancement...")
    print(f"Player 1: {test_match['player1_id'][:8] if test_match['player1_id'] else 'None'}")
    print(f"Player 2: {test_match['player2_id'][:8] if test_match['player2_id'] else 'None'}")
    
    # Reset match to pending
    supabase.table('matches').update({
        'status': 'pending',
        'winner_id': None,
        'player1_score': 0,
        'player2_score': 0
    }).eq('id', match_id).execute()
    print("Match reset to pending")
    
    # Check current LB Round 101 state
    lb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()
    initial_filled = sum(1 for m in lb_matches.data if m.get('player1_id') or m.get('player2_id'))
    print(f"LB Round 101 before: {initial_filled}/4 matches have players")
    
    # Now complete the match (simulate user clicking in UI)
    winner_id = test_match['player1_id']  # Player 1 wins
    loser_id = test_match['player2_id']
    
    print(f"\nCompleting match: Winner {winner_id[:8]}, Loser {loser_id[:8]}")
    
    # Update match as completed
    supabase.table('matches').update({
        'status': 'completed',
        'winner_id': winner_id,
        'player1_score': 2,
        'player2_score': 1
    }).eq('id', match_id).execute()
    print("Match completed in database")
    
    # Check LB Round 101 after
    lb_matches_after = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()
    final_filled = sum(1 for m in lb_matches_after.data if m.get('player1_id') or m.get('player2_id'))
    print(f"LB Round 101 after: {final_filled}/4 matches have players")
    
    if final_filled > initial_filled:
        print("✅ SUCCESS: Loser was advanced!")
    else:
        print("❌ FAILURE: Loser was NOT advanced")
        
    # Show which matches have losers
    for match in lb_matches_after.data:
        if match.get('player1_id') or match.get('player2_id'):
            p1 = match.get('player1_id', '')[:8] if match.get('player1_id') else 'Empty'
            p2 = match.get('player2_id', '')[:8] if match.get('player2_id') else 'Empty'
            print(f"  LB Match {match['match_number']}: {p1} vs {p2}")

if __name__ == "__main__":
    test_match_completion()