-- =====================================================
-- ADDITIONAL MATCHES POLICY FOR CREATION
-- Execute this in Supabase Dashboard > SQL Editor
-- =====================================================

-- Add a more permissive policy for matches creation
-- This allows any authenticated user to create matches for tournaments they participate in

DROP POLICY IF EXISTS "matches_creation_access" ON matches;

CREATE POLICY "matches_creation_access" 
ON matches 
FOR INSERT
USING (
    -- Tournament exists and user is either organizer or participant
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = matches.tournament_id 
        AND (
            t.organizer_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM tournament_participants tp
                WHERE tp.tournament_id = t.id 
                AND tp.user_id = auth.uid()
            )
        )
    )
    OR
    -- Club owner can create matches for their club's tournaments
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON c.id = t.club_id
        WHERE t.id = matches.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- Admin can create any matches
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
    OR
    -- Allow if no authentication (for system operations)
    auth.uid() IS NULL
);

-- Verify the new policy
SELECT 
    tablename, 
    policyname, 
    cmd,
    'Additional creation policy added' as status
FROM pg_policies 
WHERE tablename = 'matches' AND policyname = 'matches_creation_access';