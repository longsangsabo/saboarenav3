#!/usr/bin/env python3
"""
Check database state
"""

from supabase import create_client

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def check_database_state():
    # Check tournaments
    tournaments = supabase.table('tournaments').select('*').execute()
    print('🏆 TOURNAMENTS:')
    for t in tournaments.data:
        tid = t["id"][:8]
        name = t["name"]
        format_type = t["format"]
        status = t["status"]
        print(f'   {tid}: {name} - {format_type} - {status}')

    # Check matches for sabo1
    tournament_id = '95cee835-9265-4b08-95b1-a5f9a67c1ec8'
    matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
    print(f'\n🎯 Matches for sabo1: {len(matches.data) if matches.data else 0}')

    # Check all matches
    all_matches = supabase.table('matches').select('tournament_id, round_number, match_number').execute()
    print(f'\n📊 Total matches in DB: {len(all_matches.data) if all_matches.data else 0}')
    if all_matches.data:
        tournaments_with_matches = set(m['tournament_id'] for m in all_matches.data)
        print('   Tournaments with matches:')
        for tid in tournaments_with_matches:
            count = len([m for m in all_matches.data if m['tournament_id'] == tid])
            tid_short = tid[:8]
            print(f'      {tid_short}: {count} matches')

if __name__ == "__main__":
    check_database_state()