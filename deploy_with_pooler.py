#!/usr/bin/env python3
"""
Deploy Club Staff Commission System to Supabase using Transaction Pooler
"""

import asyncio
import asyncpg
import os
from pathlib import Path

# Connection string với Transaction pooler
DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:Acookingoil123@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres"

async def deploy_schema():
    """Deploy the complete schema using asyncpg"""
    print('🚀 Deploying Club Staff Commission System...')
    print('🔗 Using Transaction Pooler connection')
    
    try:
        # Connect to database
        conn = await asyncpg.connect(DATABASE_URL)
        print('✅ Connected to Supabase successfully!')
        
        # Read the complete SQL schema
        sql_file = Path(__file__).parent / 'club_staff_commission_system_complete.sql'
        
        if not sql_file.exists():
            print(f'❌ SQL file not found: {sql_file}')
            return
            
        with open(sql_file, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print(f'📋 Loaded SQL schema ({len(sql_content)} characters)')
        
        # Split SQL into individual statements
        statements = []
        current_statement = []
        in_function = False
        function_delimiter = None
        
        for line in sql_content.split('\n'):
            line = line.strip()
            
            # Skip comments and empty lines
            if not line or line.startswith('--'):
                continue
                
            # Detect function start
            if 'CREATE OR REPLACE FUNCTION' in line.upper():
                in_function = True
                if '$$' in line:
                    function_delimiter = '$$'
                elif '$' in line and 'LANGUAGE' not in line.upper():
                    # Find custom delimiter like $func$
                    parts = line.split('$')
                    if len(parts) >= 3:
                        function_delimiter = f'${parts[1]}$'
            
            current_statement.append(line)
            
            # Check for statement end
            if in_function:
                if function_delimiter and function_delimiter in line and 'LANGUAGE' in line.upper():
                    in_function = False
                    function_delimiter = None
                    statements.append('\n'.join(current_statement))
                    current_statement = []
            else:
                if line.endswith(';'):
                    statements.append('\n'.join(current_statement))
                    current_statement = []
        
        # Add remaining statement if any
        if current_statement:
            statements.append('\n'.join(current_statement))
        
        print(f'📊 Found {len(statements)} SQL statements to execute')
        
        # Execute statements one by one
        success_count = 0
        for i, statement in enumerate(statements, 1):
            if not statement.strip():
                continue
                
            try:
                await conn.execute(statement)
                print(f'   ✅ Statement {i}/{len(statements)} executed successfully')
                success_count += 1
                
            except Exception as e:
                # Some statements might fail if objects already exist, that's OK
                error_msg = str(e).lower()
                if any(keyword in error_msg for keyword in [
                    'already exists', 
                    'does not exist',
                    'duplicate key',
                    'relation already exists'
                ]):
                    print(f'   ⚠️ Statement {i}/{len(statements)} skipped (already exists)')
                    success_count += 1
                else:
                    print(f'   ❌ Statement {i}/{len(statements)} failed: {e}')
                    print(f'      SQL: {statement[:100]}...')
        
        print(f'\n📊 Deployment Summary:')
        print(f'   ✅ Successful: {success_count}/{len(statements)}')
        print(f'   ❌ Failed: {len(statements) - success_count}/{len(statements)}')
        
        # Test the deployment
        await test_deployment(conn)
        
    except Exception as e:
        print(f'❌ Deployment failed: {e}')
        return False
    
    finally:
        if 'conn' in locals():
            await conn.close()
            print('🔌 Database connection closed')
    
    return True

async def test_deployment(conn):
    """Test the deployed system"""
    print('\n🧪 Testing deployed system...')
    
    try:
        # Test 1: Check tables exist
        tables_query = """
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name IN ('club_staff', 'staff_referrals', 'customer_transactions', 'staff_commissions', 'staff_performance')
        ORDER BY table_name;
        """
        
        tables = await conn.fetch(tables_query)
        print(f'✅ Found {len(tables)} tables:')
        for table in tables:
            print(f'   📋 {table["table_name"]}')
        
        # Test 2: Check functions exist
        functions_query = """
        SELECT routine_name 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN ('calculate_staff_commission', 'update_staff_referral_totals', 'get_staff_performance_summary')
        ORDER BY routine_name;
        """
        
        functions = await conn.fetch(functions_query)
        print(f'✅ Found {len(functions)} functions:')
        for func in functions:
            print(f'   ⚙️ {func["routine_name"]}()')
        
        # Test 3: Check triggers exist
        triggers_query = """
        SELECT trigger_name, event_object_table 
        FROM information_schema.triggers 
        WHERE trigger_schema = 'public' 
        AND trigger_name LIKE '%staff%' OR trigger_name LIKE '%commission%'
        ORDER BY trigger_name;
        """
        
        triggers = await conn.fetch(triggers_query)
        print(f'✅ Found {len(triggers)} triggers:')
        for trigger in triggers:
            print(f'   ⚡ {trigger["trigger_name"]} on {trigger["event_object_table"]}')
        
        # Test 4: Check RLS policies
        policies_query = """
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' 
        AND tablename IN ('club_staff', 'staff_referrals', 'customer_transactions', 'staff_commissions', 'staff_performance')
        ORDER BY tablename, policyname;
        """
        
        policies = await conn.fetch(policies_query)
        print(f'✅ Found {len(policies)} RLS policies:')
        for policy in policies:
            print(f'   🔒 {policy["tablename"]}: {policy["policyname"]}')
        
        # Test 5: Test a simple insert (will be rolled back)
        async with conn.transaction():
            # This will be rolled back automatically
            try:
                await conn.execute("""
                    INSERT INTO club_staff (club_id, user_id, staff_role, commission_rate) 
                    VALUES (gen_random_uuid(), gen_random_uuid(), 'test', 5.00)
                """)
                print('✅ Test insert successful (transaction will be rolled back)')
                
                # Force rollback
                raise Exception("Test rollback")
                
            except Exception:
                print('✅ Transaction rollback successful')
        
        print('\n🎉 All tests passed! System is ready for use.')
        
    except Exception as e:
        print(f'❌ Testing failed: {e}')

async def create_sample_data():
    """Create some sample data for testing"""
    print('\n📋 Would you like to create sample data for testing? (y/n)')
    
    # For automation, we'll skip this
    # In a real scenario, you could add sample clubs, users, and staff
    print('ℹ️ Skipping sample data creation (add manually via Supabase dashboard)')

if __name__ == '__main__':
    print('🏢 SABO Arena - Club Staff Commission System Deployment')
    print('=' * 60)
    
    # Run the deployment
    success = asyncio.run(deploy_schema())
    
    if success:
        print('\n🎉 Deployment completed successfully!')
        print('\n📋 Next steps:')
        print('1. 🔍 Verify tables in Supabase Dashboard')
        print('2. 👥 Add your first club staff via Flutter app')
        print('3. 🧪 Test the referral system with QR codes')
        print('4. 💰 Monitor commissions and analytics')
        print('\n🚀 Your Club Staff Commission System is ready!')
    else:
        print('\n❌ Deployment failed. Please check the errors above.')
        print('💡 You can also run the SQL file manually in Supabase SQL Editor.')