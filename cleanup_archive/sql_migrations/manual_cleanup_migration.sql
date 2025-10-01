-- ================================================================
-- COMPLETE FORMAT COLUMNS CLEANUP MIGRATION
-- ================================================================
-- Remove old columns: format, tournament_type  
-- Keep only new columns: game_format, bracket_format
-- 
-- EXECUTE THIS SQL DIRECTLY IN SUPABASE SQL EDITOR
-- ================================================================

-- Phase 1: Check if old columns still exist
SELECT 
    'SCHEMA CHECK - Column Status' as phase,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tournaments' 
AND column_name IN ('format', 'tournament_type', 'game_format', 'bracket_format')
ORDER BY column_name;

-- Phase 2: Drop old columns (IF THEY STILL EXIST)
ALTER TABLE tournaments DROP COLUMN IF EXISTS format CASCADE;
ALTER TABLE tournaments DROP COLUMN IF EXISTS tournament_type CASCADE;

-- Phase 3: Verify clean schema
SELECT 
    'AFTER MIGRATION - Schema Verification' as phase,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'tournaments' 
AND column_name LIKE '%format%'
ORDER BY column_name;

-- Phase 4: Verify current tournament data
SELECT 
    'CURRENT TOURNAMENT DATA' as phase,
    title,
    game_format,
    bracket_format,
    status
FROM tournaments 
WHERE title IN ('sabo1', 'single2', 'knockout1')
ORDER BY title;

-- Phase 5: Show all tournaments with clean schema
SELECT 
    'ALL TOURNAMENTS - Clean Schema' as phase,
    title,
    game_format,
    bracket_format,
    status,
    created_at
FROM tournaments 
ORDER BY created_at DESC;