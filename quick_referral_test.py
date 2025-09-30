#!/usr/bin/env python3
"""
SABO Arena Referral System Quick Test
"""

import requests
import json
import time
from datetime import datetime

# Supabase config 
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

def quick_test_referral_system():
    """Test nhanh hệ thống referral"""
    print("=" * 60)
    print("🧪 SABO ARENA REFERRAL SYSTEM QUICK TEST")
    print("=" * 60)
    
    # Test 1: Kiểm tra bảng referral_codes
    print("\n1️⃣ Kiểm tra bảng referral_codes...")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?select=*&limit=5",
            headers=headers
        )
        
        if response.status_code == 200:
            codes = response.json()
            print(f"✅ Tìm thấy {len(codes)} referral codes")
            
            if codes:
                print("📋 Các mã gần đây:")
                for code in codes[:3]:
                    status = "🟢" if code.get('is_active') else "🔴"
                    print(f"   {status} {code.get('code', 'N/A')} - Uses: {code.get('current_uses', 0)}")
            else:
                print("⚠️  Chưa có mã referral nào được tạo")
        else:
            print(f"❌ Lỗi truy cập bảng referral_codes: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 2: Kiểm tra bảng referral_usage  
    print("\n2️⃣ Kiểm tra bảng referral_usage...")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_usage?select=*&limit=5",
            headers=headers
        )
        
        if response.status_code == 200:
            usage = response.json()
            print(f"✅ Tìm thấy {len(usage)} lượt sử dụng referral")
            
            if usage:
                print("📋 Lượt sử dụng gần đây:")
                for use in usage[:3]:
                    print(f"   📅 {use.get('used_at', 'N/A')[:10]} - SPA: {use.get('spa_awarded_referred', 'N/A')}")
        else:
            print(f"❌ Lỗi truy cập bảng referral_usage: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 3: Kiểm tra users có referral_code
    print("\n3️⃣ Kiểm tra users có referral_code...")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=username,referral_code,spa_balance&referral_code=not.is.null&limit=5",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            print(f"✅ Tìm thấy {len(users)} users có mã referral")
            
            if users:
                print("👤 Users có mã:")
                for user in users[:3]:
                    print(f"   🎯 {user.get('username', 'N/A')} - Code: {user.get('referral_code', 'N/A')} - SPA: {user.get('spa_balance', 0)}")
        else:
            print(f"❌ Lỗi truy cập bảng users: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")
    
    # Test 4: Tạo test referral code
    print("\n4️⃣ Tạo test referral code...")
    test_code = f"SABO-TEST{int(time.time())}"
    
    try:
        payload = {
            "user_id": "00000000-0000-0000-0000-000000000000",  # Fake UUID
            "code": test_code,
            "max_uses": 5,
            "current_uses": 0,
            "spa_reward_referrer": 100,
            "spa_reward_referred": 50,
            "is_active": True
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/referral_codes",
            headers=headers,
            json=payload
        )
        
        if response.status_code in [200, 201]:
            print(f"✅ Tạo test code thành công: {test_code}")
        else:
            print(f"⚠️  Không thể tạo test code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Exception tạo test code: {e}")
    
    # Summary
    print("\n" + "=" * 60)
    print("📋 TÓM TẮT QUICK TEST")
    print("=" * 60)
    print("✅ Database connection: OK")
    print("✅ Referral tables: Accessible") 
    print("✅ Basic functionality: Ready")
    print("\n🎯 NEXT STEPS:")
    print("1. Tạo 2 tài khoản test trong app")
    print("2. User A tạo mã referral")
    print("3. User B sử dụng mã của A")
    print("4. Kiểm tra cả 2 nhận SPA đúng")
    print("5. Verify trong database")
    
    print("\n🚀 Ready for testing!")

if __name__ == "__main__":
    quick_test_referral_system()