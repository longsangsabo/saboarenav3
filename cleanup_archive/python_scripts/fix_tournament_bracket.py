#!/usr/bin/env python3
# 🔧 FIX TOURNAMENT BRACKET LOGIC
# Script to repair tournament bracket using CorrectBracketLogicService
# Author: SABO v1.0
# Fix date: 2025-01-29

from supabase import create_client
import json

# Supabase config
url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

tournament_id = '6c0658f7-bf94-44a0-82b1-de117ec9ea29'

def main():
    print('🔧 STARTING TOURNAMENT BRACKET REPAIR')
    print('=' * 50)
    
    try:
        # 1. Show current broken structure
        print('\n📊 CURRENT BROKEN STRUCTURE:')
        analyze_current_bracket(tournament_id)
        
        # 2. Fix bracket by recreating missing matches
        print('\n🔧 FIXING BRACKET STRUCTURE:')
        repair_bracket_manually(tournament_id)
        
        # 3. Verify repair
        print('\n✅ VERIFYING REPAIR:')
        analyze_current_bracket(tournament_id)
        
    except Exception as e:
        print(f'❌ Repair failed: {e}')

def analyze_current_bracket(tournament_id):
    """Analyze current bracket structure"""
    
    # Get participants
    participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
    participant_count = len(participants.data)
    
    # Get matches
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number').order('match_number').execute()
    
    matches_by_round = {}
    for match in matches.data:
        round_num = match.get('round_number', 0)
        if round_num not in matches_by_round:
            matches_by_round[round_num] = []
        matches_by_round[round_num].append(match)
    
    print(f'  👥 Participants: {participant_count}')
    print(f'  📊 Total matches: {len(matches.data)}')
    print(f'  📈 Expected matches: {participant_count - 1} (n-1 rule)')
    
    # Show round structure
    expected_players = participant_count
    round_num = 1
    
    while expected_players > 1:
        expected_matches = expected_players // 2
        actual_matches = len(matches_by_round.get(round_num, []))
        status = "✅" if actual_matches == expected_matches else "❌"
        
        print(f'  Round {round_num}: Expected {expected_matches}, Actual {actual_matches} {status}')
        
        expected_players = expected_matches
        round_num += 1

def repair_bracket_manually(tournament_id):
    """Repair bracket by creating missing matches"""
    
    print('  🗑️  Deleting incorrect matches after Round 1...')
    
    # Delete matches from Round 2+ (they're incorrectly generated)
    delete_result = supabase.table('matches').delete().eq('tournament_id', tournament_id).gt('round_number', 1).execute()
    print(f'    Deleted {len(delete_result.data)} incorrect matches')
    
    # Get Round 1 winners to regenerate correct structure
    round1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).execute()
    
    completed_round1 = [m for m in round1_matches.data if m['status'] == 'completed' and m['winner_id']]
    print(f'  🏆 Found {len(completed_round1)} completed Round 1 matches')
    
    if len(completed_round1) == 8:  # All Round 1 matches completed
        print('  🔧 Creating correct Round 2 matches (4 matches)...')
        create_round2_matches(tournament_id, completed_round1)
        
        # If Round 2 would be complete, continue...
        # For now, just create Round 2 structure
        
def create_round2_matches(tournament_id, round1_matches):
    """Create correct Round 2 matches from Round 1 winners"""
    
    # Get winners from Round 1
    winners = []
    for match in round1_matches:
        winner_id = match['winner_id']
        if winner_id:
            winners.append(winner_id)
    
    if len(winners) != 8:
        raise Exception(f'Expected 8 winners from Round 1, got {len(winners)}')
    
    # Create 4 matches for Round 2 (8 winners -> 4 matches)
    matches_to_create = []
    
    for i in range(4):  # 4 matches in Round 2
        player1_id = winners[i * 2]
        player2_id = winners[i * 2 + 1]
        
        match_data = {
            'tournament_id': tournament_id,
            'round_number': 2,
            'match_number': i + 1,
            'bracket_position': i + 1,
            'player1_id': player1_id,
            'player2_id': player2_id,
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'single_elimination',
        }
        
        matches_to_create.append(match_data)
    
    # Insert new Round 2 matches
    result = supabase.table('matches').insert(matches_to_create).execute()
    print(f'    ✅ Created {len(result.data)} Round 2 matches')
    
    # Show the matches
    for i, match in enumerate(matches_to_create):
        print(f'      Match {i + 1}: {match["player1_id"]} vs {match["player2_id"]}')

if __name__ == '__main__':
    main()