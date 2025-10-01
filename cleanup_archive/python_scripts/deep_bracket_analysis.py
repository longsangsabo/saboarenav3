#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Deep analysis of bracket generation issue
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def deep_bracket_analysis():
    print("🔍 DEEP BRACKET ANALYSIS")
    print("=" * 50)
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'
    
    # Check WB Round 1 first
    print("📊 WB ROUND 1 ANALYSIS:")
    print("-" * 30)
    wb_r1_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 1).order('match_number').execute()
    
    r1_players = []
    for match in wb_r1_matches.data:
        print(f"Match {match['match_number']}: {match['player1_id']} vs {match['player2_id']}")
        if match['player1_id']:
            r1_players.append(match['player1_id'])
        if match['player2_id']:
            r1_players.append(match['player2_id'])
    
    # Check for R1 duplicates
    r1_duplicates = []
    for player in set(r1_players):
        if r1_players.count(player) > 1:
            r1_duplicates.append(player)
    
    if r1_duplicates:
        print(f"❌ WB R1 HAS DUPLICATES: {len(r1_duplicates)}")
        for dup in r1_duplicates:
            print(f"  - {dup} appears {r1_players.count(dup)} times")
    else:
        print("✅ WB R1 has no duplicates")
    
    # Check WB Round 2
    print(f"\n📊 WB ROUND 2 ANALYSIS:")
    print("-" * 30)
    wb_r2_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 2).order('match_number').execute()
    
    r2_players = []
    for match in wb_r2_matches.data:
        print(f"Match {match['match_number']}: {match['player1_id']} vs {match['player2_id']}")
        if match['player1_id']:
            r2_players.append(match['player1_id'])
        if match['player2_id']:
            r2_players.append(match['player2_id'])
    
    # Check for R2 duplicates
    r2_duplicates = []
    for player in set(r2_players):
        if r2_players.count(player) > 1:
            r2_duplicates.append(player)
    
    if r2_duplicates:
        print(f"❌ WB R2 HAS DUPLICATES: {len(r2_duplicates)}")
        for dup in r2_duplicates:
            print(f"  - {dup} appears {r2_players.count(dup)} times")
            
            # Find which matches contain this duplicate
            for match in wb_r2_matches.data:
                if match['player1_id'] == dup or match['player2_id'] == dup:
                    print(f"    Found in Match {match['match_number']} as {'P1' if match['player1_id'] == dup else 'P2'}")
    else:
        print("✅ WB R2 has no duplicates")
    
    # Check LB rounds too
    print(f"\n📊 LB ROUND 101 ANALYSIS:")
    print("-" * 30)
    lb_r101_matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).eq('round_number', 101).order('match_number').execute()
    
    for match in lb_r101_matches.data:
        print(f"Match {match['match_number']}: {match['player1_id']} vs {match['player2_id']}")

if __name__ == "__main__":
    deep_bracket_analysis()