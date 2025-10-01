#!/usr/bin/env python3
"""
Kiểm tra cấu trúc database thực tế từ Supabase
"""

import requests
import json
from datetime import datetime

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

def check_table_structure(table_name):
    """Kiểm tra cấu trúc bảng"""
    print(f"\n📋 Table: {table_name}")
    print("-" * 50)
    
    try:
        # Lấy 1 record để xem cấu trúc
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/{table_name}?limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            if data:
                record = data[0]
                print("✅ Table exists with columns:")
                for key, value in record.items():
                    value_type = type(value).__name__
                    value_preview = str(value)[:30] if value else "null"
                    print(f"  • {key:20} | {value_type:10} | {value_preview}")
            else:
                print("✅ Table exists but empty")
        elif response.status_code == 404:
            print("❌ Table not found")
        else:
            print(f"❌ Error: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ Error checking {table_name}: {e}")

def check_users_table():
    """Kiểm tra bảng users chi tiết"""
    print(f"\n🔍 DETAILED USERS TABLE ANALYSIS")
    print("=" * 60)
    
    try:
        # Lấy vài user để phân tích
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?limit=3",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            if users:
                print(f"📊 Found {len(users)} users")
                
                # Phân tích cấu trúc
                sample_user = users[0]
                print("\n🔍 User table structure:")
                for key, value in sample_user.items():
                    has_data = "✅" if value is not None else "❌"
                    print(f"  {has_data} {key:20} = {value}")
                
                # Kiểm tra rank và elo distribution
                print(f"\n📈 Current user data:")
                for user in users:
                    name = user.get('display_name', 'No name')[:15]
                    rank = user.get('rank', 'None')
                    elo = user.get('elo_rating', 0)
                    spa = user.get('spa_points', 0)
                    print(f"  • {name:15} | Rank: {rank:4} | ELO: {elo:4} | SPA: {spa:4}")
            else:
                print("⚠️ No users found")
        else:
            print(f"❌ Error getting users: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def check_club_members_table():
    """Kiểm tra bảng club_members chi tiết"""
    print(f"\n🔍 DETAILED CLUB_MEMBERS TABLE ANALYSIS")
    print("=" * 60)
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?limit=5",
            headers=headers
        )
        
        if response.status_code == 200:
            members = response.json()
            if members:
                print(f"📊 Found {len(members)} memberships")
                
                # Phân tích cấu trúc
                sample_member = members[0]
                print("\n🔍 Club_members table structure:")
                for key, value in sample_member.items():
                    has_data = "✅" if value is not None else "❌"
                    print(f"  {has_data} {key:20} = {value}")
                
                # Kiểm tra confirmed_rank field
                print(f"\n📈 Current membership data:")
                for member in members:
                    user_id = member.get('user_id', 'No user')[:8]
                    club_id = member.get('club_id', 'No club')[:8] 
                    status = member.get('status', 'None')
                    confirmed_rank = member.get('confirmed_rank', 'None')
                    print(f"  • User: {user_id}... | Club: {club_id}... | Status: {status} | Rank: {confirmed_rank}")
            else:
                print("⚠️ No memberships found")
        else:
            print(f"❌ Error getting club_members: {response.text}")
            
    except Exception as e:
        print(f"❌ Error: {e}")

def check_available_tables():
    """Kiểm tra các bảng có sẵn"""
    print(f"\n🔍 CHECKING AVAILABLE TABLES")
    print("=" * 60)
    
    common_tables = [
        'users', 'clubs', 'club_members', 'tournaments', 
        'matches', 'challenges', 'posts', 'comments',
        'notifications', 'friendships'
    ]
    
    existing_tables = []
    
    for table in common_tables:
        try:
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/{table}?limit=1",
                headers=headers
            )
            
            if response.status_code == 200:
                existing_tables.append(table)
                print(f"✅ {table}")
            elif response.status_code == 404:
                print(f"❌ {table} - Not found")
            else:
                print(f"⚠️ {table} - Error: {response.status_code}")
                
        except Exception as e:
            print(f"❌ {table} - Exception: {e}")
    
    return existing_tables

def analyze_rank_system_readiness():
    """Phân tích xem hệ thống rank có sẵn sàng không"""
    print(f"\n🎯 RANK SYSTEM READINESS ANALYSIS")
    print("=" * 60)
    
    # Kiểm tra có users với rank không
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?rank=not.is.null",
            headers=headers
        )
        
        users_with_rank = 0
        if response.status_code == 200:
            users_with_rank = len(response.json())
            
        print(f"👥 Users with rank: {users_with_rank}")
        
        # Kiểm tra có approved memberships không
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?status=eq.approved",
            headers=headers
        )
        
        approved_memberships = 0
        if response.status_code == 200:
            approved_memberships = len(response.json())
            
        print(f"🏆 Approved memberships: {approved_memberships}")
        
        # Kiểm tra có confirmed_rank không
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?confirmed_rank=not.is.null",
            headers=headers
        )
        
        memberships_with_rank = 0
        if response.status_code == 200:
            memberships_with_rank = len(response.json())
            
        print(f"📊 Memberships with confirmed_rank: {memberships_with_rank}")
        
        # Tóm tắt
        print(f"\n📋 SUMMARY:")
        if users_with_rank == 0 and approved_memberships > 0:
            print("⚠️ Issue detected: Users have club memberships but no ranks")
            print("💡 Solution: Need automation to sync ranks from club confirmations")
        elif users_with_rank > 0:
            print("✅ Some users already have ranks")
        else:
            print("ℹ️ No rank data found - system is fresh")
            
    except Exception as e:
        print(f"❌ Error analyzing readiness: {e}")

def main():
    print("🔍 SUPABASE DATABASE STRUCTURE ANALYSIS")
    print("=" * 60)
    print(f"🌐 Connected to: {SUPABASE_URL}")
    print(f"🔑 Using service role for full access")
    
    # 1. Kiểm tra bảng có sẵn
    existing_tables = check_available_tables()
    
    # 2. Phân tích bảng users
    if 'users' in existing_tables:
        check_users_table()
    
    # 3. Phân tích bảng club_members
    if 'club_members' in existing_tables:
        check_club_members_table()
    
    # 4. Phân tích bảng khác
    for table in ['clubs', 'challenges']:
        if table in existing_tables:
            check_table_structure(table)
    
    # 5. Phân tích tình trạng rank system
    analyze_rank_system_readiness()
    
    print(f"\n🎯 NEXT STEPS:")
    print("=" * 60)
    print("1. Review the actual table structures above")
    print("2. Adjust the automation SQL script based on real columns")
    print("3. Run the corrected SQL script in Supabase Dashboard")
    print("4. Test the automation system")

if __name__ == "__main__":
    main()