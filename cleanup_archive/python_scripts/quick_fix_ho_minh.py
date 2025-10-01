#!/usr/bin/env python3
"""
Quick fix for Hồ Minh rank issue
"""

import requests
import json
import sys

# Supabase config - sử dụng anon key thay vì service role
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

headers = {
    'apikey': ANON_KEY,
    'Authorization': f'Bearer {ANON_KEY}',
    'Content-Type': 'application/json'
}

def search_user():
    """Search for user with various methods"""
    print("🔍 Tìm kiếm user Hồ Minh...")
    
    # Try different search patterns
    search_patterns = [
        "full_name=eq.Hồ Minh",
        "full_name=ilike.*Hồ*",
        "full_name=ilike.*Minh*"
    ]
    
    for pattern in search_patterns:
        print(f"   Thử pattern: {pattern}")
        try:
            response = requests.get(
                f'{SUPABASE_URL}/rest/v1/users?{pattern}',
                headers=headers
            )
            
            if response.status_code == 200:
                users = response.json()
                if users:
                    print(f"✅ Tìm thấy {len(users)} user(s):")
                    for i, user in enumerate(users):
                        print(f"   {i+1}. {user.get('full_name', 'Unknown')} - Rank: {user.get('rank', 'None')} - ELO: {user.get('elo_rating', 0)}")
                    return users
            else:
                print(f"   ❌ Status: {response.status_code}")
        except Exception as e:
            print(f"   ❌ Error: {e}")
    
    return None

def update_user_rank(user_id, new_rank, new_elo):
    """Update user rank and ELO"""
    print(f"\n🔄 Updating user {user_id} to rank {new_rank} with ELO {new_elo}...")
    
    update_data = {
        'rank': new_rank,
        'elo_rating': new_elo
    }
    
    try:
        response = requests.patch(
            f'{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}',
            headers=headers,
            json=update_data
        )
        
        if response.status_code in [200, 204]:
            print("✅ Cập nhật thành công!")
            return True
        else:
            print(f"❌ Lỗi cập nhật: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def main():
    print("🏆 FIX HỒ MINH RANK SYSTEM")
    print("="*50)
    
    # Search for users
    users = search_user()
    
    if not users:
        print("\n❌ Không tìm thấy user nào. Thử tìm tất cả users:")
        try:
            response = requests.get(
                f'{SUPABASE_URL}/rest/v1/users?select=id,full_name,rank,elo_rating&limit=10',
                headers=headers
            )
            if response.status_code == 200:
                all_users = response.json()
                print(f"📋 {len(all_users)} users đầu tiên:")
                for user in all_users:
                    print(f"   - {user.get('full_name', 'Unknown')} (Rank: {user.get('rank', 'None')})")
        except Exception as e:
            print(f"❌ Không thể lấy danh sách users: {e}")
        return
    
    # Find user with issue
    target_user = None
    for user in users:
        if user.get('rank') in ['K', None] and 'Hồ' in user.get('full_name', ''):
            target_user = user
            break
    
    if not target_user:
        print("\n❌ Không tìm thấy user Hồ Minh có rank K")
        return
    
    print(f"\n🎯 Target user: {target_user['full_name']}")
    print(f"   Current rank: {target_user.get('rank', 'None')}")
    print(f"   Current ELO: {target_user.get('elo_rating', 0)}")
    
    # Update to rank I with ELO 2200
    success = update_user_rank(target_user['id'], 'I', 2200)
    
    if success:
        print("\n🎉 Hoàn thành! Hãy refresh app để thấy thay đổi.")
    else:
        print("\n❌ Cập nhật thất bại.")

if __name__ == "__main__":
    main()