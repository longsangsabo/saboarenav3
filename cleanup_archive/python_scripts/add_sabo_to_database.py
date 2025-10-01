from supabase import create_client
import psycopg2
from urllib.parse import urlparse

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

print('🔧 ADDING SABO FORMATS TO DATABASE CONSTRAINT')
print('=' * 60)

# Extract connection info from Supabase URL
parsed_url = urlparse(SUPABASE_URL)
host = parsed_url.netloc
database = 'postgres'

# Try to connect directly to PostgreSQL
print('1️⃣ Attempting direct PostgreSQL connection...')

# Common PostgreSQL connection parameters for Supabase
connection_params = [
    {
        'host': 'db.mogjjvscxjwvhtpkrlqr.supabase.co',
        'port': 5432,
        'database': 'postgres',
        'user': 'postgres',
        'password': 'your-supabase-db-password'  # Need real password
    },
    {
        'host': 'aws-0-ap-southeast-1.pooler.supabase.com',
        'port': 6543,
        'database': 'postgres', 
        'user': 'postgres.mogjjvscxjwvhtpkrlqr',
        'password': 'your-supabase-db-password'  # Need real password
    }
]

# Since we don't have the direct DB password, let's create SQL file instead
print('2️⃣ Creating SQL script to execute in Supabase Dashboard...')

sql_script = '''-- ================================
-- ADD SABO FORMATS TO DATABASE CONSTRAINT
-- Execute this in Supabase SQL Editor
-- ================================

BEGIN;

-- Step 1: Drop existing constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Step 2: Add new constraint with SABO formats
ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN (
    -- Original formats
    'single_elimination',
    'double_elimination',
    'round_robin',
    'swiss',
    
    -- SABO specific formats with unique logic
    'sabo_de16',           -- SABO Double Elimination 16 players
    'sabo_de32',           -- SABO Double Elimination 32 players  
    'sabo_se16',           -- SABO Single Elimination 16 players
    'sabo_se32',           -- SABO Single Elimination 32 players
    'sabo_double_elimination' -- SABO Double Elimination (general)
));

-- Step 3: Verify constraint was created
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'check_bracket_format';

-- Step 4: Test the new constraint
INSERT INTO tournaments (
    club_id, 
    organizer_id, 
    title, 
    description,
    start_date, 
    registration_deadline, 
    max_participants,
    entry_fee, 
    prize_pool, 
    bracket_format,  -- This should now accept sabo_de16!
    game_format,
    status, 
    current_participants
) VALUES (
    (SELECT club_id FROM tournaments LIMIT 1),
    (SELECT organizer_id FROM tournaments LIMIT 1),
    'Test SABO DE16 Format',
    'Testing new SABO constraint',
    '2025-10-01 00:00:00+00',
    '2025-09-30 00:00:00+00',
    16,
    0,
    0,  
    'sabo_de16',  -- This should work now!
    '8-ball',
    'upcoming',
    0
);

-- Step 5: Clean up test data
DELETE FROM tournaments WHERE title = 'Test SABO DE16 Format';

COMMIT;

-- ================================
-- VERIFICATION QUERIES
-- ================================

-- Check if constraint allows SABO formats
SELECT 'Constraint updated successfully' as status;

-- List all allowed bracket formats
SELECT unnest(string_to_array(
    substring(pg_get_constraintdef(oid) from '\\((.*?)\\)'), ','
)) as allowed_formats
FROM pg_constraint 
WHERE conname = 'check_bracket_format';
'''

# Write SQL script to file
with open('add_sabo_formats_to_database.sql', 'w', encoding='utf-8') as f:
    f.write(sql_script)

print('✅ Created add_sabo_formats_to_database.sql')
print('')
print('🎯 EXECUTE THIS SQL IN SUPABASE DASHBOARD:')
print('1. Open https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr')
print('2. Go to SQL Editor')
print('3. Copy content from add_sabo_formats_to_database.sql')
print('4. Execute the SQL')
print('')
print('✅ After execution, these formats will be supported:')
print('   - sabo_de16 (SABO Double Elimination 16)')
print('   - sabo_de32 (SABO Double Elimination 32)')
print('   - sabo_se16 (SABO Single Elimination 16)')
print('   - sabo_se32 (SABO Single Elimination 32)')
print('   - Plus all original formats')
print('')
print('🚀 Then SABO DE16 tournament creation will work with original logic!')

# Also test using Supabase client with service role
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('')
print('3️⃣ Testing current constraint status...')
try:
    # Try to get sample data to understand current state
    tournaments = supabase.table('tournaments').select('bracket_format').execute()
    formats = set()
    for t in tournaments.data:
        if t['bracket_format']:
            formats.add(t['bracket_format'])
    
    print(f'   Current formats in database: {sorted(formats)}')
    
    # Try to create with sabo_de16 to test constraint
    print('   Testing sabo_de16 constraint...')
    test_tournament = {
        'club_id': tournaments.data[0]['club_id'] if tournaments.data else 'test',
        'organizer_id': tournaments.data[0]['organizer_id'] if tournaments.data else 'test',
        'title': 'Test SABO DE16',
        'description': 'Test',
        'start_date': '2025-10-01T00:00:00Z',
        'registration_deadline': '2025-09-30T00:00:00Z',
        'max_participants': 16,
        'entry_fee': 0,
        'prize_pool': 0,
        'bracket_format': 'sabo_de16',
        'game_format': '8-ball',
        'status': 'upcoming',
        'current_participants': 0
    }
    
    response = supabase.table('tournaments').insert(test_tournament).execute()
    if response.data:
        print('   ✅ sabo_de16 already works! Constraint may be updated.')
        # Clean up
        supabase.table('tournaments').delete().eq('id', response.data[0]['id']).execute()
    
except Exception as e:
    if 'check_bracket_format' in str(e):
        print('   ❌ Constraint still blocks sabo_de16')
        print('   ➡️  Execute the SQL script to fix this')
    else:
        print(f'   ⚠️  Other error: {str(e)[:100]}...')

print('')
print('💡 IMPORTANT: sabo_de16 has different logic than double_elimination')
print('   Each SABO format needs specific implementation in bracket services')