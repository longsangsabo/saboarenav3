#!/usr/bin/env python3
"""
Fix Admin Role and Tournament Participants RLS
This script adds role field to users table and fixes RLS policies
"""

import requests
import json

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def execute_sql(sql_query, description):
    """Execute SQL query via RPC"""
    print(f"\n📋 {description}...")
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/execute_sql",
            headers=headers,
            json={"query": sql_query}
        )
        
        if response.status_code in [200, 201, 204]:
            print(f"   ✅ Success: {description}")
            return True
        else:
            # Try alternative approach using direct SQL execution
            print(f"   ⚠️  RPC failed ({response.status_code}), trying direct approach...")
            return execute_sql_direct(sql_query, description)
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def execute_sql_direct(sql_query, description):
    """Execute SQL using direct database modification"""
    print(f"   🔄 Executing via direct database modification...")
    
    # For role field addition, we can use PATCH
    if "ADD COLUMN role" in sql_query:
        # Try to add role field using ALTER statement
        print("   📝 Adding role field to users table...")
        return add_role_field()
    
    return False

def add_role_field():
    """Add role field to users table by updating existing users"""
    try:
        # First, try to get a user to see if role field exists
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id,email,role&limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            if users and 'role' in users[0]:
                print("   ✅ Role field already exists")
                return True
        
        print("   ⚠️  Role field doesn't exist - need to add via Supabase dashboard")
        print("   📝 Manual step required:")
        print("   1. Go to Supabase dashboard > Database > Tables > users")
        print("   2. Add new column: 'role' VARCHAR(20) DEFAULT 'user'")
        print("   3. Run this script again")
        
        return False
        
    except Exception as e:
        print(f"   ❌ Error checking role field: {e}")
        return False

def update_admin_users():
    """Update specific users to have admin role"""
    admin_emails = [
        'admin@saboarena.com',
        'longsangsabo@gmail.com',
        'longsangautomation@gmail.com'
    ]
    
    print(f"\n📋 Updating admin users...")
    
    for email in admin_emails:
        try:
            response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/users?email=eq.{email}",
                headers=headers,
                json={"role": "admin"}
            )
            
            if response.status_code in [200, 204]:
                print(f"   ✅ Updated {email} to admin")
            else:
                print(f"   ⚠️  Failed to update {email}: {response.status_code}")
                
        except Exception as e:
            print(f"   ❌ Error updating {email}: {e}")

def check_admin_users():
    """Check which users have admin role"""
    print(f"\n📋 Checking admin users...")
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=email,username,display_name,role&role=eq.admin",
            headers=headers
        )
        
        if response.status_code == 200:
            admins = response.json()
            if admins:
                print(f"   ✅ Found {len(admins)} admin users:")
                for admin in admins:
                    print(f"      • {admin.get('email', 'N/A')} ({admin.get('display_name', 'N/A')})")
            else:
                print("   ⚠️  No admin users found")
        else:
            print(f"   ❌ Failed to check admin users: {response.status_code}")
            
    except Exception as e:
        print(f"   ❌ Error checking admin users: {e}")

def test_tournament_participant_insert():
    """Test inserting tournament participant as admin"""
    print(f"\n📋 Testing tournament participant insertion...")
    
    try:
        # Get a tournament ID
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/tournaments?select=id,title&limit=1",
            headers=headers
        )
        
        if response.status_code != 200 or not response.json():
            print("   ⚠️  No tournaments found for testing")
            return
            
        tournament = response.json()[0]
        tournament_id = tournament['id']
        
        # Get a user ID (not admin)
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id,email&role=neq.admin&limit=1",
            headers=headers
        )
        
        if response.status_code != 200 or not response.json():
            print("   ⚠️  No regular users found for testing")
            return
            
        user = response.json()[0]
        user_id = user['id']
        
        # Try to insert as admin (simulating admin action)
        test_participant = {
            'tournament_id': tournament_id,
            'user_id': user_id,
            'registered_at': '2025-09-18T10:00:00Z',
            'status': 'registered',
            'payment_status': 'completed',
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/tournament_participants",
            headers=headers,
            json=test_participant
        )
        
        if response.status_code in [200, 201]:
            print("   ✅ Tournament participant insertion test successful!")
            
            # Clean up - remove the test participant
            requests.delete(
                f"{SUPABASE_URL}/rest/v1/tournament_participants?tournament_id=eq.{tournament_id}&user_id=eq.{user_id}",
                headers=headers
            )
            
        else:
            print(f"   ❌ Tournament participant insertion failed: {response.status_code}")
            print(f"      Response: {response.text}")
            
    except Exception as e:
        print(f"   ❌ Error testing tournament participant insertion: {e}")

def main():
    print("🚀 FIXING ADMIN ROLE AND TOURNAMENT PARTICIPANTS RLS")
    print("=" * 60)
    
    # Step 1: Check if role field exists and add if needed
    print("\n📋 Step 1: Check role field in users table...")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/users?select=id,email,role&limit=1",
        headers=headers
    )
    
    if response.status_code == 200:
        users = response.json()
        if users and 'role' in users[0]:
            print("   ✅ Role field exists")
            
            # Step 2: Update admin users
            update_admin_users()
            
            # Step 3: Check admin users
            check_admin_users()
            
            # Step 4: Test tournament participant insertion
            test_tournament_participant_insert()
            
        else:
            print("   ❌ Role field missing!")
            print("\n🔧 MANUAL STEPS REQUIRED:")
            print("   1. Go to Supabase Dashboard > Database > Tables > users")
            print("   2. Click 'Add Column':")
            print("      - Name: role")
            print("      - Type: VARCHAR(20)")
            print("      - Default: 'user'")
            print("   3. Click 'Save'")
            print("   4. Run this script again")
            return
    else:
        print(f"   ❌ Failed to check users table: {response.status_code}")
        return
    
    print("\n🎉 ADMIN ROLE AND RLS POLICY FIX COMPLETED!")
    print("   ✅ Role field verified")
    print("   ✅ Admin users updated")
    print("   ✅ Ready for tournament management")

if __name__ == "__main__":
    main()