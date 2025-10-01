from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA TOURNAMENT "doublesabo1"')
print('=' * 50)

# Tìm tournament doublesabo1
result = supabase.table('tournaments').select('*').ilike('title', '%doublesabo1%').execute()

if result.data:
    tournament = result.data[0]
    print(f'📋 Tournament: {tournament.get("title")}')
    print(f'🆔 ID: {tournament.get("id")}')
    print(f'📅 Created: {tournament.get("created_at")}')
    print(f'📋 Database format field: "{tournament.get("format")}"')
    print(f'🎮 Database tournament_type field: "{tournament.get("tournament_type")}"')
    print(f'📝 Description: {tournament.get("description", "No description")}')
    print(f'🏆 Max participants: {tournament.get("max_participants")}')
    print(f'💰 Entry fee: {tournament.get("entry_fee")}')
    print(f'🎯 Prize pool: {tournament.get("prize_pool")}')
    
    print('\n🚨 PHÂN TÍCH VẤN ĐỀ:')
    print('   Bạn tạo với format: double_elimination')
    print(f'   Database lưu format: "{tournament.get("format")}"')
    print(f'   Database lưu tournament_type: "{tournament.get("tournament_type")}"')
    
    if tournament.get("tournament_type") != "double_elimination":
        print('   ❌ VẤN ĐỀ XÁC NHẬN: format KHÔNG được lưu đúng!')
    else:
        print('   ✅ Tournament_type được lưu đúng')
        
    if tournament.get("format") == "8-ball":
        print('   ✅ Format field chứa game type đúng')
    else:
        print(f'   ⚠️ Format field: "{tournament.get("format")}" - không phải game type')
        
else:
    print('❌ Không tìm thấy tournament "doublesabo1"')
    
# Kiểm tra các tournaments gần đây nhất
print('\n📊 5 TOURNAMENTS GẦN NHẤT:')
recent = supabase.table('tournaments').select('title, format, tournament_type, created_at').order('created_at').limit(5).execute()
for i, t in enumerate(recent.data, 1):
    print(f'{i}. {t.get("title")} - format: "{t.get("format")}" - tournament_type: "{t.get("tournament_type")}"')