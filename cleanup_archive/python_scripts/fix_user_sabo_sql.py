#!/usr/bin/env python3
"""
Fix user 'sabo' - Reset to correct new user defaults using direct SQL
"""

print("🔧 Manual SQL for fixing user 'sabo'...")
print("\n📋 Execute these SQL commands in Supabase SQL Editor:")
print("=" * 60)

print("""
-- 1. Check current user 'sabo' data
SELECT username, elo_rating, rank 
FROM users 
WHERE username = 'sabo';

-- 2. Update user 'sabo' with correct new user defaults
UPDATE users 
SET 
    elo_rating = 1000,  -- Correct starting ELO
    rank = NULL         -- No rank for new users
WHERE username = 'sabo';

-- 3. Verify the update
SELECT username, elo_rating, rank 
FROM users 
WHERE username = 'sabo';

-- Expected results:
-- username: sabo
-- elo_rating: 1000
-- rank: NULL
""")

print("=" * 60)
print("✅ Copy and paste the SQL above into Supabase Dashboard > SQL Editor")
print("🎯 This will fix user 'sabo' to have correct new user defaults")
print("   - ELO: 1000 (was 1200)")
print("   - Rank: NULL (was 'E')")