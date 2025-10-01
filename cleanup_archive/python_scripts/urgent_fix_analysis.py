from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🚨 URGENT FIX - TOURNAMENT FORMAT DISPLAY ISSUE')
print('=' * 60)

# Tìm tournament sabo1
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    t = tournament.data[0]
    print(f'📋 TOURNAMENT: {t["title"]}')
    
    db_format = t.get('format')  # "8-ball" 
    db_tournament_type = t.get('tournament_type')  # "double_elimination"
    
    print(f'\n🗄️ DATABASE:')
    print(f'   format = "{db_format}"')
    print(f'   tournament_type = "{db_tournament_type}"')
    
    print(f'\n🔄 APP MAPPING (Current):')
    print(f'   tournament.format (Dart) = "{db_tournament_type}" (double_elimination)')
    print(f'   tournament.tournamentType (Dart) = "{db_format}" (8-ball)')
    
    print(f'\n📱 UI DATA CONVERSION (_convertTournamentToUIData):')
    print(f'   _tournamentData["format"] = tournament.tournamentType = "{db_format}" (8-ball)')
    print(f'   _tournamentData["eliminationType"] = tournament.formatDisplayName = "Double Elimination"')
    
    print(f'\n🎯 HEADER WIDGET HIỂN THỊ:')
    print(f'   tournament["format"] = "{db_format}" (8-ball)')
    print(f'   Nhưng Header widget có thể có logic format display hidden!')
    
    print(f'\n🚨 PHÂN TÍCH NGUYÊN NHÂN "Không xác định":')
    print(f'   • Header widget nhận tournament["format"] = "8-ball"')
    print(f'   • Nhưng hiển thị "Không xác định" thay vì "8-ball"') 
    print(f'   • Có thể có function format display ẩn đang convert 8-ball → Không xác định')
    print(f'   • Hoặc có caching/state issue')
    
    print(f'\n💡 GIẢI PHÁP:')
    print(f'   1. HEADER widget nên hiển thị eliminationType thay vì format')
    print(f'   2. Format = game type (8-ball) chỉ hiển thị ở info detail')
    print(f'   3. Header badge nên hiển thị "Double Elimination"')
    
    print(f'\n🔧 HÀNH ĐỘNG CẦN LÀM:')
    print(f'   1. Sửa tournament_header_widget.dart')
    print(f'   2. Thay tournament["format"] → tournament["eliminationType"]')
    print(f'   3. Test để đảm bảo hiển thị "Double Elimination"')

else:
    print('❌ Không tìm thấy tournament sabo1')