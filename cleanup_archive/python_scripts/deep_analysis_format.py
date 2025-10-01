from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🚨 DEEP ANALYSIS - ROOT CAUSE CHO "Không xác định"')
print('=' * 60)

# Tìm tournament sabo1
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    t = tournament.data[0]
    print(f'📋 TOURNAMENT DATA:')
    print(f'   Title: {t["title"]}')
    print(f'   ID: {t["id"]}')
    
    print(f'\n🗄️ DATABASE RAW VALUES:')
    db_format = t.get('format')  # "8-ball"
    db_tournament_type = t.get('tournament_type')  # "double_elimination"
    
    print(f'   format (DB): "{db_format}"')
    print(f'   tournament_type (DB): "{db_tournament_type}"')
    
    print(f'\n🔍 ANALYSIS CÁC TRƯỜNG HỢP HIỂN THỊ:')
    
    # 1. Tournament Model mapping
    print(f'   1️⃣ TOURNAMENT MODEL MAPPING:')
    print(f'      tournament.format (Dart) = "{db_tournament_type}" (từ tournament_type DB)')
    print(f'      tournament.tournamentType (Dart) = "{db_format}" (từ format DB)')
    
    # 2. formatDisplayName getter
    print(f'\n   2️⃣ FORMAT DISPLAY NAME LOGIC:')
    if db_tournament_type == 'double_elimination':
        format_display = 'Double Elimination'
        print(f'      ✅ formatDisplayName = "{format_display}"')
    elif db_tournament_type == 'single_elimination':
        format_display = 'Single Elimination'
        print(f'      ✅ formatDisplayName = "{format_display}"')
    else:
        format_display = db_tournament_type.replace('_', ' ').upper() if db_tournament_type else 'KHÔNG XÁC ĐỊNH'
        print(f'      ❌ formatDisplayName = "{format_display}"')
    
    # 3. UI conversion possibilities
    print(f'\n   3️⃣ UI DATA CONVERSION SCENARIOS:')
    
    # Scenario A: Đang dùng tournamentType (8-ball) cho eliminationType
    print(f'      🅰️ Nếu dùng tournament.tournamentType:')
    print(f'         eliminationType = "{db_format}" → "Không xác định" ❌')
    
    # Scenario B: Đang dùng formatDisplayName (Double Elimination)
    print(f'      🅱️ Nếu dùng tournament.formatDisplayName:')
    print(f'         eliminationType = "{format_display}" → Đúng ✅')
    
    # Scenario C: Đang dùng format raw (double_elimination)
    print(f'      🅲️ Nếu dùng tournament.format raw:')
    print(f'         eliminationType = "{db_tournament_type}" → Cần format ⚠️')
    
    print(f'\n🎯 NHẬN ĐỊNH:')
    print(f'   • Database có format = "8-ball", tournament_type = "double_elimination"')
    print(f'   • Model mapping ĐÚNG: format ← tournament_type, tournamentType ← format') 
    print(f'   • formatDisplayName getter có logic cho "double_elimination" ✅')
    print(f'   • Vấn đề có thể ở UI conversion hoặc widget khác đang dùng sai field')
    
    print(f'\n🔍 CẦN KIỂM TRA:')
    print(f'   1. Tournament header widget')
    print(f'   2. Tournament info widget')  
    print(f'   3. Dropdown/selection widget')
    print(f'   4. Tournament list items')
    print(f'   5. Cache hoặc stale data')

else:
    print('❌ Không tìm thấy tournament sabo1')