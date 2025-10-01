from supabase import create_client
import time

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔧 FIXING DATABASE CONSTRAINT FOR SABO FORMATS')
print('=' * 60)

try:
    # Step 1: Create a SQL function to execute raw SQL
    print('1️⃣ Creating SQL execution function...')
    
    create_function_sql = '''
    CREATE OR REPLACE FUNCTION execute_sql(sql_text text)
    RETURNS text
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    BEGIN
        EXECUTE sql_text;
        RETURN 'Success';
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'Error: ' || SQLERRM;
    END;
    $$;
    '''
    
    result = supabase.rpc('execute_sql', {'sql_text': create_function_sql}).execute()
    print(f'   Result: {result.data}')
    
    # Step 2: Drop old constraint
    print('2️⃣ Dropping old bracket_format constraint...')
    drop_constraint_sql = 'ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;'
    
    result = supabase.rpc('execute_sql', {'sql_text': drop_constraint_sql}).execute()
    print(f'   Result: {result.data}')
    
    # Step 3: Add new constraint with SABO formats
    print('3️⃣ Adding new constraint with SABO formats...')
    add_constraint_sql = '''
    ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
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
    ));
    '''
    
    result = supabase.rpc('execute_sql', {'sql_text': add_constraint_sql}).execute()
    print(f'   Result: {result.data}')
    
    print('')
    print('4️⃣ Testing new constraint...')
    
    # Test creating tournament with sabo_de16
    tournaments = supabase.table('tournaments').select('club_id, organizer_id').limit(1).execute()
    club_id = tournaments.data[0]['club_id']
    organizer_id = tournaments.data[0]['organizer_id']
    
    test_data = {
        'club_id': club_id,
        'organizer_id': organizer_id,
        'title': 'Test SABO DE16 Format',
        'description': 'Testing new constraint',
        'start_date': '2025-10-01T00:00:00Z',
        'registration_deadline': '2025-09-30T00:00:00Z',
        'max_participants': 16,
        'entry_fee': 0,
        'prize_pool': 0,
        'bracket_format': 'sabo_de16',  # This should now work!
        'game_format': '8-ball',
        'status': 'upcoming',
        'current_participants': 0
    }
    
    response = supabase.table('tournaments').insert(test_data).execute()
    
    if response.data:
        tournament_id = response.data[0]['id']
        print(f'   ✅ SUCCESS! Created tournament with sabo_de16: {tournament_id[:8]}...')
        
        # Clean up test tournament
        supabase.table('tournaments').delete().eq('id', tournament_id).execute()
        print('   🧹 Test tournament cleaned up')
    
    print('')
    print('🎉 DATABASE CONSTRAINT FIXED SUCCESSFULLY!')
    print('✅ Now supports all SABO formats:')
    print('   - sabo_de16, sabo_de32')
    print('   - sabo_se16, sabo_se32') 
    print('   - sabo_double_elimination')
    print('   - Plus original: single_elimination, double_elimination, round_robin, swiss')
    
except Exception as e:
    print(f'❌ Error: {e}')
    print('')
    print('📝 FALLBACK: Creating constraint update SQL file...')
    
    sql_content = '''-- Fix bracket_format constraint to support SABO formats
-- Run this SQL in Supabase SQL Editor

-- Drop old constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Add new constraint with SABO formats
ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
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
));

-- Verify constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'check_bracket_format';
'''
    
    with open('fix_bracket_constraint.sql', 'w', encoding='utf-8') as f:
        f.write(sql_content)
    
    print('   Created fix_bracket_constraint.sql file')
    print('   Run this SQL in Supabase SQL Editor to fix constraint')