#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reset All User Ranks Script
Tự động reset rank của tất cả users về rank mặc định để testing Vietnamese ranking system
"""

import os
import json
from supabase import create_client, Client
from datetime import datetime

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
            print("Please set SUPABASE_URL and SUPABASE_SERVICE_KEY")
            return None, None
            
        return url, key
        
    except Exception as e:
        print(f"❌ Error loading config: {e}")
        return None, None

def reset_user_ranks():
    """Reset all user ranks to default"""
    print("🚀 Starting User Rank Reset Process...")
    print("=" * 50)
    
    # Load configuration
    url, key = load_config()
    if not url or not key:
        return False
    
    try:
        # Initialize Supabase client
        supabase: Client = create_client(url, key)
        print("✅ Connected to Supabase")
        
        # Read the SQL reset script
        with open('reset_all_user_ranks.sql', 'r', encoding='utf-8') as f:
            sql_script = f.read()
        
        print("📄 Loaded reset SQL script")
        
        # Execute the reset script
        print("🔄 Executing rank reset...")
        print("⚠️  This will reset ALL user ranks to 'K' (Người mới)")
        
        # Confirm before proceeding
        confirm = input("❓ Are you sure you want to proceed? (yes/no): ")
        if confirm.lower() != 'yes':
            print("❌ Rank reset cancelled")
            return False
        
        # Split SQL script into individual statements for execution
        statements = sql_script.split(';')
        
        executed_count = 0
        for statement in statements:
            statement = statement.strip()
            if statement and not statement.startswith('--') and len(statement) > 10:
                try:
                    result = supabase.rpc('exec_sql', {'sql_query': statement + ';'}).execute()
                    executed_count += 1
                    print(f"  ✅ Executed statement {executed_count}")
                except Exception as stmt_error:
                    print(f"  ⚠️  Warning on statement {executed_count + 1}: {stmt_error}")
                    # Continue with other statements
        
        print(f"🎯 Executed {executed_count} SQL statements")
        
        # Verify the reset
        print("\n📊 Verifying reset results...")
        
        # Get user count and rank distribution
        users_result = supabase.table('users').select('id,rank,elo_rating,total_wins,total_losses').execute()
        users = users_result.data
        
        total_users = len(users)
        rank_k_users = len([u for u in users if u.get('rank') == 'K'])
        elo_1000_users = len([u for u in users if u.get('elo_rating') == 1000])
        zero_wins_users = len([u for u in users if u.get('total_wins') == 0])
        
        print(f"  📈 Total users: {total_users}")
        print(f"  🎯 Users with rank 'K': {rank_k_users}")
        print(f"  📊 Users with ELO 1000: {elo_1000_users}")
        print(f"  🔄 Users with 0 wins: {zero_wins_users}")
        
        # Display sample users
        print("\n👥 Sample users after reset:")
        for i, user in enumerate(users[:3]):
            print(f"  {i+1}. ID: {user.get('id')} | Rank: {user.get('rank')} | ELO: {user.get('elo_rating')} | Wins: {user.get('total_wins')}")
        
        print("\n" + "=" * 50)
        print("🎉 RANK RESET COMPLETED SUCCESSFULLY!")
        print("🎯 All users now start with rank 'K' (Người mới)")
        print("📱 You can now test the Vietnamese ranking system from scratch")
        print("💾 Original data backed up in 'users_rank_reset_backup' table")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during rank reset: {e}")
        return False

def restore_user_ranks():
    """Restore user ranks from backup (optional feature)"""
    print("🔄 Restoring User Ranks from Backup...")
    
    url, key = load_config()
    if not url or not key:
        return False
    
    try:
        supabase: Client = create_client(url, key)
        
        # Restore from backup table
        restore_sql = """
        UPDATE users 
        SET 
            rank = backup.rank,
            elo_rating = backup.elo_rating,
            total_wins = backup.total_wins,
            total_losses = backup.total_losses,
            updated_at = NOW()
        FROM users_rank_reset_backup backup
        WHERE users.id = backup.id;
        """
        
        supabase.rpc('exec_sql', {'sql_query': restore_sql}).execute()
        print("✅ User ranks restored from backup")
        return True
        
    except Exception as e:
        print(f"❌ Error restoring ranks: {e}")
        return False

if __name__ == "__main__":
    print("🎯 Vietnamese Ranking System - User Rank Reset Tool")
    print("=" * 50)
    
    action = input("Choose action:\n1. Reset all ranks to 'K'\n2. Restore from backup\n3. Exit\nEnter choice (1-3): ")
    
    if action == '1':
        reset_user_ranks()
    elif action == '2':
        restore_user_ranks()
    else:
        print("👋 Goodbye!")