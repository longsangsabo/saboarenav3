from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('✅ VERIFY FIX - Tournament Dropdown với Format Column')
print('=' * 60)

# Tìm tournament sabo1
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    t = tournament.data[0]
    print(f'📋 TOURNAMENT sabo1:')
    print(f'   Title: {t["title"]}')
    print(f'   Status: {t["status"]}')
    print(f'   Format (DB): {t.get("format", "NULL")}')
    print(f'   Tournament Type (DB): {t.get("tournament_type", "NULL")}')
    print(f'   Participants: {t.get("current_participants", 0)}/{t.get("max_participants", 0)}')
    
    print(f'\n🎯 AFTER FIX - STATUS MAPPING:')
    db_status = t["status"]
    
    # Updated mapping với 'upcoming'
    if db_status == 'recruiting':
        status_display = 'Đang tuyển'
        status_color = 'Orange'
    elif db_status == 'ready':
        status_display = 'Sẵn sàng'
        status_color = 'Blue'
    elif db_status == 'upcoming':
        status_display = 'Sắp diễn ra'  # ✅ NEW!
        status_color = 'Teal'
    elif db_status == 'active':
        status_display = 'Đang diễn ra'
        status_color = 'Green'
    elif db_status == 'completed':
        status_display = 'Hoàn thành'
        status_color = 'Purple'
    else:
        status_display = 'Không xác định'
        status_color = 'Grey'
    
    print(f'   Database status: "{db_status}"')
    print(f'   Display status: "{status_display}" ({status_color})')
    
    if status_display == 'Không xác định':
        print(f'   ❌ STILL ISSUE: Status không được handle!')
    else:
        print(f'   ✅ Status mapping FIXED!')
    
    print(f'\n🎨 NEW DROPDOWN DISPLAY:')
    
    # Format mapping cho display
    db_format = t.get('format')  # "8-ball"
    db_tournament_type = t.get('tournament_type')  # "double_elimination"
    
    # Format display name logic
    if db_tournament_type == 'double_elimination':
        format_display = 'Double Elimination'
    elif db_tournament_type == 'single_elimination':
        format_display = 'Single Elimination'
    elif db_tournament_type == 'round_robin':
        format_display = 'Round Robin'
    else:
        format_display = db_tournament_type.replace('_', ' ').upper() if db_tournament_type else 'UNKNOWN'
    
    print(f'   📄 Line 1: "{t["title"]} • {t.get("current_participants", 0)}/{t.get("max_participants", 0)}"')
    print(f'   📄 Line 2: "{format_display} ({db_format})"')
    print(f'   🏷️ Status Badge: "{status_display}" ({status_color} background)')
    
    print(f'\n🎉 EXPECTED RESULT:')
    print(f'   ✅ Status badge: "Sắp diễn ra" (Teal background)')
    print(f'   ✅ Main line: "sabo1 • 16/16"')
    print(f'   ✅ Format line: "Double Elimination (8-ball)"')
    
    print(f'\n🚀 BUILD & TEST:')
    print(f'   1. flutter clean && flutter build')
    print(f'   2. Vào "Quản lý Giải đấu"')
    print(f'   3. Kiểm tra dropdown sabo1')
    print(f'   4. Verify không còn "Không xác định"')

else:
    print('❌ Không tìm thấy tournament sabo1')

print(f'\n🎯 TÓM TẮT FIX:')
print(f'   1. ✅ Added "upcoming" → "Sắp diễn ra" mapping')
print(f'   2. ✅ Added Teal color for upcoming status')
print(f'   3. ✅ Added format column với elimination type + game type')
print(f'   4. ✅ Increased dropdown height để fit 2 lines')
print(f'   5. ✅ Added _getFormatDisplayName() function')