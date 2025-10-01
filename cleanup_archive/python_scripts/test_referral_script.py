#!/usr/bin/env python3
"""
SABO Arena Referral System Tester
Test tính năng referral trước khi phát hành app
"""

import requests
import json
import time
from datetime import datetime

# Supabase config (thay bằng config thật của bạn)
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

def log_message(message, level="INFO"):
    """Log test messages với timestamp"""
    timestamp = datetime.now().strftime("%H:%M:%S")
    prefix = {
        "INFO": "ℹ️",
        "SUCCESS": "✅", 
        "ERROR": "❌",
        "WARNING": "⚠️",
        "TEST": "🧪"
    }
    print(f"[{timestamp}] {prefix.get(level, '📝')} {message}")

def create_test_referral_code(user_id, code_suffix=""):
    """Tạo mã referral test"""
    referral_code = f"SABO-TEST{code_suffix}{int(time.time())}"
    
    payload = {
        "user_id": user_id,
        "code": referral_code,
        "max_uses": 5,
        "current_uses": 0,
        "spa_reward_referrer": 100,
        "spa_reward_referred": 50,
        "is_active": True
    }
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/referral_codes",
            headers=headers,
            json=payload
        )
        
        if response.status_code in [200, 201]:
            log_message(f"Tạo mã referral thành công: {referral_code}", "SUCCESS")
            return referral_code
        else:
            log_message(f"Lỗi tạo mã referral: {response.status_code} - {response.text}", "ERROR")
            return None
            
    except Exception as e:
        log_message(f"Exception tạo mã referral: {e}", "ERROR")
        return None

def test_referral_code_exists(code):
    """Kiểm tra mã referral có tồn tại không"""
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?code=eq.{code}&select=*",
            headers=headers
        )
        
        if response.status_code == 200:
            codes = response.json()
            if codes:
                code_data = codes[0]
                log_message(f"Mã {code} tồn tại - Active: {code_data['is_active']}", "SUCCESS")
                return code_data
            else:
                log_message(f"Mã {code} không tồn tại", "WARNING")
                return None
        else:
            log_message(f"Lỗi kiểm tra mã: {response.status_code}", "ERROR")
            return None
            
    except Exception as e:
        log_message(f"Exception kiểm tra mã: {e}", "ERROR")
        return None

def simulate_referral_usage(code, referred_user_id):
    """Mô phỏng việc sử dụng mã referral"""
    # Lấy thông tin mã referral
    code_data = test_referral_code_exists(code)
    if not code_data:
        return False
        
    # Kiểm tra limit
    if code_data['max_uses'] and code_data['current_uses'] >= code_data['max_uses']:
        log_message(f"Mã {code} đã đạt giới hạn sử dụng", "WARNING")
        return False
    
    # Tạo record usage
    usage_payload = {
        "referral_code_id": code_data['id'],
        "referrer_id": code_data['user_id'],
        "referred_user_id": referred_user_id,
        "spa_awarded_referrer": code_data['spa_reward_referrer'],
        "spa_awarded_referred": code_data['spa_reward_referred']
    }
    
    try:
        # Insert usage record
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/referral_usage",
            headers=headers,
            json=usage_payload
        )
        
        if response.status_code in [200, 201]:
            log_message(f"Sử dụng mã {code} thành công!", "SUCCESS")
            log_message(f"Referrer nhận: {code_data['spa_reward_referrer']} SPA", "SUCCESS")
            log_message(f"Referred nhận: {code_data['spa_reward_referred']} SPA", "SUCCESS")
            
            # Update current_uses
            update_response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/referral_codes?id=eq.{code_data['id']}",
                headers=headers,
                json={"current_uses": code_data['current_uses'] + 1}
            )
            
            if update_response.status_code == 204:
                log_message("Cập nhật usage count thành công", "SUCCESS")
            
            return True
        else:
            log_message(f"Lỗi sử dụng mã: {response.status_code} - {response.text}", "ERROR")
            return False
            
    except Exception as e:
        log_message(f"Exception sử dụng mã: {e}", "ERROR")
        return False

def check_referral_stats():
    """Kiểm tra thống kê referral system"""
    log_message("Kiểm tra thống kê referral system...", "TEST")
    
    try:
        # Đếm tổng số mã
        codes_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?select=count",
            headers=headers
        )
        
        # Đếm tổng số usage
        usage_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_usage?select=count",
            headers=headers
        )
        
        # Lấy mã gần đây
        recent_codes = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?select=code,is_active,current_uses,created_at&order=created_at.desc&limit=5",
            headers=headers
        )
        
        if all(r.status_code == 200 for r in [codes_response, usage_response, recent_codes]):
            log_message("📊 THỐNG KÊ REFERRAL SYSTEM", "INFO")
            log_message(f"Total referral codes: {len(codes_response.json())}", "INFO")
            log_message(f"Total usage records: {len(usage_response.json())}", "INFO")
            
            log_message("Mã gần đây:", "INFO")
            for code in recent_codes.json():
                status = "🟢" if code['is_active'] else "🔴"
                log_message(f"  {status} {code['code']} - Uses: {code['current_uses']}", "INFO")
        
    except Exception as e:
        log_message(f"Lỗi kiểm tra stats: {e}", "ERROR")

def run_comprehensive_test():
    """Chạy test toàn diện referral system"""
    print("=" * 60)
    print("🧪 SABO ARENA REFERRAL SYSTEM TEST")
    print("=" * 60)
    
    # Test 1: Tạo mã referral
    log_message("TEST 1: Tạo mã referral", "TEST")
    test_user_id = f"test_user_{int(time.time())}"
    referral_code = create_test_referral_code(test_user_id, "_MAIN")
    
    if not referral_code:
        log_message("Không thể tạo mã referral, dừng test", "ERROR")
        return
    
    time.sleep(1)
    
    # Test 2: Kiểm tra mã tồn tại
    log_message("TEST 2: Kiểm tra mã tồn tại", "TEST")
    code_data = test_referral_code_exists(referral_code)
    
    time.sleep(1)
    
    # Test 3: Mô phỏng sử dụng mã
    log_message("TEST 3: Mô phỏng sử dụng mã", "TEST")
    referred_user_1 = f"referred_user_{int(time.time())}_1"
    success1 = simulate_referral_usage(referral_code, referred_user_1)
    
    time.sleep(1)
    
    # Test 4: Sử dụng mã lần 2
    log_message("TEST 4: Sử dụng mã lần 2", "TEST")
    referred_user_2 = f"referred_user_{int(time.time())}_2"
    success2 = simulate_referral_usage(referral_code, referred_user_2)
    
    time.sleep(1)
    
    # Test 5: Kiểm tra stats
    log_message("TEST 5: Kiểm tra stats", "TEST")
    check_referral_stats()
    
    # Summary
    print("\n" + "=" * 60)
    print("📋 TỔNG KẾT TEST")
    print("=" * 60)
    
    total_tests = 4
    passed_tests = sum([
        bool(referral_code),
        bool(code_data), 
        success1,
        success2
    ])
    
    log_message(f"Tổng số test: {total_tests}", "INFO")
    log_message(f"Test passed: {passed_tests}", "SUCCESS" if passed_tests == total_tests else "WARNING")
    log_message(f"Test failed: {total_tests - passed_tests}", "ERROR" if passed_tests < total_tests else "SUCCESS")
    
    if passed_tests == total_tests:
        log_message("🎉 REFERRAL SYSTEM HOẠT ĐỘNG TỐTE!", "SUCCESS")
        log_message("✅ Sẵn sàng cho production!", "SUCCESS")
    else:
        log_message("⚠️ Có vấn đề cần khắc phục trước khi phát hành", "WARNING")

def manual_test_menu():
    """Menu test thủ công"""
    while True:
        print("\n" + "=" * 50)
        print("🧪 SABO ARENA REFERRAL MANUAL TEST")
        print("=" * 50)
        print("1. Tạo mã referral test")
        print("2. Kiểm tra mã có tồn tại không")  
        print("3. Mô phỏng sử dụng mã")
        print("4. Kiểm tra thống kê")
        print("5. Chạy test toàn diện")
        print("0. Thoát")
        
        choice = input("\nChọn option (0-5): ").strip()
        
        if choice == "1":
            user_id = input("Nhập User ID (hoặc Enter để tự động): ").strip()
            if not user_id:
                user_id = f"test_user_{int(time.time())}"
            create_test_referral_code(user_id)
            
        elif choice == "2":
            code = input("Nhập mã referral để kiểm tra: ").strip()
            if code:
                test_referral_code_exists(code)
                
        elif choice == "3":
            code = input("Nhập mã referral: ").strip()
            user_id = input("Nhập Referred User ID (hoặc Enter để tự động): ").strip()
            if not user_id:
                user_id = f"referred_user_{int(time.time())}"
            if code:
                simulate_referral_usage(code, user_id)
                
        elif choice == "4":
            check_referral_stats()
            
        elif choice == "5":
            run_comprehensive_test()
            
        elif choice == "0":
            log_message("Thoát test menu", "INFO")
            break
        else:
            log_message("Option không hợp lệ", "WARNING")

if __name__ == "__main__":
    print("🚀 SABO Arena Referral System Tester")
    print("Chọn mode:")
    print("1. Auto test (chạy tất cả test tự động)")
    print("2. Manual test (test thủ công)")
    
    mode = input("Chọn mode (1 hoặc 2): ").strip()
    
    if mode == "1":
        run_comprehensive_test()
    elif mode == "2":
        manual_test_menu()
    else:
        print("Mode không hợp lệ!")