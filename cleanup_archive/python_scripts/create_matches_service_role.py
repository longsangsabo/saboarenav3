#!/usr/bin/env python3
"""
Test matches creation với service role key để bypass RLS
"""

import os
import sys
from supabase import create_client, Client
import uuid
from datetime import datetime

# Database connection - SỬ DỤNG SERVICE ROLE KEY
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.rYcF7BcXJvDmC7OkVyTfLqGnxCh4FZ8rXb3Yt5LpXqU"

# Nếu service role key trên không work, thử key này:
BACKUP_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.I7M0r_8tJbM-bTVJ8Fql5r7LF4bH9F4Y2NUu9VoqLgQ"

def test_service_role_access():
    """Test xem service role key có hoạt động không"""
    print("🔐 Testing service role access...")
    
    for i, key in enumerate([SERVICE_ROLE_KEY, BACKUP_SERVICE_KEY], 1):
        try:
            print(f"\n   Testing key #{i}...")
            supabase = create_client(SUPABASE_URL, key)
            
            # Test query
            result = supabase.table('tournaments').select('id').limit(1).execute()
            print(f"   ✅ Key #{i} works! Found {len(result.data)} tournaments")
            return supabase
            
        except Exception as e:
            print(f"   ❌ Key #{i} failed: {e}")
            continue
    
    print("   ❌ All service role keys failed!")
    return None

def create_matches_with_service_role(supabase, tournament_id, participants):
    """Tạo matches với service role (bypass RLS)"""
    matches = []
    
    # Round 1: Pair up participants
    for i in range(0, len(participants), 2):
        player1 = participants[i]
        player2 = participants[i + 1] if i + 1 < len(participants) else None
        
        match = {
            'id': str(uuid.uuid4()),
            'tournament_id': tournament_id,
            'player1_id': player1['user_id'],
            'player2_id': player2['user_id'] if player2 else None,
            'round_number': 1,
            'match_number': (i // 2) + 1,
            'status': 'pending',
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
        }
        
        # Handle BYE
        if player2 is None:
            match['winner_id'] = player1['user_id']
            match['status'] = 'completed'
            match['player1_score'] = 2
            match['player2_score'] = 0
        
        matches.append(match)
    
    return matches

def main():
    print("=== TẠO MATCHES VỚI SERVICE ROLE ===\n")
    
    # Test service role access
    supabase = test_service_role_access()
    if not supabase:
        print("❌ Cannot connect with service role. Exiting.")
        return
    
    print("\n1. TÌM TOURNAMENTS CẦN TẠO MATCHES:")
    print("-" * 50)
    
    # Get tournaments without matches
    tournaments = supabase.table('tournaments').select('*').execute()
    tournaments_need_matches = []
    
    for tournament in tournaments.data:
        tournament_id = tournament['id']
        
        # Check participants
        participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
        participant_count = len(participants.data)
        
        # Check matches
        matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        match_count = len(matches.data)
        
        if participant_count >= 2 and match_count == 0:
            tournaments_need_matches.append({
                'tournament': tournament,
                'participants': participants.data
            })
            print(f"🏆 Tournament: {tournament.get('title', 'No title')}")
            print(f"   ID: {tournament_id}")
            print(f"   Participants: {participant_count}")
            print()
    
    if not tournaments_need_matches:
        print("✅ Không có tournament nào cần tạo matches.")
        return
    
    print(f"\n2. TẠO MATCHES VỚI SERVICE ROLE:")
    print("-" * 50)
    
    total_created = 0
    
    for item in tournaments_need_matches:
        tournament = item['tournament']
        tournament_id = tournament['id']
        participants = item['participants']
        
        print(f"\n🏗️ Creating matches for: {tournament.get('title', 'No title')}")
        
        try:
            # Create matches
            matches = create_matches_with_service_role(supabase, tournament_id, participants)
            
            # Insert with service role (should bypass RLS)
            supabase.table('matches').insert(matches).execute()
            print(f"   ✅ Created {len(matches)} matches successfully!")
            
            # Update tournament status
            supabase.table('tournaments').update({
                'status': 'in_progress',
                'updated_at': datetime.now().isoformat()
            }).eq('id', tournament_id).execute()
            print(f"   📝 Updated tournament status to 'in_progress'")
            
            total_created += len(matches)
            
        except Exception as e:
            print(f"   ❌ Error creating matches: {e}")
    
    print(f"\n🎉 HOÀN THÀNH!")
    print("-" * 50)
    print(f"✅ Đã tạo tổng cộng {total_created} matches")
    
    # Verify results
    print(f"\n3. KIỂM TRA KẾT QUẢ:")
    print("-" * 50)
    
    for item in tournaments_need_matches:
        tournament = item['tournament']
        tournament_id = tournament['id']
        
        matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        print(f"🏆 {tournament.get('title', 'No title')}: {len(matches.data)} matches")

if __name__ == "__main__":
    main()