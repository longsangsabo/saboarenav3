#!/usr/bin/env python3
import requests
import json
import time

# Supabase configuration with service role
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def deploy_with_service_role():
    """Deploy schema using service role key"""
    
    print('🚀 Deploying with Service Role Key...')
    
    try:
        # Read schema file
        with open('shift_reporting_schema.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f'📄 Loaded schema: {len(sql_content)} characters')
        
        # Headers with service role
        headers = {
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
        
        # Split SQL into individual statements
        statements = []
        current_statement = ""
        in_function = False
        paren_count = 0
        
        lines = sql_content.split('\n')
        
        for line in lines:
            stripped = line.strip()
            
            # Skip comments and empty lines
            if not stripped or stripped.startswith('--'):
                continue
            
            # Track function boundaries
            if 'CREATE OR REPLACE FUNCTION' in stripped.upper():
                in_function = True
                current_statement += line + '\n'
                continue
            elif in_function and stripped.endswith('$$;'):
                in_function = False
                current_statement += line + '\n'
                statements.append(current_statement.strip())
                current_statement = ""
                continue
            elif in_function:
                current_statement += line + '\n'
                continue
            
            # Regular statement processing
            current_statement += line + '\n'
            
            # End of statement
            if stripped.endswith(';'):
                if current_statement.strip():
                    statements.append(current_statement.strip())
                current_statement = ""
        
        print(f'📊 Parsed {len(statements)} SQL statements')
        
        # Try different API endpoints for SQL execution
        endpoints_to_try = [
            '/rest/v1/rpc/exec_sql',
            '/rest/v1/rpc/execute_sql', 
            '/rest/v1/rpc/sql_exec',
            '/database/sql'
        ]
        
        successful = 0
        failed = 0
        
        for endpoint in endpoints_to_try:
            print(f'\n🔄 Trying endpoint: {endpoint}')
            
            # Try to execute full schema at once
            try:
                response = requests.post(
                    f'{SUPABASE_URL}{endpoint}',
                    headers=headers,
                    json={'sql': sql_content},
                    timeout=60
                )
                
                if response.status_code in [200, 201, 204]:
                    print('✅ Full schema executed successfully!')
                    successful = len(statements)
                    break
                else:
                    print(f'❌ Endpoint {endpoint} failed: {response.status_code}')
                    print(f'Response: {response.text[:200]}')
                    
            except Exception as e:
                print(f'❌ Error with {endpoint}: {e}')
                continue
        
        # If full schema failed, try individual statements
        if successful == 0:
            print('\n🔄 Trying individual statements...')
            
            for i, statement in enumerate(statements, 1):
                if len(statement.strip()) < 10:
                    continue
                
                print(f'⚡ Executing statement {i}/{len(statements)}...')
                print(f'   {statement[:60]}...')
                
                for endpoint in ['/rest/v1/rpc/exec_sql', '/database/sql']:
                    try:
                        response = requests.post(
                            f'{SUPABASE_URL}{endpoint}',
                            headers=headers,
                            json={'sql': statement},
                            timeout=30
                        )
                        
                        if response.status_code in [200, 201, 204]:
                            successful += 1
                            print(f'  ✅ Success')
                            break
                        else:
                            print(f'  ❌ Failed ({response.status_code}): {response.text[:100]}')
                            
                    except Exception as e:
                        print(f'  ❌ Error: {e}')
                        continue
                else:
                    failed += 1
                
                # Small delay
                time.sleep(0.2)
        
        print(f'\n📈 Deployment Summary:')
        print(f'  ✅ Successful: {successful}')
        print(f'  ❌ Failed: {failed}')
        
        if successful > 0:
            print('\n🎉 Some statements executed successfully!')
            verify_deployment()
        else:
            print('\n❌ No statements executed successfully.')
            try_raw_postgres_connection()
            
    except FileNotFoundError:
        print('❌ shift_reporting_schema.sql not found!')
    except Exception as e:
        print(f'❌ Deployment failed: {e}')

def try_raw_postgres_connection():
    """Try direct PostgreSQL connection with service role credentials"""
    print('\n🔄 Trying direct PostgreSQL connection...')
    
    try:
        import psycopg2
        
        # Try different connection strings
        connection_strings = [
            "postgresql://postgres:password@db.mogjjvscxjwvhtpkrlqr.supabase.co:5432/postgres",
            "postgresql://postgres.mogjjvscxjwvhtpkrlqr:password@aws-0-ap-southeast-1.pooler.supabase.co:6543/postgres",
            "postgresql://service_role@db.mogjjvscxjwvhtpkrlqr.supabase.co:5432/postgres"
        ]
        
        for conn_str in connection_strings:
            try:
                print(f'🔗 Trying: {conn_str[:50]}...')
                conn = psycopg2.connect(conn_str)
                cursor = conn.cursor()
                
                print('✅ Connected! Executing schema...')
                
                with open('shift_reporting_schema.sql', 'r') as f:
                    schema_sql = f.read()
                
                cursor.execute(schema_sql)
                conn.commit()
                
                print('✅ Schema deployed successfully via PostgreSQL!')
                
                cursor.close()
                conn.close()
                return True
                
            except Exception as e:
                print(f'❌ Connection failed: {e}')
                continue
    
    except ImportError:
        print('❌ psycopg2 not available')
    
    return False

def verify_deployment():
    """Verify deployment by checking tables"""
    print('\n🔍 Verifying deployment...')
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    tables_to_check = [
        'shift_sessions',
        'shift_transactions', 
        'shift_inventory',
        'shift_expenses',
        'shift_reports'
    ]
    
    for table in tables_to_check:
        try:
            response = requests.get(
                f'{SUPABASE_URL}/rest/v1/{table}?limit=1',
                headers=headers,
                timeout=10
            )
            
            if response.status_code == 200:
                print(f'  ✅ Table {table} exists and accessible')
            elif response.status_code == 406:
                # Table exists but no data
                print(f'  ✅ Table {table} exists (empty)')
            else:
                print(f'  ❌ Table {table} not accessible: {response.status_code}')
                
        except Exception as e:
            print(f'  ❌ Error checking {table}: {e}')

def create_basic_structure():
    """Create basic table structure if full schema fails"""
    print('\n🔧 Creating basic table structure as fallback...')
    
    headers = {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Basic table SQL
    basic_tables = [
        """
        CREATE TABLE IF NOT EXISTS shift_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            club_id UUID NOT NULL,
            staff_id UUID NOT NULL,
            shift_date DATE NOT NULL DEFAULT CURRENT_DATE,
            start_time TIME NOT NULL DEFAULT CURRENT_TIME,
            end_time TIME,
            opening_cash DECIMAL(12,2) DEFAULT 0,
            closing_cash DECIMAL(12,2),
            total_revenue DECIMAL(12,2) DEFAULT 0,
            cash_revenue DECIMAL(12,2) DEFAULT 0,
            status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'handed_over')),
            notes TEXT,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW()
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS shift_transactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            shift_session_id UUID NOT NULL,
            club_id UUID NOT NULL,
            transaction_type TEXT NOT NULL CHECK (transaction_type IN ('revenue', 'expense', 'refund')),
            category TEXT NOT NULL,
            description TEXT NOT NULL,
            amount DECIMAL(12,2) NOT NULL,
            payment_method TEXT NOT NULL CHECK (payment_method IN ('cash', 'card', 'digital')),
            recorded_at TIMESTAMP DEFAULT NOW(),
            created_at TIMESTAMP DEFAULT NOW()
        );
        """
    ]
    
    for i, sql in enumerate(basic_tables, 1):
        try:
            # Try multiple endpoints
            for endpoint in ['/rest/v1/rpc/exec_sql', '/database/sql']:
                try:
                    response = requests.post(
                        f'{SUPABASE_URL}{endpoint}',
                        headers=headers,
                        json={'sql': sql},
                        timeout=30
                    )
                    
                    if response.status_code in [200, 201, 204]:
                        print(f'  ✅ Basic table {i} created')
                        break
                    else:
                        print(f'  ❌ Basic table {i} failed: {response.text[:100]}')
                        
                except Exception as e:
                    print(f'  ❌ Error creating basic table {i}: {e}')
                    continue
                    
        except Exception as e:
            print(f'❌ Failed to create basic table {i}: {e}')

def main():
    print('🎯 SUPABASE DEPLOYMENT WITH SERVICE ROLE')
    print('=' * 50)
    print('🔑 Using Service Role Key for elevated permissions')
    print()
    
    # Try deployment with service role
    deploy_with_service_role()
    
    print('\n💡 If deployment failed, you can still use manual method:')
    print('1. Go to Supabase Dashboard SQL Editor')
    print('2. Copy content from shift_reporting_schema.sql')
    print('3. Paste and execute')
    print('\n🚀 Deployment attempt completed!')

if __name__ == '__main__':
    main()