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

def test_existing_request():
    """Test function with existing request"""
    print("🔍 TESTING FUNCTION WITH EXISTING REQUEST")
    print("=" * 50)
    
    # Get existing pending request
    print("1️⃣ Getting existing pending request...")
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/rank_requests?status=eq.pending&limit=1",
        headers=headers
    )
    
    if response.status_code == 200:
        requests_data = response.json()
        if requests_data:
            request = requests_data[0]
            request_id = request['id']
            user_id = request['user_id']
            
            print(f"✅ Found existing request: {request_id}")
            print(f"   User: {user_id}")
            print(f"   Status: {request['status']}")
            
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
                        print(f"   User name: {updated_user.get('display_name', 'No name')}")
                        
                else:
                    print(f"❌ Function failed: {result}")
            else:
                print(f"❌ Function call failed: {function_response.text}")
                
        else:
            print("❌ No pending requests found")
            
            # Create a simple test request without created_at
            print("Creating simple test request...")
            test_request_data = {
                "user_id": "8dc68b2e-8c94-47d7-a2d7-a70b218c32a8",  # Known user
                "club_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",   # Known club
                "status": "pending",
                "notes": "Test request - Rank mong muốn: D+"
            }
            
            create_response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rank_requests",
                headers=headers,
                json=test_request_data
            )
            
            print(f"Create response: {create_response.status_code}")
            print(f"Create response text: {create_response.text}")
            
    else:
        print(f"❌ Failed to get requests: {response.text}")

if __name__ == "__main__":
    test_existing_request()