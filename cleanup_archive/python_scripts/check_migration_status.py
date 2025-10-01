from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔍 CHECKING CURRENT DATABASE SCHEMA:')
print('=' * 50)

# Get tournaments table schema
tournaments = supabase.table('tournaments').select('*').limit(1).execute()
if tournaments.data:
    columns = list(tournaments.data[0].keys())
    format_columns = [col for col in columns if 'format' in col.lower()]
    
    print('📋 Format-related columns in tournaments table:')
    for col in format_columns:
        print(f'   ✅ {col}')
    
    print(f'\n🎯 Total format columns: {len(format_columns)}')
    
    # Check sabo1 data
    sabo1 = supabase.table('tournaments').select('title, game_format, bracket_format').eq('title', 'sabo1').execute()
    if sabo1.data:
        t = sabo1.data[0]
        print(f'\n🏆 sabo1 tournament data:')
        print(f'   game_format: {t.get("game_format")}')
        print(f'   bracket_format: {t.get("bracket_format")}')
    
    if len(format_columns) == 2 and 'game_format' in format_columns and 'bracket_format' in format_columns:
        print(f'\n✅ MIGRATION ALREADY COMPLETE!')
        print(f'✅ Database has clean schema with only 2 format columns!')
        print(f'🚀 READY FOR IMMEDIATE ADVANCEMENT TESTING!')
    else:
        print(f'\n⚠️ Migration needed - found {len(format_columns)} format columns')
        print('All format columns:', format_columns)
else:
    print('❌ No tournament data found')