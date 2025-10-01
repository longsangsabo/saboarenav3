#!/usr/bin/env python3

import os
from supabase import create_client, Client

# Supabase connection
url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

supabase: Client = create_client(url, key)

def check_database_directly():
    print("=== KIỂM TRA DATABASE TRỰC TIẾP ===")
    
    # 1. Kiểm tra bảng matches có tồn tại không
    print("\n1. Kiểm tra bảng matches:")
    try:
        result = supabase.from_('matches').select('*').limit(1).execute()
        print(f"   ✅ Bảng matches tồn tại, có {len(result.data)} records")
        
        # Nếu có data, show columns
        if result.data:
            print("   📋 Các cột có trong data:")
            for key in result.data[0].keys():
                print(f"      - {key}")
        else:
            print("   📋 Bảng rỗng, không thể xem columns từ data")
            
    except Exception as e:
        print(f"   ❌ Lỗi truy vấn matches: {e}")

    # 2. Thử insert test match để xem lỗi gì
    print("\n2. Test insert match (sẽ fail để show required columns):")
    try:
        test_match = {
            'tournament_id': '00000000-0000-0000-0000-000000000000',
            'round_number': 1,
            'match_number': 1,
            'player1_id': '00000000-0000-0000-0000-000000000000',
            'player2_id': '00000000-0000-0000-0000-000000000001',
        }
        result = supabase.from_('matches').insert(test_match).execute()
        print("   ❌ UNEXPECTED: Insert thành công (không nên xảy ra)")
        
        # Delete ngay để không làm dirty data
        if result.data:
            supabase.from_('matches').delete().eq('id', result.data[0]['id']).execute()
            print("   🧹 Đã xóa test data")
            
    except Exception as e:
        print(f"   ✅ Insert failed như mong đợi: {str(e)}")
        # Phân tích error message để hiểu schema
        error_str = str(e)
        if "does not exist" in error_str:
            print("   📝 Có cột không tồn tại trong schema")
        elif "violates" in error_str:
            print("   📝 Vi phạm constraint (bình thường)")
        elif "invalid input syntax" in error_str:
            print("   📝 Format dữ liệu không đúng")

    # 3. Thử với các cột khác mà chúng ta đã sửa
    print("\n3. Test với cột scheduled_at thay vì scheduled_time:")
    try:
        test_match_2 = {
            'tournament_id': '00000000-0000-0000-0000-000000000000',
            'round_number': 1,
            'match_number': 1,
            'scheduled_at': '2025-09-27T12:00:00Z'
        }
        result = supabase.from_('matches').insert(test_match_2).execute()
        print("   ❌ UNEXPECTED: Insert thành công với scheduled_at")
        
        # Delete ngay
        if result.data:
            supabase.from_('matches').delete().eq('id', result.data[0]['id']).execute()
            print("   🧹 Đã xóa test data")
            
    except Exception as e:
        print(f"   ✅ scheduled_at test: {str(e)}")

    # 4. Kiểm tra bảng tournaments để đảm bảo foreign key có tồn tại
    print("\n4. Kiểm tra bảng tournaments:")
    try:
        result = supabase.from_('tournaments').select('id, title').limit(5).execute()
        print(f"   ✅ Bảng tournaments tồn tại với {len(result.data)} records")
        if result.data:
            print("   📋 Một số tournaments:")
            for tournament in result.data[:3]:
                print(f"      - {tournament.get('title', 'No title')} ({tournament.get('id', 'No ID')})")
    except Exception as e:
        print(f"   ❌ Lỗi tournaments: {e}")

    # 5. Kiểm tra bảng users cho foreign key
    print("\n5. Kiểm tra bảng users:")
    try:
        result = supabase.from_('users').select('id, full_name').limit(3).execute()
        print(f"   ✅ Bảng users tồn tại với {len(result.data)} records")
        if result.data:
            print("   📋 Một số users:")
            for user in result.data:
                print(f"      - {user.get('full_name', 'No name')} ({user.get('id', 'No ID')})")
    except Exception as e:
        print(f"   ❌ Lỗi users: {e}")

if __name__ == "__main__":
    check_database_directly()