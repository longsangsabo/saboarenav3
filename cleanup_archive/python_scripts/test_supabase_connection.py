from supabase import create_client
import json

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

print('🔌 KIỂM TRA KẾT NỐI SUPABASE')
print('=' * 50)

try:
    # Initialize Supabase client
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    print('✅ Supabase client initialized successfully')
    
    # Test connection by querying tournaments table
    tournaments = supabase.table('tournaments').select('id, title, bracket_format').limit(5).execute()
    
    if tournaments.data:
        print(f'✅ Connection successful! Found {len(tournaments.data)} tournaments')
        print('\n📋 CURRENT TOURNAMENTS:')
        for t in tournaments.data:
            print(f'   - {t["title"][:20]:20} | Format: {t["bracket_format"]}')
    else:
        print('⚠️  Connection OK but no tournaments found')
    
    # Test service role permissions
    print('\n🔐 TESTING SERVICE ROLE PERMISSIONS:')
    
    # Try to read system tables (only service_role can do this)
    try:
        # Check if we can access pg_constraint to see constraints
        result = supabase.rpc('get_table_constraints', {'table_name': 'tournaments'}).execute()
        print('✅ Service role permissions confirmed - can access system info')
    except Exception as e:
        print(f'⚠️  Limited permissions: {str(e)[:50]}...')
    
    print('\n🎯 CONNECTION STATUS: READY TO FIX DATABASE!')
    
except Exception as e:
    print(f'❌ Connection failed: {e}')
    print('   Check SUPABASE_URL and SERVICE_KEY')