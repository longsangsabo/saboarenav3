#!/usr/bin/env python3
"""
Check actual matches table structure on Supabase
"""

import os
from supabase import create_client

def check_matches_table_structure():
    # Supabase credentials
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"
    
    # Initialize Supabase client
    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    try:
        print("🔍 Checking actual matches table structure...")
        
        # Get table structure from information_schema
        result = supabase.rpc('get_table_structure', {
            'table_name': 'matches'
        }).execute()
        
        if result.data:
            print("✅ Table structure from RPC:")
            for column in result.data:
                print(f"  {column}")
        else:
            print("❌ RPC failed, using alternative method...")
            
            # Alternative: Try to insert a test record to see what fields are required
            print("\n🧪 Testing required fields by attempting insert...")
            
            # Try minimal insert
            try:
                response = supabase.table('matches').insert({
                    'tournament_id': '00000000-0000-0000-0000-000000000000'
                }).execute()
                print("✅ Minimal insert worked!")
            except Exception as e:
                error_msg = str(e)
                if "violates not-null constraint" in error_msg:
                    print(f"❌ Required field missing: {error_msg}")
                elif "violates foreign key constraint" in error_msg:
                    print(f"⚠️  Foreign key issue: {error_msg}")
                else:
                    print(f"🔍 Other error: {error_msg}")
            
            # Try with common required fields
            test_data = {
                'tournament_id': '00000000-0000-0000-0000-000000000000',
                'player1_id': '00000000-0000-0000-0000-000000000001', 
                'player2_id': '00000000-0000-0000-0000-000000000002',
                'round_number': 1,
                'match_number': 1,
                'status': 'pending'
            }
            
            for field, value in test_data.items():
                try:
                    test_insert = {k: v for k, v in test_data.items() if k == field or k == 'tournament_id'}
                    response = supabase.table('matches').insert(test_insert).execute()
                    print(f"✅ Field '{field}' accepted")
                except Exception as e:
                    error_msg = str(e)
                    if "violates not-null constraint" in error_msg:
                        # Extract the missing field name
                        if 'column "' in error_msg and '" of relation' in error_msg:
                            missing_field = error_msg.split('column "')[1].split('" of relation')[0]
                            print(f"❌ Field '{field}' requires: {missing_field}")
                    elif "does not exist" in error_msg:
                        print(f"❌ Field '{field}' does not exist in table")
                    else:
                        print(f"🔍 Field '{field}' error: {error_msg[:100]}")
            
            # Get existing matches to see actual structure
            print("\n📊 Checking existing matches for actual field names...")
            existing = supabase.table('matches').select('*').limit(1).execute()
            if existing.data:
                print("✅ Actual fields in matches table:")
                for key in existing.data[0].keys():
                    print(f"  - {key}")
            else:
                print("📝 No existing matches found")
                
            # Check enum values
            print("\n🎯 Testing match_status enum values...")
            valid_statuses = []
            for status in ['pending', 'in_progress', 'completed', 'scheduled', 'cancelled']:
                try:
                    supabase.table('matches').insert({
                        'tournament_id': '00000000-0000-0000-0000-000000000000',
                        'player1_id': '00000000-0000-0000-0000-000000000001',
                        'player2_id': '00000000-0000-0000-0000-000000000002', 
                        'round_number': 1,
                        'match_number': 1,
                        'status': status
                    }).execute()
                    valid_statuses.append(status)
                except Exception as e:
                    if "Invalid input value for enum" in str(e):
                        print(f"❌ Status '{status}' is invalid")
                    elif "violates foreign key constraint" in str(e):
                        valid_statuses.append(status)
                        print(f"✅ Status '{status}' is valid (FK error expected)")
                    else:
                        print(f"🔍 Status '{status}': {str(e)[:50]}...")
            
            print(f"\n✅ Valid match_status values: {valid_statuses}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_matches_table_structure()