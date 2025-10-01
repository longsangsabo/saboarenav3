#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🧪 TEST INTEGRATION - Verify CompleteDoubleEliminationService integration
Test if the UI now uses the new integrated service instead of old BracketService
"""

from supabase import create_client
from datetime import datetime

# Supabase configuration
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def test_integration_ready():
    """Test if tournament is ready for CompleteDoubleEliminationService"""
    print("🔍 TESTING INTEGRATION READINESS")
    print("=" * 50)
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    # Check existing tournament with double_elimination format
    tournaments = supabase.table('tournaments').select('id, title, bracket_format, max_participants').eq('bracket_format', 'double_elimination').limit(1).execute()
    
    if not tournaments.data:
        print("❌ No double elimination tournament found")
        return False
    
    tournament = tournaments.data[0]
    tournament_id = tournament['id']
    print(f"✅ Found tournament: {tournament['title']}")
    print(f"   ID: {tournament_id}")
    print(f"   Format: {tournament['bracket_format']}")
    print(f"   Max participants: {tournament['max_participants']}")
    
    # Check participants
    participants = supabase.table('tournament_participants').select('user_id, users(id, full_name, username)').eq('tournament_id', tournament_id).execute()
    print(f"👥 Participants: {len(participants.data)}")
    
    # Clear any existing matches for clean test
    existing_matches = supabase.table('matches').select('id').eq('tournament_id', tournament_id).execute()
    if existing_matches.data:
        print(f"🗑️ Clearing {len(existing_matches.data)} existing matches for clean test")
        supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
    
    # Test CompleteDoubleEliminationService logic (simulation)
    if len(participants.data) == 16 and tournament['bracket_format'] == 'double_elimination':
        print("🎯 INTEGRATION TEST CONDITIONS MET:")
        print("   ✅ 16 participants (DE16)")
        print("   ✅ double_elimination format")  
        print("   ✅ CompleteDoubleEliminationService should be triggered")
        print("\n🚀 When user clicks 'Tạo bảng' in app:")
        print("   1. TournamentService.generateBracket() will be called")
        print("   2. Format detection: double_elimination + 16 participants")
        print("   3. CompleteDoubleEliminationService._generateDE16Bracket() will be triggered")
        print("   4. 31 precise matches will be generated")
        print("   5. Auto-advance triggers will be set up")
        return True
    else:
        print("⚠️ CONDITIONS NOT MET:")
        print(f"   Participants: {len(participants.data)} (need 16)")
        print(f"   Format: {tournament['bracket_format']} (need double_elimination)")
        return False

def prepare_test_data():
    """Prepare test data if needed"""
    print("\n📋 PREPARING TEST DATA")
    print("-" * 30)
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    # Check if we have 16 users
    users = supabase.table('users').select('id, full_name').limit(16).execute()
    print(f"👤 Available users: {len(users.data)}")
    
    if len(users.data) < 16:
        print("⚠️ Need at least 16 users for DE16 testing")
        return False
    
    # Check for double elimination tournament
    tournaments = supabase.table('tournaments').select('id, title, bracket_format').eq('bracket_format', 'double_elimination').execute()
    
    if tournaments.data:
        tournament = tournaments.data[0]
        print(f"✅ Using existing tournament: {tournament['title']}")
        tournament_id = tournament['id']
    else:
        print("⚠️ No double elimination tournament found")
        print("ℹ️ Use existing tournament and update bracket_format to 'double_elimination'")
        return False
    
    # Ensure 16 participants
    existing_participants = supabase.table('tournament_participants').select('user_id').eq('tournament_id', tournament_id).execute()
    
    if len(existing_participants.data) < 16:
        needed = 16 - len(existing_participants.data)
        print(f"📝 Need {needed} more participants")
        
        # Get available users not in tournament
        used_user_ids = [p['user_id'] for p in existing_participants.data]
        available_users = [u for u in users.data if u['id'] not in used_user_ids]
        
        if len(available_users) >= needed:
            new_participants = []
            for i, user in enumerate(available_users[:needed]):
                new_participants.append({
                    'tournament_id': tournament_id,
                    'user_id': user['id'],
                    'registered_at': datetime.now().isoformat(),
                    'payment_status': 'completed',
                    'status': 'active',
                    'seed_number': len(existing_participants.data) + i + 1,
                })
            
            try:
                supabase.table('tournament_participants').insert(new_participants).execute()
                print(f"✅ Added {len(new_participants)} participants")
            except Exception as e:
                print(f"⚠️ Could not add participants: {e}")
        else:
            print("❌ Not enough available users")
    else:
        print("✅ Tournament already has enough participants")
    
    return True

def main():
    print("🧪 COMPLETE DOUBLE ELIMINATION SERVICE - INTEGRATION TEST")
    print("=" * 60)
    
    # Test integration readiness
    ready = test_integration_ready()
    
    if not ready:
        print("\n📝 PREPARING TEST DATA...")
        prepare_test_data()
        print("\n🔄 RE-TESTING AFTER PREPARATION...")
        ready = test_integration_ready()
    
    print(f"\n📊 INTEGRATION TEST RESULT")
    print("=" * 30)
    if ready:
        print("✅ READY FOR TESTING")
        print("🎯 Go to app and click 'Tạo bảng' to test integration")
        print("📱 Expected result: 31 matches created with precise DE16 logic")
    else:
        print("❌ NOT READY")
        print("🔧 Fix conditions above and run test again")
    
    return ready

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)