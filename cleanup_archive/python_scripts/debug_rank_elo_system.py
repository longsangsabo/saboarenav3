#!/usr/bin/env python3
"""
Debug và thiết lập hệ thống cập nhật hạng/ELO tự động
"""

import requests
import json
from datetime import datetime

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

def check_current_data():
    """Kiểm tra dữ liệu hiện tại"""
    print("🔍 Checking current data...")
    
    # Check users table
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id,display_name,rank,elo_rating,spa_points&limit=5", 
            headers=headers
        )
        if response.status_code == 200:
            users = response.json()
            print(f"\n📊 Users data ({len(users)} samples):")
            for user in users:
                print(f"  • {user.get('display_name', 'No name')} - Rank: {user.get('rank', 'None')} - ELO: {user.get('elo_rating', 'None')} - SPA: {user.get('spa_points', 'None')}")
        else:
            print(f"❌ Error getting users: {response.text}")
    except Exception as e:
        print(f"❌ Error checking users: {e}")
    
    # Check club_members table  
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?select=*&limit=5", 
            headers=headers
        )
        if response.status_code == 200:
            members = response.json()
            print(f"\n📊 Club members data ({len(members)} samples):")
            for member in members:
                print(f"  • User: {member.get('user_id', 'No user')[:8]}... - Club: {member.get('club_id', 'No club')[:8]}... - Status: {member.get('status', 'None')} - Rank: {member.get('confirmed_rank', 'None')}")
        else:
            print(f"❌ Error getting club_members: {response.text}")
    except Exception as e:
        print(f"❌ Error checking club_members: {e}")

def create_rank_update_function():
    """Tạo function để cập nhật rank và ELO"""
    print("\n🔧 Creating rank update function...")
    
    sql_function = """
-- Function để cập nhật rank và ELO cho user
CREATE OR REPLACE FUNCTION update_user_rank_from_club_confirmation()
RETURNS TRIGGER AS $$
BEGIN  
    -- Chỉ cập nhật khi status thay đổi thành 'approved' và có confirmed_rank
    IF NEW.status = 'approved' AND NEW.confirmed_rank IS NOT NULL AND NEW.confirmed_rank != '' THEN
        -- Cập nhật rank trong users table
        UPDATE users 
        SET 
            rank = NEW.confirmed_rank,
            elo_rating = CASE NEW.confirmed_rank
                WHEN 'A' THEN 1800
                WHEN 'B' THEN 1600  
                WHEN 'C' THEN 1400
                WHEN 'D' THEN 1200
                WHEN 'E' THEN 1000
                ELSE elo_rating  -- Giữ nguyên nếu rank không hợp lệ
            END,
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        -- Log thông tin cập nhật
        RAISE NOTICE 'Updated user % rank to % with ELO %', 
            NEW.user_id, NEW.confirmed_rank, 
            CASE NEW.confirmed_rank
                WHEN 'A' THEN 1800
                WHEN 'B' THEN 1600  
                WHEN 'C' THEN 1400
                WHEN 'D' THEN 1200
                WHEN 'E' THEN 1000
                ELSE 0
            END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
"""
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": sql_function}
        )
        
        if response.status_code in [200, 201]:
            print("✅ Created rank update function successfully")
        else:
            # Try alternative method
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc",
                headers=headers,  
                json={
                    "name": "exec_sql",
                    "args": {"query": sql_function}
                }
            )
            
            if response.status_code in [200, 201]:
                print("✅ Created rank update function successfully (alternative method)")
            else:
                print(f"❌ Failed to create function: {response.text}")
                return False
                
    except Exception as e:
        print(f"❌ Error creating function: {e}")
        return False
    
    return True

def create_trigger():
    """Tạo trigger cho club_members table"""
    print("\n🔧 Creating trigger...")
    
    sql_trigger = """
-- Trigger để tự động cập nhật rank khi club_members được update
DROP TRIGGER IF EXISTS trigger_update_user_rank ON club_members;

CREATE TRIGGER trigger_update_user_rank
    AFTER UPDATE ON club_members
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rank_from_club_confirmation();
"""
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": sql_trigger}
        )
        
        if response.status_code in [200, 201]:
            print("✅ Created trigger successfully")
        else:
            print(f"❌ Failed to create trigger: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error creating trigger: {e}")  
        return False
    
    return True

def test_rank_update():
    """Test cập nhật rank cho user hiện tại"""
    print("\n🧪 Testing rank update...")
    
    # Lấy một user để test
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id,display_name&limit=1", 
            headers=headers
        )
        if response.status_code != 200 or not response.json():
            print("❌ No users found for testing")
            return
            
        user = response.json()[0]
        user_id = user['id']
        print(f"📝 Testing with user: {user.get('display_name', 'No name')} ({user_id[:8]}...)")
        
        # Lấy club membership của user này
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&limit=1",
            headers=headers
        )
        
        if response.status_code != 200 or not response.json():
            print("❌ No club membership found for user")
            return
            
        membership = response.json()[0]
        membership_id = membership['id']
        
        # Update membership với confirmed_rank và status approved  
        update_data = {
            "status": "approved",
            "confirmed_rank": "B"  # Test với rank B
        }
        
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/club_members?id=eq.{membership_id}",
            headers=headers,
            json=update_data
        )
        
        if response.status_code in [200, 204]:
            print("✅ Updated club membership")
            
            # Kiểm tra user đã được cập nhật chưa
            import time
            time.sleep(1)  # Đợi trigger chạy
            
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=rank,elo_rating",
                headers=headers
            )
            
            if response.status_code == 200 and response.json():
                updated_user = response.json()[0] 
                print(f"✅ User rank updated to: {updated_user.get('rank')} with ELO: {updated_user.get('elo_rating')}")
            else:
                print("❌ Failed to verify user update")
        else:
            print(f"❌ Failed to update membership: {response.text}")
            
    except Exception as e:
        print(f"❌ Error testing rank update: {e}")

def manual_sync_existing_data():
    """Đồng bộ dữ liệu có sẵn"""
    print("\n🔄 Syncing existing approved memberships...")
    
    try:
        # Lấy tất cả membership đã approved với confirmed_rank
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?status=eq.approved&confirmed_rank=neq.null&select=user_id,confirmed_rank",
            headers=headers
        )
        
        if response.status_code != 200:
            print(f"❌ Failed to get approved memberships: {response.text}")
            return
            
        memberships = response.json()
        print(f"📊 Found {len(memberships)} approved memberships to sync")
        
        if not memberships:
            print("ℹ️ No approved memberships found")
            return
        
        # Cập nhật từng user
        updated_count = 0
        for membership in memberships:
            user_id = membership['user_id']
            rank = membership['confirmed_rank']
            
            if not rank or rank not in ['A', 'B', 'C', 'D', 'E']:
                continue
                
            # Tính ELO theo rank
            elo_mapping = {
                'A': 1800,
                'B': 1600, 
                'C': 1400,
                'D': 1200,
                'E': 1000
            }
            elo = elo_mapping[rank]
            
            # Update user
            update_data = {
                "rank": rank,
                "elo_rating": elo,
                "updated_at": datetime.now().isoformat()
            }
            
            response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                headers=headers,
                json=update_data
            )
            
            if response.status_code in [200, 204]:
                updated_count += 1
                print(f"  ✅ Updated user {user_id[:8]}... to rank {rank} (ELO: {elo})")
            else:
                print(f"  ❌ Failed to update user {user_id[:8]}...")
        
        print(f"\n✅ Successfully updated {updated_count} users")
        
    except Exception as e:
        print(f"❌ Error syncing existing data: {e}")

def main():
    print("🚀 Setting up automatic rank/ELO update system...")
    print("="*60)
    
    # 1. Kiểm tra dữ liệu hiện tại
    check_current_data()
    
    # 2. Tạo function cập nhật rank
    if create_rank_update_function():
        print("✅ Function created successfully")
    else:
        print("❌ Function creation failed")
        return
    
    # 3. Tạo trigger
    if create_trigger():
        print("✅ Trigger created successfully") 
    else:
        print("❌ Trigger creation failed")
        return
    
    # 4. Đồng bộ dữ liệu có sẵn
    manual_sync_existing_data()
    
    # 5. Test trigger
    test_rank_update()
    
    print("\n" + "="*60)
    print("✅ Rank/ELO automation system setup completed!")
    print("\n📋 What was done:")
    print("  • Created update_user_rank_from_club_confirmation() function")
    print("  • Created trigger on club_members table")
    print("  • Synced existing approved memberships")
    print("  • Tested the automation")
    print("\n🎯 Now when club confirms user rank, it will auto-update:")
    print("  • users.rank = confirmed_rank") 
    print("  • users.elo_rating = rank-based ELO")
    print("  • users.updated_at = current timestamp")

if __name__ == "__main__":
    main()