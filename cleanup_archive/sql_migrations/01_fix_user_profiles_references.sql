-- ===================================
-- SCRIPT 1: FIX USER_PROFILES REFERENCES
-- ===================================
-- Run this first to fix all users references in database

-- 1. Drop all policies that might reference users
DROP POLICY IF EXISTS "matches_select_policy" ON matches;
DROP POLICY IF EXISTS "matches_insert_policy" ON matches;
DROP POLICY IF EXISTS "matches_update_policy" ON matches;
DROP POLICY IF EXISTS "matches_delete_policy" ON matches;

-- 2. Drop any triggers that might reference users
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON matches;
DROP TRIGGER IF EXISTS matches_user_profiles_trigger ON matches;

-- 3. Drop any functions that might reference users
DROP FUNCTION IF EXISTS get_match_with_profiles();
DROP FUNCTION IF EXISTS update_match_with_profiles();

-- 4. Create simple RLS policies for matches table
CREATE POLICY "Allow read matches" ON matches FOR SELECT TO public USING (true);
CREATE POLICY "Allow insert matches" ON matches FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "Allow update matches" ON matches FOR UPDATE TO public USING (true);
CREATE POLICY "Allow delete matches" ON matches FOR DELETE TO public USING (true);

-- 5. Verify matches table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'matches' 
ORDER BY ordinal_position;