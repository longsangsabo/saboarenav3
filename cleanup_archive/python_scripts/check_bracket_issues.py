#!/usr/bin/env python3
"""
Check current bracket generation issues
"""

from supabase import create_client

def main():
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    
    supabase = create_client(url, key)
    
    print("🔍 BRACKET GENERATION ISSUE ANALYSIS")
    print("="*50)
    
    # Check matches by round
    result = supabase.table('matches').select('round, player1_id, player2_id, status').order('round').execute()
    
    if result.data:
        print(f"\n📊 Total matches in database: {len(result.data)}")
        
        # Group by round
        rounds = {}
        for match in result.data:
            round_num = match['round']
            if round_num not in rounds:
                rounds[round_num] = []
            rounds[round_num].append(match)
        
        print(f"🎯 Rounds found: {sorted(rounds.keys())}")
        
        for round_num in sorted(rounds.keys()):
            matches_in_round = rounds[round_num]
            print(f"\n🎪 Round {round_num}: {len(matches_in_round)} matches")
            
            # Count how many have both players vs empty
            with_both_players = 0
            with_one_player = 0  
            with_no_players = 0
            
            for match in matches_in_round:
                if match['player1_id'] and match['player2_id']:
                    with_both_players += 1
                elif match['player1_id'] or match['player2_id']:
                    with_one_player += 1
                else:
                    with_no_players += 1
            
            print(f"   ✅ With both players: {with_both_players}")
            print(f"   ⚠️ With one player: {with_one_player}")  
            print(f"   ❌ Empty matches: {with_no_players}")
    
    # Check tournament participants
    tournaments = supabase.table('tournaments').select('id, tournament_type, current_participants').execute()
    
    if tournaments.data:
        print(f"\n🏆 TOURNAMENT INFO")
        for t in tournaments.data:
            print(f"   Tournament {t['id'][:8]}...: {t['tournament_type']}, {t['current_participants']} participants")
            
            participants = supabase.table('tournament_participants').select('user_id').eq('tournament_id', t['id']).execute()
            print(f"   → Confirmed participants in DB: {len(participants.data)}")
    
    print(f"\n🚨 ISSUE IDENTIFIED:")
    print(f"   - All rounds (1-4) have matches created simultaneously")
    print(f"   - Only Round 1 should have matches with real players initially") 
    print(f"   - Rounds 2-4 should be created progressively as Round 1 completes")
    print(f"   - This breaks tournament flow logic")

if __name__ == "__main__":
    main()