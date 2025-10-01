-- =============================================================================
-- RANK REQUESTS EVIDENCE URLS MIGRATION
-- Adds evidence_urls column to store tournament result images
-- =============================================================================

-- Check current table structure
SELECT 'CURRENT TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'rank_requests' 
ORDER BY ordinal_position;

-- Add evidence_urls column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'rank_requests' 
        AND column_name = 'evidence_urls'
    ) THEN
        ALTER TABLE rank_requests 
        ADD COLUMN evidence_urls TEXT[] DEFAULT NULL;
        
        RAISE NOTICE 'evidence_urls column added successfully';
    ELSE
        RAISE NOTICE 'evidence_urls column already exists';
    END IF;
END $$;

-- Add comment to document the column
COMMENT ON COLUMN rank_requests.evidence_urls IS 
'Array of image URLs showing tournament results from the last 3 months as evidence for rank registration';

-- Create index for faster queries (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_rank_requests_evidence 
ON rank_requests USING GIN (evidence_urls);

-- Verify the final structure
SELECT 'FINAL TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'rank_requests' 
ORDER BY ordinal_position;

-- Show sample data to understand current format
SELECT 'SAMPLE DATA' as info;
SELECT id, user_id, club_id, status, notes, evidence_urls
FROM rank_requests 
ORDER BY requested_at DESC 
LIMIT 3;