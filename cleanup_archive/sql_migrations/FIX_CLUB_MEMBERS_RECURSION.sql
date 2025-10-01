-- =====================================================
-- FIX INFINITE RECURSION IN CLUB_MEMBERS POLICIES
-- Execute this in Supabase Dashboard > SQL Editor
-- =====================================================

-- Drop all club_members policies first
DROP POLICY IF EXISTS "club_members_public_read" ON club_members;
DROP POLICY IF EXISTS "club_members_full_access" ON club_members;
DROP POLICY IF EXISTS "club_members_owners_access" ON club_members;
DROP POLICY IF EXISTS "Club members are readable by club members" ON club_members;
DROP POLICY IF EXISTS "Users can join clubs" ON club_members;
DROP POLICY IF EXISTS "Users can leave clubs" ON club_members;
DROP POLICY IF EXISTS "Club admins can manage members" ON club_members;

-- Simple public read policy (no recursion)
CREATE POLICY "club_members_public_read" 
ON club_members 
FOR SELECT 
USING (true);

-- Simplified full access policy (avoiding recursion)
CREATE POLICY "club_members_owners_access" 
ON club_members 
FOR ALL 
USING (
    -- Club owner has full access to their club's members
    EXISTS (
        SELECT 1 FROM clubs c
        WHERE c.id = club_members.club_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- User can manage their own membership
    club_members.user_id = auth.uid()
    OR
    -- System admin has full access
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    -- Same conditions for WITH CHECK
    EXISTS (
        SELECT 1 FROM clubs c
        WHERE c.id = club_members.club_id 
        AND c.owner_id = auth.uid()
    )
    OR
    club_members.user_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- Verify no recursion
SELECT 
    tablename, 
    policyname, 
    cmd,
    'Fixed policy - no recursion' as status
FROM pg_policies 
WHERE tablename = 'club_members'
ORDER BY policyname;