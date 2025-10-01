#!/usr/bin/env python3
"""
Debug R4 M15 duplicate issue
"""

from supabase import create_client

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def debug_r4_m15():
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'

    # Get R4 M15 detailed data
    r4_match = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 4).eq('match_number', 15).single().execute()

    print('🔍 WB FINAL (R4 M15) DETAILED ANALYSIS')
    print('='*50)
    match = r4_match.data
    print(f'Match ID: {match["id"]}')
    print(f'Player1 ID: {match.get("player1_id", "None")}')
    print(f'Player2 ID: {match.get("player2_id", "None")}')
    print(f'Status: {match.get("status", "unknown")}')
    print(f'Winner: {match.get("winner_id", "None")}')

    # Check if both slots have same player
    p1 = match.get('player1_id')
    p2 = match.get('player2_id')
    if p1 and p2 and p1 == p2:
        print(f'\n❌ CONFIRMED DUPLICATE: Same player {p1} in both slots!')
    else:
        print(f'\n✅ No duplicate detected')

    print('\n🎯 ADVANCEMENT TRACE:')
    print('   Expected: M13 winner (27776859) → player1_id')
    print('   Expected: M14 winner (6294b63f) → player2_id')
    print(f'   Actual player1_id: {match.get("player1_id", "None")}') 
    print(f'   Actual player2_id: {match.get("player2_id", "None")}')

    return p1 == p2 if p1 and p2 else False

if __name__ == "__main__":
    has_duplicate = debug_r4_m15()
    if has_duplicate:
        print('\n💥 BUG CONFIRMED: Smart slot assignment logic is faulty!')
    else:
        print('\n🎉 No issues found')