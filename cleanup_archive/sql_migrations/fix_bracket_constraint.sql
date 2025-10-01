-- Fix bracket_format constraint to support SABO formats
-- Run this SQL in Supabase SQL Editor

-- Drop old constraint
ALTER TABLE tournaments DROP CONSTRAINT IF EXISTS check_bracket_format;

-- Add new constraint with SABO formats
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

-- Verify constraint
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conname = 'check_bracket_format';
