#!/usr/bin/env python3

from supabase import create_client, Client

# Supabase connection
url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

supabase: Client = create_client(url, key)

def find_actual_schema():
    print("=== TÌM SCHEMA THỰC TẾ ===")
    
    # Thử nhiều cột có thể có trong matches table
    possible_columns = [
        'id', 'tournament_id', 'match_number', 'round_number',
        'player1_id', 'player2_id', 'player1_score', 'player2_score',
        'winner_id', 'status', 'created_at', 'updated_at',
        'scheduled_time', 'scheduled_at', 'started_at', 'completed_at',
        'format', 'table_number', 'match_data', 'notes'
    ]
    
    working_columns = []
    failed_columns = []
    
    print("Thử từng cột để tìm cột nào có thực sự...")
    
    for col in possible_columns:
        try:
            # Thử select cột này
            result = supabase.from_('matches').select(col).limit(1).execute()
            working_columns.append(col)
            print(f"   ✅ {col}")
        except Exception as e:
            failed_columns.append(col)
            print(f"   ❌ {col}: {str(e)[:60]}...")
    
    print(f"\n📊 KẾT QUẢ:")
    print(f"✅ Cột TỒN TẠI ({len(working_columns)}):")
    for col in working_columns:
        print(f"   - {col}")
    
    print(f"\n❌ Cột KHÔNG TỒN TẠI ({len(failed_columns)}):")
    for col in failed_columns:
        print(f"   - {col}")
    
    # Thử insert với chỉ các cột working
    print(f"\n🔧 Test insert với cột thực tế...")
    try:
        # Lấy tournament ID thật
        tournaments = supabase.from_('tournaments').select('id').limit(1).execute()
        if tournaments.data:
            tournament_id = tournaments.data[0]['id']
            
            # Tạo test match chỉ với cột tồn tại
            test_data = {
                'tournament_id': tournament_id,
                'round_number': 1,
                'match_number': 1,
                'status': 'scheduled'
            }
            
            # Thêm các cột optional nếu có
            if 'player1_score' in working_columns:
                test_data['player1_score'] = 0
            if 'player2_score' in working_columns:
                test_data['player2_score'] = 0
                
            result = supabase.from_('matches').insert(test_data).execute()
            print(f"   ✅ INSERT THÀNH CÔNG với data: {test_data}")
            
            # Xóa ngay để clean up
            if result.data:
                supabase.from_('matches').delete().eq('id', result.data[0]['id']).execute()
                print("   🧹 Đã xóa test record")
                
        else:
            print("   ❌ Không có tournament để test")
            
    except Exception as e:
        print(f"   ❌ Insert failed: {e}")

if __name__ == "__main__":
    find_actual_schema()