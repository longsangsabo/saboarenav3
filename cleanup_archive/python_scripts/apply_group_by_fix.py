import os
from supabase import create_client, Client

def fix_rpc_group_by():
    """Fix the GROUP BY error in RPC function"""
    
    # Supabase configuration
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    service_role_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.CxhOgxTU8CxGXXMlwWyJYMxWmDJyPjw7d8fLk5_5JnE"
    
    print("🔧 FIXING RPC GROUP BY ERROR")
    print("=" * 40)
    
    try:
        # Read the SQL fix file
        with open('fix_rpc_group_by.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("📝 SQL Fix to apply:")
        print("=" * 30)
        print(sql_content)
        print("=" * 30)
        
        print("\n⚠️  MANUAL ACTION REQUIRED:")
        print("1. Go to https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql")
        print("2. Copy the content from fix_rpc_group_by.sql")
        print("3. Paste and run it in the SQL Editor")
        print("4. Test admin function again in Flutter app")
        
        print("\n🎯 ROOT CAUSE:")
        print("- Original RPC used ORDER BY created_at without GROUP BY")
        print("- PostgreSQL requires columns in ORDER BY to be in GROUP BY")
        print("- Fix: Remove ORDER BY clause in array_agg()")
        
        print("\n✅ After applying this fix, admin should be able to add users!")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    fix_rpc_group_by()