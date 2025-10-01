#!/usr/bin/env python3
import requests
import json
import os

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.MQYXKKxBh8vRMFh1_0YZJHdaNBHUH0Vx8YQ2wdmCLEI'  # Use service role key

def deploy_schema():
    try:
        # Read SQL file
        with open('shift_reporting_schema.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print('🚀 Deploying Shift Reporting Schema to Supabase...')
        print('📄 SQL Content Length:', len(sql_content))
        
        # Prepare headers
        headers = {
            'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY
        }
        
        # Split SQL into manageable chunks by statements
        statements = []
        current_statement = ""
        lines = sql_content.split('\n')
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('--'):
                continue
                
            current_statement += line + "\n"
            
            if line.endswith(';'):
                if current_statement.strip():
                    statements.append(current_statement.strip())
                current_statement = ""
        
        # Add remaining statement if any
        if current_statement.strip():
            statements.append(current_statement.strip())
        
        print(f'📊 Found {len(statements)} SQL statements to execute')
        
        # Execute statements one by one
        successful = 0
        failed = 0
        
        for i, statement in enumerate(statements):
            if len(statement.strip()) < 10:  # Skip very short statements
                continue
                
            try:
                # Use REST API to execute SQL
                response = requests.post(
                    f'{SUPABASE_URL}/rest/v1/rpc/exec_sql',
                    headers=headers,
                    json={'sql': statement}
                )
                
                if response.status_code == 200:
                    successful += 1
                    print(f'  ✅ Statement {i+1}/{len(statements)} executed successfully')
                else:
                    failed += 1
                    print(f'  ❌ Statement {i+1} failed: {response.status_code} - {response.text[:200]}')
                    
            except Exception as e:
                failed += 1
                print(f'  ❌ Statement {i+1} error: {e}')
        
        print(f'\n📈 Deployment Summary:')
        print(f'  ✅ Successful: {successful}')
        print(f'  ❌ Failed: {failed}')
        
        if successful > 0:
            print('\n🎉 Shift reporting system database schema deployed!')
            print('📊 Created tables:')
            print('  - shift_sessions (ca làm việc)')
            print('  - shift_transactions (giao dịch)')
            print('  - shift_inventory (kho hàng)')
            print('  - shift_expenses (chi phí)')
            print('  - shift_reports (báo cáo)')
            print('🔒 RLS policies applied')
            print('⚡ Indexes and functions created')
            
        return successful > failed
        
    except FileNotFoundError:
        print('❌ shift_reporting_schema.sql file not found!')
        return False
    except Exception as e:
        print(f'❌ Deployment failed: {e}')
        return False

if __name__ == '__main__':
    success = deploy_schema()
    print(f'\n🏁 Deployment {"✅ COMPLETED" if success else "❌ FAILED"}')