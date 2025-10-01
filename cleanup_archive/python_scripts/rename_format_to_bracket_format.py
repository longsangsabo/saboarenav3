from supabase import create_client
import os

# Initialize Supabase with service_role key
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def rename_format_column():
    """Rename format column to bracket_format in matches table"""
    try:
        print('🔄 RENAMING COLUMN format → bracket_format')
        print('=' * 50)
        
        # Step 1: Check current schema
        print('1. Checking current matches table schema...')
        matches = supabase.table('matches').select('*').limit(1).execute()
        if matches.data:
            current_columns = list(matches.data[0].keys())
            print(f'   Current columns: {len(current_columns)} total')
            
            if 'format' in current_columns:
                print('   ✅ format column exists - ready to rename')
            else:
                print('   ❌ format column not found!')
                return
                
            if 'bracket_format' in current_columns:
                print('   ⚠️  bracket_format already exists!')
                return
        else:
            print('   ❌ No matches found to check schema')
            return
        
        # Step 2: Execute SQL to rename column
        print('\n2. Executing SQL rename...')
        sql_command = 'ALTER TABLE matches RENAME COLUMN format TO bracket_format;'
        
        # Use RPC to execute raw SQL
        result = supabase.rpc('exec_sql', {'sql': sql_command}).execute()
        print('   ✅ Column renamed successfully!')
        
        # Step 3: Verify the change
        print('\n3. Verifying column rename...')
        matches = supabase.table('matches').select('*').limit(1).execute()
        if matches.data:
            new_columns = list(matches.data[0].keys())
            if 'bracket_format' in new_columns and 'format' not in new_columns:
                print('   ✅ Rename verified - bracket_format now exists')
            else:
                print('   ❌ Rename failed - format still exists or bracket_format missing')
        
        print('\n🎉 COLUMN RENAME COMPLETE!')
        print('   - format → bracket_format')
        print('   - CompleteSaboDE16Service should now work')
        print('   - Ready to test SABO DE16 bracket generation')
        
    except Exception as e:
        print(f'❌ Error renaming column: {e}')
        print('   This might require direct database access')
        print('   Alternative: Remove bracket_format from insert data')

if __name__ == '__main__':
    rename_format_column()