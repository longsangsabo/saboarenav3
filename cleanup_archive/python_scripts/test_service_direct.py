"""
Test MatchProgressionService directly by simulating the exact call pattern from Flutter UI
"""
import requests
import json
from supabase import create_client

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

# Initialize Supabase client
supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def test_manual_loser_advancement():
    """
    Manually test the loser advancement logic by:
    1. Identify all completed WB Round 1 matches
    2. For each completed match, manually place the loser in LB Round 101
    3. Verify all 7 losers are properly placed
    """
    print("=== MANUAL LOSER ADVANCEMENT TEST ===")
    
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # Get all completed WB Round 1 matches
    wb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).eq('status', 'completed').execute()
    
    print(f"Found {len(wb_matches.data)} completed WB Round 1 matches")
    
    # Get all LB Round 101 matches
    lb_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()
    lb_matches_data = lb_matches.data
    
    print(f"Found {len(lb_matches_data)} LB Round 101 matches")
    
    # For each completed WB match, determine loser and place in LB
    for i, wb_match in enumerate(wb_matches.data):
        winner_id = wb_match['winner_id']
        player1_id = wb_match['player1_id']
        player2_id = wb_match['player2_id']
        
        # Calculate loser
        loser_id = player2_id if winner_id == player1_id else player1_id
        
        print(f"\nWB Match {i+1}: Winner={winner_id[:8]}, Loser={loser_id[:8]}")
        
        # Find best LB match to place loser
        best_lb_match = None
        for lb_match in lb_matches_data:
            # Prefer empty matches first
            if not lb_match.get('player1_id') and not lb_match.get('player2_id'):
                best_lb_match = lb_match
                break
            # Then matches with only one player
            elif not lb_match.get('player1_id') or not lb_match.get('player2_id'):
                best_lb_match = lb_match
                break
        
        if best_lb_match:
            # Place loser in best available slot
            if not best_lb_match.get('player1_id'):
                update_field = 'player1_id'
            else:
                update_field = 'player2_id'
            
            # Update LB match
            supabase.table('matches').update({
                update_field: loser_id
            }).eq('id', best_lb_match['id']).execute()
            
            print(f"  → Placed loser {loser_id[:8]} in LB Match {best_lb_match['match_number']} as {update_field}")
            
            # Update local data
            best_lb_match[update_field] = loser_id
        else:
            print(f"  ❌ No available LB match for loser {loser_id[:8]}")
    
    # Final verification
    print("\n=== FINAL VERIFICATION ===")
    lb_final = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).execute()
    
    total_players = 0
    for lb_match in lb_final.data:
        p1 = lb_match.get('player1_id')
        p2 = lb_match.get('player2_id')
        match_players = sum([1 for p in [p1, p2] if p])
        total_players += match_players
        
        print(f"LB Match {lb_match['match_number']}: P1={p1[:8] if p1 else 'Empty'}, P2={p2[:8] if p2 else 'Empty'}")
    
    print(f"\nTOTAL: {total_players}/7 losers placed in LB Round 101")
    
    if total_players == 7:
        print("✅ SUCCESS: All losers properly advanced!")
    else:
        print(f"❌ FAILURE: Missing {7 - total_players} losers")

if __name__ == "__main__":
    test_manual_loser_advancement()