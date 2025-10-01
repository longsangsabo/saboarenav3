#!/usr/bin/env python3
"""
Complete Tournament Auto-Fill and Trigger Test
Test auto-progression system với mock data
"""

from supabase import create_client
import sys

def connect_supabase():
    """Connect to Supabase"""
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    return create_client(url, key)

def create_test_winners_for_sabo678(supabase):
    """
    Tạo test data cho sabo678 tournament để test auto-progression
    """
    
    tournament_id = '0afe5240-af1e-47d2-8e27-25a1bc727c4d'
    
    print("🧪 CREATING TEST DATA FOR SABO678")
    print("=" * 50)
    
    # Get all R1 matches
    r1_matches = supabase.table('matches').select('match_number, player1_id, player2_id')\
        .eq('tournament_id', tournament_id)\
        .eq('round_number', 1)\
        .order('match_number')\
        .execute()
    
    if not r1_matches.data:
        print("❌ No R1 matches found!")
        return
    
    print(f"📋 Found {len(r1_matches.data)} R1 matches")
    
    # Set winners for R1 matches (player1 always wins for simplicity)
    winners_set = 0
    
    for match in r1_matches.data:
        match_num = match['match_number']
        player1_id = match['player1_id']
        player2_id = match['player2_id']
        
        if not player1_id or not player2_id:
            print(f"  ⚠️ R1M{match_num}: Missing players")
            continue
        
        # Set player1 as winner and status as completed
        try:
            result = supabase.table('matches').update({
                'winner_id': player1_id,
                'status': 'completed'
            }).eq('tournament_id', tournament_id)\
              .eq('round_number', 1)\
              .eq('match_number', match_num)\
              .execute()
            
            if result.data:
                print(f"  ✅ R1M{match_num}: Set winner {player1_id[:8]}...")
                winners_set += 1
            else:
                print(f"  ❌ R1M{match_num}: Failed to set winner")
                
        except Exception as e:
            print(f"  ❌ R1M{match_num}: Error - {e}")
    
    print(f"\n🎯 Test data created: {winners_set} winners set")
    return winners_set

def main():
    """Main function"""
    
    supabase = connect_supabase()
    
    print("🚀 TOURNAMENT AUTO-PROGRESSION TEST SYSTEM")
    print("=" * 60)
    
    # Create test data for sabo678
    winners_created = create_test_winners_for_sabo678(supabase)
    
    if winners_created > 0:
        print(f"\n🎉 Test data ready! Now running auto-fill...")
        
        # Import and run the auto-fill system
        import tournament_auto_fill
        
        # Run auto-fill on sabo678
        tournament_id = '0afe5240-af1e-47d2-8e27-25a1bc727c4d'
        updates = tournament_auto_fill.fill_tournament_progression(supabase, tournament_id)
        
        if updates > 0:
            print(f"\n🏆 SUCCESS: Auto-progression worked! {updates} matches filled!")
        else:
            print(f"\n💭 No matches filled - check prerequisites")
    else:
        print(f"\n❌ No test data created")

if __name__ == "__main__":
    main()