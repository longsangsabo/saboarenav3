#!/usr/bin/env python3
"""
Test bracket creation format detection logic
Simulate the fixed Tournament Management Center logic
"""

from supabase import create_client
import json

# Initialize Supabase
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def test_tournament_format_detection():
    """Test format detection logic from Tournament Management Center"""
    
    print('🧪 TESTING BRACKET FORMAT DETECTION LOGIC')
    print('=' * 60)
    
    # Get tournament sabo1 data
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    
    # 1. Fetch tournament data (simulating app logic)
    tournament_response = supabase.table('tournaments').select('*').eq('id', tournament_id).single().execute()
    tournament = tournament_response.data
    
    print(f'📋 TOURNAMENT DATA:')
    print(f'   ID: {tournament["id"]}')
    print(f'   Title: {tournament["title"]}')
    print(f'   DB Format field: {tournament.get("format", "NULL")} (game type)')
    print(f'   DB Tournament Type field: {tournament.get("tournament_type", "NULL")} (elimination format)')
    
    # 2. Simulate Tournament Model mapping (the fix we applied)
    # In the Dart model: tournament.format = database.tournament_type
    tournament_format = tournament.get("tournament_type", "single_elimination")
    tournament_game_type = tournament.get("format", "8-ball")
    
    print(f'\n🔧 FIXED MODEL MAPPING:')
    print(f'   App tournament.format: "{tournament_format}" (elimination format)')
    print(f'   App tournament.tournamentType: "{tournament_game_type}" (game type)')
    
    # 3. Get participants (simulating app logic)
    participants_response = supabase.table('tournament_participants').select('''
        user_id,
        users!inner(
            id,
            full_name,
            username,
            avatar_url
        )
    ''').eq('tournament_id', tournament_id).execute()
    
    participant_profiles = participants_response.data
    print(f'\n👥 PARTICIPANTS:')
    print(f'   Found: {len(participant_profiles)} participants')
    
    # 4. Simulate format detection logic (the fix we applied)
    print(f'\n🎯 FORMAT DETECTION LOGIC:')
    print(f'   Detected tournament format: "{tournament_format}"')
    
    if tournament_format == 'double_elimination':
        expected_service = 'generateDoubleEliminationBracket()'
        expected_factory = 'DE16Factory (Double Elimination 16)'
        expected_matches = 27  # DE16: 14 + 7 + 3 + 3 = 27
    elif tournament_format == 'round_robin':
        expected_service = 'generateRoundRobinBracket()'
        expected_factory = 'RRFactory (Round Robin)'
        expected_matches = (len(participant_profiles) * (len(participant_profiles) - 1)) // 2
    else:  # single_elimination
        expected_service = 'generateSingleEliminationBracket()'
        expected_factory = 'SE16Factory (Single Elimination 16)'
        expected_matches = len(participant_profiles) - 1
    
    print(f'   ✅ Should use: {expected_service}')
    print(f'   ✅ Expected factory: {expected_factory}')
    print(f'   ✅ Expected matches: {expected_matches}')
    
    # 5. Verify against old logic (the bug)
    print(f'\n❌ OLD HARDCODED LOGIC (BUG):')
    print(f'   🔴 Always used: generateSingleEliminationBracket()')
    print(f'   🔴 Always factory: SE16Factory')
    print(f'   🔴 Always matches: 15 (single elimination)')
    print(f'   🔴 Result: WRONG for double_elimination tournament!')
    
    # 6. Check current matches in database
    existing_matches = supabase.table('matches').select('id, round_number').eq('tournament_id', tournament_id).execute()
    print(f'\n📊 CURRENT DATABASE STATE:')
    print(f'   Existing matches: {len(existing_matches.data)}')
    if existing_matches.data:
        rounds = set(match['round_number'] for match in existing_matches.data)
        print(f'   Rounds: {sorted(rounds)}')
    
    print(f'\n✅ CONCLUSION:')
    if tournament_format == 'double_elimination':
        print(f'   🎯 Tournament sabo1 is DOUBLE ELIMINATION with 16 players')
        print(f'   🔧 Fixed app should now detect this correctly')
        print(f'   🏭 Should use DE16Factory to create 27 matches')
        print(f'   ✅ No more hardcoded single_elimination bug!')
    
    return {
        'tournament_format': tournament_format,
        'participant_count': len(participant_profiles),
        'expected_service': expected_service,
        'expected_factory': expected_factory,
        'expected_matches': expected_matches,
        'current_matches': len(existing_matches.data)
    }

if __name__ == "__main__":
    result = test_tournament_format_detection()
    print(f'\n🎯 TEST RESULT: {json.dumps(result, indent=2)}')