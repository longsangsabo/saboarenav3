#!/usr/bin/env python3
"""
Check current database state and add current user to club
"""

import requests
import json
from datetime import datetime

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

def check_database_state():
    """Check current state of database"""
    print("🔍 Checking database state...")
    
    # Check clubs
    try:
        response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?select=*", headers=headers)
        if response.status_code == 200:
            clubs = response.json()
            print(f"📊 Found {len(clubs)} clubs:")
            for club in clubs[:3]:  # Show first 3
                print(f"  - {club.get('name', 'Unnamed')} (ID: {club['id']}, Owner: {club.get('owner_id', 'No owner')})")
        else:
            print(f"❌ Error getting clubs: {response.text}")
    except Exception as e:
        print(f"❌ Error checking clubs: {e}")
    
    # Check users
    try:
        response = requests.get(f"{SUPABASE_URL}/rest/v1/users?select=id,display_name,email&limit=3", headers=headers)
        if response.status_code == 200:
            users = response.json()
            print(f"👥 Found {len(users)} users:")
            for user in users:
                print(f"  - {user.get('display_name', 'No name')} ({user.get('email', 'No email')}) - ID: {user['id']}")
        else:
            print(f"❌ Error getting users: {response.text}")
    except Exception as e:
        print(f"❌ Error checking users: {e}")
    
    # Check club_members
    try:
        response = requests.get(f"{SUPABASE_URL}/rest/v1/club_members?select=*&limit=5", headers=headers)
        if response.status_code == 200:
            members = response.json()
            print(f"🏢 Found {len(members)} club members:")
            for member in members:
                print(f"  - User: {member['user_id']}, Club: {member['club_id']}, Role: {member.get('role', 'No role')}")
        else:
            print(f"❌ Error getting club members: {response.text}")
    except Exception as e:
        print(f"❌ Error checking club members: {e}")

def add_user_to_first_club():
    """Add current user to first available club"""
    try:
        # Get first club
        response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?limit=1", headers=headers)
        if response.status_code != 200 or not response.json():
            print("❌ No clubs found")
            return
            
        club = response.json()[0]
        club_id = club['id']
        
        # Get first user  
        response = requests.get(f"{SUPABASE_URL}/rest/v1/users?limit=1", headers=headers)
        if response.status_code != 200 or not response.json():
            print("❌ No users found")
            return
            
        user = response.json()[0]
        user_id = user['id']
        
        print(f"🔗 Adding user {user.get('display_name', user_id)} to club {club.get('name', club_id)}")
        
        # Check if already member
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?club_id=eq.{club_id}&user_id=eq.{user_id}",
            headers=headers
        )
        
        if response.status_code == 200 and response.json():
            print("✅ User is already a member of this club")
            return
            
        # Add as member
        member_data = {
            "club_id": club_id,
            "user_id": user_id,
            "role": "owner",  # Make them owner for testing
            "status": "active",
            "joined_at": datetime.now().isoformat()
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/club_members",
            headers=headers,
            json=member_data
        )
        
        if response.status_code == 201:
            print("✅ Successfully added user to club!")
            
            # Add a few more sample members
            for i in range(3):
                sample_member = {
                    "club_id": club_id,
                    "user_id": f"sample-user-{i+1}",
                    "role": "member",
                    "status": "active",
                    "joined_at": datetime.now().isoformat()
                }
                
                requests.post(
                    f"{SUPABASE_URL}/rest/v1/club_members",
                    headers=headers,
                    json=sample_member
                )
            
            print("✅ Added 3 additional sample members")
            
        else:
            print(f"❌ Failed to add user to club: {response.text}")
            
    except Exception as e:
        print(f"❌ Error adding user to club: {e}")

if __name__ == "__main__":
    check_database_state()
    print("\n" + "="*50)
    add_user_to_first_club()
    print("\n🔄 Please refresh your app to see the changes!")