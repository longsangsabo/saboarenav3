from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA FORMAT CỦA GIẢI sabo1')
print('=' * 45)

# Tìm tournament sabo1
print('1. 🎯 TÌM TOURNAMENT sabo1:')
tournament = supabase.table('tournaments').select('*').ilike('title', '%sabo1%').execute()

if tournament.data:
    for i, t in enumerate(tournament.data, 1):
        print(f'   {i}. Title: {t.get("title", "NULL")}')
        print(f'      ID: {t.get("id", "NULL")}')
        print(f'      Format (DB): {t.get("format", "NULL")}')
        print(f'      Tournament Type (DB): {t.get("tournament_type", "NULL")}')
        print(f'      Status: {t.get("status", "NULL")}')
        print(f'      Created: {t.get("created_at", "NULL")[:19] if t.get("created_at") else "NULL"}')
        
        # Kiểm tra format mapping
        db_format = t.get("format")
        db_tournament_type = t.get("tournament_type")
        
        print(f'\n   🔄 FORMAT ANALYSIS:')
        print(f'      - Database format field: "{db_format}"')
        print(f'      - Database tournament_type field: "{db_tournament_type}"')
        
        # Mapping logic như trong app
        if db_format == 'double_elimination':
            print(f'      ✅ SHOULD DISPLAY: "Double Elimination"')
        elif db_format == 'single_elimination':
            print(f'      ✅ SHOULD DISPLAY: "Single Elimination"')
        elif db_format == 'round_robin':
            print(f'      ✅ SHOULD DISPLAY: "Round Robin"')
        else:
            print(f'      ❌ UNKNOWN FORMAT: Will display "Không xác định"')
        
        print('   ' + '-' * 40)
else:
    print('   ❌ Không tìm thấy tournament sabo1')

# Kiểm tra tất cả tournaments để tìm pattern
print('\n2. 🔍 KIỂM TRA TẤT CẢ TOURNAMENTS:')
all_tournaments = supabase.table('tournaments').select('id, title, format, tournament_type, status').execute()

if all_tournaments.data:
    print(f'   📊 Tổng cộng: {len(all_tournaments.data)} tournaments')
    
    format_counts = {}
    for t in all_tournaments.data:
        fmt = t.get('format', 'NULL')
        format_counts[fmt] = format_counts.get(fmt, 0) + 1
    
    print(f'\n   📈 FORMAT DISTRIBUTION:')
    for fmt, count in format_counts.items():
        print(f'      {fmt}: {count} tournaments')
        
    print(f'\n   🎯 RECENT TOURNAMENTS:')
    for i, t in enumerate(all_tournaments.data[-5:], 1):
        title = t.get('title', 'NULL')[:20] + '...' if len(t.get('title', '')) > 20 else t.get('title', 'NULL')
        print(f'      {i}. {title} -> format: "{t.get("format", "NULL")}"')

print('\n3. 💡 DIAGNOSIS:')
print('   Nếu format đang có giá trị đúng trong DB nhưng app hiển thị "Không xác định"')
print('   thì có thể là vấn đề ở:')
print('   • formatDisplayName getter trong Tournament model')
print('   • Logic hiển thị trong UI component')
print('   • Case sensitivity trong string comparison')
print('   • Null/empty value handling')