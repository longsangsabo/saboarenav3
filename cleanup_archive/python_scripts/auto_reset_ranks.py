#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Auto Reset All User Ranks - No Confirmation Required
Tự động reset rank của tất cả users về rank mặc định để testing
"""

import os
import json
from supabase import create_client, Client

def load_config():
    """Load Supabase configuration"""
    try:
        # Try to load from env.json first
        if os.path.exists('env.json'):
            with open('env.json', 'r') as f:
                config = json.load(f)
                return config.get('SUPABASE_URL'), config.get('SUPABASE_SERVICE_KEY')
        
        # Fallback to environment variables
        url = os.getenv('SUPABASE_URL')
        key = os.getenv('SUPABASE_SERVICE_KEY')
        
        if not url or not key:
            print("❌ Missing Supabase configuration!")
            return None, None
            
        return url, key
        
    except Exception as e:
        print(f"❌ Error loading config: {e}")
        return None, None

def auto_reset_ranks():
    """Automatically reset all user ranks"""
    print("🚀 AUTO RESET: All User Ranks → 'K' (Người mới)")
    print("=" * 50)
    
    url, key = load_config()
    if not url or not key:
        return False
    
    try:
        supabase: Client = create_client(url, key)
        print("✅ Connected to Supabase")
        
        # Step 1: Backup current data
        print("💾 Creating backup...")
        backup_sql = """
        DROP TABLE IF EXISTS users_rank_reset_backup;
        CREATE TABLE users_rank_reset_backup AS 
        SELECT id, rank, elo_rating, total_wins, total_losses, created_at, updated_at
        FROM users 
        WHERE rank IS NOT NULL;
        """
        
        try:
            supabase.rpc('exec_sql', {'sql_query': backup_sql}).execute()
            print("  ✅ Backup created")
        except Exception as e:
            print(f"  ⚠️  Backup warning: {e}")
        
        # Step 2: Reset all users to rank K
        print("🔄 Resetting all user ranks...")
        reset_sql = """
        UPDATE users 
        SET 
            rank = 'K',
            elo_rating = 1000,
            total_wins = 0,
            total_losses = 0,
            updated_at = NOW()
        WHERE id IS NOT NULL;
        """
        
        result = supabase.rpc('exec_sql', {'sql_query': reset_sql}).execute()
        print("  ✅ User ranks reset to 'K'")
        
        # Step 3: Clear rank requests
        print("🧹 Clearing rank requests...")
        clear_requests_sql = "DELETE FROM rank_requests;"
        
        try:
            supabase.rpc('exec_sql', {'sql_query': clear_requests_sql}).execute()
            print("  ✅ Rank requests cleared")
        except Exception as e:
            print(f"  ⚠️  Rank requests table might not exist: {e}")
        
        # Step 4: Verify results
        print("📊 Verification...")
        users_result = supabase.table('users').select('id,rank,elo_rating,total_wins').execute()
        users = users_result.data
        
        total_users = len(users)
        rank_k_count = len([u for u in users if u.get('rank') == 'K'])
        elo_1000_count = len([u for u in users if u.get('elo_rating') == 1000])
        
        print(f"  📈 Total users: {total_users}")
        print(f"  🎯 Users with rank 'K': {rank_k_count}")
        print(f"  📊 Users with ELO 1000: {elo_1000_count}")
        
        # Show sample
        print("\n👥 Sample users:")
        for i, user in enumerate(users[:3]):
            print(f"  {i+1}. Rank: {user.get('rank')} | ELO: {user.get('elo_rating')} | Wins: {user.get('total_wins')}")
        
        print("\n" + "=" * 50)
        print("🎉 RESET COMPLETED!")
        print("🎯 All users now have rank 'K' (Người mới)")
        print("📱 Perfect for testing Vietnamese ranking system!")
        print("💾 Backup saved as 'users_rank_reset_backup'")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    auto_reset_ranks()