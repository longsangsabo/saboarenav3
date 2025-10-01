#!/usr/bin/env python3
"""
🎯 SABO ARENA - Tournament Progression Checker
Check why automatic match creation is not working
"""

from supabase import create_client

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def check_tournament_progression():
    print("🔍 TOURNAMENT PROGRESSION ANALYSIS")
    print("=" * 60)
    
    supabase = create_client(SUPABASE_URL, ANON_KEY)
    
    # Use specific tournament ID that has progression issues
    tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'
    print(f"📊 Analyzing tournament: {tournament_id}")
    
    # Get all matches for this tournament
    matches_result = supabase.table('matches').select(
        'round_number, match_number, player1_id, player2_id, winner_id, status'
    ).eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
    
    # Group by rounds
    rounds_data = {}
    for match in matches_result.data:
        round_num = match['round_number']
        if round_num not in rounds_data:
            rounds_data[round_num] = []
        rounds_data[round_num].append(match)
    
    print(f"\n📋 Tournament Structure:")
    print("-" * 40)
    
    progression_issues = []
    
    for round_num in sorted(rounds_data.keys()):
        matches = rounds_data[round_num]
        completed_matches = [m for m in matches if m['winner_id']]
        total_matches = len(matches)
        completed_count = len(completed_matches)
        
        print(f"\n🔸 Round {round_num}: {completed_count}/{total_matches} matches completed")
        
        # Check if round is complete
        round_complete = completed_count == total_matches
        next_round_exists = (round_num + 1) in rounds_data
        
        if round_complete and not next_round_exists:
            progression_issues.append({
                'round': round_num,
                'issue': 'Round complete but next round not created',
                'completed_matches': completed_matches
            })
            print(f"   ⚠️ ISSUE: Round {round_num} complete but Round {round_num + 1} missing!")
        
        # Show individual matches
        for i, match in enumerate(matches):
            status = "✅ WINNER" if match['winner_id'] else "⏳ NO WINNER"
            player1 = match['player1_id'][:8] if match['player1_id'] else 'TBD'
            player2 = match['player2_id'][:8] if match['player2_id'] else 'TBD'
            match_name = f"R{round_num}M{match['match_number']}"
            print(f"     {match_name}: {player1} vs {player2} -> {status}")
        
        # Check for partial completion that should trigger next round creation
        if round_num == 1 and completed_count >= 2:  # For example, R1M1 and R1M2 complete
            pairs_ready = completed_count // 2
            if pairs_ready > 0:
                next_round_should_have = pairs_ready
                if next_round_exists:
                    next_round_matches = len(rounds_data[round_num + 1])
                    if next_round_matches < next_round_should_have:
                        print(f"   ⚠️ Partial progression issue: {pairs_ready} next round matches should exist but only {next_round_matches} found")
                else:
                    print(f"   ⚠️ Partial progression issue: {pairs_ready} next round matches should be created")
    
    # Analyze progression issues
    print(f"\n🚨 PROGRESSION ISSUES FOUND:")
    print("-" * 40)
    
    if progression_issues:
        for issue in progression_issues:
            print(f"❌ Round {issue['round']}: {issue['issue']}")
            print(f"   Winners available for next round:")
            for match in issue['completed_matches']:
                winner_id = match['winner_id'][:8] if match['winner_id'] else 'None'
                print(f"     - Match {match['match_number']}: Winner {winner_id}")
    else:
        print("✅ No progression issues found - system working correctly")
    
    # Check for triggers and functions
    print(f"\n🔧 CHECKING DATABASE TRIGGERS:")
    print("-" * 40)
    
    # This would require checking actual database triggers
    print("❓ Need to check if match update triggers exist for automatic progression")
    print("❓ Need to verify trigger logic for creating next round matches")
    
    return progression_issues

def suggest_fixes():
    print(f"\n💡 SUGGESTED FIXES:")
    print("-" * 40)
    print("1. Create database trigger on matches table UPDATE")
    print("2. Trigger should fire when winner_id is set")
    print("3. Check if all matches in round are complete")
    print("4. If complete, automatically create next round matches")
    print("5. Use tournament format factory to determine bracket structure")

if __name__ == "__main__":
    issues = check_tournament_progression()
    suggest_fixes()
    
    if issues:
        print(f"\n🚀 Next Action: Fix automatic tournament progression system")
    else:
        print(f"\n✅ Tournament progression system appears to be working correctly")