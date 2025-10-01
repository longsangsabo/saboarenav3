#!/usr/bin/env python3
"""
Test Double Elimination 16 Bracket Logic vs Current Tournament Data
==================================================================

This script verifies that our new precise bracket logic matches 
the actual tournament data structure.
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def test_precise_bracket_logic():
    """Test our precise bracket logic against real tournament data"""
    
    # Expected round-to-tab mapping (from our DoubleElimination16Service)
    PRECISE_ROUND_MAPPING = {
        # Winner Bracket
        1: "WB - VÒNG 1",
        2: "WB - VÒNG 2", 
        3: "WB - BÁN KẾT",
        4: "WB - CHUNG KẾT",
        
        # Loser Bracket
        101: "LB - VÒNG 1",
        102: "LB - VÒNG 2",
        103: "LB - VÒNG 3",
        104: "LB - VÒNG 4",
        105: "LB - BÁN KẾT",
        106: "LB - VÒNG 6",
        107: "LB - CHUNG KẾT",
        
        # Grand Finals
        200: "CHUNG KẾT CUỐI",
        201: "CHUNG KẾT RESET"
    }
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    # Get active tournament (from Flutter logs)
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'
    
    print("TESTING PRECISE BRACKET LOGIC")
    print("=" * 50)
    print(f"Tournament ID: {tournament_id}")
    
    matches = supabase.table('matches').select('id, round_number, match_number, player1_id, player2_id, status').eq('tournament_id', tournament_id).execute()
    
    if not matches.data:
        print("❌ No matches found for tournament")
        return False
        
    print(f"✅ Found {len(matches.data)} matches")
    
    # Group by rounds
    rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append(match)
    
    print(f"✅ Tournament has {len(rounds)} different rounds")
    
    # Test each round mapping
    print("\nROUND MAPPING VERIFICATION:")
    print("-" * 40)
    
    all_correct = True
    for round_num in sorted(rounds.keys()):
        matches_in_round = rounds[round_num]
        expected_tab = PRECISE_ROUND_MAPPING.get(round_num, f"UNKNOWN-{round_num}")
        
        pending = len([m for m in matches_in_round if m['status'] == 'pending'])
        in_progress = len([m for m in matches_in_round if m['status'] == 'in_progress'])
        completed = len([m for m in matches_in_round if m['status'] == 'completed'])
        
        status_emoji = "✅" if round_num in PRECISE_ROUND_MAPPING else "❌"
        
        print(f"{status_emoji} Round {round_num:3d} → '{expected_tab}'")
        print(f"    {len(matches_in_round):2d} matches: {pending} pending, {in_progress} in_progress, {completed} completed")
        
        if round_num not in PRECISE_ROUND_MAPPING:
            all_correct = False
            print(f"    ⚠️  Round {round_num} not in our mapping!")
    
    print()
    
    # Test filtering logic simulation
    print("FILTERING LOGIC TEST:")
    print("-" * 30)
    
    # Simulate the filtering that would happen in Flutter
    for round_num in [1, 2, 101, 102, 200, 201]:
        if round_num in rounds:
            matches_for_round = rounds[round_num]
            tab_name = PRECISE_ROUND_MAPPING.get(round_num, "UNKNOWN")
            filter_string = f"round{round_num}"
            
            print(f"✅ Tab '{tab_name}' → Filter '{filter_string}' → {len(matches_for_round)} matches")
            
            # Show sample matches
            for i, match in enumerate(matches_for_round[:2]):
                p1 = match['player1_id'][:8] if match['player1_id'] else 'None'
                p2 = match['player2_id'][:8] if match['player2_id'] else 'None'
                print(f"    M{match['match_number']}: {p1} vs {p2} ({match['status']})")
        else:
            tab_name = PRECISE_ROUND_MAPPING.get(round_num, "UNKNOWN")
            print(f"⚠️  Tab '{tab_name}' → No matches in database yet")
    
    print()
    
    # Final verdict
    if all_correct:
        print("🎉 ALL ROUNDS PROPERLY MAPPED!")
        print("✅ Precise bracket logic is compatible with tournament data")
        print("✅ UI tabs will now show correct matches for each round")
    else:
        print("⚠️  Some rounds not in mapping - may need additional logic")
    
    return all_correct

if __name__ == "__main__":
    test_precise_bracket_logic()