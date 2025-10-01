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

def test_with_real_data():
    """Use service role to test function with actual pending requests"""
    print("🔍 TESTING WITH REAL DATA")
    print("=" * 50)
    
    # First get pending requests
    print("\n1️⃣ Getting pending requests...")
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/rank_requests?status=eq.pending&limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            requests_data = response.json()
            if requests_data:
                request = requests_data[0]
                request_id = request['id']
                print(f"✅ Found pending request: {request_id}")
                print(f"   User: {request['user_id']}")
                print(f"   Club: {request['club_id']}")
                print(f"   Notes: {request['notes'][:100]}...")
                
                # Test the function with service role (bypassing auth)
                print(f"\n2️⃣ Testing approval with service role...")
                
                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/rpc/club_review_rank_change_request",
                    headers=headers,
                    json={
                        "p_request_id": request_id,
                        "p_approved": True,
                        "p_club_comments": "Test approval via service role"
                    }
                )
                
                print(f"Function call status: {response.status_code}")
                if response.status_code == 200:
                    result = response.json()
                    print("✅ Function executed successfully!")
                    print(json.dumps(result, indent=2))
                    
                    # Check if request was actually updated
                    print(f"\n3️⃣ Checking if request was updated...")
                    check_response = requests.get(
                        f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
                        headers=headers
                    )
                    
                    if check_response.status_code == 200:
                        updated_request = check_response.json()[0]
                        print(f"✅ Request status: {updated_request['status']}")
                        print(f"   Reviewed by: {updated_request['reviewed_by']}")
                        print(f"   Reviewed at: {updated_request['reviewed_at']}")
                    
                else:
                    print(f"❌ Function failed: {response.text}")
                    
                    # Try to understand the error better
                    if "enum" in response.text.lower() or "status" in response.text.lower():
                        print("\n🔍 This looks like the enum casting issue!")
                        print("Let's try updating status directly to see the actual error:")
                        
                        # Test direct status update
                        test_response = requests.patch(
                            f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
                            headers=headers,
                            json={"status": "approved"}
                        )
                        
                        print(f"Direct update status: {test_response.status_code}")
                        if test_response.status_code != 204:
                            print(f"Direct update error: {test_response.text}")
                        else:
                            print("✅ Direct status update worked - function issue confirmed")
                
            else:
                print("❌ No pending requests found")
        else:
            print(f"❌ Failed to get requests: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

def check_user_club_relationships():
    """Check if there are proper user-club relationships for testing"""
    print("\n🔍 CHECKING USER-CLUB RELATIONSHIPS")
    print("=" * 50)
    
    try:
        # Get clubs
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/clubs?limit=3",
            headers=headers
        )
        
        if response.status_code == 200:
            clubs = response.json()
            print(f"✅ Found {len(clubs)} clubs")
            for club in clubs:
                print(f"   Club: {club['name']} (ID: {club['id']})")
                print(f"   Owner: {club['owner_id']}")
        
        # Get users with ranks
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?rank=not.is.null&limit=3",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            print(f"✅ Found {len(users)} users with ranks")
            for user in users:
                print(f"   User: {user.get('display_name', 'No name')} (Rank: {user['rank']})")
                
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    test_with_real_data()
    check_user_club_relationships()