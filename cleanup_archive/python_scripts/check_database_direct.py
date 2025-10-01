#!/usr/bin/env python3
import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def check_rank_requests_table():
    """Check if rank_requests table exists and get sample data"""
    print("\n🔍 Checking rank_requests table")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/rank_requests?limit=3",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ rank_requests table exists with {len(data)} records (showing first 3):")
            print(json.dumps(data, indent=2, default=str))
            return data
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
            return None
    except Exception as e:
        print(f"❌ Exception: {e}")
        return None

def test_club_review_function():
    """Test the club_review_rank_change_request function with dummy data"""
    print("\n🔍 Testing club_review_rank_change_request function")
    try:
        # First, let's see if the function exists by calling it with invalid params
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/club_review_rank_change_request",
            headers=headers,
            json={
                "p_request_id": "00000000-0000-0000-0000-000000000000",
                "p_approved": True,
                "p_club_comments": "Test call"
            }
        )
        
        print(f"Function call status: {response.status_code}")
        if response.status_code == 200:
            print("✅ Function exists and returned:")
            print(json.dumps(response.json(), indent=2))
        else:
            print(f"❌ Function call failed: {response.text}")
            
        return response.status_code == 200
        
    except Exception as e:
        print(f"❌ Exception: {e}")
        return False

def check_available_functions():
    """List available RPC functions by trying common ones"""
    print("\n🔍 Checking available RPC functions")
    
    common_functions = [
        "get_pending_rank_change_requests",
        "submit_rank_change_request", 
        "club_review_rank_change_request",
        "admin_approve_rank_change_request"
    ]
    
    available_functions = []
    
    for func in common_functions:
        try:
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/{func}",
                headers=headers,
                json={}
            )
            
            if response.status_code != 404:
                available_functions.append(func)
                print(f"✅ {func} - Available (status: {response.status_code})")
            else:
                print(f"❌ {func} - Not found")
                
        except Exception as e:
            print(f"❌ {func} - Error: {e}")
    
    return available_functions

def create_test_request():
    """Create a test rank request to see the actual error"""
    print("\n🔍 Creating test rank request to see actual error")
    try:
        test_data = {
            "user_id": "00000000-0000-0000-0000-000000000001",
            "club_id": "00000000-0000-0000-0000-000000000002", 
            "status": "pending",
            "notes": "Test request to check status enum"
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rank_requests",
            headers=headers,
            json=test_data
        )
        
        print(f"Create request status: {response.status_code}")
        if response.status_code == 201:
            print("✅ Test request created successfully")
            print(json.dumps(response.json(), indent=2, default=str))
        else:
            print(f"❌ Failed to create test request: {response.text}")
            # This will show us the actual enum/type error
            
    except Exception as e:
        print(f"❌ Exception: {e}")

def check_table_schema():
    """Check table schema using introspection endpoint"""
    print("\n🔍 Checking table schema via introspection")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/",
            headers=headers
        )
        
        if response.status_code == 200:
            schema = response.json()
            print("✅ Schema information retrieved")
            
            # Look for rank_requests table definition
            if 'definitions' in schema:
                if 'rank_requests' in schema['definitions']:
                    print("Found rank_requests table definition:")
                    print(json.dumps(schema['definitions']['rank_requests'], indent=2))
                else:
                    print("❌ rank_requests table not found in schema definitions")
            else:
                print("❌ No definitions found in schema")
                
        else:
            print(f"❌ Failed to get schema: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    print("🔍 SUPABASE DATABASE DIAGNOSTIC (Direct API)")
    print("=" * 60)
    
    # Check if table exists and structure
    check_rank_requests_table()
    
    # Check available RPC functions
    available_funcs = check_available_functions()
    
    # Test the problematic function
    test_club_review_function()
    
    # Try to create a test request to see the actual error
    create_test_request()
    
    # Check table schema
    check_table_schema()
    
    print("\n" + "=" * 60)
    print("🏁 DIAGNOSTIC COMPLETE")