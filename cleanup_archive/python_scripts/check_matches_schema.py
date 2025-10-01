#!/usr/bin/env python3

import os
from supabase import create_client, Client

# Supabase connection
url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

supabase: Client = create_client(url, key)

def check_matches_table():
    try:
        # Try to query matches table directly to see structure
        print("=== CHECKING MATCHES TABLE ===")
        try:
            result = supabase.from_('matches').select('*').limit(1).execute()
            print(f"✅ Matches table exists and returned {len(result.data)} records")
            if result.data:
                print("Available columns in matches table:")
                for key in result.data[0].keys():
                    print(f"  - {key}")
            else:
                print("No data in matches table, but table exists")
        except Exception as e:
            print(f"❌ Error querying matches table: {e}")
            
        # Try inserting a test match to see what columns are expected
        print("\n=== TESTING MATCH INSERT (will fail to show required columns) ===")
        try:
            test_match = {
                'tournament_id': 'test-id',
                'round_number': 1,
                'match_number': 1,
            }
            result = supabase.from_('matches').insert(test_match).execute()
            print("✅ Test insert succeeded (unexpected)")
        except Exception as e:
            print(f"❌ Test insert failed (expected): {e}")
            # This error will show us what columns are required/missing
            
    except Exception as e:
        print(f"❌ Error checking matches table: {e}")

if __name__ == "__main__":
    check_matches_table()