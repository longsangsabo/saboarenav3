#!/usr/bin/env python3
"""
Fix rank for user Hồ Minh - Update from K to I with correct ELO
"""

import requests
import json

# Supabase config
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.JQ7cZ6aTCgJJyLPpD8r1m9hNx4fSiVPDJ5lEBIZxr0U'

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

def main():
    print("🔍 Tìm user Hồ Minh...")
    
    # Search for user
    response = requests.get(
        f'{SUPABASE_URL}/rest/v1/users?full_name=eq.Hồ Minh',
        headers=headers
    )
    
    if response.status_code != 200:
        print(f"❌ Lỗi API: {response.status_code}")
        return
    
    users = response.json()
    if not users:
        print("❌ Không tìm thấy user Hồ Minh")
        # Try fuzzy search
        print("🔍 Thử tìm kiếm mờ...")
        response = requests.get(
            f'{SUPABASE_URL}/rest/v1/users?full_name=like.*Hồ*',
            headers=headers
        )
        users = response.json()
        if users:
            print("📋 Các user có tên chứa 'Hồ':")
            for u in users:
                print(f"  - {u['full_name']} (ID: {u['id']}) - Rank: {u.get('rank', 'None')}")
        return
    
    user = users[0]
    user_id = user['id']
    current_rank = user.get('rank', 'None')
    current_elo = user.get('elo_rating', 1000)
    
    print(f"✅ Tìm thấy user: {user['full_name']}")
    print(f"📊 Thông tin hiện tại:")
    print(f"   - ID: {user_id}")
    print(f"   - Rank: {current_rank}")
    print(f"   - ELO: {current_elo}")
    
    # ELO mapping for rank I
    new_elo = 2200  # Rank I should have ELO around 2200
    
    print(f"\n🔄 Cập nhật rank thành 'I' và ELO thành {new_elo}...")
    
    update_data = {
        'rank': 'I',
        'elo_rating': new_elo
    }
    
    update_response = requests.patch(
        f'{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}',
        headers=headers,
        json=update_data
    )
    
    if update_response.status_code in [200, 204]:
        print("✅ Cập nhật thành công!")
        
        # Verify update
        print("🔍 Kiểm tra lại kết quả...")
        verify_response = requests.get(
            f'{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}',
            headers=headers
        )
        
        if verify_response.status_code == 200:
            updated_user = verify_response.json()[0]
            print(f"📈 Kết quả sau cập nhật:")
            print(f"   - Rank: {updated_user['rank']}")
            print(f"   - ELO: {updated_user['elo_rating']}")
            print(f"\n🎉 User {updated_user['full_name']} đã được cập nhật thành công!")
        else:
            print("❌ Không thể verify kết quả")
    else:
        print(f"❌ Lỗi cập nhật: {update_response.status_code}")
        print(f"Chi tiết: {update_response.text}")

if __name__ == "__main__":
    main()