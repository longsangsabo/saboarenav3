-- Fix User Rank Default Issue
-- Removes default rank value to ensure new users are unranked by default

-- 1. Remove any default value for rank column (should be NULL for new users)
ALTER TABLE users ALTER COLUMN rank DROP DEFAULT;

-- 2. Add comment to clarify NULL means unranked
COMMENT ON COLUMN users.rank IS 'User rank: K, K+, I, I+, H, H+, G, G+, F, F+, E, E+. NULL means unranked.';

-- 3. Update any existing users with problematic E rank and low ELO
-- (Users with E rank but ELO <= 1200 are likely incorrectly assigned)
UPDATE users 
SET rank = NULL 
WHERE rank = 'E' 
AND elo_rating <= 1200 
AND created_at >= NOW() - INTERVAL '30 days';

-- 4. Verify the fix
SELECT 'RANK VERIFICATION' as status;
SELECT 
    rank,
    COUNT(*) as count,
    AVG(elo_rating) as avg_elo
FROM users 
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY rank
ORDER BY count DESC;