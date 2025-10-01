#!/usr/bin/env python3
from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'

print('🔍 CHECKING WB ROUND 1 PARTICIPANTS')
print('=' * 40)

wb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()

if wb_r1_matches.data:
    print(f'Found {len(wb_r1_matches.data)} WB Round 1 matches:')
    for match in wb_r1_matches.data:
        match_num = match['match_number']
        p1 = match['player1_id'][:8] if match['player1_id'] else 'NULL'
        p2 = match['player2_id'][:8] if match['player2_id'] else 'NULL'
        print(f'  M{match_num}: P1={p1}, P2={p2}')
        
    # Check if all are NULL
    null_count = sum(1 for m in wb_r1_matches.data if not m['player1_id'] or not m['player2_id'])
    print(f'')
    print(f'❌ Matches with NULL players: {null_count}/{len(wb_r1_matches.data)}')
    
    if null_count > 0:
        print('💡 PROBLEM: WB Round 1 matches have NULL participants!')
        print('   This means _generateWBRound1WithParticipants() failed!')
    else:
        print('✅ All matches have participants!')
else:
    print('❌ No WB Round 1 matches found!')