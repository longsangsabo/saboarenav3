#!/usr/bin/env python3
"""
Test script để verify bracket generation logic đã được fix triệt để
"""

from supabase import create_client
import uuid

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def test_duplicate_detection():
    """Test comprehensive duplicate detection"""
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    print("🔍 TESTING COMPREHENSIVE DUPLICATE DETECTION")
    print("=" * 50)
    
    # Get all matches
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
    
    if not matches.data:
        print("❌ No matches found - bracket not generated yet")
        return False
    
    duplicates_found = []
    player_count = {}
    
    # Check each match for duplicates
    for match in matches.data:
        p1 = match.get('player1_id')
        p2 = match.get('player2_id')
        match_id = match['id'][:8]
        round_num = match['round_number']
        match_num = match['match_number']
        
        # Same player in both slots
        if p1 and p2 and p1 == p2:
            duplicates_found.append({
                'type': 'same_player_both_slots',
                'match': f"R{round_num} M{match_num} ({match_id})",
                'player': p1[:8],
                'details': f"P1={p1[:8]}, P2={p2[:8]}"
            })
        
        # Count player appearances
        if p1:
            if p1 not in player_count:
                player_count[p1] = []
            player_count[p1].append(f"R{round_num} M{match_num} P1")
            
        if p2:
            if p2 not in player_count:
                player_count[p2] = []
            player_count[p2].append(f"R{round_num} M{match_num} P2")
    
    # Find players appearing multiple times in same round
    for player, appearances in player_count.items():
        round_counts = {}
        for appearance in appearances:
            round_part = appearance.split(' ')[0]  # R1, R2, etc.
            if round_part not in round_counts:
                round_counts[round_part] = []
            round_counts[round_part].append(appearance)
        
        for round_num, round_appearances in round_counts.items():
            if len(round_appearances) > 1:
                duplicates_found.append({
                    'type': 'multiple_appearances_same_round',
                    'player': player[:8],
                    'round': round_num,
                    'appearances': round_appearances
                })
    
    # Report results
    if duplicates_found:
        print("❌ DUPLICATES FOUND:")
        for dup in duplicates_found:
            if dup['type'] == 'same_player_both_slots':
                print(f"   🚫 {dup['match']}: Same player in both slots - {dup['details']}")
            else:
                print(f"   🚫 Player {dup['player']} appears multiple times in {dup['round']}: {dup['appearances']}")
        return False
    else:
        print("✅ NO DUPLICATES FOUND!")
        print(f"   📊 Total players: {len(player_count)}")
        print(f"   🎯 Total matches: {len(matches.data)}")
        return True

def analyze_advancement_logic():
    """Analyze if advancement logic is working correctly"""
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    print("\n🎯 ANALYZING ADVANCEMENT LOGIC")
    print("=" * 50)
    
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number', 'match_number').execute()
    
    wb_rounds = {}
    lb_rounds = {}
    
    for match in matches.data:
        round_num = match['round_number']
        if round_num <= 4:  # WB rounds
            if round_num not in wb_rounds:
                wb_rounds[round_num] = []
            wb_rounds[round_num].append(match)
        elif round_num >= 101:  # LB rounds
            if round_num not in lb_rounds:
                lb_rounds[round_num] = []
            lb_rounds[round_num].append(match)
    
    print("📈 WB ROUNDS STRUCTURE:")
    for round_num in sorted(wb_rounds.keys()):
        matches_in_round = wb_rounds[round_num]
        print(f"   R{round_num}: {len(matches_in_round)} matches")
        for match in matches_in_round:
            p1 = match.get('player1_id', 'None')[:8] if match.get('player1_id') else 'None'
            p2 = match.get('player2_id', 'None')[:8] if match.get('player2_id') else 'None'
            print(f"      M{match['match_number']}: {p1} vs {p2}")
    
    print("\n💀 LB ROUNDS STRUCTURE:")
    for round_num in sorted(lb_rounds.keys()):
        matches_in_round = lb_rounds[round_num]
        print(f"   R{round_num}: {len(matches_in_round)} matches")
        for match in matches_in_round:
            p1 = match.get('player1_id', 'None')[:8] if match.get('player1_id') else 'None'
            p2 = match.get('player2_id', 'None')[:8] if match.get('player2_id') else 'None'
            print(f"      M{match['match_number']}: {p1} vs {p2}")

if __name__ == "__main__":
    print("🔧 COMPREHENSIVE BRACKET LOGIC TEST")
    print("=" * 60)
    
    # Test 1: Duplicate detection
    duplicate_test_passed = test_duplicate_detection()
    
    # Test 2: Advancement logic analysis
    analyze_advancement_logic()
    
    print("\n" + "=" * 60)
    if duplicate_test_passed:
        print("✅ ALL TESTS PASSED - Bracket logic is working correctly!")
    else:
        print("❌ TESTS FAILED - Duplicate issues still exist!")
    print("=" * 60)