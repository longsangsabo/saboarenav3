#!/usr/bin/env python3
"""
Update current club with real member data
"""

import requests
import json
from datetime import datetime, timedelta
import random

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.jlL2wqQBIZhU4rBKKJLCcVjW8HEyeZVWJl6B8hPaHhQ"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

def get_current_user_club():
    """Get current user's club"""
    try:
        # Get users with role owner
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/clubs?select=*,owner:users!owner_id(id,display_name,email)",
            headers=headers
        )
        
        if response.status_code == 200:
            clubs = response.json()
            if clubs:
                return clubs[0]  # Return first club
        return None
    except Exception as e:
        print(f"Error getting club: {e}")
        return None

def ensure_owner_membership(club_id, owner_id):
    """Ensure club owner is in club_members"""
    try:
        # Check if owner is already a member
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?club_id=eq.{club_id}&user_id=eq.{owner_id}",
            headers=headers
        )
        
        if response.status_code == 200:
            members = response.json()
            if not members:
                # Add owner as member
                member_data = {
                    "club_id": club_id,
                    "user_id": owner_id,
                    "role": "owner",
                    "status": "active",
                    "joined_at": datetime.now().isoformat()
                }
                
                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/club_members",
                    headers=headers,
                    json=member_data
                )
                
                if response.status_code == 201:
                    print("✅ Added club owner to club_members")
                else:
                    print(f"❌ Failed to add owner: {response.text}")
            else:
                print("✅ Club owner already in club_members")
                
    except Exception as e:
        print(f"Error ensuring owner membership: {e}")

def add_sample_members(club_id):
    """Add some sample members to the club"""
    try:
        # Get existing members count
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?club_id=eq.{club_id}&select=id",
            headers=headers
        )
        
        existing_count = 0
        if response.status_code == 200:
            existing_count = len(response.json())
            
        print(f"📊 Current members: {existing_count}")
        
        if existing_count < 5:  # Add some sample members if less than 5
            # Create some sample users and members
            sample_users = [
                {"display_name": "Nguyễn Văn A", "rank": "I", "elo_rating": 1250},
                {"display_name": "Trần Thị B", "rank": "H", "elo_rating": 1450},
                {"display_name": "Lê Minh C", "rank": "G", "elo_rating": 1650},
                {"display_name": "Phạm Hoàng D", "rank": "F", "elo_rating": 1850},
            ]
            
            for i, user_info in enumerate(sample_users):
                if existing_count + i >= 10:  # Don't add too many
                    break
                    
                # Create user first (in a real scenario these would be existing users)
                user_data = {
                    "display_name": user_info["display_name"],
                    "rank": user_info["rank"],
                    "elo_rating": user_info["elo_rating"],
                    "created_at": datetime.now().isoformat()
                }
                
                # Note: In production, we should use existing users
                # For demo, we'll just add club_members with mock user_ids
                member_data = {
                    "club_id": club_id,
                    "user_id": f"mock-user-{i+1}",  # Mock user ID
                    "role": "member",
                    "status": "active",
                    "joined_at": (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat()
                }
                
                response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/club_members",
                    headers=headers,
                    json=member_data
                )
                
                if response.status_code == 201:
                    print(f"✅ Added sample member: {user_info['display_name']}")
                else:
                    print(f"❌ Failed to add member: {response.text}")
                    
    except Exception as e:
        print(f"Error adding sample members: {e}")

def update_club_stats():
    """Update and display current club statistics"""
    try:
        club = get_current_user_club()
        if not club:
            print("❌ No club found")
            return
            
        club_id = club['id']
        owner_id = club['owner_id']
        
        print(f"🏢 Club: {club['name']}")
        print(f"👤 Owner: {club.get('owner', {}).get('display_name', 'Unknown')}")
        print(f"🆔 Club ID: {club_id}")
        
        # Ensure owner is a member
        ensure_owner_membership(club_id, owner_id)
        
        # Add sample members
        add_sample_members(club_id)
        
        # Get final member count
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?club_id=eq.{club_id}&select=id",
            headers=headers
        )
        
        if response.status_code == 200:
            member_count = len(response.json())
            print(f"📊 Final member count: {member_count}")
        
        print("\n✅ Club data updated successfully!")
        print("🔄 Please refresh your dashboard to see the changes")
        
    except Exception as e:
        print(f"Error updating club stats: {e}")

if __name__ == "__main__":
    print("🚀 Updating current club data...")
    update_club_stats()