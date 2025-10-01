-- Add evidence_urls column to rank_requests table
-- This allows users to submit tournament result images as evidence

DO $$
BEGIN
    -- Check if evidence_urls column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'rank_requests' 
        AND column_name = 'evidence_urls'
    ) THEN
        ALTER TABLE rank_requests 
        ADD COLUMN evidence_urls TEXT[] DEFAULT NULL;
        
        RAISE NOTICE 'Added evidence_urls column to rank_requests table';
    ELSE
        RAISE NOTICE 'evidence_urls column already exists';
    END IF;
END $$;

-- Add comment to document the column
COMMENT ON COLUMN rank_requests.evidence_urls IS 'Array of image URLs showing tournament results from the last 3 months as evidence for rank registration';

-- Create index for faster queries (optional)
CREATE INDEX IF NOT EXISTS idx_rank_requests_evidence 
ON rank_requests USING GIN (evidence_urls);

-- Show the table structure to verify
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'rank_requests'
ORDER BY ordinal_position;