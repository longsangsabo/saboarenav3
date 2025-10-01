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

def test_fixed_function():
    """Test the fixed function"""
    print("🔍 TESTING FIXED FUNCTION")
    print("=" * 50)
    
    # First create a test request
    print("1️⃣ Creating test request...")
    
    # Get a user
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/users?limit=1",
        headers=headers
    )
    
    if response.status_code != 200:
        print(f"❌ Failed to get users: {response.text}")
        return
        
    users = response.json()
    if not users:
        print("❌ No users found")
        return
        
    user = users[0]
    user_id = user['id']
    print(f"✅ Using user: {user.get('display_name', user_id)}")
    
    # Get a club
    club_response = requests.get(
        f"{SUPABASE_URL}/rest/v1/clubs?limit=1",
        headers=headers
    )
    
    if club_response.status_code != 200:
        print(f"❌ Failed to get clubs: {club_response.text}")
        return
        
    clubs = club_response.json()
    if not clubs:
        print("❌ No clubs found")
        return
        
    club = clubs[0]
    club_id = club['id']
    print(f"✅ Using club: {club.get('name', club_id)}")
    
    # Create test request
    test_request_data = {
        "user_id": user_id,
        "club_id": club_id,
        "status": "pending",
        "notes": "Test request - Rank mong muốn: D+",
        "created_at": "now()"
    }
    
    create_response = requests.post(
        f"{SUPABASE_URL}/rest/v1/rank_requests",
        headers=headers,
        json=test_request_data
    )
    
    if create_response.status_code == 201:
        created_request = create_response.json()[0]
        request_id = created_request['id']
        print(f"✅ Created test request: {request_id}")
        
        # Test the function
        print(f"\n2️⃣ Testing function approval...")
        
        function_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/club_review_rank_change_request",
            headers=headers,
            json={
                "request_id": request_id,
                "action": "approve",
                "new_rank": "D+"
            }
        )
        
        print(f"Status code: {function_response.status_code}")
        print(f"Response: {function_response.text}")
        
        if function_response.status_code == 200:
            result = function_response.json()
            print(f"✅ Function result: {result}")
            
            if result.get('success'):
                print("🎉 FUNCTION WORKS!")
                
                # Verify changes
                print(f"\n3️⃣ Verifying changes...")
                
                # Check request status
                verify_response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
                    headers=headers
                )
                
                if verify_response.status_code == 200:
                    updated_request = verify_response.json()[0]
                    print(f"✅ Request status: {updated_request['status']}")
                    
                # Check user rank
                user_response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=rank,display_name",
                    headers=headers
                )
                
                if user_response.status_code == 200:
                    updated_user = user_response.json()[0]
                    print(f"✅ User rank: {updated_user['rank']}")
                    
            else:
                print(f"❌ Function failed: {result}")
        else:
            print(f"❌ Function call failed: {function_response.text}")
            
        # Cleanup - delete test request
        print(f"\n4️⃣ Cleaning up...")
        delete_response = requests.delete(
            f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
            headers=headers
        )
        
        if delete_response.status_code == 204:
            print("✅ Test request deleted")
        else:
            print(f"⚠️ Failed to delete test request: {delete_response.text}")
            
    else:
        print(f"❌ Failed to create test request: {create_response.text}")

if __name__ == "__main__":
    test_fixed_function()