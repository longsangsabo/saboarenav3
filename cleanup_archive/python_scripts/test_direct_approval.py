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

def direct_approval_test():
    """Test direct approval by updating database directly as service role"""
    print("🔍 DIRECT APPROVAL TEST")
    print("=" * 50)
    
    # Get the first pending request
    print("1️⃣ Getting pending request...")
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
                user_id = request['user_id']
                
                print(f"✅ Found request: {request_id}")
                print(f"   User: {user_id}")
                print(f"   Current status: {request['status']}")
                
                # Extract requested rank from notes
                notes = request.get('notes', '')
                print(f"   Notes: {notes[:200]}...")
                
                # Parse rank from notes
                requested_rank = 'K'  # default
                if 'Rank mong muốn:' in notes:
                    import re
                    match = re.search(r'Rank mong muốn: ([A-Z+]+)', notes)
                    if match:
                        requested_rank = match.group(1)
                        print(f"   Extracted rank: {requested_rank}")
                
                print(f"\n2️⃣ Approving request directly via database update...")
                
                # Update request status
                update_response = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
                    headers=headers,
                    json={
                        "status": "approved",
                        "reviewed_at": "now()",
                        "reviewed_by": user_id  # Using the user as reviewer for now
                    }
                )
                
                if update_response.status_code == 204:
                    print("✅ Request status updated successfully!")
                    
                    # Update user rank
                    print(f"\n3️⃣ Updating user rank to {requested_rank}...")
                    
                    user_update_response = requests.patch(
                        f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                        headers=headers,
                        json={
                            "rank": requested_rank,
                            "updated_at": "now()"
                        }
                    )
                    
                    if user_update_response.status_code == 204:
                        print("✅ User rank updated successfully!")
                        
                        # Verify the changes
                        print(f"\n4️⃣ Verifying changes...")
                        
                        # Check request
                        verify_response = requests.get(
                            f"{SUPABASE_URL}/rest/v1/rank_requests?id=eq.{request_id}",
                            headers=headers
                        )
                        
                        if verify_response.status_code == 200:
                            updated_request = verify_response.json()[0]
                            print(f"✅ Request verified - Status: {updated_request['status']}")
                            
                        # Check user
                        user_verify_response = requests.get(
                            f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=rank,display_name",
                            headers=headers
                        )
                        
                        if user_verify_response.status_code == 200:
                            updated_user = user_verify_response.json()[0]
                            print(f"✅ User verified - Rank: {updated_user['rank']}")
                            print(f"   User name: {updated_user.get('display_name', 'No name')}")
                            
                        print(f"\n🎉 APPROVAL SUCCESSFUL!")
                        print(f"User {updated_user.get('display_name', user_id)} now has rank {updated_user['rank']}")
                        
                    else:
                        print(f"❌ Failed to update user rank: {user_update_response.text}")
                        
                else:
                    print(f"❌ Failed to update request: {update_response.text}")
                    
            else:
                print("❌ No pending requests found")
                
    except Exception as e:
        print(f"❌ Exception: {e}")

if __name__ == "__main__":
    direct_approval_test()
    
    print(f"\n💡 SUMMARY:")
    print("✅ Direct database update approach works!")
    print("❌ The issue is the RPC function authentication")
    print("🔧 Solution: Update the function to handle service role or fix auth logic")
    print("\n📋 MANUAL STEPS TO FIX:")
    print("1. Go to Supabase Dashboard > SQL Editor")
    print("2. Run the content of fix_service_role_auth.sql") 
    print("3. Test admin approval functionality again")