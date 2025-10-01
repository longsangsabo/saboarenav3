#!/usr/bin/env python3
"""
Fix Hồ Minh automation với service key đúng và rank system K, I+, H, G, F, E+
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

# Correct Vietnamese billiards ELO mapping
RANK_ELO_MAPPING = {
    'K': 1000,
    'K+': 1100, 
    'I': 1200,
    'I+': 1300,
    'H': 1400,
    'H+': 1500,
    'G': 1600,
    'G+': 1700,
    'F': 1800,
    'F+': 1900,
    'E': 2000,
    'E+': 2100
}

def fix_ho_minh_automation():
    """Automation fix cho user Hồ Minh với rank system đúng"""
    
    print("🎯 AUTOMATION FIX CHO HỒ MINH - VIETNAMESE BILLIARDS RANK")
    print("=" * 60)
    
    # Test connection first
    try:
        test_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?limit=1",
            headers=headers
        )
        print(f"🔗 Connection test: {test_response.status_code}")
        
        if test_response.status_code != 200:
            print(f"❌ Connection failed: {test_response.text}")
            return False
    except Exception as e:
        print(f"❌ Connection error: {e}")
        return False
    
    # Tìm user Hồ Minh
    print("🔍 Tìm user Hồ Minh...")
    
    try:
        # Search với nhiều pattern
        search_patterns = [
            "full_name=ilike.*Hồ*",
            "display_name=ilike.*Hồ*",
            "full_name=ilike.*Minh*",
            "display_name=ilike.*Minh*"
        ]
        
        target_user = None
        all_users = []
        
        for pattern in search_patterns:
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?{pattern}&select=id,full_name,display_name,rank,elo_rating",
                headers=headers
            )
            
            if response.status_code == 200:
                users = response.json()
                all_users.extend(users)
                
                for user in users:
                    name = user.get('full_name', '') or user.get('display_name', '')
                    if ('Hồ' in name and 'Minh' in name) or name == 'Hồ Minh':
                        target_user = user
                        print(f"✅ Tìm thấy: {name}")
                        break
                
                if target_user:
                    break
        
        if not target_user:
            print("❌ Không tìm thấy user Hồ Minh. Thử list một số users:")
            unique_users = {u['id']: u for u in all_users}.values()
            for user in list(unique_users)[:10]:
                name = user.get('full_name') or user.get('display_name', 'Unknown')
                rank = user.get('rank', 'None')
                elo = user.get('elo_rating', 0)
                print(f"   - {name} (Rank: {rank}, ELO: {elo})")
            return False
        
        user_id = target_user['id']
        current_rank = target_user.get('rank')
        current_elo = target_user.get('elo_rating', 0)
        user_name = target_user.get('full_name') or target_user.get('display_name')
        
        print(f"📊 Current status for {user_name}:")
        print(f"   - Rank: {current_rank}")
        print(f"   - ELO: {current_elo}")
        
        # AUTOMATION: Update rank I với ELO 1300 (rank I+)
        target_rank = 'I+'  # User được confirm rank I, nên set I+ với ELO 1300
        target_elo = RANK_ELO_MAPPING[target_rank]
        
        print(f"🚀 AUTOMATION: Update rank {target_rank} với ELO {target_elo}...")
        
        update_response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
            headers=headers,
            json={
                "rank": target_rank,
                "elo_rating": target_elo
            }
        )
        
        if update_response.status_code in [200, 204]:
            print("✅ AUTOMATION SUCCESS!")
            
            # Verify
            verify_response = requests.get(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}&select=id,full_name,display_name,rank,elo_rating",
                headers=headers
            )
            
            if verify_response.status_code == 200:
                updated_user = verify_response.json()[0]
                print(f"🎉 Updated successfully:")
                print(f"   - Name: {updated_user.get('full_name') or updated_user.get('display_name')}")
                print(f"   - Rank: {updated_user['rank']}")
                print(f"   - ELO: {updated_user['elo_rating']}")
                
                return True
        else:
            print(f"❌ Update failed: {update_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def create_general_automation():
    """Fix cho tất cả users có vấn đề rank/ELO không đồng bộ"""
    
    print("\n🔧 CREATING GENERAL AUTOMATION...")
    
    try:
        # Lấy users có rank nhưng ELO không phù hợp
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?rank=not.is.null&select=id,full_name,display_name,rank,elo_rating&limit=20",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            
            if users:
                print(f"📋 Found {len(users)} users có rank:")
                fixed_count = 0
                
                for user in users:
                    name = user.get('full_name') or user.get('display_name', 'Unknown')
                    current_rank = user.get('rank')
                    current_elo = user.get('elo_rating', 0)
                    expected_elo = RANK_ELO_MAPPING.get(current_rank, current_elo)
                    
                    print(f"   - {name}: Rank {current_rank}, ELO {current_elo}")
                    
                    # Fix nếu ELO không match rank
                    if abs(current_elo - expected_elo) > 50:  # Tolerance 50 ELO
                        print(f"     🔄 Fixing ELO: {current_elo} → {expected_elo}")
                        
                        fix_response = requests.patch(
                            f"{SUPABASE_URL}/rest/v1/users?id=eq.{user['id']}",
                            headers=headers,
                            json={"elo_rating": expected_elo}
                        )
                        
                        if fix_response.status_code in [200, 204]:
                            print(f"     ✅ Fixed!")
                            fixed_count += 1
                        else:
                            print(f"     ❌ Failed to fix")
                
                print(f"\n🎯 Fixed {fixed_count}/{len(users)} users")
                return True
            else:
                print("✅ Không có users nào cần fix")
                return True
        else:
            print(f"❌ Cannot get users: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ General automation error: {e}")
        return False

def display_rank_mapping():
    """Hiển thị rank mapping cho reference"""
    print("\n📋 VIETNAMESE BILLIARDS RANK-ELO MAPPING:")
    print("-" * 50)
    for rank, elo in RANK_ELO_MAPPING.items():
        print(f"   {rank:>3} = {elo:>4} ELO")

if __name__ == "__main__":
    display_rank_mapping()
    
    # Step 1: Fix Hồ Minh specifically  
    success_ho_minh = fix_ho_minh_automation()
    
    # Step 2: Fix any other users with similar issues
    success_general = create_general_automation()
    
    if success_ho_minh and success_general:
        print("\n🎉 AUTOMATION COMPLETE!")
        print("📱 Hãy refresh app để thấy changes!")
        print("🔄 Rank system: K → K+ → I → I+ → H → G → F → E+")
    else:
        print("\n⚠️ Có một số vấn đề trong automation")