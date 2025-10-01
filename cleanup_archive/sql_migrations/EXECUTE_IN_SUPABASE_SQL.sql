-- ===================================================
-- EXECUTE THIS SQL IN SUPABASE DASHBOARD 
-- Link: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql
-- ===================================================

BEGIN;

-- Step 1: Drop the old constraint that blocks SABO formats
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Step 2: Add new constraint that supports SABO formats with unique logic
ALTER TABLE tournaments ADD CONSTRAINT check_bracket_format 
CHECK (bracket_format IN (
    -- Original standard formats
    'single_elimination',     -- Standard single elimination
    'double_elimination',     -- Standard double elimination  
    'round_robin',           -- Round robin format
    'swiss',                 -- Swiss system format
    
    -- SABO specific formats with unique logic
    'sabo_de16',             -- SABO Double Elimination 16 players (unique logic)
    'sabo_de32',             -- SABO Double Elimination 32 players (unique logic)
    'sabo_se16',             -- SABO Single Elimination 16 players (unique logic)
    'sabo_se32',             -- SABO Single Elimination 32 players (unique logic)
    'sabo_double_elimination' -- SABO Double Elimination general (unique logic)
));

-- Step 3: Verify the constraint was created correctly
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conname = 'check_bracket_format';

-- Step 4: Test that sabo_de16 format is now allowed
DO $$
DECLARE
    test_club_id UUID;
    test_organizer_id UUID;
    test_tournament_id UUID;
BEGIN
    -- Get existing IDs for test
    SELECT club_id, organizer_id INTO test_club_id, test_organizer_id 
    FROM tournaments LIMIT 1;
    
    -- Try to insert a tournament with sabo_de16 format
    INSERT INTO tournaments (
        club_id, organizer_id, title, description,
        start_date, registration_deadline, max_participants,
        entry_fee, prize_pool, bracket_format, game_format,
        status, current_participants
    ) VALUES (
        test_club_id,
        test_organizer_id,
        'Test SABO DE16 Format',
        'Testing constraint allows sabo_de16',
        '2025-10-01 00:00:00+00',
        '2025-09-30 00:00:00+00',
        16,
        0,
        0,
        'sabo_de16',  -- This should work now!
        '8-ball',
        'upcoming',
        0
    ) RETURNING id INTO test_tournament_id;
    
    -- Clean up test tournament
    DELETE FROM tournaments WHERE id = test_tournament_id;
    
    RAISE NOTICE 'SUCCESS: sabo_de16 format is now allowed in database!';
END $$;

COMMIT;

-- Final verification
SELECT 'Database constraint updated successfully! SABO formats are now supported.' as result;