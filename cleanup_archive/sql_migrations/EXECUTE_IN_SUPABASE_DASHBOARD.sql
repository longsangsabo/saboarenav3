-- =====================================================
-- RLS POLICIES RELAXATION - COPY PASTE TO SUPABASE DASHBOARD
-- Execute this in Supabase Dashboard > SQL Editor
-- =====================================================

-- =====================================================
-- STEP 1: TOURNAMENTS TABLE
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Tournaments are publicly readable" ON tournaments;
DROP POLICY IF EXISTS "Club owners can manage tournaments" ON tournaments;
DROP POLICY IF EXISTS "Tournament organizers can manage tournaments" ON tournaments;
DROP POLICY IF EXISTS "public_read_tournaments" ON tournaments;
DROP POLICY IF EXISTS "club_owners_full_tournament_access" ON tournaments;

-- Public read policy
CREATE POLICY "tournaments_public_read" 
ON tournaments 
FOR SELECT 
USING (true);

-- Club owners and organizers full access
CREATE POLICY "tournaments_owners_full_access" 
ON tournaments 
FOR ALL 
USING (
    -- Club owner has full access to their club's tournaments
    EXISTS (
        SELECT 1 FROM clubs 
        WHERE clubs.id = tournaments.club_id 
        AND clubs.owner_id = auth.uid()
    )
    OR 
    -- Tournament organizer has full access
    tournaments.organizer_id = auth.uid()
    OR
    -- Admin has full access
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'admin'
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM clubs 
        WHERE clubs.id = tournaments.club_id 
        AND clubs.owner_id = auth.uid()
    )
    OR 
    tournaments.organizer_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users 
        WHERE users.id = auth.uid() 
        AND users.role = 'admin'
    )
);

-- =====================================================
-- STEP 2: TOURNAMENT_PARTICIPANTS TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can register for tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament organizers can manage participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admin users can manage all tournament participants" ON tournament_participants;
DROP POLICY IF EXISTS "Users can update own participation" ON tournament_participants;
DROP POLICY IF EXISTS "Users can withdraw from tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament participants are publicly readable" ON tournament_participants;
DROP POLICY IF EXISTS "Admin full access" ON tournament_participants;
DROP POLICY IF EXISTS "User self registration" ON tournament_participants;
DROP POLICY IF EXISTS "User manage own participation" ON tournament_participants;
DROP POLICY IF EXISTS "Public read participants" ON tournament_participants;

-- Public read access
CREATE POLICY "participants_public_read" 
ON tournament_participants 
FOR SELECT 
USING (true);

-- Full access for club owners, organizers, admins, and users for own records  
CREATE POLICY "participants_full_access" 
ON tournament_participants 
FOR ALL 
USING (
    -- Club owner has full access to participants in their club's tournaments
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON t.club_id = c.id
        WHERE t.id = tournament_participants.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    -- Tournament organizer has full access
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = tournament_participants.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    -- Admin has full access
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
    OR
    -- User can manage their own participation
    tournament_participants.user_id = auth.uid()
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM tournaments t
        JOIN clubs c ON t.club_id = c.id
        WHERE t.id = tournament_participants.tournament_id 
        AND c.owner_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = tournament_participants.tournament_id 
        AND t.organizer_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
    OR
    tournament_participants.user_id = auth.uid()
);

-- =====================================================
-- STEP 3: CLUB_MEMBERS TABLE
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Club members are readable by club members" ON club_members;
DROP POLICY IF EXISTS "Users can join clubs" ON club_members;
DROP POLICY IF EXISTS "Users can leave clubs" ON club_members;
DROP POLICY IF EXISTS "Club admins can manage members" ON club_members;

-- Public read access
CREATE POLICY "club_members_public_read" 
ON club_members 
FOR SELECT 
USING (true);

-- Full access for club owners, admins, and users for own records
CREATE POLICY "club_members_full_access" 
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
    -- Club admin can manage members
    EXISTS (
        SELECT 1 FROM club_members cm
        WHERE cm.club_id = club_members.club_id 
        AND cm.user_id = auth.uid()
        AND cm.role IN ('owner', 'admin')
        AND cm.status = 'active'
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
    EXISTS (
        SELECT 1 FROM clubs c
        WHERE c.id = club_members.club_id 
        AND c.owner_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM club_members cm
        WHERE cm.club_id = club_members.club_id 
        AND cm.user_id = auth.uid()
        AND cm.role IN ('owner', 'admin')
        AND cm.status = 'active'
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

-- =====================================================
-- STEP 4: CLUBS TABLE
-- =====================================================

-- Drop existing policies
DROP POLICY IF EXISTS "Clubs are publicly readable" ON clubs;
DROP POLICY IF EXISTS "Club owners can manage clubs" ON clubs;

-- Public read access
CREATE POLICY "clubs_public_read" 
ON clubs 
FOR SELECT 
USING (true);

-- Club owners and admins full access
CREATE POLICY "clubs_owners_full_access" 
ON clubs 
FOR ALL 
USING (
    clubs.owner_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
) 
WITH CHECK (
    clubs.owner_id = auth.uid()
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- =====================================================
-- STEP 5: MATCHES TABLE
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

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify policies are created
SELECT 
    tablename, 
    policyname, 
    cmd,
    'Policy created successfully' as status
FROM pg_policies 
WHERE tablename IN ('tournaments', 'tournament_participants', 'club_members', 'clubs', 'matches')
  AND policyname LIKE '%_public_read'
   OR policyname LIKE '%_full_access'
   OR policyname LIKE '%_owners_full_access'
ORDER BY tablename, policyname;