-- Create challenges table if not exists and ensure all columns
CREATE TABLE IF NOT EXISTS challenges (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  challenger_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  challenged_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  challenge_type VARCHAR(50) DEFAULT 'giao_luu',
  game_type VARCHAR(20) DEFAULT '8-ball',
  scheduled_time TIMESTAMP WITH TIME ZONE,
  time_slot VARCHAR(50),
  location VARCHAR(255),
  handicap INTEGER DEFAULT 0,
  spa_points INTEGER DEFAULT 0,
  message TEXT,
  status VARCHAR(20) DEFAULT 'pending',
  expires_at TIMESTAMP WITH TIME ZONE,
  accepted_at TIMESTAMP WITH TIME ZONE,
  declined_at TIMESTAMP WITH TIME ZONE,
  decline_reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if they don't exist
ALTER TABLE challenges 
ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball',
ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS time_slot VARCHAR(50),
ADD COLUMN IF NOT EXISTS location VARCHAR(255),
ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS declined_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS decline_reason TEXT,
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;

-- Ensure proper indexes
CREATE INDEX IF NOT EXISTS idx_challenges_challenger_id ON challenges(challenger_id);
CREATE INDEX IF NOT EXISTS idx_challenges_challenged_id ON challenges(challenged_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON challenges(game_type);
CREATE INDEX IF NOT EXISTS idx_challenges_scheduled_time ON challenges(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_challenges_type_status ON challenges(challenge_type, status);
CREATE INDEX IF NOT EXISTS idx_challenges_expires_at ON challenges(expires_at);

-- Enable RLS
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view their challenges" ON challenges;
CREATE POLICY "Users can view their challenges" ON challenges 
FOR SELECT USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);

DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
CREATE POLICY "Users can create challenges" ON challenges 
FOR INSERT WITH CHECK (auth.uid() = challenger_id);

DROP POLICY IF EXISTS "Users can update their challenges" ON challenges;
CREATE POLICY "Users can update their challenges" ON challenges 
FOR UPDATE USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);

-- Comments
COMMENT ON TABLE challenges IS 'Challenge system for player-to-player matches and scheduling';
COMMENT ON COLUMN challenges.challenge_type IS 'giao_luu (friendly), thach_dau (competitive), or schedule_request (schedule appointment)';
COMMENT ON COLUMN challenges.game_type IS 'Type of billiards game: 8-ball, 9-ball, 10-ball';
COMMENT ON COLUMN challenges.scheduled_time IS 'Scheduled date and time for the match/appointment';
COMMENT ON COLUMN challenges.time_slot IS 'Time slot for schedule requests (e.g., 08:00 - 10:00)';
COMMENT ON COLUMN challenges.location IS 'Location/venue for the match';
COMMENT ON COLUMN challenges.handicap IS 'Handicap value for the match';
COMMENT ON COLUMN challenges.spa_points IS 'SPA points wagered in the challenge';
COMMENT ON COLUMN challenges.expires_at IS 'When the challenge expires if not accepted';
COMMENT ON COLUMN challenges.accepted_at IS 'Timestamp when challenge was accepted';
COMMENT ON COLUMN challenges.declined_at IS 'Timestamp when challenge was declined';
COMMENT ON COLUMN challenges.decline_reason IS 'Reason for declining the challenge';