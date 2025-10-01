-- Update RLS Policies for Tournament Participants
-- This allows admin users to add any user to tournaments

-- Drop existing policies that might conflict
DROP POLICY IF EXISTS "Users can register for tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament organizers can manage participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admin users can manage all tournament participants" ON tournament_participants;

-- Recreate policies with admin support

-- 1. Users can register themselves for tournaments
CREATE POLICY "Users can register for tournaments" 
ON tournament_participants 
FOR INSERT 
WITH CHECK (
    auth.uid() = user_id  -- User registering themselves
    OR 
    EXISTS (  -- OR admin user registering someone else
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
    OR
    EXISTS (  -- OR tournament organizer adding someone
        SELECT 1 FROM tournaments t
        WHERE t.id = tournament_participants.tournament_id 
        AND t.organizer_id = auth.uid()
    )
);

-- 2. Tournament organizers can manage all participants in their tournaments
CREATE POLICY "Tournament organizers can manage participants" 
ON tournament_participants 
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM tournaments t
        WHERE t.id = tournament_participants.tournament_id 
        AND t.organizer_id = auth.uid()
    )
);

-- 3. Admin users can manage participants in any tournament
CREATE POLICY "Admin users can manage all tournament participants" 
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

-- 4. Users can update/delete their own participation  
CREATE POLICY "Users can update own participation" 
ON tournament_participants 
FOR UPDATE 
USING (
    auth.uid() = user_id
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

CREATE POLICY "Users can withdraw from tournaments" 
ON tournament_participants 
FOR DELETE 
USING (
    auth.uid() = user_id
    OR
    EXISTS (
        SELECT 1 FROM users u 
        WHERE u.id = auth.uid() 
        AND u.role = 'admin'
    )
);

-- 5. Allow reading tournament participants (public data)
CREATE POLICY "Tournament participants are publicly readable" 
ON tournament_participants 
FOR SELECT 
USING (true);

-- Ensure RLS is enabled
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON tournament_participants TO authenticated;
GRANT SELECT ON tournament_participants TO anon;

-- Test query: Show current admin users
SELECT 'Current Admin Users:' as info;
SELECT id, email, username, display_name, role 
FROM users 
WHERE role = 'admin';

-- Test query: Show tournament participants count
SELECT 'Tournament Participants Count:' as info;
SELECT COUNT(*) as total_participants FROM tournament_participants;