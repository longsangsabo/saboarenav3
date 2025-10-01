-- Fix Tournament Participants RLS Policy
-- This fixes the RLS error when admin tries to add users to tournaments

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can register for tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament organizers can manage participants" ON tournament_participants;

-- Create new policies that allow admin operations

-- 1. Users can register themselves for tournaments
CREATE POLICY "Users can register for tournaments" 
ON tournament_participants 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

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

-- 4. Allow reading tournament participants (public data)
CREATE POLICY "Tournament participants are publicly readable" 
ON tournament_participants 
FOR SELECT 
USING (true);

-- 5. Users can update/delete their own participation
CREATE POLICY "Users can update own participation" 
ON tournament_participants 
FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can withdraw from tournaments" 
ON tournament_participants 
FOR DELETE 
USING (auth.uid() = user_id);

-- Ensure RLS is enabled
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL ON tournament_participants TO authenticated;
GRANT SELECT ON tournament_participants TO anon;