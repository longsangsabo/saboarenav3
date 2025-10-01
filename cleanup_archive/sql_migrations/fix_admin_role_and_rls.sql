-- Add role field to users table and fix RLS policies
-- This migration adds admin role support and fixes tournament participants RLS

-- Step 1: Add role field to users table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE public.users 
        ADD COLUMN role VARCHAR(20) DEFAULT 'user';
    END IF;
END
$$;

-- Step 2: Update admin users (assuming specific admin email or username)
-- You can update this based on your admin criteria
UPDATE public.users 
SET role = 'admin' 
WHERE email IN (
    'admin@saboarena.com',
    'longsang063@gmail.com', 
    'admin@gmail.com'
) OR username IN (
    'admin',
    'longsang063',
    'sabo_admin'
);

-- Step 3: Drop existing restrictive policies for tournament_participants
DROP POLICY IF EXISTS "Users can register for tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Tournament organizers can manage participants" ON tournament_participants;
DROP POLICY IF EXISTS "Admin users can manage all tournament participants" ON tournament_participants;

-- Step 4: Create new policies that allow admin operations

-- 4.1: Users can register themselves for tournaments
CREATE POLICY "Users can register for tournaments" 
ON tournament_participants 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 4.2: Tournament organizers can manage all participants in their tournaments
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

-- 4.3: Admin users can manage participants in any tournament
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

-- Step 5: Keep existing policies for reading and user self-management
-- Tournament participants are publicly readable (already exists)
-- Users can update own participation (already exists)  
-- Users can withdraw from tournaments (already exists)

-- Step 6: Ensure RLS is enabled and grant permissions
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
GRANT ALL ON tournament_participants TO authenticated;
GRANT SELECT ON tournament_participants TO anon;

-- Step 7: Add index for better performance on role queries
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Step 8: Display current admin users
SELECT id, email, username, display_name, role 
FROM users 
WHERE role = 'admin';