#!/usr/bin/env python3
import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

def deploy_missing_function():
    """Deploy the missing club_review_rank_change_request function"""
    
    # Read the SQL file
    with open('fix_missing_function.sql', 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    # Split into individual statements
    statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
    
    headers = {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    
    success_count = 0
    total_count = len(statements)
    
    print("🚀 DEPLOYING MISSING FUNCTION")
    print("=" * 50)
    
    for i, statement in enumerate(statements, 1):
        print(f"\n📋 Step {i}/{total_count}: Executing SQL statement")
        print(f"SQL: {statement[:100]}...")
        
        try:
            # Use the RPC endpoint to execute raw SQL
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/sql",
                headers=headers,
                json={"query": statement}
            )
            
            if response.status_code == 200:
                print(f"✅ Success!")
                success_count += 1
            else:
                # Try alternative approach using function calls
                print(f"⚠️  Direct SQL failed, trying alternative...")
                
                # If it's a CREATE FUNCTION statement, we'll need to handle it differently
                if "CREATE OR REPLACE FUNCTION" in statement:
                    print(f"❌ Cannot deploy function via REST API: {response.text}")
                else:
                    print(f"❌ Failed: {response.text}")
                
        except Exception as e:
            print(f"❌ Exception: {e}")
    
    print(f"\n" + "=" * 50)
    print(f"🎯 DEPLOYMENT COMPLETE: {success_count}/{total_count} statements executed")
    
    if success_count == total_count:
        print("✅ All functions deployed successfully!")
    else:
        print(f"⚠️  {total_count - success_count} statements failed.")
        print("💡 You may need to run the SQL manually in Supabase Dashboard")

def test_function_after_deploy():
    """Test if the function is now available"""
    print("\n🔍 Testing function availability after deployment")
    
    headers = {
        "apikey": SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
        "Content-Type": "application/json"
    }
    
    try:
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/club_review_rank_change_request",
            headers=headers,
            json={
                "p_request_id": "00000000-0000-0000-0000-000000000000",
                "p_approved": True,
                "p_club_comments": "Test call"
            }
        )
        
        if response.status_code == 404:
            print("❌ Function still not found - manual deployment needed")
        elif response.status_code == 400 and "User not authenticated" in response.text:
            print("✅ Function exists! (Got expected auth error)")
        else:
            print(f"✅ Function exists! Status: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    deploy_missing_function()
    test_function_after_deploy()
    
    print("\n💡 NEXT STEPS:")
    print("1. If deployment failed, manually run fix_missing_function.sql in Supabase Dashboard")
    print("2. Go to Supabase Dashboard > SQL Editor")
    print("3. Copy the content of fix_missing_function.sql and run it")
    print("4. Test the admin approval functionality again")