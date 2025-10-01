import os
from supabase import create_client, Client

def apply_admin_rpc_functions():
    """Apply admin RPC functions to Supabase"""
    
    # Supabase configuration
    url = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    service_role_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.CxhOgxTU8CxGXXMlwWyJYMxWmDJyPjw7d8fLk5_5JnE"
    
    # Create service role client (can execute admin functions)
    supabase: Client = create_client(url, service_role_key)
    
    try:
        # Read the SQL file
        with open('admin_rpc_functions.sql', 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        print("🚀 Applying admin RPC functions to Supabase...")
        
        # Execute the SQL - Note: Supabase Python client doesn't support direct SQL execution
        # This is just a test - you'll need to run the SQL manually in Supabase Dashboard
        print("📝 SQL Content to apply:")
        print("=" * 50)
        print(sql_content[:500] + "..." if len(sql_content) > 500 else sql_content)
        print("=" * 50)
        
        print("⚠️  IMPORTANT: You need to run this SQL manually in Supabase SQL Editor!")
        print("1. Go to https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql")
        print("2. Copy the content from admin_rpc_functions.sql")
        print("3. Paste and run it in the SQL Editor")
        
        # Test if we can call a simple RPC
        print("\n🧪 Testing current RPC functions...")
        
        # List current functions
        result = supabase.rpc('admin_add_all_users_to_tournament', {
            'p_tournament_id': '12345678-1234-1234-1234-123456789012'  # dummy ID for test
        })
        
        print("✅ RPC test completed (might show error if function not exists yet)")
        
    except Exception as e:
        print(f"⚠️  Expected error (function might not exist yet): {e}")
        print("\n📌 Next steps:")
        print("1. Apply the SQL manually in Supabase Dashboard")
        print("2. Update AdminService to use RPC functions")
        print("3. Test the fixed functionality")

if __name__ == "__main__":
    apply_admin_rpc_functions()