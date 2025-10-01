#!/usr/bin/env python3
"""
Tournament Auto-Fill System
Tự động fill winners từ round trước vào round tiếp theo cho SABO tournaments
"""

from supabase import create_client
import sys

def connect_supabase():
    """Connect to Supabase"""
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    return create_client(url, key)

def get_progression_map(tournament_format):
    """
    Get progression map based on tournament format
    """
    
    if tournament_format == "SE16":
        # Single Elimination 16-player (31 matches total)
        return {
            'R2M1': ['R1M1', 'R1M2'],   # Winners from R1M1 vs R1M2
            'R2M2': ['R1M3', 'R1M4'],   # Winners from R1M3 vs R1M4
            'R2M3': ['R1M5', 'R1M6'],   # Winners from R1M5 vs R1M6
            'R2M4': ['R1M7', 'R1M8'],   # Winners from R1M7 vs R1M8
            'R2M5': ['R1M9', 'R1M10'],  # Winners from R1M9 vs R1M10
            'R2M6': ['R1M11', 'R1M12'], # Winners from R1M11 vs R1M12
            'R2M7': ['R1M13', 'R1M14'], # Winners from R1M13 vs R1M14
            'R2M8': ['R1M15', 'R1M16'], # Winners from R1M15 vs R1M16
            
            'R3M1': ['R2M1', 'R2M2'],   # Winners from R2M1 vs R2M2
            'R3M2': ['R2M3', 'R2M4'],   # Winners from R2M3 vs R2M4
            'R3M3': ['R2M5', 'R2M6'],   # Winners from R2M5 vs R2M6
            'R3M4': ['R2M7', 'R2M8'],   # Winners from R2M7 vs R2M8
            
            'R4M1': ['R3M1', 'R3M2'],   # Winners from R3M1 vs R3M2
            'R4M2': ['R3M3', 'R3M4'],   # Winners from R3M3 vs R3M4
            
            'R5M1': ['R4M1', 'R4M2'],   # Winners from R4M1 vs R4M2 (Final)
        }
    
    elif tournament_format == "SE8":
        # Single Elimination 8-player (15 matches total)
        return {
            'R2M1': ['R1M1', 'R1M2'],   # Winners from R1M1 vs R1M2
            'R2M2': ['R1M3', 'R1M4'],   # Winners from R1M3 vs R1M4
            'R2M3': ['R1M5', 'R1M6'],   # Winners from R1M5 vs R1M6
            'R2M4': ['R1M7', 'R1M8'],   # Winners from R1M7 vs R1M8
            
            'R3M1': ['R2M1', 'R2M2'],   # Winners from R2M1 vs R2M2
            'R3M2': ['R2M3', 'R2M4'],   # Winners from R2M3 vs R2M4
            
            'R4M1': ['R3M1', 'R3M2'],   # Winners from R3M1 vs R3M2 (Final)
        }
    
    elif tournament_format == "DE16":
        # SABO DE16 Progression Map (27 matches total)
        return {
            # Winners Bracket
            'R2M1': ['R1M1', 'R1M2'],   # Winners from R1M1 vs R1M2
            'R2M2': ['R1M3', 'R1M4'],   # Winners from R1M3 vs R1M4
            'R2M3': ['R1M5', 'R1M6'],   # Winners from R1M5 vs R1M6
            'R2M4': ['R1M7', 'R1M8'],   # Winners from R1M7 vs R1M8
            'R2M5': ['R1M9', 'R1M10'],  # Winners from R1M9 vs R1M10
            'R2M6': ['R1M11', 'R1M12'], # Winners from R1M11 vs R1M12
            'R2M7': ['R1M13', 'R1M14'], # Winners from R1M13 vs R1M14
            'R2M8': ['R1M15', 'R1M16'], # Winners from R1M15 vs R1M16
            
            'R3M1': ['R2M1', 'R2M2'],   # Winners from R2M1 vs R2M2
            'R3M2': ['R2M3', 'R2M4'],   # Winners from R2M3 vs R2M4
            'R3M3': ['R2M5', 'R2M6'],   # Winners from R2M5 vs R2M6
            'R3M4': ['R2M7', 'R2M8'],   # Winners from R2M7 vs R2M8
            
            'R4M1': ['R3M1', 'R3M2'],   # Winners from R3M1 vs R3M2
            'R4M2': ['R3M3', 'R3M4'],   # Winners from R3M3 vs R3M4
            
            'R5M1': ['R4M1', 'R4M2'],   # Winners from R4M1 vs R4M2 (Final)
        }
    
    elif tournament_format == "DE8":
        # SABO DE8 Progression Map (15 matches total)
        return {
            # Winners Bracket
            'R2M1': ['R1M1', 'R1M2'],   # Winners from R1M1 vs R1M2
            'R2M2': ['R1M3', 'R1M4'],   # Winners from R1M3 vs R1M4
            'R2M3': ['R1M5', 'R1M6'],   # Winners from R1M5 vs R1M6
            'R2M4': ['R1M7', 'R1M8'],   # Winners from R1M7 vs R1M8
            
            'R3M1': ['R2M1', 'R2M2'],   # Winners from R2M1 vs R2M2
            'R3M2': ['R2M3', 'R2M4'],   # Winners from R2M3 vs R2M4
            
            'R4M1': ['R3M1', 'R3M2'],   # Winners from R3M1 vs R3M2 (Final)
        }
    
    else:
        print(f"⚠️ Unsupported tournament format: {tournament_format}")
        return {}

def get_match_winner(supabase, tournament_id, round_num, match_num):
    """Get winner ID from specific match"""
    try:
        result = supabase.table('matches').select('winner_id')\
            .eq('tournament_id', tournament_id)\
            .eq('round_number', round_num)\
            .eq('match_number', match_num)\
            .execute()
        
        if result.data and len(result.data) > 0:
            return result.data[0]['winner_id']
        return None
    except Exception as e:
        print(f"❌ Error getting winner for R{round_num}M{match_num}: {e}")
        return None

def update_match_players(supabase, tournament_id, round_num, match_num, player1_id, player2_id):
    """Update match with player IDs"""
    try:
        result = supabase.table('matches').update({
            'player1_id': player1_id,
            'player2_id': player2_id,
            'status': 'pending'  # Set to pending when players are assigned
        }).eq('tournament_id', tournament_id)\
          .eq('round_number', round_num)\
          .eq('match_number', match_num)\
          .execute()
        
        if result.data:
            print(f"✅ Updated R{round_num}M{match_num}: {player1_id[:8]}... vs {player2_id[:8]}...")
            return True
        else:
            print(f"❌ Failed to update R{round_num}M{match_num}")
            return False
            
    except Exception as e:
        print(f"❌ Error updating R{round_num}M{match_num}: {e}")
        return False

def detect_tournament_format(supabase, tournament_id):
    """Auto-detect tournament format based on match count and structure"""
    
    matches = supabase.table('matches').select('round_number, match_number').eq('tournament_id', tournament_id).execute()
    
    total_matches = len(matches.data)
    
    # Count matches per round
    rounds = {}
    for match in matches.data:
        round_num = match['round_number']
        if round_num not in rounds:
            rounds[round_num] = 0
        rounds[round_num] += 1
    
    round_counts = [rounds[i] for i in sorted(rounds.keys())]
    
    # Single Elimination formats
    if total_matches == 31 and round_counts == [16, 8, 4, 2, 1]:
        return "SE16"  # Single Elimination 16-player
    elif total_matches == 15 and round_counts == [8, 4, 2, 1]:
        return "SE8"   # Single Elimination 8-player
    # Double Elimination formats  
    elif total_matches == 15:
        return "DE8"
    elif total_matches == 27:
        return "DE16"
    elif total_matches == 57:
        return "DE32"
    else:
        print(f"⚠️ Unknown format with {total_matches} matches, pattern {round_counts}")
        return "UNKNOWN"

def fill_tournament_progression(supabase, tournament_id):
    """Fill winners from completed rounds into next rounds"""
    
    print(f"🏆 Processing tournament progression for: {tournament_id}")
    
    # Auto-detect format
    detected_format = detect_tournament_format(supabase, tournament_id)
    print(f"🎯 Detected format: {detected_format}")
    
    progression_map = get_progression_map(detected_format)
    updates_made = 0
    
    for target_match, source_matches in progression_map.items():
        # Parse target match (e.g., "R2M1" -> round=2, match=1)
        target_round = int(target_match[1])
        target_match_num = int(target_match[3:])
        
        print(f"\n🔍 Checking {target_match} (R{target_round}M{target_match_num})...")
        
        # Check if target match already has players
        current_match = supabase.table('matches').select('player1_id, player2_id')\
            .eq('tournament_id', tournament_id)\
            .eq('round_number', target_round)\
            .eq('match_number', target_match_num)\
            .execute()
        
        if not current_match.data:
            print(f"  ⚠️ Target match {target_match} not found")
            continue
            
        current_p1 = current_match.data[0]['player1_id']
        current_p2 = current_match.data[0]['player2_id']
        
        if current_p1 and current_p2:
            print(f"  ✅ {target_match} already has players")
            continue
        
        # Get winners from source matches
        winners = []
        all_sources_complete = True
        
        for source_match in source_matches:
            # Parse source match (e.g., "R1M1" -> round=1, match=1)
            source_round = int(source_match[1])
            source_match_num = int(source_match[3:])
            
            winner_id = get_match_winner(supabase, tournament_id, source_round, source_match_num)
            
            if winner_id:
                winners.append(winner_id)
                print(f"    ✅ {source_match} winner: {winner_id[:8]}...")
            else:
                print(f"    ❌ {source_match} no winner yet")
                all_sources_complete = False
                break
        
        # If we have both winners, update the target match
        if all_sources_complete and len(winners) == 2:
            success = update_match_players(supabase, tournament_id, target_round, target_match_num, winners[0], winners[1])
            if success:
                updates_made += 1
        else:
            print(f"  ⏳ {target_match} waiting for source matches to complete")
    
    print(f"\n🎯 Tournament progression completed!")
    print(f"📊 Updates made: {updates_made}")
    return updates_made

def main():
    """Main function"""
    
    if len(sys.argv) > 1:
        tournament_id = sys.argv[1]
    else:
        # Default to sabo345 tournament
        tournament_id = '2cca5f19-40ca-4b71-a120-f7bdd305f7c4'
    
    print("🚀 TOURNAMENT AUTO-FILL SYSTEM")
    print("=" * 50)
    
    supabase = connect_supabase()
    
    # Get tournament info
    tournament = supabase.table('tournaments').select('title, format').eq('id', tournament_id).execute()
    
    if not tournament.data:
        print(f"❌ Tournament {tournament_id} not found!")
        return
    
    tournament_name = tournament.data[0]['title']
    tournament_format = tournament.data[0]['format']
    
    print(f"📋 Tournament: {tournament_name}")
    print(f"🎮 Format: {tournament_format}")
    print(f"🆔 ID: {tournament_id}")
    
    # Fill progression
    updates = fill_tournament_progression(supabase, tournament_id)
    
    if updates > 0:
        print(f"\n🎉 SUCCESS: {updates} matches updated with new players!")
    else:
        print(f"\n💡 No updates needed - all matches already have players or waiting for prerequisites")

if __name__ == "__main__":
    main()