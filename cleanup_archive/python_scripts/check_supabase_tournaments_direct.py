from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA TRỰC TIẾP BẢNG TOURNAMENTS')
print('=' * 60)

# Lấy tất cả tournaments và kiểm tra 2 cột tournament_type và format
try:
    result = supabase.table('tournaments').select('id, title, format, tournament_type, created_at').order('created_at').execute()
    
    if result.data:
        print(f'📊 Tìm thấy {len(result.data)} tournaments:')
        print()
        
        for i, tournament in enumerate(result.data, 1):
            print(f'{i:2}. 🏆 {tournament.get("title", "No title")}')
            print(f'     ID: {tournament.get("id", "No ID")[:8]}...')
            print(f'     📋 format: "{tournament.get("format", "NULL")}"')
            print(f'     🎮 tournament_type: "{tournament.get("tournament_type", "NULL")}"')
            print(f'     📅 Created: {tournament.get("created_at", "Unknown")[:10]}')
            print()
            
        print('🔍 PHÂN TÍCH DỮ LIỆU:')
        print('-' * 40)
        
        format_values = [t.get('format') for t in result.data if t.get('format')]
        tournament_type_values = [t.get('tournament_type') for t in result.data if t.get('tournament_type')]
        
        print(f'📋 Các giá trị trong cột FORMAT:')
        unique_formats = list(set(format_values))
        for fmt in unique_formats:
            count = format_values.count(fmt)
            print(f'   • "{fmt}" - {count} tournament(s)')
        
        print(f'\n🎮 Các giá trị trong cột TOURNAMENT_TYPE:')
        unique_types = list(set(tournament_type_values))
        for typ in unique_types:
            count = tournament_type_values.count(typ)
            print(f'   • "{typ}" - {count} tournament(s)')
        
        print(f'\n📊 THỐNG KÊ:')
        print(f'   • Tổng tournaments: {len(result.data)}')
        print(f'   • Có format: {len(format_values)}')
        print(f'   • Có tournament_type: {len(tournament_type_values)}')
        print(f'   • Format NULL: {len(result.data) - len(format_values)}')
        print(f'   • Tournament_type NULL: {len(result.data) - len(tournament_type_values)}')
        
        print(f'\n🔄 MAPPING HIỆN TẠI (theo code đã fix):')
        print(f'   • Database format → Tournament.tournamentType (game type)')
        print(f'   • Database tournament_type → Tournament.format (elimination format)')
        
    else:
        print('❌ Không tìm thấy tournaments nào')
        
except Exception as e:
    print(f'❌ Lỗi kết nối Supabase: {e}')