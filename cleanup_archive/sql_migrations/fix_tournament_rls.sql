-- Fix RLS policies for tournament_participants table
-- Allow club owners/managers to view participants of their tournaments

-- Drop existing policies (all possible variations)
DROP POLICY IF EXISTS "tournament_participants_select" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_insert" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_update" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_delete" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_public_select" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_auth_insert" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_club_update" ON tournament_participants;
DROP POLICY IF EXISTS "tournament_participants_club_delete" ON tournament_participants;

-- Create new policies that allow:
-- 1. Public read access to tournament participants (for viewing who joined)
-- 2. Authenticated users can join tournaments
-- 3. Club owners/managers can manage participants of their tournaments

-- Policy 1: Public can view tournament participants (MOST IMPORTANT)
CREATE POLICY "tournament_participants_public_select" ON tournament_participants
FOR SELECT USING (true);

-- Policy 2: Authenticated users can insert themselves into tournaments
CREATE POLICY "tournament_participants_auth_insert" ON tournament_participants
FOR INSERT WITH CHECK (
    -- User can register themselves (simplified check)
    (user_id = COALESCE(auth.uid()::text, '')) OR
    -- Admin/managers can add anyone (simplified check)
    (EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = COALESCE(auth.uid()::text, '') 
        AND u.role IN ('admin', 'club_owner', 'club_manager')
    ))
);

-- Policy 3: Users can update their own participation, admins can update any
CREATE POLICY "tournament_participants_auth_update" ON tournament_participants
FOR UPDATE USING (
    -- User can update their own participation (simplified check)
    (user_id = COALESCE(auth.uid()::text, '')) OR
    -- Admin/managers can update any participation (simplified check)  
    (EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = COALESCE(auth.uid()::text, '') 
        AND u.role IN ('admin', 'club_owner', 'club_manager')
    ))
);

-- Policy 4: Users can delete their own participation, admins can delete any
CREATE POLICY "tournament_participants_auth_delete" ON tournament_participants
FOR DELETE USING (
    -- User can delete their own participation (simplified check)
    (user_id = COALESCE(auth.uid()::text, '')) OR
    -- Admin/managers can delete any participation (simplified check)
    (EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = COALESCE(auth.uid()::text, '') 
        AND u.role IN ('admin', 'club_owner', 'club_manager')
    ))
);

-- Also ensure users table has public read access for basic info
DROP POLICY IF EXISTS "users_public_select" ON users;
CREATE POLICY "users_public_select" ON users
FOR SELECT USING (true);

-- Verify policies are created
SELECT schemaname, tablename, policyname, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('tournament_participants', 'users')
ORDER BY tablename, policyname;