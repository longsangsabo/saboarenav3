-- Fix user 'bosa' ELO and rank issue
-- User was created with old hardcoded values (ELO 1200 instead of 1000)

BEGIN;

-- 1. Check current user 'bosa' data before fix
SELECT 'BEFORE FIX:' as status, username, elo_rating, rank, created_at 
FROM users 
WHERE username = 'bosa';

-- 2. Update user 'bosa' with correct new user defaults
UPDATE users 
SET 
    elo_rating = 1000,  -- Correct starting ELO for new users
    rank = NULL         -- No rank for new users (should be NULL, not 'E')
WHERE username = 'bosa';

-- 3. Verify the update
SELECT 'AFTER FIX:' as status, username, elo_rating, rank, created_at 
FROM users 
WHERE username = 'bosa';

-- 4. Check if there are other users with incorrect default values
SELECT 'OTHER_USERS_WITH_1200_ELO:' as status, COUNT(*) as count
FROM users 
WHERE elo_rating = 1200 AND rank IS NULL AND created_at > NOW() - INTERVAL '7 days';

-- 5. Show any users created in last 7 days with ELO 1200 (potential issue)
SELECT 'RECENT_USERS_WITH_1200:' as status, username, elo_rating, rank, created_at
FROM users 
WHERE elo_rating = 1200 AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

COMMIT;

-- Expected results for user 'bosa':
-- BEFORE FIX: elo_rating = 1200, rank = 'E' or some value
-- AFTER FIX:  elo_rating = 1000, rank = NULL