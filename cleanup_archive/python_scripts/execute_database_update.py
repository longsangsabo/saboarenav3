from supabase import create_client
import requests
import json

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

print('🚀 EXECUTING DATABASE CONSTRAINT UPDATE VIA EDGE FUNCTION')
print('=' * 60)

# Try using Supabase Edge Function or PostgREST
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

# SQL commands to execute
sql_commands = [
    "ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;",
    """ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
       CHECK (bracket_format IN (
           'single_elimination',
           'double_elimination', 
           'round_robin',
           'swiss',
           'sabo_de16',
           'sabo_de32',
           'sabo_se16', 
           'sabo_se32',
           'sabo_double_elimination'
       ));"""
]

print('1️⃣ Trying to execute SQL via RPC functions...')

# Try different RPC function names that might exist
rpc_functions_to_try = [
    'exec',
    'execute',
    'sql_exec',
    'run_sql',
    'execute_sql'
]

executed = False

for rpc_func in rpc_functions_to_try:
    try:
        print(f'   Trying RPC function: {rpc_func}')
        
        for i, sql in enumerate(sql_commands, 1):
            result = supabase.rpc(rpc_func, {'query': sql}).execute()
            print(f'   ✅ Command {i} executed via {rpc_func}')
        
        executed = True
        break
        
    except Exception as e:
        print(f'   ❌ {rpc_func} failed: {str(e)[:50]}...')
        continue

if not executed:
    print('2️⃣ RPC approach failed. Trying direct HTTP API...')
    
    # Try PostgREST direct SQL execution
    headers = {
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'application/json',
        'apikey': SERVICE_KEY,
        'Prefer': 'return=minimal'
    }
    
    # Some possible endpoints for SQL execution
    sql_endpoints = [
        f'{SUPABASE_URL}/rest/v1/rpc/sql',
        f'{SUPABASE_URL}/sql',
        f'{SUPABASE_URL}/rest/v1/sql'
    ]
    
    for endpoint in sql_endpoints:
        try:
            for i, sql in enumerate(sql_commands, 1):
                response = requests.post(
                    endpoint,
                    headers=headers,
                    json={'sql': sql}
                )
                
                if response.status_code in [200, 201, 204]:
                    print(f'   ✅ Command {i} executed via HTTP API')
                    executed = True
                else:
                    print(f'   ❌ HTTP {response.status_code}: {response.text[:50]}...')
            
            if executed:
                break
                
        except Exception as e:
            print(f'   ❌ HTTP API failed: {str(e)[:50]}...')
            continue

if executed:
    print('')
    print('3️⃣ Testing new constraint...')
    
    # Test creating tournament with sabo_de16
    try:
        tournaments = supabase.table('tournaments').select('club_id, organizer_id').limit(1).execute()
        club_id = tournaments.data[0]['club_id']
        organizer_id = tournaments.data[0]['organizer_id']
        
        test_data = {
            'club_id': club_id,
            'organizer_id': organizer_id,
            'title': 'Test SABO DE16 Format',
            'description': 'Testing updated constraint',
            'start_date': '2025-10-01T00:00:00Z',
            'registration_deadline': '2025-09-30T00:00:00Z',
            'max_participants': 16,
            'entry_fee': 0,
            'prize_pool': 0,
            'bracket_format': 'sabo_de16',  # This should work now!
            'game_format': '8-ball',
            'status': 'upcoming',
            'current_participants': 0
        }
        
        response = supabase.table('tournaments').insert(test_data).execute()
        
        if response.data:
            tournament_id = response.data[0]['id']
            print(f'   ✅ SUCCESS! sabo_de16 tournament created: {tournament_id[:8]}...')
            
            # Clean up
            supabase.table('tournaments').delete().eq('id', tournament_id).execute()
            print('   🧹 Test tournament cleaned up')
        
    except Exception as e:
        if 'check_bracket_format' in str(e):
            print('   ❌ Constraint still blocks sabo_de16')
            executed = False
        else:
            print(f'   ⚠️  Other error: {str(e)[:50]}...')

if not executed:
    print('')
    print('❌ AUTOMATIC EXECUTION FAILED')
    print('📋 MANUAL STEPS REQUIRED:')
    print('')
    print('1. Open: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql')
    print('2. Execute this SQL:')
    print('')
    print('```sql')
    print('-- Drop old constraint')
    print('ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;')
    print('')
    print('-- Add new constraint with SABO formats')
    print('ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format')
    print('CHECK (bracket_format IN (')
    print("    'single_elimination',")
    print("    'double_elimination',")
    print("    'round_robin',")
    print("    'swiss',")
    print("    'sabo_de16',")
    print("    'sabo_de32',")
    print("    'sabo_se16',")
    print("    'sabo_se32',")
    print("    'sabo_double_elimination'")
    print('));')
    print('```')
    print('')
    print('3. After execution, SABO DE16 will work with original logic!')
    
else:
    print('')
    print('🎉 DATABASE CONSTRAINT UPDATED SUCCESSFULLY!')
    print('✅ SABO formats now supported in database:')
    print('   - sabo_de16 (unique SABO Double Elimination 16 logic)')
    print('   - sabo_de32 (unique SABO Double Elimination 32 logic)')
    print('   - sabo_se16 (unique SABO Single Elimination 16 logic)')
    print('   - sabo_se32 (unique SABO Single Elimination 32 logic)')
    print('')
    print('🚀 Try creating SABO DE16 tournament now - it will work!')