-- ================================
-- ADD SABO FORMATS TO DATABASE CONSTRAINT
-- Execute this in Supabase SQL Editor
-- ================================

BEGIN;

-- Step 1: Drop existing constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Step 2: Add new constraint with SABO formats
ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN (
    -- Original formats
    'single_elimination',
    'double_elimination',
    'round_robin',
    'swiss',
    
    -- SABO specific formats with unique logic
    'sabo_de16',           -- SABO Double Elimination 16 players
    'sabo_de32',           -- SABO Double Elimination 32 players  
    'sabo_se16',           -- SABO Single Elimination 16 players
    'sabo_se32',           -- SABO Single Elimination 32 players
    'sabo_double_elimination' -- SABO Double Elimination (general)
));

-- Step 3: Verify constraint was created
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'check_bracket_format';

-- Step 4: Test the new constraint
INSERT INTO tournaments (
    club_id, 
    organizer_id, 
    title, 
    description,
    start_date, 
    registration_deadline, 
    max_participants,
    entry_fee, 
    prize_pool, 
    bracket_format,  -- This should now accept sabo_de16!
    game_format,
    status, 
    current_participants
) VALUES (
    (SELECT club_id FROM tournaments LIMIT 1),
    (SELECT organizer_id FROM tournaments LIMIT 1),
    'Test SABO DE16 Format',
    'Testing new SABO constraint',
    '2025-10-01 00:00:00+00',
    '2025-09-30 00:00:00+00',
    16,
    0,
    0,  
    'sabo_de16',  -- This should work now!
    '8-ball',
    'upcoming',
    0
);

-- Step 5: Clean up test data
DELETE FROM tournaments WHERE title = 'Test SABO DE16 Format';

COMMIT;

-- ================================
-- VERIFICATION QUERIES
-- ================================

-- Check if constraint allows SABO formats
SELECT 'Constraint updated successfully' as status;

-- List all allowed bracket formats
SELECT unnest(string_to_array(
    substring(pg_get_constraintdef(oid) from '\((.*?)\)'), ','
)) as allowed_formats
FROM pg_constraint 
WHERE conname = 'check_bracket_format';
