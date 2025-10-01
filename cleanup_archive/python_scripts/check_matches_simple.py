#!/usr/bin/env python3
"""
Check actual matches table structure on Supabase - Simple approach
"""

import os
from supabase import create_client

def check_matches_directly():
    # Supabase credentials
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    # Initialize Supabase client
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 Checking matches table by trying to get existing data...")
    
    try:
        # Get existing matches to see actual structure
        existing = supabase.table('matches').select('*').limit(1).execute()
        if existing.data:
            print("✅ Found existing matches! Actual fields:")
            for key in existing.data[0].keys():
                print(f"  - {key}")
        else:
            print("📝 No existing matches found, table exists but empty")
            
        # Check what fields cause errors
        print("\n🧪 Testing field requirements by trying inserts...")
        
        # Test with minimal required fields we know
        test_cases = [
            # Case 1: Absolute minimum
            {
                'tournament_id': '00000000-0000-0000-0000-000000000000'
            },
            # Case 2: Add players
            {
                'tournament_id': '00000000-0000-0000-0000-000000000000',
                'player1_id': '00000000-0000-0000-0000-000000000001',
                'player2_id': '00000000-0000-0000-0000-000000000002'
            },
            # Case 3: Add round info
            {
                'tournament_id': '00000000-0000-0000-0000-000000000000',
                'player1_id': '00000000-0000-0000-0000-000000000001',
                'player2_id': '00000000-0000-0000-0000-000000000002',
                'round_number': 1,
                'match_number': 1
            },
            # Case 4: Add status
            {
                'tournament_id': '00000000-0000-0000-0000-000000000000',
                'player1_id': '00000000-0000-0000-0000-000000000001',
                'player2_id': '00000000-0000-0000-0000-000000000002',
                'round_number': 1,
                'match_number': 1,
                'status': 'pending'
            }
        ]
        
        for i, test_data in enumerate(test_cases, 1):
            print(f"\n🧪 Test Case {i}: {list(test_data.keys())}")
            try:
                response = supabase.table('matches').insert(test_data).execute()
                print(f"✅ Test {i} SUCCESS! Required fields found.")
                # Clean up if successful
                if response.data:
                    supabase.table('matches').delete().eq('id', response.data[0]['id']).execute()
                break
            except Exception as e:
                error_msg = str(e)
                if "violates not-null constraint" in error_msg:
                    # Extract missing field
                    if 'column "' in error_msg:
                        missing_field = error_msg.split('column "')[1].split('"')[0]
                        print(f"❌ Test {i} FAILED: Missing required field '{missing_field}'")
                elif "violates foreign key constraint" in error_msg:
                    print(f"✅ Test {i} PASSED constraints but FK failed (expected)")
                    break
                elif "does not exist" in error_msg:
                    field = error_msg.split('column "')[1].split('"')[0] if 'column "' in error_msg else "unknown"
                    print(f"❌ Test {i} FAILED: Field '{field}' does not exist")
                else:
                    print(f"🔍 Test {i} OTHER ERROR: {error_msg[:100]}")
                    
    except Exception as e:
        print(f"❌ Error accessing table: {e}")

if __name__ == "__main__":
    check_matches_directly()