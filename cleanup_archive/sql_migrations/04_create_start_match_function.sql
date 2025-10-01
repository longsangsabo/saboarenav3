-- ===================================
-- SCRIPT 4: CREATE START MATCH FUNCTION
-- ===================================
-- Run this to create function for starting matches

-- Create function to start a match
CREATE OR REPLACE FUNCTION start_match(
  p_match_id UUID
) RETURNS JSON AS $$
DECLARE
  result JSON;
  updated_count INTEGER;
BEGIN
  -- Update match status to in_progress
  UPDATE matches 
  SET 
    status = 'in_progress',
    start_time = NOW(),
    updated_at = NOW()
  WHERE id = p_match_id
    AND status = 'pending';
  
  -- Get number of affected rows
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  
  -- Build result
  IF updated_count > 0 THEN
    result := json_build_object(
      'success', true,
      'message', 'Match started successfully',
      'match_id', p_match_id,
      'updated_count', updated_count
    );
  ELSE
    result := json_build_object(
      'success', false,
      'message', 'Match not found or already started',
      'match_id', p_match_id,
      'updated_count', 0
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION start_match(UUID) TO public;
GRANT EXECUTE ON FUNCTION start_match(UUID) TO anon;