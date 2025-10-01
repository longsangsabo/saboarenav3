#!/usr/bin/env python3
import os
import json
from supabase import create_client

# Load config
if os.path.exists('env.json'):
    with open('env.json', 'r') as f:
        config = json.load(f)
        url = config.get('SUPABASE_URL')
        key = config.get('SUPABASE_SERVICE_ROLE_KEY')
else:
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')

if not url or not key:
    print("❌ Missing config")
    exit(1)

try:
    supabase = create_client(url, key)
    print("✅ Connected to Supabase")
    
    # Simple reset query
    print("🔄 Resetting ranks...")
    
    # Update all users to rank K
    result = supabase.table('users').update({
        'rank': 'K',
        'elo_rating': 1000,
        'total_wins': 0,
        'total_losses': 0
    }).not_.is_('id', 'null').execute()
    
    print(f"✅ Updated {len(result.data)} users")
    
    # Verify
    users = supabase.table('users').select('rank,elo_rating').limit(5).execute()
    print("📊 Sample results:")
    for user in users.data:
        print(f"  Rank: {user['rank']}, ELO: {user['elo_rating']}")
    
    print("🎉 DONE! All users reset to rank 'K'")
    
except Exception as e:
    print(f"❌ Error: {e}")