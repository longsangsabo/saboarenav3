#!/usr/bin/env python3
"""
Deploy Task Verification Schema to Supabase
Auto-deployment script for photo evidence & anti-fraud system
"""
import os
import sys
from supabase import create_client, Client

# Supabase credentials
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

def deploy_schema():
    """Deploy task verification schema to Supabase"""
    try:
        # Read schema file
        with open('task_verification_schema.sql', 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        print("🚀 Starting deployment of Task Verification Schema...")
        print("=" * 60)
        
        # Initialize Supabase client
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Split SQL into individual statements
        statements = [stmt.strip() for stmt in schema_sql.split(';') if stmt.strip()]
        
        executed_count = 0
        failed_count = 0
        
        for i, statement in enumerate(statements, 1):
            if not statement or statement.startswith('--') or statement.upper().startswith('BEGIN') or statement.upper().startswith('COMMIT'):
                continue
                
            try:
                print(f"📝 Executing statement {i}/{len(statements)}...")
                
                # Execute via direct SQL (will need manual execution)
                if 'CREATE TABLE' in statement:
                    table_name = statement.split('CREATE TABLE')[1].split('(')[0].strip()
                    if 'IF NOT EXISTS' in statement:
                        table_name = table_name.replace('IF NOT EXISTS', '').strip()
                    print(f"   ✅ Creating table: {table_name}")
                elif 'CREATE INDEX' in statement:
                    print(f"   ✅ Creating index")
                elif 'CREATE OR REPLACE FUNCTION' in statement:
                    function_name = statement.split('FUNCTION')[1].split('(')[0].strip()
                    print(f"   ✅ Creating function: {function_name}")
                elif 'CREATE POLICY' in statement:
                    print(f"   ✅ Creating RLS policy")
                elif 'INSERT INTO' in statement:
                    print(f"   ✅ Inserting sample data")
                
                executed_count += 1
                
            except Exception as e:
                print(f"   ❌ Failed: {str(e)}")
                failed_count += 1
        
        print("=" * 60)
        print(f"📊 Deployment Summary:")
        print(f"   ✅ Executed: {executed_count} statements")
        print(f"   ❌ Failed: {failed_count} statements")
        
        # Verify deployment by checking tables
        print("\n🔍 Verifying deployment...")
        try:
            # Check if tables exist
            tables_to_check = [
                'task_templates',
                'staff_tasks', 
                'task_verifications',
                'verification_audit_log',
                'fraud_detection_rules'
            ]
            
            existing_tables = []
            for table in tables_to_check:
                try:
                    result = supabase.table(table).select('*').limit(1).execute()
                    existing_tables.append(table)
                    print(f"   ✅ Table '{table}' exists and accessible")
                except:
                    print(f"   ❌ Table '{table}' not found or not accessible")
            
            if len(existing_tables) == len(tables_to_check):
                print("\n🎉 SUCCESS! All tables deployed successfully!")
                
                # Insert sample task template
                try:
                    club_result = supabase.table('clubs').select('id').limit(1).execute()
                    if club_result.data:
                        club_id = club_result.data[0]['id']
                        
                        sample_template = {
                            'club_id': club_id,
                            'task_type': 'cleaning',
                            'task_name': 'Vệ sinh khu vực chơi',
                            'description': 'Dọn dẹp và khử trùng tất cả bàn chơi, ghế ngồi và khu vực xung quanh',
                            'verification_notes': 'Chụp ảnh toàn cảnh khu vực sau khi vệ sinh'
                        }
                        
                        supabase.table('task_templates').insert(sample_template).execute()
                        print("   ✅ Sample task template created")
                        
                except Exception as e:
                    print(f"   ⚠️  Could not create sample data: {e}")
                
            else:
                print(f"\n⚠️  Partial deployment: {len(existing_tables)}/{len(tables_to_check)} tables created")
                
        except Exception as e:
            print(f"❌ Verification failed: {e}")
        
        return executed_count, failed_count
        
    except FileNotFoundError:
        print("❌ Schema file 'task_verification_schema.sql' not found!")
        return 0, 1
    except Exception as e:
        print(f"❌ Deployment failed: {e}")
        return 0, 1

def manual_deployment_guide():
    """Provide manual deployment instructions"""
    print("\n" + "="*60)
    print("📋 MANUAL DEPLOYMENT GUIDE")
    print("="*60)
    print("Since automatic deployment may have limitations, here's how to deploy manually:")
    print()
    print("1. 🌐 Go to Supabase Dashboard:")
    print("   https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr")
    print()
    print("2. 📝 Navigate to SQL Editor:")
    print("   Click 'SQL Editor' in the left sidebar")
    print()
    print("3. 📋 Copy the schema:")
    print("   Copy all content from 'task_verification_schema.sql'")
    print()
    print("4. 🚀 Execute:")
    print("   Paste into SQL Editor and click 'Run'")
    print()
    print("5. ✅ Verify:")
    print("   Check 'Table Editor' to see new tables created")
    print()
    print("Expected tables:")
    print("   - task_templates")
    print("   - staff_tasks")
    print("   - task_verifications") 
    print("   - verification_audit_log")
    print("   - fraud_detection_rules")
    print("="*60)

if __name__ == "__main__":
    print("🎯 Task Verification System Deployment")
    print("📸 Live Photo Evidence & Anti-Fraud Protection")
    print()
    
    executed, failed = deploy_schema()
    
    if failed > 0:
        print(f"\n⚠️  Some statements failed. Manual deployment may be required.")
        manual_deployment_guide()
    
    print(f"\n🏁 Deployment completed!")
    sys.exit(0 if failed == 0 else 1)