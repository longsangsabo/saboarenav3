import requests
import json
import random
from datetime import datetime

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Vietnamese names for realistic data
first_names = [
    "An", "Bình", "Cường", "Dũng", "Đức", "Giang", "Hải", "Hùng", "Khang", "Long",
    "Minh", "Nam", "Phong", "Quang", "Sơn", "Thành", "Tuấn", "Văn", "Vinh", "Yên",
    "Anh", "Linh", "Mai", "Nga", "Oanh", "Phương", "Quyên", "Thu", "Trang", "Vy"
]

last_names = [
    "Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Phan", "Vũ", "Võ", "Đặng", "Bùi",
    "Đỗ", "Hồ", "Ngô", "Dương", "Lý", "Đinh", "Trịnh", "Tăng", "Lương", "Đào"
]

def get_rank_from_elo(elo):
    """Chuyển đổi ELO rating thành rank theo hệ thống SABO Arena"""
    if elo >= 2100:
        return 'E+'
    elif elo >= 2000:
        return 'E'
    elif elo >= 1900:
        return 'F+'
    elif elo >= 1800:
        return 'F'
    elif elo >= 1700:
        return 'G+'
    elif elo >= 1600:
        return 'G'
    elif elo >= 1500:
        return 'H+'
    elif elo >= 1400:
        return 'H'
    elif elo >= 1300:
        return 'I+'
    elif elo >= 1200:
        return 'I'
    elif elo >= 1100:
        return 'K+'
    else:
        return 'K'

def update_existing_users_diversity():
    print("🔄 STRATEGY: Update existing users with diverse data")
    print("="*60)
    
    # Get existing users
    response = requests.get(
        f"{SUPABASE_URL}/rest/v1/users",
        headers=headers
    )
    
    if response.status_code != 200:
        print(f"❌ Cannot get existing users: {response.text}")
        return
    
    existing_users = response.json()
    print(f"📊 Found {len(existing_users)} existing users to update")
    
    if len(existing_users) < 2:
        print("❌ Need at least 2 users to create diversity")
        return
    
    successful_updates = 0
    
    for i, user in enumerate(existing_users):
        if i == 0:  # Skip first user to keep original admin
            print(f"⏭️  Skipping user '{user['username']}' (keeping as original)")
            continue
            
        user_id = user['id']
        
        # Generate new diverse data
        first_name = random.choice(first_names)
        last_name = random.choice(last_names)
        full_name = f"{last_name} {first_name}"
        
        # Random ELO rating theo hệ thống SABO - từ K (1000) đến E+ (2200+)
        elo_rating = random.randint(1000, 2200)
        
        # Thống kê phù hợp với ELO rating
        if elo_rating >= 2000:  # E, E+ ranks
            wins = random.randint(40, 80)
            losses = random.randint(5, 20)
        elif elo_rating >= 1600:  # G, G+, F, F+ ranks  
            wins = random.randint(20, 50)
            losses = random.randint(10, 30)
        elif elo_rating >= 1300:  # I+, H, H+ ranks
            wins = random.randint(10, 30)
            losses = random.randint(15, 35)
        else:  # K, K+, I ranks
            wins = random.randint(5, 20)
            losses = random.randint(10, 40)
        
        total_matches = wins + losses
        ranking_points = elo_rating + random.randint(-200, 200)
        spa_points = random.randint(min(100, elo_rating//10), max(500, elo_rating//2))
        
        # Create update data
        update_data = {
            "full_name": full_name,
            "display_name": f"{first_name}{last_name}_{random.randint(1000,9999)}",
            "bio": f"Tôi là {full_name}, chơi bida với ELO {elo_rating}",
            "rank": get_rank_from_elo(elo_rating),
            "elo_rating": elo_rating,
            "total_wins": wins,
            "total_losses": losses,
            "wins": wins,
            "losses": losses,
            "total_matches": total_matches,
            "total_games": total_matches,
            "ranking_points": ranking_points,
            "spa_points": spa_points,
            "spa_points_won": random.randint(0, spa_points),
            "spa_points_lost": random.randint(0, spa_points//2),
            "win_streak": random.randint(0, 5),
            "tournaments_played": random.randint(0, 3),
            "tournament_wins": random.randint(0, 1),
            "total_tournaments": random.randint(0, 5),
            "is_online": random.choice([True, False]),
            "is_verified": random.choice([True, False]),
            "challenge_win_streak": random.randint(0, 3),
            "is_available_for_challenges": random.choice([True, False]),
            "preferred_match_type": random.choice(["thach_dau", "giai_dau", "tu_do"]),
            "max_challenge_distance": random.randint(1, 10),
            "total_prize_pool": random.randint(0, wins * 10000),
            "favorite_game": random.choice(["8-Ball", "9-Ball", "10-Ball", "Straight Pool"]),
            "location_name": random.choice([
                "Quận Hoàn Kiếm, Hà Nội",
                "Quận Ba Đình, Hà Nội", 
                "Quận Cầu Giấy, Hà Nội",
                "Quận 1, TP.HCM",
                "Quận 3, TP.HCM",
                "Hải Châu, Đà Nẵng"
            ]),
            "latitude": round(random.uniform(20.5, 21.5), 8),
            "longitude": round(random.uniform(105.5, 106.5), 8),
            "updated_at": datetime.now().isoformat(),
            "last_seen": datetime.now().isoformat(),
        }
        
        try:
            response = requests.patch(
                f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                headers=headers,
                json=update_data
            )
            
            if response.status_code in [200, 204]:
                successful_updates += 1
                rank = update_data['rank']
                elo = update_data['elo_rating']
                print(f"✅ {successful_updates:2d}: {full_name} - Rank {rank} (ELO: {elo})")
            else:
                print(f"❌ Error updating user {user_id}: {response.status_code}")
                print(f"   Response: {response.text[:200]}...")
                
        except Exception as e:
            print(f"❌ Exception updating user {user_id}: {str(e)}")
    
    print(f"\n🎉 HOÀN THÀNH! Đã update thành công {successful_updates} users")
    
    # Show summary
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=full_name,rank,elo_rating&order=elo_rating.desc",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            print(f"\n📊 DANH SÁCH USERS THEO RANK:")
            print("-" * 60)
            for i, user in enumerate(users, 1):
                name = user['full_name']
                rank = user['rank']
                elo = user['elo_rating']
                print(f"{i:2d}. {name:<20} | Rank {rank:<3} | ELO {elo}")
            
    except Exception as e:
        print(f"Không thể hiển thị danh sách: {e}")

if __name__ == "__main__":
    update_existing_users_diversity()