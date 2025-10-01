-- Add RLS policy for updating matches
-- This allows users to update match results

-- First, let's create a policy that allows updating matches for tournament participants
CREATE OR REPLACE POLICY "Allow updating matches for participants" ON matches 
FOR UPDATE 
TO public 
USING (
  EXISTS (
    SELECT 1 FROM tournament_participants tp 
    WHERE tp.tournament_id = matches.tournament_id
  )
);

-- Alternative: Allow updating matches for anyone (less secure but works for now)
-- CREATE OR REPLACE POLICY "Allow updating matches" ON matches 
-- FOR UPDATE 
-- TO public 
-- USING (true);

-- Let's also ensure INSERT policy exists for match results
CREATE OR REPLACE POLICY "Allow inserting matches" ON matches 
FOR INSERT 
TO public 
WITH CHECK (true);