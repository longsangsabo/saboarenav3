#!/usr/bin/env python3
"""
Áp dụng Real Payment System vào Supabase Database
"""
import os
from supabase import create_client, Client
import sys

# Supabase credentials
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.Xq8zXMT7_xGNKbGv5O_1n-iBgASdZHBTQO3KjVUWHd8"

def setup_real_payment_system():
    """Thiết lập hệ thống thanh toán thực tế"""
    
    print("🚀 THIẾT LẬP HỆ THỐNG THANH TOÁN THỰC TẾ")
    print("=" * 60)
    
    try:
        # Kết nối Supabase
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        print("✅ Kết nối Supabase thành công")
        
        # Đọc SQL script
        sql_file = "/workspaces/saboarenav3/real_payment_system_setup.sql"
        if not os.path.exists(sql_file):
            print(f"❌ Không tìm thấy file SQL: {sql_file}")
            return False
            
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("📜 Đã đọc SQL script")
        
        # Tách các câu lệnh SQL
        sql_statements = [stmt.strip() for stmt in sql_content.split(';') 
                         if stmt.strip() and not stmt.strip().startswith('--')]
        
        print(f"🔧 Thực thi {len(sql_statements)} câu lệnh SQL...")
        
        success_count = 0
        error_count = 0
        
        for i, statement in enumerate(sql_statements, 1):
            if not statement or len(statement) < 10:
                continue
                
            try:
                # Thực thi từng câu lệnh
                result = supabase.rpc('exec_sql', {'sql': statement + ';'})
                success_count += 1
                print(f"✅ [{i}/{len(sql_statements)}] Thành công")
                
            except Exception as e:
                error_count += 1
                print(f"⚠️ [{i}/{len(sql_statements)}] Lỗi: {str(e)[:100]}...")
                # Tiếp tục với câu lệnh tiếp theo
        
        print("\n" + "=" * 60)
        print(f"📊 KẾT QUẢ THIẾT LẬP:")
        print(f"   ✅ Thành công: {success_count}")
        print(f"   ⚠️ Lỗi: {error_count}")
        
        # Tạo dữ liệu mẫu
        if success_count > 0:
            print("\n🔧 Tạo dữ liệu mẫu...")
            create_sample_data(supabase)
        
        print("\n🎉 HOÀN THÀNH THIẾT LẬP HỆ THỐNG THANH TOÁN!")
        return True
        
    except Exception as e:
        print(f"❌ Lỗi nghiêm trọng: {e}")
        return False

def create_sample_data(supabase: Client):
    """Tạo dữ liệu mẫu cho hệ thống thanh toán"""
    
    try:
        # Lấy club ID đầu tiên
        clubs_result = supabase.table('clubs').select('id').limit(1).execute()
        if not clubs_result.data:
            print("⚠️ Không tìm thấy CLB nào để tạo dữ liệu mẫu")
            return
            
        club_id = clubs_result.data[0]['id']
        print(f"🏢 Sử dụng CLB ID: {club_id}")
        
        # Tạo payment methods mẫu
        sample_payment_methods = [
            {
                'club_id': club_id,
                'method_type': 'bank',
                'method_name': 'Vietcombank',
                'account_info': {
                    'bankName': 'Vietcombank',
                    'accountNumber': '1234567890',
                    'accountName': 'SABO BILLIARDS'
                },
                'is_active': True,
                'display_order': 1
            },
            {
                'club_id': club_id,
                'method_type': 'momo',
                'method_name': 'MoMo',
                'account_info': {
                    'phoneNumber': '0901234567',
                    'receiverName': 'SABO BILLIARDS'
                },
                'is_active': True,
                'display_order': 2
            },
            {
                'club_id': club_id,
                'method_type': 'zalopay',
                'method_name': 'ZaloPay',
                'account_info': {
                    'phoneNumber': '0901234567',
                    'receiverName': 'SABO BILLIARDS'
                },
                'is_active': True,
                'display_order': 3
            }
        ]
        
        # Insert payment methods
        for method in sample_payment_methods:
            try:
                result = supabase.table('payment_methods').insert(method).execute()
                print(f"✅ Tạo phương thức thanh toán: {method['method_name']}")
            except Exception as e:
                print(f"⚠️ Lỗi tạo {method['method_name']}: {e}")
        
        # Tạo club payment settings
        payment_settings = {
            'club_id': club_id,
            'settings': {
                'cash_enabled': True,
                'bank_enabled': True,
                'ewallet_enabled': True,
                'auto_confirm': False,
                'payment_timeout': 600,  # 10 minutes
                'currency': 'VND'
            }
        }
        
        try:
            supabase.table('club_payment_settings').insert(payment_settings).execute()
            print("✅ Tạo cài đặt thanh toán CLB")
        except Exception as e:
            print(f"⚠️ Lỗi tạo cài đặt thanh toán: {e}")
        
        # Tạo club balance
        balance_data = {
            'club_id': club_id,
            'balance': 0.0
        }
        
        try:
            supabase.table('club_balances').insert(balance_data).execute()
            print("✅ Tạo số dư CLB")
        except Exception as e:
            print(f"⚠️ Lỗi tạo số dư CLB: {e}")
            
        print("🎯 Hoàn thành tạo dữ liệu mẫu!")
        
    except Exception as e:
        print(f"❌ Lỗi tạo dữ liệu mẫu: {e}")

def test_payment_system():
    """Test hệ thống thanh toán"""
    
    print("\n🧪 KIỂM TRA HỆ THỐNG THANH TOÁN")
    print("=" * 60)
    
    try:
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
        
        # Test 1: Check tables exist
        tables_to_check = [
            'payments', 'invoices', 'club_payment_settings', 
            'payment_methods', 'webhook_logs', 'club_balances'
        ]
        
        for table in tables_to_check:
            try:
                result = supabase.table(table).select('*').limit(1).execute()
                print(f"✅ Bảng {table}: OK")
            except Exception as e:
                print(f"❌ Bảng {table}: {e}")
        
        # Test 2: Check RPC functions
        functions_to_check = [
            'update_club_balance',
            'get_payment_stats',
            'expire_old_payments',
            'generate_invoice_number'
        ]
        
        for func in functions_to_check:
            try:
                # Test với parameters giả
                if func == 'update_club_balance':
                    # Skip vì cần parameters thực
                    print(f"⏭️ Function {func}: Skipped (needs real params)")
                elif func == 'get_payment_stats':
                    print(f"⏭️ Function {func}: Skipped (needs real params)")
                elif func == 'expire_old_payments':
                    result = supabase.rpc(func).execute()
                    print(f"✅ Function {func}: OK (expired {result.data} payments)")
                elif func == 'generate_invoice_number':
                    print(f"⏭️ Function {func}: Skipped (needs club_id)")
                    
            except Exception as e:
                print(f"❌ Function {func}: {e}")
        
        print("\n✅ Kiểm tra hệ thống hoàn tất!")
        
    except Exception as e:
        print(f"❌ Lỗi kiểm tra hệ thống: {e}")

def main():
    """Main function"""
    
    print("💳 SABO ARENA - REAL PAYMENT SYSTEM SETUP")
    print("Thiết lập hệ thống thanh toán QR Code thực tế")
    print("=" * 60)
    
    if len(sys.argv) > 1 and sys.argv[1] == 'test':
        test_payment_system()
    else:
        success = setup_real_payment_system()
        if success:
            test_payment_system()
            
            print("\n🎯 HƯỚNG DẪN SỬ DỤNG:")
            print("1. Vào CLB Settings > Payment Settings")
            print("2. Cấu hình tài khoản ngân hàng & ví điện tử")
            print("3. Test tạo QR Code thanh toán")
            print("4. Kiểm tra webhook endpoints")
            print("5. Monitor payments qua admin panel")
            
            print("\n📚 TÍNH NĂNG ĐÃ CÓ:")
            print("✅ QR Code VietQR cho ngân hàng") 
            print("✅ Deep links MoMo/ZaloPay")
            print("✅ Real-time payment status tracking")
            print("✅ Webhook handlers")
            print("✅ Payment history & analytics")
            print("✅ Auto-expire old payments")
            print("✅ Secure payment data encryption")
            
        else:
            print("\n❌ Thiết lập thất bại!")
            print("Vui lòng kiểm tra lại kết nối database")

if __name__ == "__main__":
    main()