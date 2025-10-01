-- Migration to add new fields to challenges table for enhanced challenge and schedule functionality
-- Date: $(date)

-- Add new columns to challenges table
ALTER TABLE challenges 
ADD COLUMN IF NOT EXISTS game_type VARCHAR(20) DEFAULT '8-ball',
ADD COLUMN IF NOT EXISTS scheduled_time TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS time_slot VARCHAR(50),
ADD COLUMN IF NOT EXISTS location VARCHAR(255),
ADD COLUMN IF NOT EXISTS handicap INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS spa_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS declined_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS decline_reason TEXT;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_challenges_game_type ON challenges(game_type);
CREATE INDEX IF NOT EXISTS idx_challenges_scheduled_time ON challenges(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_challenges_type_status ON challenges(challenge_type, status);

-- Update challenge_type to support schedule_request
COMMENT ON COLUMN challenges.challenge_type IS 'giao_luu (friendly), thach_dau (competitive), or schedule_request (schedule appointment)';
COMMENT ON COLUMN challenges.game_type IS 'Type of billiards game: 8-ball, 9-ball, 10-ball';
COMMENT ON COLUMN challenges.scheduled_time IS 'Scheduled date and time for the match/appointment';
COMMENT ON COLUMN challenges.time_slot IS 'Time slot for schedule requests (e.g., 08:00 - 10:00)';
COMMENT ON COLUMN challenges.location IS 'Location/venue for the match';
COMMENT ON COLUMN challenges.handicap IS 'Handicap value for the match';
COMMENT ON COLUMN challenges.spa_points IS 'SPA points wagered in the challenge';
COMMENT ON COLUMN challenges.accepted_at IS 'Timestamp when challenge was accepted';
COMMENT ON COLUMN challenges.declined_at IS 'Timestamp when challenge was declined';
COMMENT ON COLUMN challenges.decline_reason IS 'Reason for declining the challenge';

-- Ensure RLS policies are in place for challenges
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

-- Policy for users to view challenges they are involved in
DROP POLICY IF EXISTS "Users can view their challenges" ON challenges;
CREATE POLICY "Users can view their challenges" ON challenges 
FOR SELECT USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);

-- Policy for users to insert challenges
DROP POLICY IF EXISTS "Users can create challenges" ON challenges;
CREATE POLICY "Users can create challenges" ON challenges 
FOR INSERT WITH CHECK (auth.uid() = challenger_id);

-- Policy for users to update challenges they are involved in
DROP POLICY IF EXISTS "Users can update their challenges" ON challenges;
CREATE POLICY "Users can update their challenges" ON challenges 
FOR UPDATE USING (
  auth.uid() = challenger_id OR 
  auth.uid() = challenged_id
);

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON challenges TO authenticated;

COMMENT ON TABLE challenges IS 'Enhanced challenges table supporting competitive challenges, friendly matches, and schedule requests';

-- Sample data for testing (optional)
-- INSERT INTO challenges (challenger_id, challenged_id, challenge_type, game_type, scheduled_time, location, spa_points, message)
-- SELECT 
--   u1.id, 
--   u2.id, 
--   'thach_dau', 
--   '8-ball', 
--   NOW() + INTERVAL '1 day', 
--   'Billiards Club Sài Gòn',
--   500,
--   'Thách đấu 8-ball, stakes 500 SPA points!'
-- FROM users u1, users u2 
-- WHERE u1.id != u2.id 
-- LIMIT 1;

-- Refresh updated_at trigger for challenges
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_challenges_updated_at ON challenges;
CREATE TRIGGER update_challenges_updated_at
    BEFORE UPDATE ON challenges
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Test query to verify the migration
-- SELECT column_name, data_type, is_nullable, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'challenges' 
-- ORDER BY ordinal_position;