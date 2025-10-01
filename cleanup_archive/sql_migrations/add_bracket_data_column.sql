-- Add bracket_data column to tournaments table
-- This column will store the bracket structure as JSON

ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS bracket_data JSONB;

-- Add comment for documentation
COMMENT ON COLUMN tournaments.bracket_data IS 'Stores bracket structure and match pairings as JSON';

-- Add an index for better performance when querying bracket data
CREATE INDEX IF NOT EXISTS idx_tournaments_bracket_data ON tournaments USING GIN (bracket_data);

-- Verify the change
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tournaments' 
  AND column_name = 'bracket_data';