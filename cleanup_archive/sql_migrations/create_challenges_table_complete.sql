-- Create challenges table with complete schema for SimpleChallengeService
-- Run this in Supabase SQL Editor

-- Drop existing table if you want to recreate with new schema
-- DROP TABLE IF EXISTS challenges CASCADE;

-- Create challenges table
CREATE TABLE IF NOT EXISTS challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenger_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenged_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_type VARCHAR(50) NOT NULL DEFAULT 'giao_luu', -- 'giao_luu' or 'thach_dau'
  game_type VARCHAR(20) DEFAULT '8-ball', -- '8-ball', '9-ball', '10-ball'
  scheduled_time TIMESTAMP WITH TIME ZONE,
  location VARCHAR(255),
  handicap INTEGER DEFAULT 0,
  spa_points INTEGER DEFAULT 0,
  message TEXT,
  status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
  accepted_at TIMESTAMP WITH TIME ZONE,
  declined_at TIMESTAMP WITH TIME ZONE,
  decline_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON challenges(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON challenges(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_challenge_type ON challenges(challenge_type);
CREATE INDEX IF NOT EXISTS idx_challenges_created_at ON challenges(created_at);
CREATE INDEX IF NOT EXISTS idx_challenges_expires_at ON challenges(expires_at);

-- Enable Row Level Security
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their challenges" ON challenges;
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
DROP POLICY IF EXISTS "Users can update their challenges" ON challenges;

-- RLS Policies for authenticated users
CREATE POLICY "Users can view their challenges" ON challenges 
FOR SELECT USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);

CREATE POLICY "Users can create challenges" ON challenges 
FOR INSERT WITH CHECK (auth.uid() = challenger_id);

CREATE POLICY "Users can update their challenges" ON challenges 
FOR UPDATE USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);

-- Allow service role full access (for development)
CREATE POLICY "Service role full access" ON challenges 
FOR ALL USING (
  current_setting('role') = 'service_role'
);

-- Comments for documentation
COMMENT ON TABLE challenges IS 'Player-to-player challenge system';
COMMENT ON COLUMN challenges.challenge_type IS 'Type: giao_luu (friendly) or thach_dau (competitive)';
COMMENT ON COLUMN challenges.game_type IS 'Billiards game type: 8-ball, 9-ball, 10-ball';
COMMENT ON COLUMN challenges.spa_points IS 'SPA points wagered (0 for friendly challenges)';
COMMENT ON COLUMN challenges.handicap IS 'Handicap value applied to match';
COMMENT ON COLUMN challenges.expires_at IS 'When challenge expires if not accepted';

-- Insert test challenge for verification (optional)
DO $$
DECLARE
    test_user_1 UUID := '00000000-0000-0000-0000-000000000001';
    test_user_2 UUID := '00000000-0000-0000-0000-000000000002';
BEGIN
    -- Only insert if test users exist and no test challenge exists
    IF EXISTS (SELECT 1 FROM auth.users WHERE id = test_user_1) AND
       EXISTS (SELECT 1 FROM auth.users WHERE id = test_user_2) AND
       NOT EXISTS (SELECT 1 FROM challenges WHERE challenger_id = test_user_1 AND challenged_id = test_user_2) THEN
        
        INSERT INTO challenges (
            challenger_id,
            challenged_id,
            challenge_type,
            game_type,
            scheduled_time,
            location,
            spa_points,
            message
        ) VALUES (
            test_user_1,
            test_user_2,
            'thach_dau',
            '8-ball',
            NOW() + INTERVAL '2 hours',
            'Billiards Club Sài Gòn',
            200,
            'Test challenge from database setup'
        );
        
        RAISE NOTICE 'Test challenge created successfully';
    END IF;
END $$;

-- Verify table creation
SELECT 
    'challenges' AS table_name,
    COUNT(*) AS row_count,
    MAX(created_at) AS latest_record
FROM challenges;

RAISE NOTICE 'Challenges table setup complete! ✅';