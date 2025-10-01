#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fix User Rank Default Issue
Sửa lỗi user mới có rank "E" (Huyền thoại) thay vì NULL (Unranked)
"""

import json
import requests

def load_config():
    """Load Supabase configuration"""
    try:
        with open('env.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ File env.json not found!")
        return None

def fix_rank_default_issue():
    """Fix the rank default issue in database"""
    
    print("🔧 FIXING USER RANK DEFAULT ISSUE")
    print("=" * 50)
    
    config = load_config()
    if not config:
        return False
    
    SUPABASE_URL = config['SUPABASE_URL']
    SERVICE_ROLE_KEY = config['SUPABASE_SERVICE_ROLE_KEY']
    
    headers = {
        'apikey': SERVICE_ROLE_KEY,
        'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Step 1: Check current situation
    print("📋 Step 1: Checking current users with problematic ranks...")
    
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/users",
        headers=headers,
        params={
            'select': 'id,full_name,rank,elo_rating,created_at',
            'order': 'created_at.desc',
            'limit': 20
        }
    )
    
    if response.status_code != 200:
        print(f"❌ Failed to query users: {response.status_code}")
        return False
    
    users = response.json()
    print(f"✅ Found {len(users)} recent users")
    
    # Find users with problematic ranks (E rank but low ELO)
    problematic_users = []
    for user in users:
        rank = user.get('rank')
        elo = user.get('elo_rating', 1200)
        created_at = user.get('created_at', '')
        
        # If user has E rank but ELO is default (1200 or lower), it's likely wrong
        if rank == 'E' and elo <= 1200:
            problematic_users.append(user)
            print(f"🚨 Found problematic user: {user.get('full_name')} - Rank: {rank}, ELO: {elo}")
    
    if not problematic_users:
        print("✅ No problematic users found!")
        return True
    
    # Step 2: Fix the users
    print(f"\n🔧 Step 2: Fixing {len(problematic_users)} problematic users...")
    
    fixed_count = 0
    for user in problematic_users:
        user_id = user['id']
        
        # Set rank to NULL (unranked)
        update_response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/users",
            headers=headers,
            params={'id': f'eq.{user_id}'},
            json={'rank': None}  # Set to NULL
        )
        
        if update_response.status_code in [200, 204]:
            print(f"✅ Fixed user: {user.get('full_name')} - Set rank to NULL (Unranked)")
            fixed_count += 1
        else:
            print(f"❌ Failed to fix user: {user.get('full_name')} - Status: {update_response.status_code}")
    
    # Step 3: Check database default value and fix if needed
    print(f"\n🛠️ Step 3: Checking and fixing database default rank value...")
    
    # We can't directly alter table via REST API, but let's create a script
    fix_sql = """
-- Fix database default rank value
-- Remove any default value for rank column (should be NULL for new users)
ALTER TABLE users ALTER COLUMN rank DROP DEFAULT;

-- Add comment to clarify NULL means unranked
COMMENT ON COLUMN users.rank IS 'User rank: K, K+, I, I+, H, H+, G, G+, F, F+, E, E+. NULL means unranked.';
"""
    
    print("📝 SQL to fix database schema:")
    print(fix_sql)
    print("\n⚠️  Please run this SQL manually in Supabase Dashboard:")
    print("   1. Go to Supabase Dashboard > SQL Editor")
    print("   2. Copy and paste the SQL above")
    print("   3. Execute it")
    
    print(f"\n🎉 SUMMARY:")
    print(f"   ✅ Fixed {fixed_count} users (set rank to NULL)")
    print(f"   📝 SQL script provided for schema fix")
    print(f"   🔍 New users should now be unranked by default")
    
    return True

if __name__ == "__main__":
    fix_rank_default_issue()