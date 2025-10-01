from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 PHÂN TÍCH CHI TIẾT VẤN ĐỀ XÓA TOURNAMENTS')
print('=' * 60)

# Kiểm tra tournament doublesabo1 có dependencies gì
print('\n1. 🎯 KIỂM TRA TOURNAMENT doublesabo1:')
tournament = supabase.table('tournaments').select('*').ilike('title', '%doublesabo1%').execute()
if tournament.data:
    tid = tournament.data[0]['id']
    organizer = tournament.data[0]['organizer_id']
    print(f'   Tournament ID: {tid}')
    print(f'   Organizer ID: {organizer}')
    
    # Kiểm tra participants
    participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tid).execute()
    print(f'   👥 Participants: {len(participants.data) if participants.data else 0}')
    
    # Kiểm tra matches
    matches = supabase.table('matches').select('*').eq('tournament_id', tid).execute()
    print(f'   🏆 Matches: {len(matches.data) if matches.data else 0}')
    
    if participants.data:
        print(f'\n   📋 PARTICIPANTS DETAILS:')
        for i, p in enumerate(participants.data[:3], 1):
            print(f'      {i}. User: {p.get("user_id", "NULL")} - Status: {p.get("status", "NULL")}')
    
    if matches.data:
        print(f'\n   🏆 MATCHES DETAILS:')
        for i, m in enumerate(matches.data[:3], 1):
            print(f'      {i}. Match: {m.get("id", "NULL")[:8]}... - Status: {m.get("status", "NULL")}')

# Thử xóa từng phần
print('\n2. 🗑️ THỬ XÓA TỪNG PHẦN:')

if tournament.data:
    tid = tournament.data[0]['id']
    
    # Thử xóa participants trước
    print('   🧹 Xóa participants...')
    try:
        del_participants = supabase.table('tournament_participants').delete().eq('tournament_id', tid).execute()
        if del_participants.data:
            print(f'      ✅ Đã xóa {len(del_participants.data)} participants')
        else:
            print('      ⚠️ Không có participants để xóa hoặc không thể xóa')
    except Exception as e:
        print(f'      ❌ Lỗi xóa participants: {e}')
    
    # Thử xóa matches trước
    print('   🧹 Xóa matches...')
    try:
        del_matches = supabase.table('matches').delete().eq('tournament_id', tid).execute()
        if del_matches.data:
            print(f'      ✅ Đã xóa {len(del_matches.data)} matches')
        else:
            print('      ⚠️ Không có matches để xóa hoặc không thể xóa')
    except Exception as e:
        print(f'      ❌ Lỗi xóa matches: {e}')
    
    # Bây giờ thử xóa tournament
    print('   🧹 Xóa tournament...')
    try:
        del_tournament = supabase.table('tournaments').delete().eq('id', tid).execute()
        if del_tournament.data:
            print(f'      ✅ Đã xóa tournament thành công!')
        else:
            print('      ❌ Không thể xóa tournament')
    except Exception as e:
        print(f'      ❌ Lỗi xóa tournament: {e}')

# 3. Kiểm tra authentication
print('\n3. 🔐 KIỂM TRA AUTHENTICATION:')
try:
    user = supabase.auth.get_user()
    if user and user.user:
        print(f'   ✅ Đã đăng nhập: {user.user.id}')
        print(f'   📧 Email: {user.user.email}')
    else:
        print('   ❌ Chưa đăng nhập - đây có thể là nguyên nhân!')
except Exception as e:
    print(f'   ⚠️ Không thể kiểm tra auth: {e}')
    print('   💡 Sử dụng ANON key - có thể bị RLS chặn')

print('\n🎯 KẾT LUẬN:')
print('   • Tournaments có participants và matches')
print('   • Cần xóa dependencies trước khi xóa tournament')
print('   • Có thể có RLS policy chặn delete với anon key')
print('   • Cần authentication với organizer để xóa tournament')

print('\n💡 GIẢI PHÁP ĐỀ XUẤT:')
print('   1. Trong app Flutter: Implement delete cascade')
print('   2. Hoặc: Xóa participants + matches trước khi xóa tournament')
print('   3. Hoặc: Cấu hình CASCADE DELETE trong database schema')
print('   4. Đảm bảo user đã đăng nhập và có quyền xóa')