from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔧 VERIFY FIX - Tournament Format Display')
print('=' * 50)

# Tìm tournament sabo1
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    t = tournament.data[0]
    print(f'📋 TOURNAMENT: {t["title"]}')
    print(f'🆔 ID: {t["id"]}')
    
    print(f'\n📊 DATABASE VALUES:')
    print(f'   format (DB): "{t.get("format", "NULL")}"')
    print(f'   tournament_type (DB): "{t.get("tournament_type", "NULL")}"')
    
    print(f'\n🔄 APP MAPPING (After fix):')
    db_format = t.get('format')  # "8-ball" (game type)
    db_tournament_type = t.get('tournament_type')  # "double_elimination" (elimination format)
    
    print(f'   tournament.format (Dart) ← tournament_type (DB): "{db_tournament_type}"')
    print(f'   tournament.tournamentType (Dart) ← format (DB): "{db_format}"')
    
    print(f'\n✨ UI DISPLAY (After fix):')
    
    # Simulate formatDisplayName logic
    elimination_format = db_tournament_type
    if elimination_format == 'double_elimination':
        display_name = 'Double Elimination'
    elif elimination_format == 'single_elimination':
        display_name = 'Single Elimination'
    elif elimination_format == 'round_robin':
        display_name = 'Round Robin'
    else:
        display_name = elimination_format.replace('_', ' ').upper() if elimination_format else 'Không xác định'
    
    print(f'   🎯 eliminationType sẽ hiển thị: "{display_name}"')
    print(f'   🎮 format (game type) sẽ hiển thị: "{db_format}"')
    
    print(f'\n🎉 KẾT QUẢ:')
    if display_name == 'Double Elimination':
        print('   ✅ THÀNH CÔNG: Sẽ hiển thị "Double Elimination" thay vì "Không xác định"')
    else:
        print('   ❌ VẪN CÓ VẤN ĐỀ: Sẽ không hiển thị đúng')
        
else:
    print('❌ Không tìm thấy tournament sabo1')

print(f'\n💡 HƯỚNG DẪN TEST:')
print('   1. Build và chạy app Flutter')
print('   2. Vào tournament sabo1')  
print('   3. Kiểm tra phần "Hình thức" trong thông tin giải đấu')
print('   4. Nó phải hiển thị "Double Elimination" thay vì "Không xác định"')