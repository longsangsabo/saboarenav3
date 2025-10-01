from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA VẤN ĐỀ XÓA TOURNAMENTS')
print('=' * 50)

# 1. Kiểm tra RLS policies
print('\n1. 📋 DANH SÁCH TOURNAMENTS:')
try:
    result = supabase.table('tournaments').select('id, title, organizer_id, created_at').limit(5).execute()
    if result.data:
        for i, tournament in enumerate(result.data, 1):
            print(f'   {i}. {tournament.get("title")} (ID: {tournament.get("id")[:8]}...)')
            print(f'      Organizer: {tournament.get("organizer_id", "NULL")}')
    else:
        print('   ❌ Không thể đọc tournaments')
except Exception as e:
    print(f'   ❌ Lỗi đọc tournaments: {e}')

# 2. Thử xóa một tournament test
print('\n2. 🗑️ THỬ XÓA TOURNAMENT TEST:')
try:
    # Tìm tournament doublesabo1 
    test_tournament = supabase.table('tournaments').select('id, title').ilike('title', '%doublesabo1%').execute()
    
    if test_tournament.data:
        tournament_id = test_tournament.data[0]['id']
        tournament_title = test_tournament.data[0]['title']
        print(f'   🎯 Tìm thấy: {tournament_title} (ID: {tournament_id})')
        
        # Thử xóa
        print('   🗑️ Đang thử xóa...')
        delete_result = supabase.table('tournaments').delete().eq('id', tournament_id).execute()
        
        if delete_result.data:
            print(f'   ✅ Xóa thành công: {len(delete_result.data)} record')
        else:
            print('   ⚠️ Không có data trả về từ delete operation')
            
    else:
        print('   ❌ Không tìm thấy tournament doublesabo1')
        
except Exception as e:
    print(f'   ❌ Lỗi xóa tournament: {e}')
    if 'policy' in str(e).lower():
        print('   🚨 Có thể do RLS Policy chặn!')
    elif 'foreign key' in str(e).lower():
        print('   🚨 Có thể do Foreign Key constraint!')

# 3. Kiểm tra các bảng liên quan
print('\n3. 🔗 KIỂM TRA CÁC BẢNG LIÊN QUAN:')
tables_to_check = [
    'tournament_participants',
    'matches', 
    'tournament_matches',
    'brackets'
]

for table in tables_to_check:
    try:
        result = supabase.table(table).select('id').limit(1).execute()
        print(f'   ✅ Bảng {table}: Có thể truy cập')
    except Exception as e:
        print(f'   ❌ Bảng {table}: Lỗi - {e}')

# 4. Kiểm tra tournament có participants không
print('\n4. 👥 KIỂM TRA TOURNAMENT CÓ PARTICIPANTS:')
try:
    # Lấy tournament có participants
    participants = supabase.table('tournament_participants').select('tournament_id').limit(3).execute()
    if participants.data:
        for participant in participants.data:
            tid = participant['tournament_id']
            tournament_info = supabase.table('tournaments').select('title').eq('id', tid).execute()
            if tournament_info.data:
                print(f'   • Tournament: {tournament_info.data[0]["title"]} có participants')
    else:
        print('   ✅ Không có participants nào')
except Exception as e:
    print(f'   ❌ Lỗi kiểm tra participants: {e}')

# 5. Kiểm tra matches liên quan
print('\n5. 🏆 KIỂM TRA TOURNAMENT CÓ MATCHES:')
try:
    matches = supabase.table('matches').select('tournament_id').limit(3).execute()
    if matches.data:
        for match in matches.data:
            tid = match['tournament_id']
            if tid:
                tournament_info = supabase.table('tournaments').select('title').eq('id', tid).execute()
                if tournament_info.data:
                    print(f'   • Tournament: {tournament_info.data[0]["title"]} có matches')
    else:
        print('   ✅ Không có matches nào')
except Exception as e:
    print(f'   ❌ Lỗi kiểm tra matches: {e}')

print('\n🔍 PHÂN TÍCH NGUYÊN NHÂN:')
print('   1. RLS Policy: Có thể chỉ cho phép organizer xóa tournament')
print('   2. Foreign Key: Tournaments có participants/matches không thể xóa')
print('   3. Cascade Delete: Có thể chưa được cấu hình')
print('   4. Authentication: Cần đăng nhập với đúng user')

print('\n💡 GIẢI PHÁP:')
print('   1. Đăng nhập với user là organizer của tournament')
print('   2. Xóa participants và matches trước khi xóa tournament')
print('   3. Hoặc cấu hình CASCADE DELETE trong database')
print('   4. Kiểm tra RLS policies cho phép delete')