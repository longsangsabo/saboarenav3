#!/usr/bin/env python3
"""
Fix user 'sabo' - Reset to correct new user defaults
- ELO: 1000 (instead of 1200)
- Rank: NULL (instead of 'E')
"""

import os
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

# Try to get service key from environment, fallback to anon key
SUPABASE_KEY = os.getenv('SUPABASE_SERVICE_KEY', SUPABASE_ANON_KEY)

def main():
    print("🔧 Fixing user 'sabo' with correct new user defaults...")
    
    try:
        # Initialize Supabase client
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # 1. Find user 'sabo'
        print("\n1️⃣ Finding user 'sabo'...")
        result = supabase.table('user_profiles').select('*').eq('username', 'sabo').execute()
        
        if not result.data:
            print("❌ User 'sabo' not found")
            return
        
        user = result.data[0]
        print(f"✅ Found user: {user['username']}")
        print(f"   Current ELO: {user.get('elo_rating', 'NULL')}")
        print(f"   Current Rank: {user.get('rank', 'NULL')}")
        
        # 2. Update user with correct defaults
        print("\n2️⃣ Updating user 'sabo' with correct defaults...")
        
        update_data = {
            'elo_rating': 1000,  # Correct starting ELO
            'rank': None,        # No rank for new users
        }
        
        update_result = supabase.table('user_profiles').update(update_data).eq('username', 'sabo').execute()
        
        if update_result.data:
            print("✅ User 'sabo' updated successfully!")
            updated_user = update_result.data[0]
            print(f"   New ELO: {updated_user.get('elo_rating', 'NULL')}")
            print(f"   New Rank: {updated_user.get('rank', 'NULL')}")
        else:
            print("❌ Failed to update user")
            
        # 3. Verify the update
        print("\n3️⃣ Verifying update...")
        verify_result = supabase.table('user_profiles').select('username, elo_rating, rank').eq('username', 'sabo').execute()
        
        if verify_result.data:
            verified_user = verify_result.data[0]
            print("✅ Verification successful:")
            print(f"   Username: {verified_user['username']}")
            print(f"   ELO Rating: {verified_user.get('elo_rating', 'NULL')}")
            print(f"   Rank: {verified_user.get('rank', 'NULL')}")
            
            # Check if values are correct
            if verified_user.get('elo_rating') == 1000 and verified_user.get('rank') is None:
                print("🎉 User 'sabo' now has correct new user defaults!")
            else:
                print("⚠️ Values don't match expected defaults")
        else:
            print("❌ Verification failed")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()