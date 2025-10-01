#!/usr/bin/env python3
"""
Test Tournament Advancement
Simulates the advanceTournament() logic to create Round 2 from Round 1 winners
"""

import os
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def main():
    print('🚀 Testing Tournament Advancement...')
    
    supabase: Client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)
    
    # Tournament ID with completed Round 1
    tournament_id = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6'
    
    try:
        print('📊 Fetching tournament data...')
        
        # Get participants
        participants_response = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
        
        participants = []
        for p in participants_response.data:
            participants.append({
                'id': p['user_id'],
                'name': f'Player_{p["user_id"][:8]}',  # Simplified name
                'seed': p.get('seed'),
            })
        
        print(f'✅ Found {len(participants)} participants')
        
        # Get current matches
        matches_response = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number, match_number').execute()
        
        current_matches = []
        for m in matches_response.data:
            # Find players
            player1 = next((p for p in participants if p['id'] == m.get('player1_id')), None)
            player2 = next((p for p in participants if p['id'] == m.get('player2_id')), None)
            winner = next((p for p in participants if p['id'] == m.get('winner_id')), None)
            
            current_matches.append({
                'id': m['id'],
                'round_number': m['round_number'],
                'match_number': m['match_number'],
                'player1': player1,
                'player2': player2,
                'winner': winner,
                'status': m.get('status', 'pending'),
            })
        
        print(f'✅ Found {len(current_matches)} current matches')
        
        # Analyze current state
        round_groups = {}
        for match in current_matches:
            round_num = match['round_number']
            if round_num not in round_groups:
                round_groups[round_num] = []
            round_groups[round_num].append(match)
        
        print('\n📋 Current Tournament State:')
        for round_num in sorted(round_groups.keys()):
            round_matches = round_groups[round_num]
            completed = len([m for m in round_matches if m['status'] == 'completed'])
            print(f'   Round {round_num}: {len(round_matches)} matches ({completed} completed)')
        
        # Test advancement logic
        print('\n🔄 Testing tournament advancement...')
        
        # Find the highest completed round
        completed_round = None
        for round_num in sorted(round_groups.keys(), reverse=True):
            round_matches = round_groups[round_num]
            completed_count = len([m for m in round_matches if m['status'] == 'completed'])
            
            if completed_count == len(round_matches):
                completed_round = round_num
                break
        
        if completed_round is None:
            print('❌ No completed rounds found')
            return
            
        print(f'✅ Found completed round: {completed_round}')
        
        # Check if next round already exists
        next_round_num = completed_round + 1
        if next_round_num in round_groups:
            print(f'❌ Round {next_round_num} already exists')
            return
            
        print(f'🚀 Ready to create Round {next_round_num}')
        
        # Extract winners from completed round
        completed_matches = round_groups[completed_round]
        winners = []
        
        print(f'\n🏆 Winners from Round {completed_round}:')
        for i, match in enumerate(completed_matches):
            if match['winner']:
                winners.append(match['winner'])
                player1_name = match['player1']['name'] if match['player1'] else 'Unknown'
                player2_name = match['player2']['name'] if match['player2'] else 'Unknown'
                winner_name = match['winner']['name']
                print(f'   Match {i+1}: {player1_name} vs {player2_name} → Winner: {winner_name}')
            else:
                print(f'   Match {i+1}: No winner found!')
        
        if len(winners) < 2:
            print(f'❌ Need at least 2 winners, found {len(winners)}')
            return
            
        if len(winners) == 1:
            print(f'🏆 Tournament completed! Winner: {winners[0]["name"]}')
            return
        
        # Generate next round matches
        match_count = len(winners) // 2
        
        # Determine round name
        round_names = {
            1: 'Final',
            2: 'Semifinals', 
            4: 'Quarterfinals',
            8: 'Round of 16'
        }
        round_name = round_names.get(match_count, f'Round {next_round_num}')
        
        print(f'\n🎯 Generating {round_name} ({match_count} matches):')
        
        import uuid
        
        new_matches = []
        for i in range(match_count):
            player1 = winners[i * 2]
            player2 = winners[i * 2 + 1]
            
            match_id = str(uuid.uuid4())  # Generate proper UUID
            
            new_match = {
                'id': match_id,
                'tournament_id': tournament_id,
                'round_number': next_round_num,
                'match_number': i + 1,
                'player1_id': player1['id'],
                'player2_id': player2['id'],
                'status': 'pending',
            }
            
            new_matches.append(new_match)
            print(f'   Match {i+1}: {player1["name"]} vs {player2["name"]}')
        
        # Save new matches to database
        print(f'\n💾 Saving {len(new_matches)} new matches to database...')
        
        for match in new_matches:
            result = supabase.table('matches').insert(match).execute()
            print(f'   ✅ Created match: {match["id"]}')
        
        print(f'\n🎉 SUCCESS! {round_name} created with {match_count} matches')
        
        # Verify the creation
        print('\n🔍 Verifying new tournament state...')
        updated_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).order('round_number, match_number').execute()
        
        updated_round_groups = {}
        for match in updated_matches.data:
            round_num = match['round_number']
            if round_num not in updated_round_groups:
                updated_round_groups[round_num] = []
            updated_round_groups[round_num].append(match)
        
        print('📊 Updated Tournament State:')
        for round_num in sorted(updated_round_groups.keys()):
            round_matches = updated_round_groups[round_num]
            completed = len([m for m in round_matches if m['status'] == 'completed'])
            pending = len([m for m in round_matches if m['status'] == 'pending'])
            print(f'   Round {round_num}: {len(round_matches)} matches ({completed} completed, {pending} pending)')
        
    except Exception as e:
        print(f'❌ Error: {e}')
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    main()