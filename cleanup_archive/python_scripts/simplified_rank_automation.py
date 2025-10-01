#!/usr/bin/env python3
"""
Simplified rank/ELO automation without SQL functions
Uses direct REST API calls to update data
"""

import requests
import json

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def update_user_rank_and_elo(user_id, rank):
    """Update user rank and ELO directly via REST API"""
    
    elo_mapping = {
        'A': 1800,
        'B': 1600,
        'C': 1400,
        'D': 1200,
        'E': 1000
    }
    
    elo_rating = elo_mapping.get(rank, 1000)
    
    try:
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
            headers=headers,
            json={
                "rank": rank,
                "elo_rating": elo_rating
            }
        )
        
        if response.status_code in [200, 204]:
            print(f"✅ Updated user {user_id}: rank={rank}, elo={elo_rating}")
            return True
        else:
            print(f"❌ Failed to update user {user_id}: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error updating user {user_id}: {e}")
        return False

def confirm_user_rank_simple(user_id, club_id, confirmed_rank):
    """Simplified rank confirmation"""
    
    print(f"🔧 Confirming rank {confirmed_rank} for user {user_id}")
    
    # Step 1: Update club_members table (if columns exist)
    try:
        member_update = requests.patch(
            f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&club_id=eq.{club_id}",
            headers=headers,
            json={
                "status": "active"  # Update what we can
            }
        )
        
        print(f"Member update status: {member_update.status_code}")
        
    except Exception as e:
        print(f"⚠️ Could not update club_members: {e}")
    
    # Step 2: Update users table directly
    success = update_user_rank_and_elo(user_id, confirmed_rank)
    
    if success:
        return {
            "success": True,
            "message": f"User rank confirmed as {confirmed_rank}",
            "rank": confirmed_rank, 
            "elo": {
                'A': 1800, 'B': 1600, 'C': 1400, 'D': 1200, 'E': 1000
            }.get(confirmed_rank, 1000)
        }
    else:
        return {
            "success": False,
            "message": "Failed to update user rank"
        }

def get_users_without_rank_simple():
    """Get users without rank via REST API"""
    
    try:
        # Get users with null rank
        users_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?rank=is.null&select=id,display_name,rank,elo_rating",
            headers=headers
        )
        
        if users_response.status_code == 200:
            users = users_response.json()
            
            # Get their club memberships
            result = []
            for user in users:
                member_response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user['id']}&select=*,clubs(name)",
                    headers=headers
                )
                
                if member_response.status_code == 200:
                    memberships = member_response.json()
                    for membership in memberships:
                        club_name = membership.get('clubs', {}).get('name', 'Unknown Club')
                        result.append({
                            "user_id": user['id'],
                            "display_name": user['display_name'],
                            "club_name": club_name,
                            "membership_status": membership.get('status', 'unknown')
                        })
            
            return result
        else:
            print(f"❌ Failed to get users: {users_response.text}")
            return []
            
    except Exception as e:
        print(f"❌ Error getting users without rank: {e}")
        return []

def test_simplified_system():
    """Test the simplified system"""
    
    print("🧪 Testing simplified rank system...")
    
    # Get users without rank
    users = get_users_without_rank_simple()
    print(f"Found {len(users)} users without rank")
    
    if users:
        # Test with first user
        test_user = users[0]
        user_id = test_user['user_id']
        
        print(f"Testing with user: {test_user['display_name']}")
        
        # Find their club
        member_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&limit=1",
            headers=headers
        )
        
        if member_response.status_code == 200 and member_response.json():
            club_id = member_response.json()[0]['club_id']
            
            # Test confirm rank
            result = confirm_user_rank_simple(user_id, club_id, "B")
            print(f"Confirmation result: {result}")
            
            if result['success']:
                print("🎉 SIMPLIFIED SYSTEM WORKING!")
                return True
            else:
                print("❌ Simplified system failed")
                return False
        else:
            print("❌ No club membership found")
            return False
    else:
        print("ℹ️ No users without rank found")
        return True

if __name__ == "__main__":
    print("🚀 SIMPLIFIED RANK/ELO AUTOMATION SYSTEM")
    print("=" * 60)
    test_simplified_system()
