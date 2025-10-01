#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Check duplicate players in WB Round 2
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def check_duplicate_issue():
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'

    print('🔍 CHECKING WB ROUND 2 DUPLICATE ISSUE')
    print('=' * 50)

    # Get WB Round 2 matches
    wb_r2_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 2).order('match_number').execute()

    print(f'Found {len(wb_r2_matches.data)} WB Round 2 matches:')
    for match in wb_r2_matches.data:
        print(f'  Match {match["match_number"]}: P1={match["player1_id"]}, P2={match["player2_id"]}')

    # Check for duplicates
    print('\n🔍 CHECKING FOR DUPLICATE PLAYERS')
    print('=' * 30)
    players_in_r2 = []
    for match in wb_r2_matches.data:
        if match['player1_id']:
            players_in_r2.append(match['player1_id'])
        if match['player2_id']:
            players_in_r2.append(match['player2_id'])

    duplicates = []
    for player in set(players_in_r2):
        if players_in_r2.count(player) > 1:
            duplicates.append(player)

    if duplicates:
        print(f'❌ FOUND {len(duplicates)} DUPLICATE PLAYERS:')
        for dup in duplicates:
            print(f'  - Player {dup} appears {players_in_r2.count(dup)} times')
            
        # Get player names
        player_names = supabase.table('users').select('id, full_name').filter('id', 'in', duplicates).execute()
        for player in player_names.data:
            print(f'    {player["id"]}: {player["full_name"]}')
    else:
        print('✅ No duplicates found')

    # Check WB Round 1 winners to understand the issue
    print('\n🔍 CHECKING WB ROUND 1 WINNERS')
    print('=' * 30)
    wb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()

    winners = []
    for match in wb_r1_matches.data:
        if match['winner_id']:
            winners.append(match['winner_id'])
            print(f'  Match {match["match_number"]}: Winner = {match["winner_id"]}')

    print(f'\nTotal WB R1 winners: {len(winners)}')
    print(f'Expected: 8 unique winners for WB R2')
    
    # Check if winners appear multiple times
    winner_duplicates = []
    for winner in set(winners):
        if winners.count(winner) > 1:
            winner_duplicates.append(winner)
    
    if winner_duplicates:
        print(f'❌ DUPLICATE WINNERS FROM WB R1: {len(winner_duplicates)}')
        for dup in winner_duplicates:
            print(f'  - Winner {dup} appears {winners.count(dup)} times')

if __name__ == "__main__":
    check_duplicate_issue()