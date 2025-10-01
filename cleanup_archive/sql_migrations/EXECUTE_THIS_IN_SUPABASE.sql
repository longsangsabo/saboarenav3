-- Fix bracket_format constraint to support SABO formats
-- Copy and paste this SQL into Supabase SQL Editor

BEGIN;

-- Drop existing constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Add new constraint supporting SABO formats
ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN (
    'single_elimination',
    'double_elimination',
    'round_robin',
    'swiss',
    'sabo_de16',
    'sabo_de32', 
    'sabo_se16',
    'sabo_se32',
    'sabo_double_elimination'
));

-- Verify the constraint was created
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'check_bracket_format';

COMMIT;

-- Test the constraint by trying to insert a test tournament
-- (This should work now)
/*
INSERT INTO tournaments (
    club_id, organizer_id, title, description, 
    start_date, registration_deadline, max_participants,
    entry_fee, prize_pool, bracket_format, game_format,
    status, current_participants, created_at, updated_at
) VALUES (
    (SELECT club_id FROM tournaments LIMIT 1),
    (SELECT organizer_id FROM tournaments LIMIT 1),
    'Test SABO DE16',
    'Testing new constraint',
    '2025-10-01 00:00:00+00',
    '2025-09-30 00:00:00+00',
    16,
    0,
    0,
    'sabo_de16',  -- This should work now!
    '8-ball',
    'upcoming',
    0,
    NOW(),
    NOW()
);

-- Clean up test data
DELETE FROM tournaments WHERE title = 'Test SABO DE16';
*/
