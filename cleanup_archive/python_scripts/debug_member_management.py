#!/usr/bin/env python3
"""
Debug member management issues
"""

import requests
import json

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

headers = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json"
}

def test_member_query():
    """Test the exact query used by MemberManagementService"""
    print("🔍 Testing member management queries...")
    
    # Get clubs first
    print("\n1. Getting clubs...")
    response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?select=id,name", headers=headers)
    if response.status_code == 200:
        clubs = response.json()
        print(f"✅ Found {len(clubs)} clubs")
        for club in clubs[:2]:
            print(f"   - {club['name']} (ID: {club['id']})")
    else:
        print(f"❌ Error getting clubs: {response.text}")
        return

    if not clubs:
        print("❌ No clubs found!")
        return

    # Use first club for testing
    club_id = clubs[0]['id']
    club_name = clubs[0]['name']
    print(f"\n2. Testing with club: {club_name}")

    # Test the exact query from MemberManagementService
    print("\n3. Testing club_members query...")
    query_url = f"{SUPABASE_URL}/rest/v1/club_members?select=*,users(*)&club_id=eq.{club_id}"
    
    response = requests.get(query_url, headers=headers)
    if response.status_code == 200:
        members = response.json()
        print(f"✅ Query successful! Found {len(members)} members")
        
        for i, member in enumerate(members[:3]):
            user_info = member.get('users', {})
            print(f"   {i+1}. User: {user_info.get('display_name', 'No name')} | Role: {member.get('role', 'No role')} | Status: {member.get('status', 'No status')}")
    else:
        print(f"❌ Query failed: {response.status_code}")
        print(f"Error: {response.text}")

    # Test with status filter
    print("\n4. Testing with status=active filter...")
    query_url = f"{SUPABASE_URL}/rest/v1/club_members?select=*,users(*)&club_id=eq.{club_id}&status=eq.active"
    
    response = requests.get(query_url, headers=headers)
    if response.status_code == 200:
        active_members = response.json()
        print(f"✅ Active members query successful! Found {len(active_members)} active members")
    else:
        print(f"❌ Active members query failed: {response.status_code}")
        print(f"Error: {response.text}")

if __name__ == "__main__":
    test_member_query()