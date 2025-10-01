-- Migration: Rename format column to bracket_format in matches table
-- Date: October 1, 2025
-- Purpose: Fix column naming for SABO DE16 bracket generation

-- Rename the column from format to bracket_format
ALTER TABLE matches RENAME COLUMN format TO bracket_format;

-- Verify the change (optional - comment shows expected result)
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_name = 'matches' AND column_name = 'bracket_format';