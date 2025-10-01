#!/usr/bin/env python3
"""
Test new proper bracket system
"""

from supabase import create_client

def main():
    url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
    key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
    
    supabase = create_client(url, key)
    
    print("🧹 CLEARING OLD BRACKET DATA")
    print("="*50)
    
    # Clear all existing matches 
    try:
        # Get all matches first
        matches = supabase.table('matches').select('id').execute()
        print(f"Found {len(matches.data)} matches to clear")
        
        if matches.data:
            # Delete all matches  
            match_ids = [match['id'] for match in matches.data]
            supabase.table('matches').delete().in_('id', match_ids).execute()
            print(f"✅ Cleared {len(matches.data)} existing matches")
        else:
            print(f"✅ No matches to clear")
        
        # Reset tournament status (only status, not bracket_data)
        tournaments = supabase.table('tournaments').select('id, status').execute()
        
        for tournament in tournaments.data:
            if tournament['status'] != 'open':
                supabase.table('tournaments').update({
                    'status': 'open',
                }).eq('id', tournament['id']).execute()
            
        print(f"✅ Reset {len(tournaments.data)} tournaments to 'open' status")
            
        print(f"✅ Reset {len(tournaments.data)} tournaments to 'open' status")
        
        print(f"\n🎯 DATABASE READY FOR NEW BRACKET SYSTEM")
        print(f"   → All old matches cleared")
        print(f"   → Tournaments reset to 'open' status") 
        print(f"   → Ready to test ProperBracketService")
        print(f"\n📱 Go to app and click 'Tạo bảng đấu' to test new system!")
        
    except Exception as e:
        print(f"❌ Error clearing data: {e}")

if __name__ == "__main__":
    main()