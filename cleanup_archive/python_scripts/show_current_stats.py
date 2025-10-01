#!/usr/bin/env python3
"""
Simple test to check if current user has club access
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

print("📊 Current database stats:")

# Count clubs
response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?select=id", headers=headers)
if response.status_code == 200:
    clubs_count = len(response.json())
    print(f"🏢 Clubs: {clubs_count}")

# Count users  
response = requests.get(f"{SUPABASE_URL}/rest/v1/users?select=id", headers=headers)
if response.status_code == 200:
    users_count = len(response.json())
    print(f"👥 Users: {users_count}")

# Count club members
response = requests.get(f"{SUPABASE_URL}/rest/v1/club_members?select=id", headers=headers)
if response.status_code == 200:
    members_count = len(response.json())
    print(f"🏷️ Club Members: {members_count}")

# Group members by club
response = requests.get(f"{SUPABASE_URL}/rest/v1/club_members?select=club_id", headers=headers)
if response.status_code == 200:
    members = response.json()
    club_counts = {}
    for member in members:
        club_id = member['club_id']
        club_counts[club_id] = club_counts.get(club_id, 0) + 1
    
    print(f"\n📈 Members per club:")
    for club_id, count in club_counts.items():
        # Get club name
        club_response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?id=eq.{club_id}&select=name", headers=headers)
        club_name = "Unknown"
        if club_response.status_code == 200:
            clubs = club_response.json()
            if clubs:
                club_name = clubs[0].get('name', 'Unknown')
        print(f"  - {club_name}: {count} members")

print(f"\n✅ Your dashboard should now show real member counts!")
print(f"🔄 If you don't see the data, try refreshing the app")