#!/usr/bin/env python3
"""
Check user 'bosa' ELO issue - investigate why new user has ELO 1200
"""

import os
from supabase import create_client, Client

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def main():
    print("🔍 Checking user 'bosa' ELO issue...")
    
    try:
        # Initialize Supabase client
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
        
        # 1. Check user 'bosa' data
        print("\n1️⃣ Checking user 'bosa' data...")
        
        # Try different table names
        table_names = ['users', 'user_profiles', 'profiles']
        user_data = None
        
        for table_name in table_names:
            try:
                result = supabase.table(table_name).select('*').eq('username', 'bosa').execute()
                if result.data:
                    print(f"✅ Found user 'bosa' in table '{table_name}'")
                    user_data = result.data[0]
                    break
            except Exception as e:
                print(f"❌ Table '{table_name}' not found or error: {e}")
                continue
        
        if not user_data:
            print("❌ User 'bosa' not found in any table")
            return
        
        print(f"\n📊 User 'bosa' current data:")
        for key, value in user_data.items():
            if key in ['username', 'elo_rating', 'rank', 'created_at', 'id']:
                print(f"   {key}: {value}")
        
        # 2. Check if user was created recently
        print(f"\n2️⃣ User creation analysis:")
        created_at = user_data.get('created_at', 'Unknown')
        elo_rating = user_data.get('elo_rating', 'NULL')
        rank = user_data.get('rank', 'NULL')
        
        print(f"   Created at: {created_at}")
        print(f"   ELO Rating: {elo_rating}")
        print(f"   Rank: {rank}")
        
        # 3. Expected vs Actual
        print(f"\n3️⃣ Analysis:")
        if elo_rating == 1200:
            print("❌ ISSUE FOUND: User has ELO 1200 (old hardcoded value)")
            print("✅ EXPECTED: ELO should be 1000 for new users")
        elif elo_rating == 1000:
            print("✅ ELO is correct (1000 for new users)")
        else:
            print(f"⚠️ Unexpected ELO value: {elo_rating}")
        
        if rank == 'E':
            print("❌ ISSUE FOUND: User has rank 'E' (Huyền thoại)")
            print("✅ EXPECTED: Rank should be NULL for new users")
        elif rank is None or rank == 'NULL':
            print("✅ Rank is correct (NULL for new users)")
        else:
            print(f"⚠️ Unexpected rank value: {rank}")
            
        # 4. Recommendations
        print(f"\n4️⃣ Recommendations:")
        if elo_rating == 1200 or rank == 'E':
            print("🔧 Need to fix user 'bosa' data:")
            print("   - Set ELO to 1000")
            print("   - Set rank to NULL")
            print("   - This indicates registration service may still have old hardcoded values")
        else:
            print("✅ User data looks correct")
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    main()