#!/usr/bin/env python3
"""
Clear matches for specific tournament
"""

from supabase import create_client

def clear_tournament_matches():
    SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
    SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.AzCaRKCBEYlO1rBGbRHPIY1mS-2PrS0T5LXrOCvKOcY"
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    
    # Clear matches for sabo1 tournament
    tournament_id = "95cee835-9265-4b08-95b1-a5f9a67c1ec8"
    
    try:
        result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
        print(f"🗑️ Cleared matches for tournament sabo1")
        print(f"📊 Status: Success")
        
        # Check remaining matches
        remaining = supabase.table('matches').select('*').eq('tournament_id', tournament_id).execute()
        print(f"📋 Remaining matches: {len(remaining.data)}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    clear_tournament_matches()