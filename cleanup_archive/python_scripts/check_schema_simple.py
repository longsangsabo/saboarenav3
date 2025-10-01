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

def check_rank_requests_schema():
    """Check the actual schema of rank_requests table"""
    print("🔍 CHECKING RANK_REQUESTS TABLE SCHEMA")
    print("=" * 50)
    
    # Get one record to see available columns
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/rank_requests?limit=1",
        headers=headers
    )
    
    if response.status_code == 200:
        data = response.json()
        if data:
            record = data[0]
            print("✅ Available columns in rank_requests:")
            for key, value in record.items():
                print(f"   {key}: {type(value).__name__} = {value}")
        else:
            print("❌ No records found in rank_requests table")
    else:
        print(f"❌ Failed to get rank_requests data: {response.text}")

def test_simple_approval():
    """Test approval with only existing columns"""
    print(f"\n🧪 TESTING SIMPLE APPROVAL")
    print("=" * 40)
    
    # Get pending request
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
            
            print(f"✅ Testing with request: {request_id}")
            
            # Try simple update with only existing columns
            update_response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
                headers=headers,
                json={
                    "status": "approved"
                }
            )
            
            if update_response.status_code == 204:
                print("✅ Simple status update successful!")
                
                # Extract rank and update user
                notes = request.get('notes', '')
                new_rank = 'K'
                if 'Rank mong muốn:' in notes:
                    import re
                    match = re.search(r'Rank mong muốn: ([A-Z+]+)', notes)
                    if match:
                        new_rank = match.group(1)
                
                # Update user rank
                user_update_response = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                    headers=headers,
                    json={
                        "rank": new_rank
                    }
                )
                
                if user_update_response.status_code == 204:
                    print(f"✅ User rank updated to {new_rank}!")
                    
                    # Verify
                    verify_response = requests.get(
                        f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=rank,display_name",
                        headers=headers
                    )
                    
                    if verify_response.status_code == 200:
                        user = verify_response.json()[0]
                        print(f"✅ Verified: {user.get('display_name')} now has rank {user['rank']}")
                        
                    print(f"\n🎉 SIMPLE APPROVAL SUCCESSFUL!")
                else:
                    print(f"❌ Failed to update user rank: {user_update_response.text}")
            else:
                print(f"❌ Failed to update request: {update_response.text}")
        else:
            print("❌ No pending requests found")
    else:
        print(f"❌ Failed to get requests: {response.text}")

if __name__ == "__main__":
    check_rank_requests_schema()
    test_simple_approval()