from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔧 FIX TOURNAMENT DELETE ISSUE')
print('=' * 40)

# Đọc và execute SQL script
try:
    with open('fix_tournament_delete.sql', 'r', encoding='utf-8') as file:
        sql_content = file.read()
    
    print('📄 Đã đọc SQL script...')
    
    # Execute SQL (note: có thể cần service role key cho DDL operations)
    print('⚠️  Lưu ý: Script này cần SERVICE ROLE KEY để thực hiện DDL operations')
    print('🎯 HƯỚNG DẪN MANUAL:')
    print('   1. Mở Supabase Dashboard')
    print('   2. Vào SQL Editor')
    print('   3. Copy và paste script từ file fix_tournament_delete.sql')
    print('   4. Run script với Service Role privileges')
    
    print('\n📋 NỘI DUNG SCRIPT:')
    print('   • Xóa user_achievements references')
    print('   • Xóa tournament_participants')
    print('   • Xóa matches')
    print('   • Xóa tournament doublesabo1')
    print('   • Cấu hình CASCADE DELETE cho foreign keys')
    
    print('\n✨ SAU KHI CHẠY SCRIPT:')
    print('   • Tournament doublesabo1 sẽ bị xóa')
    print('   • Các tournaments khác có thể xóa dễ dàng')
    print('   • Foreign keys sẽ có CASCADE DELETE')
    
except Exception as e:
    print(f'❌ Lỗi đọc file: {e}')

# Kiểm tra hiện tại
print('\n🔍 KIỂM TRA HIỆN TẠI:')
try:
    tournament = supabase.table('tournaments').select('*').ilike('title', '%doublesabo1%').execute()
    if tournament.data:
        print(f'   ❌ Tournament doublesabo1 vẫn tồn tại: {len(tournament.data)} records')
    else:
        print('   ✅ Tournament doublesabo1 đã bị xóa')
except Exception as e:
    print(f'   ⚠️ Lỗi kiểm tra: {e}')

print('\n🎯 HÀNH ĐỘNG TIẾP THEO:')
print('   1. Copy nội dung file fix_tournament_delete.sql')
print('   2. Paste vào Supabase SQL Editor')
print('   3. Chọn "Use service role key" option')
print('   4. Run script')
print('   5. Kiểm tra kết quả')