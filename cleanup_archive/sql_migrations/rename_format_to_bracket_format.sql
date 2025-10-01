-- SABO DE16 Database Migration
-- Purpose: Rename format column to bracket_format to fix CompleteSaboDE16Service
-- Date: October 1, 2025
-- Execute in Supabase Dashboard → SQL Editor

-- Step 1: Rename the column
ALTER TABLE matches RENAME COLUMN format TO bracket_format;

-- Step 2: Verify the change (optional - comment shows expected result)
-- This query should return 'bracket_format' if rename was successful
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'matches' 
  AND column_name = 'bracket_format';

-- Step 3: Check that old column is gone (optional)
-- This query should return no rows if rename was successful  
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'matches' 
  AND column_name = 'format';

-- Migration complete!
-- Now CompleteSaboDE16Service can insert matches with bracket_format column