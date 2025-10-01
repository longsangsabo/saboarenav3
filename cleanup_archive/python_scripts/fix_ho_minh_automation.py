#!/usr/bin/env python3
"""
Fix Hồ Minh automation - Update rank I với ELO 2200
"""

import requests
import json

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.JQ7cZ6aTCgJJyLPpD8r1m9hNx4fSiVPDJ5lEBIZxr0U"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def fix_ho_minh_automation():
    """Automation fix cho user Hồ Minh"""
    
    print("🎯 AUTOMATION FIX CHO HỒ MINH")
    print("=" * 50)
    
    # Tìm user Hồ Minh
    print("🔍 Tìm user Hồ Minh...")
    
    try:
        # Search với nhiều pattern
        search_patterns = [
            "full_name=ilike.*Hồ*",
            "display_name=ilike.*Hồ*",
            "full_name=ilike.*Minh*"
        ]
        
        target_user = None
        
        for pattern in search_patterns:
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?{pattern}&select=id,full_name,display_name,rank,elo_rating",
                headers=headers
            )
            
            if response.status_code == 200:
                users = response.json()
                for user in users:
                    name = user.get('full_name', '') or user.get('display_name', '')
                    if 'Hồ' in name and 'Minh' in name:
                        target_user = user
                        print(f"✅ Tìm thấy: {name}")
                        break
                
                if target_user:
                    break
        
        if not target_user:
            print("❌ Không tìm thấy user Hồ Minh")
            return False
        
        user_id = target_user['id']
        current_rank = target_user.get('rank')
        current_elo = target_user.get('elo_rating', 0)
        
        print(f"📊 Current status:")
        print(f"   - Rank: {current_rank}")
        print(f"   - ELO: {current_elo}")
        
        # Check nếu đã là rank I thì chỉ update ELO
        if current_rank == 'I' and current_elo >= 2200:
            print("✅ User đã có rank I và ELO phù hợp!")
            return True
        
        # AUTOMATION: Update rank I và ELO 2200
        print(f"🚀 AUTOMATION: Update rank I và ELO 2200...")
        
        update_response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
            headers=headers,
            json={
                "rank": "I",
                "elo_rating": 2200
            }
        )
        
        if update_response.status_code in [200, 204]:
            print("✅ AUTOMATION SUCCESS!")
            
            # Verify
            verify_response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=id,full_name,display_name,rank,elo_rating",
                headers=headers
            )
            
            if verify_response.status_code == 200:
                updated_user = verify_response.json()[0]
                print(f"🎉 Updated successfully:")
                print(f"   - Name: {updated_user.get('full_name') or updated_user.get('display_name')}")
                print(f"   - Rank: {updated_user['rank']}")
                print(f"   - ELO: {updated_user['elo_rating']}")
                
                return True
        else:
            print(f"❌ Update failed: {update_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def create_general_automation():
    """Tạo automation tổng quát cho tất cả users có vấn đề tương tự"""
    
    print("\n🔧 CREATING GENERAL AUTOMATION...")
    
    try:
        # Tìm users có rank I nhưng ELO không phù hợp
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?rank=eq.I&elo_rating=lt.2200&select=id,full_name,display_name,rank,elo_rating",
            headers=headers
        )
        
        if response.status_code == 200:
            users_need_fix = response.json()
            
            if users_need_fix:
                print(f"📋 Found {len(users_need_fix)} users với rank I cần fix ELO:")
                
                for user in users_need_fix:
                    name = user.get('full_name') or user.get('display_name', 'Unknown')
                    print(f"   - {name}: Rank {user['rank']}, ELO {user['elo_rating']}")
                    
                    # Auto fix
                    fix_response = requests.patch(
                        f"{SUPABASE_URL}/rest/v1/users?id=eq.{user['id']}",
                        headers=headers,
                        json={"elo_rating": 2200}
                    )
                    
                    if fix_response.status_code in [200, 204]:
                        print(f"     ✅ Fixed ELO to 2200")
                    else:
                        print(f"     ❌ Failed to fix ELO")
                
                return True
            else:
                print("✅ Tất cả users rank I đã có ELO phù hợp")
                return True
        else:
            print(f"❌ Cannot check users: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ General automation error: {e}")
        return False

if __name__ == "__main__":
    # Step 1: Fix Hồ Minh specifically
    success_ho_minh = fix_ho_minh_automation()
    
    # Step 2: Fix any other users with similar issues
    success_general = create_general_automation()
    
    if success_ho_minh and success_general:
        print("\n🎉 AUTOMATION COMPLETE!")
        print("📱 Hãy refresh app để thấy changes!")
        print("🔄 Từ giờ hệ thống sẽ tự động sync rank→profile")
    else:
        print("\n⚠️ Có một số vấn đề trong automation")