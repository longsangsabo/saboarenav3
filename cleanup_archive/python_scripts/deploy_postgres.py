#!/usr/bin/env python3
import psycopg2
import sys
from urllib.parse import urlparse

# Supabase Database URL
DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:password@aws-0-ap-southeast-1.pooler.supabase.co:6543/postgres"

def deploy_with_psycopg2():
    """Deploy schema using direct PostgreSQL connection"""
    
    print('🚀 Attempting PostgreSQL direct connection...')
    
    try:
        # Read schema file
        with open('shift_reporting_schema.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f'📄 Loaded schema: {len(sql_content)} characters')
        
        # Parse connection URL
        print('🔗 Connecting to Supabase PostgreSQL...')
        
        # Try to connect (this will likely fail due to security)
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        
        print('✅ Connected successfully!')
        
        # Execute schema
        print('⚡ Executing schema...')
        cursor.execute(sql_content)
        conn.commit()
        
        print('✅ Schema deployed successfully!')
        
        # Verify tables
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name LIKE 'shift_%'
            ORDER BY table_name;
        """)
        
        tables = cursor.fetchall()
        print(f'\n📊 Created tables:')
        for table in tables:
            print(f'  ✅ {table[0]}')
            
        cursor.close()
        conn.close()
        
        return True
        
    except psycopg2.OperationalError as e:
        print(f'❌ Connection failed: {e}')
        print('🔒 This is expected - Supabase doesn\'t allow direct connections from external IPs')
        return False
        
    except FileNotFoundError:
        print('❌ shift_reporting_schema.sql not found!')
        return False
        
    except Exception as e:
        print(f'❌ Deployment failed: {e}')
        return False

def try_supabase_cli():
    """Try using Supabase CLI if available"""
    print('\n🔧 Checking for Supabase CLI...')
    
    import subprocess
    import shutil
    
    if shutil.which('supabase'):
        print('✅ Supabase CLI found!')
        try:
            # Try to run SQL via CLI
            result = subprocess.run([
                'supabase', 'db', 'push', 
                '--db-url', DATABASE_URL,
                '--file', 'shift_reporting_schema.sql'
            ], capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                print('✅ Deployed via Supabase CLI!')
                return True
            else:
                print(f'❌ CLI failed: {result.stderr}')
                return False
                
        except subprocess.TimeoutExpired:
            print('❌ CLI timeout')
            return False
        except Exception as e:
            print(f'❌ CLI error: {e}')
            return False
    else:
        print('❌ Supabase CLI not found')
        return False

def show_manual_instructions():
    """Show detailed manual deployment instructions"""
    print('\n' + '='*60)
    print('📋 MANUAL DEPLOYMENT INSTRUCTIONS')
    print('='*60)
    
    print('\n🎯 EASIEST METHOD - Supabase Dashboard:')
    print('1. Go to: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr')
    print('2. Click "SQL Editor" in left sidebar')
    print('3. Click "+ New Query" button')
    print('4. Copy ALL content from: shift_reporting_schema.sql')
    print('5. Paste into the SQL editor')
    print('6. Click "RUN" button (or Ctrl+Enter)')
    print('7. Wait for completion message')
    
    print('\n✅ EXPECTED RESULT:')
    print('- 5 new tables created (shift_sessions, shift_transactions, etc.)')
    print('- Multiple indexes created')
    print('- RLS policies applied')
    print('- Helper functions deployed')
    
    print('\n🔍 VERIFICATION:')
    print('Run this query in SQL Editor to verify:')
    print("""
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'shift_%'
ORDER BY table_name;
    """)
    
    print('\n⚠️  IF ERRORS OCCUR:')
    print('- Make sure you\'re logged in as project owner')
    print('- Check for any existing tables with same names')
    print('- Run DROP TABLE statements first if needed')
    print('- Execute schema in smaller chunks if needed')
    
    print('\n📞 NEED HELP?')
    print('- Copy any error messages for troubleshooting')
    print('- The schema file is ready at: shift_reporting_schema.sql')
    print('- All RLS policies included for security')

def main():
    print('🎯 SUPABASE SHIFT REPORTING SCHEMA DEPLOYMENT')
    print('=' * 50)
    
    # Try direct connection (will likely fail)
    if deploy_with_psycopg2():
        print('\n🎉 SUCCESS! Schema deployed via direct connection!')
        return
    
    # Try Supabase CLI
    if try_supabase_cli():
        print('\n🎉 SUCCESS! Schema deployed via Supabase CLI!')
        return
    
    # Show manual instructions if automated methods fail
    show_manual_instructions()
    
    print('\n💡 RECOMMENDATION:')
    print('Use the manual Supabase Dashboard method above.')
    print('It\'s the most reliable way to deploy the schema.')
    print('\n🚀 Ready to deploy when you are!')

if __name__ == '__main__':
    main()