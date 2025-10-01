#!/usr/bin/env python3
"""
Test hệ thống rank/ELO automation với cấu trúc database thực tế
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

def test_confirm_rank_function():
    """Test function confirm_user_rank"""
    print("🧪 Testing confirm_user_rank function...")
    
    try:
        # Lấy user đầu tiên
        response = requests.get(f"{SUPABASE_URL}/rest/v1/users?limit=1", headers=headers)
        if response.status_code != 200 or not response.json():
            print("❌ No users found")
            return False
            
        user = response.json()[0]
        user_id = user['id']
        display_name = user.get('display_name', 'No name')
        
        # Lấy club đầu tiên
        response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?limit=1", headers=headers)
        if response.status_code != 200 or not response.json():
            print("❌ No clubs found") 
            return False
            
        club = response.json()[0]
        club_id = club['id']
        club_name = club.get('name', 'No name')
        
        print(f"📝 Testing with:")
        print(f"  • User: {display_name} ({user_id[:8]}...)")
        print(f"  • Club: {club_name} ({club_id[:8]}...)")
        
        # Test function confirm_user_rank
        function_params = {
            "p_user_id": user_id,
            "p_club_id": club_id,
            "p_confirmed_rank": "B"
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/confirm_user_rank",
            headers=headers,
            json=function_params
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Function result: {result}")
            
            # Kiểm tra user đã được cập nhật chưa
            time.sleep(1)
            
            check_response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=display_name,rank,elo_rating",
                headers=headers
            )
            
            if check_response.status_code == 200 and check_response.json():
                updated_user = check_response.json()[0]
                new_rank = updated_user.get('rank')
                new_elo = updated_user.get('elo_rating')
                
                print(f"📊 User after update:")
                print(f"  • Rank: {new_rank}")
                print(f"  • ELO: {new_elo}")
                
                if new_rank == 'B' and new_elo == 1600:
                    print("🎉 SUCCESS! Automation is working perfectly!")
                    return True
                else:
                    print("⚠️ Partial success - values updated but not as expected")
                    return False
            else:
                print("❌ Failed to verify user update")
                return False
        else:
            print(f"❌ Function call failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing function: {e}")
        return False

def test_get_users_without_rank():
    """Test function get_users_without_rank"""
    print("\n📋 Testing get_users_without_rank function...")
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/get_users_without_rank",
            headers=headers,
            json={}
        )
        
        if response.status_code == 200:
            users = response.json()
            print(f"👥 Users without rank: {len(users)}")
            
            for i, user in enumerate(users[:5], 1):
                user_id = user.get('user_id', 'No ID')[:8]
                display_name = user.get('display_name', 'No name')
                club_name = user.get('club_name', 'No club')
                status = user.get('membership_status', 'No status')
                print(f"  {i}. {display_name} @ {club_name} ({status}) - {user_id}...")
                
            return True
        else:
            print(f"❌ Function call failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing function: {e}")
        return False

def show_current_rank_distribution():
    """Hiển thị phân bố rank hiện tại"""
    print("\n📊 Current rank distribution:")
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=display_name,rank,elo_rating",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            
            rank_counts = {}
            for user in users:
                rank = user.get('rank') or 'None'
                rank_counts[rank] = rank_counts.get(rank, 0) + 1
            
            print("Rank distribution:")
            for rank, count in sorted(rank_counts.items()):
                print(f"  • {rank}: {count} users")
                
            # Show some examples
            print("\nExamples:")
            for user in users[:5]:
                name = user.get('display_name', 'No name')[:15]
                rank = user.get('rank') or 'None'
                elo = user.get('elo_rating', 0)
                print(f"  • {name:15} | {rank:4} | ELO: {elo:4}")
                
        else:
            print(f"❌ Error getting users: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def test_direct_trigger():
    """Test trigger trực tiếp bằng cách update club_members"""
    print("\n🔧 Testing trigger directly...")
    
    try:
        # Lấy một membership để test
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?limit=1",
            headers=headers
        )
        
        if response.status_code != 200 or not response.json():
            print("❌ No club memberships found")
            return False
            
        member = response.json()[0]
        member_id = member['id']
        user_id = member['user_id']
        
        print(f"📝 Testing with membership: {member_id[:8]}...")
        print(f"  User: {user_id[:8]}...")
        
        # Update membership để trigger chạy
        update_data = {
            "confirmed_rank": "C",
            "approval_status": "approved"
        }
        
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/club_members?id=eq.{member_id}",
            headers=headers,
            json=update_data
        )
        
        if response.status_code in [200, 204]:
            print("✅ Updated membership")
            
            # Đợi trigger chạy
            time.sleep(2)
            
            # Kiểm tra user
            check_response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=display_name,rank,elo_rating",
                headers=headers
            )
            
            if check_response.status_code == 200 and check_response.json():
                updated_user = check_response.json()[0]
                new_rank = updated_user.get('rank')
                new_elo = updated_user.get('elo_rating')
                name = updated_user.get('display_name', 'No name')
                
                print(f"📊 User {name} after trigger:")
                print(f"  • Rank: {new_rank}")
                print(f"  • ELO: {new_elo}")
                
                if new_rank == 'C' and new_elo == 1400:
                    print("🎉 TRIGGER SUCCESS! Direct update worked!")
                    return True
                else:
                    print("⚠️ Trigger may not be working properly")
                    return False
            else:
                print("❌ Failed to verify user after trigger")
                return False
        else:
            print(f"❌ Failed to update membership: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing trigger: {e}")
        return False

def main():
    print("🚀 TESTING RANK/ELO AUTOMATION SYSTEM")
    print("=" * 60)
    print("⚠️  Make sure you've run 'rank_elo_automation_real.sql' first!")
    print("=" * 60)
    
    # 1. Hiển thị trạng thái hiện tại
    show_current_rank_distribution()
    
    # 2. Test function get_users_without_rank
    success1 = test_get_users_without_rank()
    
    # 3. Test function confirm_user_rank
    success2 = test_confirm_rank_function()
    
    # 4. Test trigger trực tiếp
    success3 = test_direct_trigger()
    
    # 5. Tóm tắt kết quả
    print("\n" + "=" * 60)
    print("📋 TEST RESULTS:")
    print(f"  • get_users_without_rank: {'✅' if success1 else '❌'}")
    print(f"  • confirm_user_rank: {'✅' if success2 else '❌'}")
    print(f"  • direct trigger: {'✅' if success3 else '❌'}")
    
    if success1 and success2 and success3:
        print("\n🎉 ALL TESTS PASSED!")
        print("✅ Rank/ELO automation system is fully functional!")
        
        print("\n💡 How to use:")
        print("  1. Admin calls: confirm_user_rank(user_id, club_id, 'B')")
        print("  2. Or directly update club_members table")
        print("  3. User profile automatically shows new rank & ELO")
    else:
        print("\n❌ SOME TESTS FAILED")
        print("Please check the SQL script and database structure")
        
    # 6. Hiển thị trạng thái cuối
    show_current_rank_distribution()

if __name__ == "__main__":
    main()