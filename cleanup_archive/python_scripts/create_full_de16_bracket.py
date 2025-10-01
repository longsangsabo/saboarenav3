#!/usr/bin/env python3
"""
🚀 TEST DE16 BRACKET CREATION
Tạo DE16 bracket để test logic mapping
"""

from supabase import create_client
import uuid
from datetime import datetime

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def create_test_de16_bracket():
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'
    
    print('🚀 CREATING FULL DE16 BRACKET')
    print('=' * 40)
    
    # Clear existing matches
    result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
    print(f'🧹 Cleared {len(result.data) if result.data else 0} existing matches')
    
    # Get participants
    participants = supabase.table('tournament_participants').select('user_id').eq('tournament_id', tournament_id).execute()
    if not participants.data or len(participants.data) < 16:
        print(f'❌ Need 16 participants, found {len(participants.data) if participants.data else 0}')
        return
    
    participant_ids = [p['user_id'] for p in participants.data[:16]]
    print(f'✅ Using {len(participant_ids)} participants')
    
    matches = []
    
    # WB Round 1: 8 matches (16 → 8)
    print('\n🎯 Creating Winners Bracket...')
    for i in range(8):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 1,
            'match_number': i + 1,
            'bracket_position': i + 1,
            'player1_id': participant_ids[i * 2],
            'player2_id': participant_ids[i * 2 + 1],
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # WB Round 2: 4 matches (8 → 4)
    for i in range(4):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 2,
            'match_number': i + 9,
            'bracket_position': i + 1,
            'player1_id': None,  # Will be filled by progression
            'player2_id': None,
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # WB Round 3: 2 matches (4 → 2)
    for i in range(2):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 3,
            'match_number': i + 13,
            'bracket_position': i + 1,
            'player1_id': None,
            'player2_id': None,
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # WB Round 4: 1 match (2 → 1) - WB Final
    match = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 4,
        'match_number': 15,
        'bracket_position': 1,
        'player1_id': None,
        'player2_id': None,
        'winner_id': None,
        'status': 'pending',
        'match_type': 'tournament',
        'format': 'double_elimination',
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat(),
    }
    matches.append(match)
    
    print('💀 Creating Losers Bracket...')
    
    # LB Round 101: 4 matches
    for i in range(4):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 101,
            'match_number': i + 16,
            'bracket_position': i + 1,
            'player1_id': None,  # WB R1 losers
            'player2_id': None,
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # LB Round 102: 4 matches
    for i in range(4):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 102,
            'match_number': i + 20,
            'bracket_position': i + 1,
            'player1_id': None,  # LB R101 winners
            'player2_id': None,  # WB R2 losers
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # LB Round 103: 2 matches
    for i in range(2):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 103,
            'match_number': i + 24,
            'bracket_position': i + 1,
            'player1_id': None,  # LB R102 winners only
            'player2_id': None,
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # LB Round 104: 2 matches
    for i in range(2):
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'round_number': 104,
            'match_number': i + 26,
            'bracket_position': i + 1,
            'player1_id': None,  # LB R103 winners
            'player2_id': None,  # WB R3 losers (THIS IS THE KEY!)
            'winner_id': None,
            'status': 'pending',
            'match_type': 'tournament',
            'format': 'double_elimination',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        matches.append(match)
    
    # LB Round 105: 1 match
    match = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 105,
        'match_number': 28,
        'bracket_position': 1,
        'player1_id': None,
        'player2_id': None,
        'winner_id': None,
        'status': 'pending',
        'match_type': 'tournament',
        'format': 'double_elimination',
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat(),
    }
    matches.append(match)
    
    # LB Round 106: 1 match
    match = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 106,
        'match_number': 29,
        'bracket_position': 1,
        'player1_id': None,  # LB R105 winner
        'player2_id': None,  # WB R4 loser
        'winner_id': None,
        'status': 'pending',
        'match_type': 'tournament',
        'format': 'double_elimination',
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat(),
    }
    matches.append(match)
    
    # LB Round 107: 1 match (LB Final)
    match = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 107,
        'match_number': 30,
        'bracket_position': 1,
        'player1_id': None,
        'player2_id': None,
        'winner_id': None,
        'status': 'pending',
        'match_type': 'tournament',
        'format': 'double_elimination',
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat(),
    }
    matches.append(match)
    
    # Grand Final: 1 match
    match = {
        'id': str(uuid.uuid4()),
        'tournament_id': tournament_id,
        'round_number': 200,
        'match_number': 31,
        'bracket_position': 1,
        'player1_id': None,  # WB Champion
        'player2_id': None,  # LB Champion
        'winner_id': None,
        'status': 'pending',
        'match_type': 'tournament',
        'format': 'double_elimination',
        'created_at': datetime.now().isoformat(),
        'updated_at': datetime.now().isoformat(),
    }
    matches.append(match)
    
    print(f'📝 Total matches created: {len(matches)}')
    
    # Insert all matches
    result = supabase.table('matches').insert(matches).execute()
    
    if result.data:
        print(f'✅ Successfully created {len(result.data)} matches!')
        
        # Group by rounds
        rounds = {}
        for match in result.data:
            round_num = match['round_number']
            if round_num not in rounds:
                rounds[round_num] = 0
            rounds[round_num] += 1
        
        print('\n📊 BRACKET STRUCTURE:')
        for round_num in sorted(rounds.keys()):
            round_type = 'WB' if round_num < 100 else 'LB' if round_num < 200 else 'GF'
            print(f'   {round_type} R{round_num}: {rounds[round_num]} matches')
        
        return True
    else:
        print('❌ Failed to create matches!')
        return False

if __name__ == '__main__':
    create_test_de16_bracket()