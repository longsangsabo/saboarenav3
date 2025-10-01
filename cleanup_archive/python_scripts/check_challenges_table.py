#!/usr/bin/env python3
"""
Check challenges table schema and test open challenge insertion
"""
import os
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def main():
    # Initialize Supabase client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    print("🔍 Checking challenges table schema...")
    
    try:
        # Get table information
        result = supabase.rpc('get_table_info', {'table_name': 'challenges'}).execute()
        print("✅ Table info retrieved successfully")
        
        # Check if we can see any challenges
        challenges = supabase.table('challenges').select('*').limit(5).execute()
        print(f"📊 Found {len(challenges.data)} existing challenges")
        
        # Try to insert test open challenge
        print("\n🧪 Testing open challenge insertion...")
        test_data = {
            'challenger_id': '8dc68b2e-8c94-47d7-a2d7-a70b218c32a8',  # Test user
            'challenged_id': None,  # Open challenge
            'challenge_type': 'thach_dau',
            'message': 'Test open challenge',
            'stakes_type': 'spa_points',
            'stakes_amount': 100,
            'match_conditions': {
                'game_type': '8-ball',
                'location': 'Test Location',
                'scheduled_time': '2025-09-26T10:00:00Z',
                'handicap': 0,
            },
            'status': 'pending',
            'handicap_challenger': 0.0,
            'handicap_challenged': 0.0,
            'rank_difference': 0,
        }
        
        result = supabase.table('challenges').insert(test_data).execute()
        print("✅ Open challenge inserted successfully!")
        print(f"Challenge ID: {result.data[0]['id']}")
        
        # Clean up - delete the test challenge
        supabase.table('challenges').delete().eq('id', result.data[0]['id']).execute()
        print("🧹 Test challenge cleaned up")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        print("This might indicate a schema issue or RLS policy problem")

if __name__ == "__main__":
    main()