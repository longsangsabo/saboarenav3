#!/usr/bin/env python3
"""
Deploy Privacy Settings Schema to Supabase
Executes user_privacy_settings_schema.sql via Supabase REST API
"""

import requests
import json
import os
import sys

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

def execute_sql_statement(sql_statement):
    """Execute a single SQL statement via Supabase Edge Function or direct execution."""
    
    # For now, let's try to create the table using REST API
    # This is a workaround since we can't execute raw SQL directly
    
    # Check if this is a CREATE TABLE statement for user_privacy_settings
    if 'CREATE TABLE user_privacy_settings' in sql_statement:
        print("⚠️  Cannot create tables via REST API. Need Supabase Dashboard or CLI.")
        return False
    
    # Check if this is a CREATE FUNCTION statement
    if 'CREATE OR REPLACE FUNCTION' in sql_statement:
        print("⚠️  Cannot create functions via REST API. Need Supabase Dashboard or CLI.")
        return False
        
    # Check if this is a CREATE POLICY statement
    if 'CREATE POLICY' in sql_statement:
        print("⚠️  Cannot create policies via REST API. Need Supabase Dashboard or CLI.")
        return False
        
    print(f"⚠️  Skipping SQL statement (not supported via REST API)")
    return False

def deploy_privacy_schema():
    """Deploy the privacy settings schema to Supabase."""
    
    print("🚀 Starting Privacy Settings Schema Deployment")
    print(f"📡 Target: {SUPABASE_URL}")
    
    # Read schema file
    try:
        with open('user_privacy_settings_schema.sql', 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        print(f"📝 Read schema file: {len(schema_sql)} characters")
    except FileNotFoundError:
        print("❌ Schema file 'user_privacy_settings_schema.sql' not found!")
        return False
    
    # Test connection first
    try:
        response = requests.get(
            f'{SUPABASE_URL}/rest/v1/',
            headers={
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': f'Bearer {SUPABASE_ANON_KEY}'
            },
            timeout=10
        )
        if response.status_code != 200:
            print(f"❌ Supabase connection failed: {response.status_code}")
            return False
        print("✅ Supabase connection verified")
    except Exception as e:
        print(f"❌ Connection error: {e}")
        return False
    
    # Split schema into statements
    statements = [stmt.strip() for stmt in schema_sql.split(';') if stmt.strip()]
    print(f"📋 Found {len(statements)} SQL statements")
    
    print("\n" + "="*60)
    print("⚠️  IMPORTANT NOTICE:")
    print("Due to Supabase REST API limitations, SQL schema deployment")
    print("requires manual execution via Supabase Dashboard.")
    print("="*60)
    
    print(f"\n📋 Schema Summary:")
    create_table_count = sum(1 for stmt in statements if 'CREATE TABLE' in stmt.upper())
    create_function_count = sum(1 for stmt in statements if 'CREATE OR REPLACE FUNCTION' in stmt.upper())
    create_policy_count = sum(1 for stmt in statements if 'CREATE POLICY' in stmt.upper())
    
    print(f"   📄 Tables to create: {create_table_count}")
    print(f"   ⚙️  Functions to create: {create_function_count}")
    print(f"   🔒 Policies to create: {create_policy_count}")
    
    # Show statements that need manual execution
    print(f"\n🔧 Manual Execution Required:")
    print(f"1. Go to Supabase Dashboard: https://supabase.com/dashboard")
    print(f"2. Navigate to SQL Editor")
    print(f"3. Copy and execute the content of 'user_privacy_settings_schema.sql'")
    print(f"4. Verify tables and functions are created successfully")
    
    return True

def verify_schema_deployment():
    """Verify that the privacy schema has been deployed successfully."""
    
    print("\n🔍 Verifying schema deployment...")
    
    # Check if user_privacy_settings table exists by trying to query it
    try:
        response = requests.get(
            f'{SUPABASE_URL}/rest/v1/user_privacy_settings?limit=1',
            headers={
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
                'Content-Type': 'application/json'
            },
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ user_privacy_settings table exists and accessible")
            return True
        elif response.status_code == 404:
            print("❌ user_privacy_settings table not found")
            return False
        else:
            print(f"⚠️  Unexpected response: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Verification error: {e}")
        return False

def main():
    """Main deployment function."""
    
    print("Privacy Settings Schema Deployment Tool")
    print("=" * 50)
    
    # Deploy schema (show instructions)
    if not deploy_privacy_schema():
        print("❌ Schema deployment preparation failed")
        sys.exit(1)
    
    # Check if already deployed
    if verify_schema_deployment():
        print("\n🎉 Privacy schema is already deployed and working!")
        
        # Test the functions
        print("\n🧪 Testing privacy functions...")
        test_privacy_functions()
    else:
        print("\n📝 Next Steps:")
        print("1. Execute the SQL schema manually in Supabase Dashboard")
        print("2. Run this script again to verify deployment")
        print("3. Test privacy functions in your Flutter app")

def test_privacy_functions():
    """Test privacy functions via RPC calls."""
    
    # Test get_user_privacy_settings function
    try:
        response = requests.post(
            f'{SUPABASE_URL}/rest/v1/rpc/get_user_privacy_settings',
            headers={
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
                'Content-Type': 'application/json'
            },
            json={'p_user_id': 'test-user-id'},
            timeout=10
        )
        
        if response.status_code == 200:
            print("✅ get_user_privacy_settings function works")
            result = response.json()
            print(f"   📊 Function result: {result}")
        else:
            print(f"❌ get_user_privacy_settings function failed: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Function test error: {e}")

if __name__ == '__main__':
    main()