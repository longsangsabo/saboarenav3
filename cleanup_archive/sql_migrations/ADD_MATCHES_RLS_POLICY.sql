-- =====================================================
-- RLS POLICY FOR MATCHES TABLE
-- Execute this in Supabase Dashboard > SQL Editor
-- =====================================================

-- Drop existing matches policies
DROP POLICY IF EXISTS "Matches are readable by everyone" ON matches;
DROP POLICY IF EXISTS "Tournament participants can create matches" ON matches;
DROP POLICY IF EXISTS "Tournament organizers can manage matches" ON matches;
DROP POLICY IF EXISTS "matches_public_read" ON matches;
DROP POLICY IF EXISTS "matches_owners_full_access" ON matches;

-- Public read policy for matches
CREATE POLICY "matches_public_read" 
ON matches 
FOR SELECT 
USING (true);

-- Full access for tournament organizers and club owners
CREATE POLICY "matches_owners_full_access" 
ON matches 
FOR ALL 
USING (
    -- Tournament organizer has full access
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = matches.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    -- Club owner has full access to their club's tournament matches
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON c.id = t.club_id
        WHERE t.id = matches.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- Players in the match can manage their own matches
    matches.player1_id = auth.uid() OR matches.player2_id = auth.uid()
    OR
    -- Admin has full access
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = matches.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON c.id = t.club_id
        WHERE t.id = matches.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    matches.player1_id = auth.uid() OR matches.player2_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- Verify matches policies
SELECT 
    tablename, 
    policyname, 
    cmd,
    'Matches policy created successfully' as status
FROM pg_policies 
WHERE tablename = 'matches'
ORDER BY policyname;