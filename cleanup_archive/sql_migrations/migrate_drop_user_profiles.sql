-- MIGRATION: DROP USER_PROFILES TABLE AND FIX CONSTRAINTS
-- This script will remove users table and fix all related issues

-- 1. Drop all foreign key constraints related to users
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Find and drop all foreign key constraints pointing to or from users
    FOR constraint_record IN 
        SELECT tc.constraint_name, tc.table_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND (tc.table_name = 'users' OR ccu.table_name = 'users')
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I CASCADE', 
                      constraint_record.table_name, constraint_record.constraint_name);
        RAISE NOTICE 'Dropped constraint % from table %', 
                     constraint_record.constraint_name, constraint_record.table_name;
    END LOOP;
END $$;

-- 2. Drop users table completely
DROP TABLE IF EXISTS users CASCADE;

-- 3. Ensure users table has all necessary columns for our app
-- Add any missing columns that might have been in users
ALTER TABLE users ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8);
ALTER TABLE users ADD COLUMN IF NOT EXISTS location_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 1000;
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_won INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS spa_points_lost INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS challenge_win_streak INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_available_for_challenges BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS preferred_match_type VARCHAR(50) DEFAULT 'both';
ALTER TABLE users ADD COLUMN IF NOT EXISTS max_challenge_distance INTEGER DEFAULT 10;

-- 4. Create proper indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_location ON users(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_users_available_challenges ON users(is_available_for_challenges);
CREATE INDEX IF NOT EXISTS idx_users_spa_points ON users(spa_points);
CREATE INDEX IF NOT EXISTS idx_users_last_seen ON users(last_seen);

-- 5. Update any existing users to have proper default values
UPDATE users 
SET 
    spa_points = COALESCE(spa_points, 1000),
    spa_points_won = COALESCE(spa_points_won, 0),
    spa_points_lost = COALESCE(spa_points_lost, 0),
    challenge_win_streak = COALESCE(challenge_win_streak, 0),
    is_available_for_challenges = COALESCE(is_available_for_challenges, true),
    preferred_match_type = COALESCE(preferred_match_type, 'both'),
    max_challenge_distance = COALESCE(max_challenge_distance, 10)
WHERE spa_points IS NULL 
   OR spa_points_won IS NULL 
   OR spa_points_lost IS NULL 
   OR challenge_win_streak IS NULL 
   OR is_available_for_challenges IS NULL 
   OR preferred_match_type IS NULL 
   OR max_challenge_distance IS NULL;

-- 6. Verification
SELECT 'USER_PROFILES MIGRATION COMPLETED!' as status;

-- Check that users is gone
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') 
        THEN '❌ users table still exists!'
        ELSE '✅ users table successfully removed'
    END as user_profiles_status;

-- Check users table structure
SELECT 
    'Users table columns' as info,
    COUNT(*) as total_columns
FROM information_schema.columns 
WHERE table_name = 'users';

-- Check for any remaining foreign key constraints mentioning users
SELECT 
    CASE 
        WHEN COUNT(*) > 0 
        THEN '❌ Found ' || COUNT(*) || ' remaining users constraints'
        ELSE '✅ No users constraints remaining'
    END as constraint_status
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND (tc.table_name = 'users' OR ccu.table_name = 'users');

-- Show current users count
SELECT 
    'Current users in database' as info,
    COUNT(*) as count
FROM users;