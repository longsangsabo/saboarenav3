#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fix duplicate players issue - Clear and regenerate bracket
"""

from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

def fix_duplicate_bracket():
    print("🔧 FIXING DUPLICATE PLAYERS IN BRACKET")
    print("=" * 50) 
    
    supabase = create_client(SUPABASE_URL, SERVICE_KEY)
    tournament_id = 'cf969300-2321-4497-909a-8d6d8d9cf2a6'
    
    # Clear existing matches
    print("🗑️ Clearing existing matches...")
    delete_result = supabase.table('matches').delete().eq('tournament_id', tournament_id).execute()
    print(f"   Deleted {len(delete_result.data) if delete_result.data else 0} matches")
    
    print("\n✅ Bracket cleared! Now go to app and click 'Tạo bảng' again")
    print("🚀 The fixed CompleteDoubleEliminationService will generate correct bracket")
    print("🎯 Expected result: No duplicate players in any round")

if __name__ == "__main__":
    fix_duplicate_bracket()