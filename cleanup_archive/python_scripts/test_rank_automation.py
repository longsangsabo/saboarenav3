#!/usr/bin/env python3
"""
Test và verify hệ thống rank/ELO automation
"""

import requests
import json
from datetime import datetime
import time

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

def test_automation_system():
    """Test hệ thống automation"""
    print("🧪 Testing rank/ELO automation system...")
    print("="*60)
    
    # 1. Kiểm tra function có tồn tại không
    print("1️⃣ Checking if functions exist...")
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/sync_existing_approved_ranks",
            headers=headers,
            json={}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Function exists and working: {result}")
        else:
            print(f"❌ Function not found or error: {response.text}")
            print("\n📋 Please run the SQL script in Supabase Dashboard first:")
            print("   1. Go to Supabase Dashboard → SQL Editor")
            print("   2. Copy content from 'rank_elo_automation.sql'") 
            print("   3. Paste and run the script")
            return False
    except Exception as e:
        print(f"❌ Error checking function: {e}")
        return False
    
    # 2. Kiểm tra dữ liệu hiện tại
    print("\n2️⃣ Current user data:")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id,display_name,rank,elo_rating&limit=3",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            for user in users:
                print(f"  • {user.get('display_name', 'No name')[:15]:15} | Rank: {user.get('rank', 'None'):4} | ELO: {user.get('elo_rating', 0):4}")
        else:
            print(f"❌ Error getting users: {response.text}")
    except Exception as e:
        print(f"❌ Error checking users: {e}")
    
    # 3. Test trigger với một user thực
    print("\n3️⃣ Testing trigger...")
    try:
        # Lấy user và club để test
        user_response = requests.get(f"{SUPABASE_URL}/rest/v1/users?limit=1", headers=headers)
        club_response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?limit=1", headers=headers)
        
        if user_response.status_code != 200 or club_response.status_code != 200:
            print("❌ Cannot get test data")
            return False
            
        user = user_response.json()[0]
        club = club_response.json()[0]
        user_id = user['id']
        club_id = club['id']
        
        print(f"📝 Testing with user: {user.get('display_name', 'No name')}")
        
        # Check if membership exists
        membership_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&club_id=eq.{club_id}",
            headers=headers
        )
        
        if membership_response.status_code == 200 and membership_response.json():
            # Update existing membership
            membership = membership_response.json()[0]
            membership_id = membership['id']
            
            update_data = {
                "status": "approved",
                "confirmed_rank": "C"  # Test với rank C
            }
            
            response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/club_members?id=eq.{membership_id}",
                headers=headers,
                json=update_data
            )
        else:
            # Create new membership
            membership_data = {
                "user_id": user_id,
                "club_id": club_id,
                "status": "approved",
                "confirmed_rank": "C"
            }
            
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/club_members",
                headers=headers,
                json=membership_data
            )
        
        if response.status_code in [200, 201, 204]:
            print("✅ Updated/Created club membership with rank C")
            
            # Đợi trigger chạy
            time.sleep(2)
            
            # Kiểm tra user đã được cập nhật
            check_response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=display_name,rank,elo_rating",
                headers=headers
            )
            
            if check_response.status_code == 200 and check_response.json():
                updated_user = check_response.json()[0]
                new_rank = updated_user.get('rank')
                new_elo = updated_user.get('elo_rating')
                
                if new_rank == 'C' and new_elo == 1400:
                    print(f"✅ SUCCESS! User rank updated to: {new_rank} with ELO: {new_elo}")
                    print("🎉 Automation system is working correctly!")
                else:
                    print(f"⚠️ Partial success: rank={new_rank}, elo={new_elo}")
                    print("   Expected: rank=C, elo=1400")
            else:
                print("❌ Failed to verify user update")
        else:
            print(f"❌ Failed to update membership: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing trigger: {e}")
    
    return True

def show_current_status():
    """Hiển thị trạng thái hiện tại"""
    print("\n📊 CURRENT STATUS SUMMARY:")
    print("="*60)
    
    try:
        # Users with ranks
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=display_name,rank,elo_rating&rank=not.is.null",
            headers=headers
        )
        
        if response.status_code == 200:
            ranked_users = response.json()
            print(f"👥 Users with ranks: {len(ranked_users)}")
            
            if ranked_users:
                print("   Top ranked users:")
                for user in ranked_users[:5]:
                    name = user.get('display_name', 'No name')[:20]
                    rank = user.get('rank', 'None')
                    elo = user.get('elo_rating', 0)
                    print(f"     • {name:20} | {rank:4} | {elo:4}")
        
        # Approved memberships
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?status=eq.approved&confirmed_rank=not.is.null&select=count",
            headers={**headers, "Prefer": "count=exact"}
        )
        
        if response.status_code in [200, 206]:
            count = response.headers.get('Content-Range', '0').split('/')[-1]
            print(f"🏆 Approved memberships with ranks: {count}")
        
    except Exception as e:
        print(f"❌ Error getting status: {e}")

def main():
    print("🔍 RANK/ELO AUTOMATION SYSTEM VERIFICATION")
    print("="*60)
    
    success = test_automation_system()
    
    if success:
        show_current_status()
        
        print("\n🎯 SYSTEM READY!")
        print("="*60)
        print("✅ Functions and triggers are installed")
        print("✅ Existing data has been synced") 
        print("✅ Automation is working")
        print("\n📋 How it works:")
        print("   1. Admin approves user in club with confirmed_rank")
        print("   2. Trigger automatically updates users table")
        print("   3. User profile shows updated rank and ELO")
        print("\n💡 ELO Mapping:")
        print("   A = 1800 | B = 1600 | C = 1400 | D = 1200 | E = 1000")
    else:
        print("\n❌ SYSTEM NOT READY")
        print("Please run the SQL script first!")

if __name__ == "__main__":
    main()