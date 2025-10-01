#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Apply Rank Default Fix to Database Schema
Chạy script SQL để fix database schema cho rank default
"""

import json
import requests

def load_config():
    """Load Supabase configuration"""
    try:
        with open('env.json', 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print("❌ File env.json not found!")
        return None

def apply_rank_schema_fix():
    """Apply the rank schema fix via direct SQL execution"""
    
    print("🛠️ APPLYING RANK SCHEMA FIX TO DATABASE")
    print("=" * 50)
    
    config = load_config()
    if not config:
        return False
    
    SUPABASE_URL = config['SUPABASE_URL']
    SERVICE_ROLE_KEY = config['SUPABASE_SERVICE_ROLE_KEY']
    
    headers = {
        'apikey': SERVICE_ROLE_KEY,
        'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
        'Content-Type': 'application/json'
    }
    
    # Read the SQL fix script
    print("📝 Reading SQL fix script...")
    try:
        with open('fix_rank_default_schema.sql', 'r', encoding='utf-8') as f:
            sql_script = f.read()
        print("✅ SQL script loaded successfully")
    except FileNotFoundError:
        print("❌ SQL script file not found!")
        return False
    
    # Try to execute via a custom function approach
    print("🔧 Attempting to execute SQL fixes...")
    
    # Split SQL into individual statements
    sql_statements = [stmt.strip() for stmt in sql_script.split(';') if stmt.strip() and not stmt.strip().startswith('--')]
    
    success_count = 0
    total_statements = len(sql_statements)
    
    for i, statement in enumerate(sql_statements, 1):
        if not statement or statement == 'SELECT':
            continue
            
        print(f"📋 Executing statement {i}/{total_statements}...")
        print(f"   SQL: {statement[:60]}...")
        
        # Try different approaches to execute SQL
        approaches = [
            'execute_sql',
            'exec_sql', 
            'run_sql',
            'query',
            'sql_query'
        ]
        
        executed = False
        for approach in approaches:
            try:
                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/rpc/{approach}",
                    headers=headers,
                    json={'sql_query': statement} if approach in ['exec_sql', 'sql_query'] else {'sql': statement}
                )
                
                if response.status_code in [200, 201, 204]:
                    print(f"   ✅ Success via {approach}")
                    success_count += 1
                    executed = True
                    break
                elif response.status_code != 404:
                    print(f"   ⚠️ {approach}: {response.status_code} - {response.text[:100]}")
                    
            except Exception as e:
                print(f"   ❌ {approach}: {str(e)[:50]}")
        
        if not executed:
            print(f"   ❌ Could not execute statement via RPC")
    
    print(f"\n🎉 EXECUTION SUMMARY:")
    print(f"   ✅ Successfully executed: {success_count}/{total_statements} statements")
    
    if success_count < total_statements:
        print(f"\n⚠️ Some statements failed. Please manually run the SQL:")
        print(f"   1. Go to Supabase Dashboard > SQL Editor")
        print(f"   2. Copy content from 'fix_rank_default_schema.sql'")
        print(f"   3. Execute it manually")
    else:
        print(f"\n🎉 All fixes applied successfully!")
        print(f"   🔍 New users will now be unranked by default")
        print(f"   ✅ Existing problematic users have been fixed")
    
    return success_count > 0

if __name__ == "__main__":
    apply_rank_schema_fix()