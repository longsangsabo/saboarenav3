"""
FINAL TEST: Complete a match via database and verify immediate loser advancement
This simulates the UI completion by calling the exact same database updates
"""
from supabase import create_client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def final_test():
    print("=== FINAL IMMEDIATE ADVANCEMENT TEST ===")
    
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Check current state
    print("\n1. CURRENT STATE CHECK:")
    wb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).execute()
    completed_count = sum(1 for m in wb_matches.data if m['status'] == 'completed')
    pending_count = sum(1 for m in wb_matches.data if m['status'] == 'pending')
    
    print(f"   WB Round 1: {completed_count} completed, {pending_count} pending")
    
    lb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()
    lb_filled = sum(1 for m in lb_matches.data if m.get('player1_id') or m.get('player2_id'))
    
    print(f"   LB Round 101: {lb_filled} slots filled")
    
    # Find pending match to complete
    pending_match = None
    for match in wb_matches.data:
        if match['status'] == 'pending':
            pending_match = match
            break
    
    if not pending_match:
        print("❌ No pending match found to test!")
        return
    
    print(f"\n2. COMPLETING MATCH: {pending_match['id'][:8]}")
    print(f"   Player 1: {pending_match['player1_id'][:8]}")
    print(f"   Player 2: {pending_match['player2_id'][:8]}")
    
    # Complete the match (simulate UI action)
    winner_id = pending_match['player1_id']  # P1 wins
    loser_id = pending_match['player2_id']   # P2 loses
    
    supabase.table('matches').update({
        'status': 'completed',
        'winner_id': winner_id,
        'player1_score': 2,
        'player2_score': 1
    }).eq('id', pending_match['id']).execute()
    
    print(f"   ✅ Match completed: Winner={winner_id[:8]}, Loser={loser_id[:8]}")
    
    # CHECK IMMEDIATE RESULTS (what the MatchProgressionService should do)
    print("\n3. CHECKING RESULTS:")
    
    # Check if winner advanced to WB Round 2
    wb2_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 2).execute()
    winner_advanced = False
    for match in wb2_matches.data:
        if match.get('player1_id') == winner_id or match.get('player2_id') == winner_id:
            winner_advanced = True
            print(f"   ✅ Winner {winner_id[:8]} advanced to WB Round 2")
            break
    
    if not winner_advanced:
        print(f"   ❌ Winner {winner_id[:8]} NOT advanced to WB Round 2")
    
    # Check if loser advanced to LB Round 101 
    lb_matches_after = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()
    loser_advanced = False
    for match in lb_matches_after.data:
        if match.get('player1_id') == loser_id or match.get('player2_id') == loser_id:
            loser_advanced = True
            print(f"   ✅ Loser {loser_id[:8]} advanced to LB Round 101")
            break
    
    if not loser_advanced:
        print(f"   ❌ Loser {loser_id[:8]} NOT advanced to LB Round 101")
    
    # Final summary
    print("\n4. FINAL RESULT:")
    if winner_advanced and loser_advanced:
        print("✅ SUCCESS: IMMEDIATE ADVANCEMENT WORKING!")
        print("   Both winner and loser advanced immediately after match completion")
    else:
        print("❌ FAILURE: Immediate advancement not working")
        print("   MatchProgressionService logic needs more debugging")
        
        # Show detailed LB state for debugging
        print("\n   LB Round 101 detailed state:")
        for i, match in enumerate(lb_matches_after.data):
            p1 = match.get('player1_id')
            p2 = match.get('player2_id')
            print(f"     Match {match['match_number']}: P1={p1[:8] if p1 else 'Empty'}, P2={p2[:8] if p2 else 'Empty'}")

if __name__ == "__main__":
    final_test()