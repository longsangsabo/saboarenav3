-- URGENT FIX: RLS Policies for Tournament Participants
-- Execute this SQL in Supabase Dashboard > SQL Editor

-- Step 1: Drop all existing conflicting policies
DROP POLICY IF EXISTS "Users can register for tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament organizers can manage participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admin users can manage all tournament participants" ON tournament_participants;
DROP POLICY IF EXISTS "Users can update own participation" ON tournament_participants;
DROP POLICY IF EXISTS "Users can withdraw from tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament participants are publicly readable" ON tournament_participants;

-- Step 2: Create simple, permissive policies

-- 2.1: Admin can do EVERYTHING with tournament participants
CREATE POLICY "Admin full access" 
ON tournament_participants 
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- 2.2: Users can register themselves
CREATE POLICY "User self registration" 
ON tournament_participants 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 2.3: Users can manage their own participation
CREATE POLICY "User manage own participation" 
ON tournament_participants 
FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "User withdraw from tournaments" 
ON tournament_participants 
FOR DELETE 
USING (auth.uid() = user_id);

-- 2.4: Public can read tournament participants
CREATE POLICY "Public read participants" 
ON tournament_participants 
FOR SELECT 
USING (true);

-- Step 3: Ensure RLS is enabled
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- Step 4: Grant permissions
GRANT ALL ON tournament_participants TO authenticated;
GRANT SELECT ON tournament_participants TO anon;

-- Step 5: Verify admin users
SELECT 'Admin Users:' as info;
SELECT id, email, username, display_name, role 
FROM users 
WHERE role = 'admin'
ORDER BY email;

-- Step 6: Test query - this should work without errors
SELECT 'Test Query:' as info;
SELECT COUNT(*) as total_participants 
FROM tournament_participants;

COMMIT;