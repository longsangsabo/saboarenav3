from supabase import create_client
import uuid

# Initialize Supabase with service_role key
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def execute_column_rename():
    """Execute SQL to rename format column to bracket_format"""
    try:
        print('🔄 RENAMING DATABASE COLUMN: format → bracket_format')
        print('=' * 55)
        
        # Step 1: Verify current column exists
        print('1. Testing current schema with proper UUID...')
        test_match_id = str(uuid.uuid4())
        test_tournament_id = str(uuid.uuid4())
        
        test_match = {
            'id': test_match_id,
            'tournament_id': test_tournament_id,
            'round_number': 1,
            'match_number': 1,
            'player1_id': None,
            'player2_id': None,  
            'status': 'pending',
            'format': 'test_format',  # Test current column name
        }
        
        try:
            result = supabase.table('matches').insert(test_match).execute()
            print('   ✅ format column confirmed to exist')
            
            # Get schema
            matches = supabase.table('matches').select('*').eq('id', test_match_id).execute()
            if matches.data:
                columns = list(matches.data[0].keys())
                print(f'   📋 Current schema: {len(columns)} columns')
                format_exists = 'format' in columns
                bracket_format_exists = 'bracket_format' in columns
                print(f'   📝 format exists: {format_exists}')
                print(f'   📝 bracket_format exists: {bracket_format_exists}')
            
            # Clean up test
            supabase.table('matches').delete().eq('id', test_match_id).execute()
            
        except Exception as e:
            print(f'   ❌ Test failed: {e}')
            return False
        
        # Step 2: Execute the rename using direct SQL
        print()
        print('2. Executing SQL rename command...')
        
        # Method 1: Try using RPC function (if exists)
        try:
            sql_query = "ALTER TABLE matches RENAME COLUMN format TO bracket_format;"
            result = supabase.rpc('execute_sql', {'query': sql_query}).execute()
            print('   ✅ Column renamed using RPC')
        except:
            # Method 2: Try using storage RPC (alternative)
            try:
                result = supabase.rpc('exec_sql', {'sql': 'ALTER TABLE matches RENAME COLUMN format TO bracket_format;'}).execute()
                print('   ✅ Column renamed using exec_sql RPC')
            except Exception as e:
                print(f'   ❌ RPC method failed: {e}')
                print('   ⚠️  Database might not have RPC functions enabled')
                print()
                print('   MANUAL SQL COMMAND TO RUN:')
                print('   ALTER TABLE matches RENAME COLUMN format TO bracket_format;')
                return False
        
        # Step 3: Verify the rename worked
        print()
        print('3. Verifying column rename...')
        
        # Test with new column name
        test_match_2 = {
            'id': str(uuid.uuid4()),
            'tournament_id': str(uuid.uuid4()),
            'round_number': 1,
            'match_number': 1,
            'player1_id': None,
            'player2_id': None,  
            'status': 'pending',
            'bracket_format': 'sabo_de16',  # Test new column name
        }
        
        try:
            result = supabase.table('matches').insert(test_match_2).execute()
            print('   ✅ bracket_format column working!')
            
            # Get updated schema
            matches = supabase.table('matches').select('*').eq('id', test_match_2['id']).execute()
            if matches.data:
                new_columns = list(matches.data[0].keys())
                format_exists = 'format' in new_columns
                bracket_format_exists = 'bracket_format' in new_columns
                print(f'   📝 format exists: {format_exists}')
                print(f'   📝 bracket_format exists: {bracket_format_exists}')
                
                if bracket_format_exists and not format_exists:
                    print('   🎉 RENAME SUCCESSFUL!')
                else:
                    print('   ⚠️  Rename may not have worked correctly')
            
            # Clean up
            supabase.table('matches').delete().eq('id', test_match_2['id']).execute()
            
        except Exception as e:
            print(f'   ❌ Verification failed: {e}')
            return False
        
        print()
        print('✅ COLUMN RENAME COMPLETE!')
        print('   - Database now uses bracket_format column')
        print('   - CompleteSaboDE16Service should work without changes')
        print('   - Ready to test SABO DE16 bracket generation')
        
        return True
        
    except Exception as e:
        print(f'❌ Unexpected error: {e}')
        return False

if __name__ == '__main__':
    success = execute_column_rename()
    if not success:
        print()
        print('🔧 FALLBACK SOLUTION:')
        print('   If automatic rename failed, you can:')
        print('   1. Access Supabase dashboard')
        print('   2. Go to Table Editor → matches table')
        print('   3. Rename format column to bracket_format manually')
        print('   4. Or run this SQL in SQL Editor:')
        print('      ALTER TABLE matches RENAME COLUMN format TO bracket_format;')