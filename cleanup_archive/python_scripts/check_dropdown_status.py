from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA DROPDOWN TOURNAMENT SELECTOR')
print('=' * 50)

# Tìm tournament sabo1
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    t = tournament.data[0]
    print(f'📋 TOURNAMENT sabo1:')
    print(f'   Title: {t["title"]}')
    print(f'   Status: {t["status"]}')
    print(f'   Format (DB): {t.get("format", "NULL")}')
    print(f'   Tournament Type (DB): {t.get("tournament_type", "NULL")}')
    print(f'   Current Participants: {t.get("current_participants", 0)}')
    print(f'   Max Participants: {t.get("max_participants", 0)}')
    
    print(f'\n🎯 STATUS MAPPING ANALYSIS:')
    db_status = t["status"]
    
    # Mapping logic từ _getStatusText function
    if db_status == 'recruiting':
        status_display = 'Đang tuyển'
    elif db_status == 'ready':
        status_display = 'Sẵn sàng'
    elif db_status == 'active':
        status_display = 'Đang diễn ra'
    elif db_status == 'completed':
        status_display = 'Hoàn thành'
    else:
        status_display = 'Không xác định'
    
    print(f'   Database status: "{db_status}"')
    print(f'   Display status: "{status_display}"')
    
    if status_display == 'Không xác định':
        print(f'   ❌ FOUND ISSUE: Status "{db_status}" không có trong mapping!')
    else:
        print(f'   ✅ Status mapping OK')
    
    print(f'\n🎨 DROPDOWN DISPLAY INFO:')
    print(f'   Hiện tại dropdown chỉ hiển thị:')
    print(f'   • Status badge: "{status_display}"')
    print(f'   • Title + participants: "{t["title"]} • {t.get("current_participants", 0)}/{t.get("max_participants", 0)}"')
    
    print(f'\n💡 ĐỀ XUẤT THÊM FORMAT COLUMN:')
    
    # Format mapping
    db_format = t.get('format')  # "8-ball"
    db_tournament_type = t.get('tournament_type')  # "double_elimination"
    
    # Elimination format display
    if db_tournament_type == 'double_elimination':
        elimination_display = 'Double Elimination'
    elif db_tournament_type == 'single_elimination':
        elimination_display = 'Single Elimination'
    elif db_tournament_type == 'round_robin':
        elimination_display = 'Round Robin'
    else:
        elimination_display = 'Unknown Format'
    
    print(f'   • Format column có thể hiển thị: "{elimination_display}"')
    print(f'   • Game type: "{db_format}"')
    
    print(f'\n🔧 CẦN FIX:')
    if status_display == 'Không xác định':
        print(f'   1. Fix status mapping cho "{db_status}"')
    print(f'   2. Thêm format column vào dropdown')
    print(f'   3. Hiển thị: "{elimination_display} ({db_format})"')

else:
    print('❌ Không tìm thấy tournament sabo1')

print(f'\n📋 KIỂM TRA TẤT CẢ TOURNAMENTS:')
all_tournaments = supabase.table('tournaments').select('id, title, status, format, tournament_type, current_participants, max_participants').execute()

if all_tournaments.data:
    print(f'Tổng cộng: {len(all_tournaments.data)} tournaments')
    for i, t in enumerate(all_tournaments.data, 1):
        db_status = t.get('status', 'NULL')
        
        # Status mapping
        if db_status == 'recruiting':
            status_display = 'Đang tuyển'
        elif db_status == 'ready':
            status_display = 'Sẵn sàng' 
        elif db_status == 'active':
            status_display = 'Đang diễn ra'
        elif db_status == 'completed':
            status_display = 'Hoàn thành'
        else:
            status_display = 'Không xác định'
            
        print(f'   {i}. {t.get("title", "NULL")}: status="{db_status}" → display="{status_display}"')
        
        if status_display == 'Không xác định':
            print(f'      ⚠️ CẦN FIX STATUS: "{db_status}"')