#!/usr/bin/env python3
"""
COMPLETE RANK/ELO MANAGEMENT SYSTEM
Hệ thống quản lý rank và ELO hoàn chỉnh cho admin
"""

import requests
import json
from datetime import datetime
import sys

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

ELO_MAPPING = {
    'A': 1800,
    'B': 1600,
    'C': 1400,
    'D': 1200,
    'E': 1000
}

class RankELOManager:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update(headers)
    
    def get_users_without_rank(self):
        """Lấy danh sách users chưa có rank"""
        try:
            response = self.session.get(
                f"{SUPABASE_URL}/rest/v1/users?rank=is.null&select=id,display_name,rank,elo_rating"
            )
            
            if response.status_code == 200:
                users = response.json()
                
                result = []
                for user in users:
                    # Lấy club memberships
                    member_response = self.session.get(
                        f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user['id']}&select=*,clubs(name,id)"
                    )
                    
                    if member_response.status_code == 200:
                        memberships = member_response.json()
                        for membership in memberships:
                            if membership.get('status') == 'active':
                                club_info = membership.get('clubs', {})
                                result.append({
                                    "user_id": user['id'],
                                    "display_name": user['display_name'],
                                    "club_id": club_info.get('id'),
                                    "club_name": club_info.get('name', 'Unknown Club'),
                                    "current_rank": user.get('rank'),
                                    "current_elo": user.get('elo_rating', 1000),
                                    "membership_status": membership.get('status')
                                })
                
                return result
            else:
                print(f"❌ Error getting users: {response.text}")
                return []
                
        except Exception as e:
            print(f"❌ Exception getting users: {e}")
            return []
    
    def get_all_users_with_rank(self):
        """Lấy tất cả users có rank"""
        try:
            response = self.session.get(
                f"{SUPABASE_URL}/rest/v1/users?rank=not.is.null&select=id,display_name,rank,elo_rating"
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                print(f"❌ Error getting ranked users: {response.text}")
                return []
                
        except Exception as e:
            print(f"❌ Exception getting ranked users: {e}")
            return []
    
    def confirm_user_rank(self, user_id, club_id, rank):
        """Xác nhận rank cho user"""
        if rank not in ELO_MAPPING:
            return {
                "success": False,
                "message": f"Invalid rank. Must be one of: {', '.join(ELO_MAPPING.keys())}"
            }
        
        try:
            # Update user rank và ELO
            elo_rating = ELO_MAPPING[rank]
            
            user_update = self.session.patch(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                json={
                    "rank": rank,
                    "elo_rating": elo_rating,
                    "updated_at": datetime.now().isoformat()
                }
            )
            
            if user_update.status_code in [200, 204]:
                # Thử update club_members nếu có thể
                try:
                    member_update = self.session.patch(
                        f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&club_id=eq.{club_id}",
                        json={"status": "active"}
                    )
                except:
                    pass  # Ignore nếu không update được
                
                return {
                    "success": True,
                    "message": f"User rank confirmed as {rank} with ELO {elo_rating}",
                    "rank": rank,
                    "elo": elo_rating,
                    "user_id": user_id
                }
            else:
                return {
                    "success": False,
                    "message": f"Failed to update user: {user_update.text}"
                }
                
        except Exception as e:
            return {
                "success": False,
                "message": f"Exception confirming rank: {e}"
            }
    
    def update_user_elo(self, user_id, new_elo):
        """Cập nhật ELO cho user"""
        try:
            response = self.session.patch(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                json={
                    "elo_rating": new_elo,
                    "updated_at": datetime.now().isoformat()
                }
            )
            
            if response.status_code in [200, 204]:
                return {"success": True, "message": f"ELO updated to {new_elo}"}
            else:
                return {"success": False, "message": f"Failed: {response.text}"}
                
        except Exception as e:
            return {"success": False, "message": f"Exception: {e}"}
    
    def get_club_members(self, club_id):
        """Lấy danh sách members của một club"""
        try:
            response = self.session.get(
                f"{SUPABASE_URL}/rest/v1/club_members?club_id=eq.{club_id}&select=*,users(id,display_name,rank,elo_rating)"
            )
            
            if response.status_code == 200:
                members = response.json()
                result = []
                
                for member in members:
                    user_info = member.get('users', {})
                    result.append({
                        "user_id": user_info.get('id'),
                        "display_name": user_info.get('display_name'),
                        "rank": user_info.get('rank'),
                        "elo_rating": user_info.get('elo_rating'),
                        "membership_status": member.get('status'),
                        "role": member.get('role')
                    })
                
                return result
            else:
                return []
                
        except Exception as e:
            print(f"❌ Error getting club members: {e}")
            return []
    
    def get_clubs(self):
        """Lấy danh sách tất cả clubs"""
        try:
            response = self.session.get(
                f"{SUPABASE_URL}/rest/v1/clubs?select=id,name,description"
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                return []
                
        except Exception as e:
            print(f"❌ Error getting clubs: {e}")
            return []

def print_users_table(users, title="USERS"):
    """In bảng users đẹp"""
    if not users:
        print(f"📋 {title}: No users found")
        return
    
    print(f"\n📋 {title} ({len(users)} users)")
    print("=" * 80)
    print(f"{'Name':<20} {'Rank':<6} {'ELO':<6} {'Club':<25} {'Status':<10}")
    print("-" * 80)
    
    for user in users:
        name = (user.get('display_name') or 'N/A')[:19]
        rank = user.get('rank') or user.get('current_rank') or 'None'
        elo = user.get('elo_rating') or user.get('current_elo') or 0
        club = (user.get('club_name') or 'N/A')[:24]
        status = (user.get('membership_status') or 'N/A')[:9]
        
        print(f"{name:<20} {rank:<6} {elo:<6} {club:<25} {status:<10}")

def interactive_menu():
    """Menu tương tác cho admin"""
    manager = RankELOManager()
    
    while True:
        print("\n" + "="*60)
        print("🏆 RANK/ELO MANAGEMENT SYSTEM")
        print("="*60)
        print("1. 📋 View users without rank")
        print("2. 🎯 Confirm user rank")
        print("3. 📊 View all ranked users")
        print("4. 🏢 View club members")
        print("5. ⚡ Update user ELO")
        print("6. 🔍 Search user")
        print("7. 📈 Rank statistics")
        print("0. ❌ Exit")
        print("-"*60)
        
        choice = input("👉 Choose option (0-7): ").strip()
        
        if choice == "0":
            print("👋 Goodbye!")
            break
        
        elif choice == "1":
            users = manager.get_users_without_rank()
            print_users_table(users, "USERS WITHOUT RANK")
        
        elif choice == "2":
            users = manager.get_users_without_rank()
            if not users:
                print("✅ All users already have ranks!")
                continue
            
            print_users_table(users, "USERS WITHOUT RANK")
            
            try:
                user_idx = int(input(f"\n👉 Select user (1-{len(users)}): ")) - 1
                if 0 <= user_idx < len(users):
                    user = users[user_idx]
                    
                    print(f"\n🎯 Confirming rank for: {user['display_name']}")
                    print("Available ranks: A (1800), B (1600), C (1400), D (1200), E (1000)")
                    
                    rank = input("👉 Enter rank (A/B/C/D/E): ").upper().strip()
                    
                    if rank in ELO_MAPPING:
                        result = manager.confirm_user_rank(
                            user['user_id'], 
                            user['club_id'], 
                            rank
                        )
                        
                        if result['success']:
                            print(f"✅ {result['message']}")
                        else:
                            print(f"❌ {result['message']}")
                    else:
                        print("❌ Invalid rank!")
                else:
                    print("❌ Invalid selection!")
            except ValueError:
                print("❌ Please enter a valid number!")
        
        elif choice == "3":
            users = manager.get_all_users_with_rank()
            print_users_table(users, "USERS WITH RANK")
        
        elif choice == "4":
            clubs = manager.get_clubs()
            if not clubs:
                print("❌ No clubs found!")
                continue
            
            print("\n🏢 AVAILABLE CLUBS:")
            for i, club in enumerate(clubs, 1):
                print(f"{i}. {club['name']}")
            
            try:
                club_idx = int(input(f"\n👉 Select club (1-{len(clubs)}): ")) - 1
                if 0 <= club_idx < len(clubs):
                    club = clubs[club_idx]
                    members = manager.get_club_members(club['id'])
                    print_users_table(members, f"MEMBERS OF {club['name']}")
                else:
                    print("❌ Invalid selection!")
            except ValueError:
                print("❌ Please enter a valid number!")
        
        elif choice == "5":
            users = manager.get_all_users_with_rank()
            if not users:
                print("❌ No ranked users found!")
                continue
            
            print_users_table(users, "RANKED USERS")
            
            try:
                user_idx = int(input(f"\n👉 Select user (1-{len(users)}): ")) - 1
                if 0 <= user_idx < len(users):
                    user = users[user_idx]
                    current_elo = user.get('elo_rating', 1000)
                    
                    print(f"\n⚡ Current ELO for {user['display_name']}: {current_elo}")
                    new_elo = int(input("👉 Enter new ELO: "))
                    
                    result = manager.update_user_elo(user['id'], new_elo)
                    
                    if result['success']:
                        print(f"✅ {result['message']}")
                    else:
                        print(f"❌ {result['message']}")
                else:
                    print("❌ Invalid selection!")
            except ValueError:
                print("❌ Please enter a valid number!")
        
        elif choice == "6":
            search_term = input("👉 Enter user name to search: ").strip()
            if search_term:
                try:
                    response = requests.get(
                        f"{SUPABASE_URL}/rest/v1/users?display_name=ilike.*{search_term}*&select=id,display_name,rank,elo_rating",
                        headers=headers
                    )
                    
                    if response.status_code == 200:
                        users = response.json()
                        print_users_table(users, f"SEARCH RESULTS FOR '{search_term}'")
                    else:
                        print("❌ Search failed!")
                except Exception as e:
                    print(f"❌ Search error: {e}")
        
        elif choice == "7":
            # Thống kê rank
            all_users = manager.get_all_users_with_rank()
            unranked = manager.get_users_without_rank()
            
            rank_stats = {}
            for user in all_users:
                rank = user.get('rank', 'Unknown')
                rank_stats[rank] = rank_stats.get(rank, 0) + 1
            
            print("\n📈 RANK STATISTICS")
            print("="*30)
            print(f"Total users with rank: {len(all_users)}")
            print(f"Users without rank: {len(unranked)}")
            print("\nRank distribution:")
            for rank in ['A', 'B', 'C', 'D', 'E']:
                count = rank_stats.get(rank, 0)
                print(f"  Rank {rank}: {count} users (ELO {ELO_MAPPING[rank]})")
        
        else:
            print("❌ Invalid option!")

def auto_confirm_all():
    """Tự động confirm rank B cho tất cả users chưa có rank"""
    manager = RankELOManager()
    users = manager.get_users_without_rank()
    
    if not users:
        print("✅ All users already have ranks!")
        return
    
    print(f"🔄 Auto-confirming rank B for {len(users)} users...")
    
    success_count = 0
    for user in users:
        result = manager.confirm_user_rank(user['user_id'], user['club_id'], 'B')
        if result['success']:
            success_count += 1
            print(f"✅ {user['display_name']}: {result['message']}")
        else:
            print(f"❌ {user['display_name']}: {result['message']}")
    
    print(f"\n📊 SUMMARY: {success_count}/{len(users)} users updated successfully")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--auto":
        auto_confirm_all()
    else:
        interactive_menu()