#!/usr/bin/env python3
"""
Check match_status enum values in Supabase database
"""

import os
from supabase import create_client

def check_match_status_enum():
    # Supabase credentials
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    # Initialize Supabase client
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    try:
        print("🔍 Checking match_status enum values...")
        
        # Query to get enum values
        result = supabase.rpc('get_enum_values', {
            'enum_name': 'match_status'
        }).execute()
        
        if result.data:
            print(f"✅ Found enum values: {result.data}")
        else:
            print("❌ Could not get enum values via RPC")
            
            # Alternative: try to get from information_schema
            print("🔍 Trying alternative method...")
            
            # Try to query a match to see what status values exist
            matches = supabase.table('matches').select('status').limit(10).execute()
            if matches.data:
                statuses = set([m.get('status') for m in matches.data if m.get('status')])
                print(f"📊 Existing status values in matches table: {list(statuses)}")
            
            # Try to insert a test match with different status values to see what works
            test_statuses = ['pending', 'scheduled', 'in_progress', 'completed', 'cancelled']
            valid_statuses = []
            
            for status in test_statuses:
                try:
                    # Try to insert a dummy match (will fail but we can see the error)
                    supabase.table('matches').insert({
                        'tournament_id': '00000000-0000-0000-0000-000000000000',
                        'status': status,
                        'round_number': 1,
                        'match_number': 999
                    }).execute()
                    valid_statuses.append(status)
                    print(f"✅ Status '{status}' is valid")
                except Exception as e:
                    if "Invalid input value for enum" in str(e):
                        print(f"❌ Status '{status}' is invalid")
                    elif "violates foreign key constraint" in str(e) or "violates not-null constraint" in str(e):
                        valid_statuses.append(status)
                        print(f"✅ Status '{status}' is valid (failed for other reasons)")
                    else:
                        print(f"⚠️  Status '{status}' - other error: {str(e)[:100]}")
            
            print(f"\n📋 Summary of valid status values: {valid_statuses}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_match_status_enum()