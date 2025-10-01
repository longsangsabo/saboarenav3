#!/usr/bin/env python3
"""
🎯 SABO ARENA - Tournament Match Creation System
Uses format-specific factories for professional tournament generation
"""

import os
import sys
from supabase import create_client, Client
import uuid
from datetime import datetime

# Import our new factory system
from tournament_match_factory import create_tournament_matches_factory

# Database connection
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def create_single_elimination_matches_legacy(tournament_id, participants):
    """🔧 Legacy single elimination logic - kept as fallback"""
    matches = []
    
    # Tính số rounds
    import math
    total_rounds = math.ceil(math.log2(len(participants)))
    
    # Round 1: Pair up all participants
    round_1_matches = []
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
        
        # Nếu chỉ có 1 player (bye), tự động thắng
        if player2 is None:
            match['winner_id'] = player1['user_id']
            match['status'] = 'completed'
            match['player1_score'] = 2
            match['player2_score'] = 0
        
        round_1_matches.append(match)
        matches.append(match)
    
    print(f"   🎯 Created {len(round_1_matches)} matches for round 1")
    
    # Các rounds tiếp theo (tạo placeholder matches)
    for round_num in range(2, total_rounds + 1):
        matches_in_round = len(participants) // (2 ** round_num)
        if matches_in_round < 1:
            matches_in_round = 1
            
        for match_num in range(1, matches_in_round + 1):
            match = {
                'id': str(uuid.uuid4()),
                'tournament_id': tournament_id,
                'player1_id': None,  # Sẽ được fill sau khi round trước hoàn thành
                'player2_id': None,
                'round_number': round_num,
                'match_number': match_num,
                'status': 'pending',
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat(),
            }
            matches.append(match)
        
        print(f"   🎯 Created {matches_in_round} placeholder matches for round {round_num}")
    
    return matches

def create_round_robin_matches_legacy(tournament_id, participants):
    """🔧 Legacy round robin logic - kept as fallback"""
    matches = []
    match_number = 1
    
    for i in range(len(participants)):
        for j in range(i + 1, len(participants)):
            match = {
                'id': str(uuid.uuid4()),
                'tournament_id': tournament_id,
                'player1_id': participants[i]['user_id'],
                'player2_id': participants[j]['user_id'],
                'round_number': 1,  # Round robin có thể có nhiều rounds nhưng đơn giản hóa
                'match_number': match_number,
                'status': 'pending',
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat(),
            }
            matches.append(match)
            match_number += 1
    
    print(f"   🎯 Created {len(matches)} round robin matches")
    return matches

def generate_matches_for_tournament(supabase, tournament_id, tournament_format='single_elimination'):
    """🎯 Generate matches using format-specific factory system"""
    
    # Lấy participants
    participants_response = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
    participants = participants_response.data
    
    if len(participants) < 2:
        print(f"   ⚠️ Tournament chỉ có {len(participants)} participants, không thể tạo matches")
        return []
    
    print(f"   👥 Generating matches for {len(participants)} participants using {tournament_format}")
    
    # Tạo matches using factory system
    try:
        factory = create_tournament_matches_factory(tournament_format, tournament_id, participants)
        matches = factory.generate_matches()
        
        print(f"   🏗️ Factory generated {len(matches)} matches ({factory.get_total_rounds()} rounds)")
        
        # Insert matches vào database
        if matches:
            supabase.table('matches').insert(matches).execute()
            print(f"   ✅ Inserted {len(matches)} matches into database")
            return matches
        
    except Exception as e:
        print(f"   ❌ Error generating matches with factory: {e}")
        print(f"   🔄 Falling back to legacy system...")
        
        # Fallback to legacy system
        if tournament_format.lower() in ['single_elimination', 'single', 'elimination']:
            matches = create_single_elimination_matches_legacy(tournament_id, participants)
        elif tournament_format.lower() in ['round_robin', 'round', 'robin']:
            matches = create_round_robin_matches_legacy(tournament_id, participants)
        else:
            matches = create_single_elimination_matches_legacy(tournament_id, participants)
        
        if matches:
            try:
                supabase.table('matches').insert(matches).execute()
                print(f"   ✅ Inserted {len(matches)} matches using legacy system")
                return matches
            except Exception as e2:
                print(f"   ❌ Error inserting matches: {e2}")
                return []
    
    return []
    if matches:
        try:
            supabase.table('matches').insert(matches).execute()
            print(f"   ✅ Inserted {len(matches)} matches into database")
            return matches
        except Exception as e:
            print(f"   ❌ Error inserting matches: {e}")
            return []
    
    return []

def main():
    print("=== TẠO MATCHES TỰ ĐỘNG CHO TOURNAMENTS ===\n")
    
    # Tạo supabase client
    supabase: Client = create_client(SUPABASE_URL, ANON_KEY)
    
    print("1. TÌM TOURNAMENTS CẦN TẠO MATCHES:")
    print("-" * 50)
    
    # Lấy tournaments có participants nhưng không có matches
    tournaments_response = supabase.table('tournaments').select('*').execute()
    tournaments_need_matches = []
    
    for tournament in tournaments_response.data:
        tournament_id = tournament['id']
        
        # Kiểm tra participants
        participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tournament_id).execute()
        participant_count = len(participants.data)
        
        # Kiểm tra matches
        matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        match_count = len(matches.data)
        
        if participant_count >= 2 and match_count == 0:
            tournaments_need_matches.append({
                'tournament': tournament,
                'participant_count': participant_count,
                'participants': participants.data
            })
            print(f"🏆 Tournament: {tournament.get('title', 'No title')}")
            print(f"   ID: {tournament_id}")
            print(f"   Participants: {participant_count}")
            print(f"   Status: {tournament.get('status', 'unknown')}")
            print()
    
    if not tournaments_need_matches:
        print("✅ Không có tournament nào cần tạo matches.")
        return
    
    print(f"\n2. TẠO MATCHES CHO {len(tournaments_need_matches)} TOURNAMENTS:")
    print("-" * 50)
    
    total_matches_created = 0
    
    for item in tournaments_need_matches:
        tournament = item['tournament']
        tournament_id = tournament['id']
        participant_count = item['participant_count']
        
        print(f"\n🏗️ Processing tournament: {tournament.get('title', 'No title')}")
        print(f"   Tournament ID: {tournament_id}")
        
        # Xác định format (mặc định single elimination)
        tournament_format = tournament.get('format', 'single_elimination')
        if not tournament_format:
            tournament_format = 'single_elimination'
        
        print(f"   Format: {tournament_format}")
        
        # Tạo matches
        matches = generate_matches_for_tournament(supabase, tournament_id, tournament_format)
        total_matches_created += len(matches)
        
        # Cập nhật tournament status nếu cần
        if matches:
            try:
                supabase.table('tournaments').update({
                    'status': 'ready',  # Sẵn sàng để bắt đầu
                    'updated_at': datetime.now().isoformat()
                }).eq('id', tournament_id).execute()
                print(f"   📝 Updated tournament status to 'ready'")
            except Exception as e:
                print(f"   ⚠️ Could not update tournament status: {e}")
    
    print(f"\n🎉 HOÀN THÀNH!")
    print("-" * 50)
    print(f"✅ Đã tạo tổng cộng {total_matches_created} matches cho {len(tournaments_need_matches)} tournaments")
    print("🚀 Các tournament này giờ đã sẵn sàng để bắt đầu!")
    
    # Hiển thị kết quả cuối cùng
    print(f"\n3. KẾT QUẢ CUỐI CÙNG:")
    print("-" * 50)
    
    for item in tournaments_need_matches:
        tournament = item['tournament']
        tournament_id = tournament['id']
        
        # Kiểm tra lại matches đã tạo
        matches = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        match_count = len(matches.data)
        
        print(f"🏆 {tournament.get('title', 'No title')}")
        print(f"   Participants: {item['participant_count']}")
        print(f"   Matches created: {match_count}")
        print(f"   Status: Ready to start ✅")
        print()

if __name__ == "__main__":
    main()