#!/usr/bin/env python3
import requests
import json
import time

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

def deploy_shift_schema_direct():
    """Deploy shift reporting schema directly to Supabase using SQL execution"""
    
    print('🚀 Starting direct Supabase deployment...')
    
    try:
        # Read the schema file
        with open('shift_reporting_schema.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f'📄 Loaded schema file: {len(sql_content)} characters')
        
        # Split into individual statements for better error handling
        statements = []
        current_statement = ""
        in_function = False
        
        for line in sql_content.split('\n'):
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith('--'):
                continue
            
            # Check for function definitions
            if 'CREATE OR REPLACE FUNCTION' in line.upper():
                in_function = True
            elif in_function and line.endswith('$$;'):
                in_function = False
                current_statement += line + '\n'
                statements.append(current_statement.strip())
                current_statement = ""
                continue
            
            current_statement += line + '\n'
            
            # End of regular statement
            if line.endswith(';') and not in_function:
                if current_statement.strip():
                    statements.append(current_statement.strip())
                current_statement = ""
        
        # Add any remaining statement
        if current_statement.strip():
            statements.append(current_statement.strip())
        
        print(f'📊 Parsed {len(statements)} SQL statements')
        
        # Headers for Supabase API
        headers = {
            'apikey': SUPABASE_ANON_KEY,
            'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
        
        successful = 0
        failed = 0
        
        # Execute statements one by one
        for i, statement in enumerate(statements, 1):
            if len(statement) < 10:  # Skip very short statements
                continue
                
            print(f'⚡ Executing statement {i}/{len(statements)}...')
            
            try:
                # Use PostgREST to execute SQL via RPC
                response = requests.post(
                    f'{SUPABASE_URL}/rest/v1/rpc/query',
                    headers=headers,
                    json={'query': statement},
                    timeout=30
                )
                
                if response.status_code in [200, 201, 204]:
                    successful += 1
                    print(f'  ✅ Success: {statement[:50]}...')
                else:
                    failed += 1
                    print(f'  ❌ Failed ({response.status_code}): {statement[:50]}...')
                    print(f'     Error: {response.text[:200]}')
                    
                # Small delay to avoid rate limiting
                time.sleep(0.1)
                
            except requests.exceptions.RequestException as e:
                failed += 1
                print(f'  ❌ Network error: {e}')
            except Exception as e:
                failed += 1
                print(f'  ❌ Error: {e}')
        
        print(f'\n📈 Deployment Summary:')
        print(f'  ✅ Successful: {successful}')
        print(f'  ❌ Failed: {failed}')
        
        if successful > 0:
            print('\n🎉 Schema deployment completed!')
            print('📊 Verifying tables...')
            verify_deployment()
        else:
            print('\n💡 Try alternative deployment method...')
            try_alternative_deployment()
            
    except FileNotFoundError:
        print('❌ shift_reporting_schema.sql file not found!')
    except Exception as e:
        print(f'❌ Deployment failed: {e}')
        print('\n💡 Trying alternative approaches...')
        try_alternative_deployment()

def verify_deployment():
    """Verify that tables were created successfully"""
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Check if tables exist by trying to access them
    tables_to_check = [
        'shift_sessions',
        'shift_transactions', 
        'shift_inventory',
        'shift_expenses',
        'shift_reports'
    ]
    
    print('\n🔍 Verifying table creation...')
    
    for table in tables_to_check:
        try:
            response = requests.get(
                f'{SUPABASE_URL}/rest/v1/{table}?limit=1',
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                print(f'  ✅ Table {table} exists and accessible')
            else:
                print(f'  ❌ Table {table} not accessible: {response.status_code}')
                
        except Exception as e:
            print(f'  ❌ Error checking {table}: {e}')

def try_alternative_deployment():
    """Try alternative deployment methods"""
    print('\n🔄 Trying alternative deployment methods...')
    
    # Method 1: Create tables individually
    try:
        create_basic_tables()
    except Exception as e:
        print(f'❌ Alternative method 1 failed: {e}')
    
    # Method 2: Manual instructions
    print('\n📋 Manual deployment instructions:')
    print('1. Go to https://supabase.com/dashboard')
    print('2. Select your project')
    print('3. Go to SQL Editor')
    print('4. Paste the content of shift_reporting_schema.sql')
    print('5. Click RUN to execute')

def create_basic_tables():
    """Create basic table structure if full schema fails"""
    print('🔧 Creating basic table structure...')
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Basic table creation SQL
    basic_sql = """
    CREATE TABLE IF NOT EXISTS shift_sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        club_id UUID NOT NULL,
        staff_id UUID NOT NULL,
        shift_date DATE NOT NULL,
        start_time TIME NOT NULL,
        end_time TIME,
        opening_cash DECIMAL(12,2) DEFAULT 0,
        total_revenue DECIMAL(12,2) DEFAULT 0,
        status TEXT DEFAULT 'active',
        created_at TIMESTAMP DEFAULT NOW()
    );
    """
    
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/rpc/query',
            headers=headers,
            json={'query': basic_sql},
            timeout=30
        )
        
        if response.status_code in [200, 201, 204]:
            print('✅ Basic shift_sessions table created')
        else:
            print(f'❌ Failed to create basic table: {response.text}')
            
    except Exception as e:
        print(f'❌ Basic table creation failed: {e}')

if __name__ == '__main__':
    deploy_shift_schema_direct()