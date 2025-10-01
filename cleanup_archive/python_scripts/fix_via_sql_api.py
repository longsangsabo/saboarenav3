import requests
import json

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

print('🔧 FIXING DATABASE CONSTRAINT VIA SQL EDGE FUNCTION')
print('=' * 60)

# Try using Supabase SQL Edge Function API
headers = {
    'Authorization': f'Bearer {SERVICE_KEY}',
    'Content-Type': 'application/json',
    'apikey': SERVICE_KEY
}

# SQL commands to fix constraint
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

print('1️⃣ Attempting to execute SQL commands...')

for i, sql in enumerate(sql_commands, 1):
    print(f'   Command {i}: {sql[:50]}...')
    
    # Try different API endpoints
    endpoints_to_try = [
        f'{SUPABASE_URL}/rest/v1/rpc/execute_sql',
        f'{SUPABASE_URL}/rest/v1/rpc/sql_execute',
        f'{SUPABASE_URL}/functions/v1/sql-executor'
    ]
    
    executed = False
    for endpoint in endpoints_to_try:
        try:
            response = requests.post(
                endpoint,
                headers=headers,
                json={'sql': sql}
            )
            
            if response.status_code == 200:
                print(f'   ✅ Success via {endpoint.split("/")[-1]}')
                executed = True
                break
            else:
                print(f'   ❌ Failed {endpoint.split("/")[-1]}: {response.status_code}')
                
        except Exception as e:
            continue
    
    if not executed:
        print(f'   ⚠️  Could not execute command {i}')

print('')
print('2️⃣ Alternative approach - Create SQL file for manual execution...')

# Create SQL file for manual execution
sql_file_content = '''-- Fix bracket_format constraint to support SABO formats
-- Copy and paste this SQL into Supabase SQL Editor

BEGIN;

-- Drop existing constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Add new constraint supporting SABO formats
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

-- Verify the constraint was created
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'check_bracket_format';

COMMIT;

-- Test the constraint by trying to insert a test tournament
-- (This should work now)
/*
INSERT INTO tournaments (
    club_id, organizer_id, title, description, 
    start_date, registration_deadline, max_participants,
    entry_fee, prize_pool, bracket_format, game_format,
    status, current_participants, created_at, updated_at
) VALUES (
    (SELECT club_id FROM tournaments LIMIT 1),
    (SELECT organizer_id FROM tournaments LIMIT 1),
    'Test SABO DE16',
    'Testing new constraint',
    '2025-10-01 00:00:00+00',
    '2025-09-30 00:00:00+00',
    16,
    0,
    0,
    'sabo_de16',  -- This should work now!
    '8-ball',
    'upcoming',
    0,
    NOW(),
    NOW()
);

-- Clean up test data
DELETE FROM tournaments WHERE title = 'Test SABO DE16';
*/
'''

with open('EXECUTE_THIS_IN_SUPABASE.sql', 'w', encoding='utf-8') as f:
    f.write(sql_file_content)

print('✅ Created EXECUTE_THIS_IN_SUPABASE.sql')
print('')
print('🎯 NEXT STEPS:')
print('1. Open Supabase Dashboard → SQL Editor')
print('2. Copy content from EXECUTE_THIS_IN_SUPABASE.sql')
print('3. Run the SQL commands')
print('4. After successful execution, SABO DE16 creation will work!')
print('')
print('💡 Or you can continue using the format mapping in Flutter code.')
print('   Both approaches work - database fix is cleaner long-term.')