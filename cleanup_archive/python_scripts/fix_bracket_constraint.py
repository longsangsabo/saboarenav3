from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

try:
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    print('🔧 FIXING BRACKET FORMAT CONSTRAINT')
    print('=' * 50)
    
    # Drop the old constraint and create new flexible one
    sql_commands = [
        # Drop existing constraint
        "ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;",
        
        # Add new flexible constraint that allows all our formats
        """ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
           CHECK (bracket_format IN (
               'SE4', 'SE8', 'SE16', 'SE32', 'SE64',
               'DE4', 'DE8', 'DE16', 'DE32', 'DE64',
               'single_elimination', 'double_elimination',
               'round_robin', 'swiss'
           ));"""
    ]
    
    for sql in sql_commands:
        print(f'⚡ Executing: {sql[:50]}...')
        result = supabase.rpc('exec_sql', {'sql': sql}).execute()
        
    print('')
    print('✅ CONSTRAINT UPDATED SUCCESSFULLY!')
    print('✅ Now supports: SE4, SE8, SE16, SE32, SE64, DE4, DE8, DE16, DE32, DE64')
    print('✅ Tournament "SABO DE16" should work now!')
    
except Exception as e:
    print(f'❌ Error: {e}')
    print('📝 Manual SQL needed - executing direct SQL...')
    
    # Manual execution
    manual_sql = """
-- Drop old constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Add new constraint supporting all formats
ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN (
    'SE4', 'SE8', 'SE16', 'SE32', 'SE64',
    'DE4', 'DE8', 'DE16', 'DE32', 'DE64',
    'single_elimination', 'double_elimination',
    'round_robin', 'swiss'
));
"""
    
    print(manual_sql)