-- ===================================
-- SCRIPT 2: CREATE MATCH UPDATE FUNCTION
-- ===================================
-- Run this after Script 1 to create RPC function for updating matches

-- Drop existing function first
DROP FUNCTION IF EXISTS update_match_result(uuid,uuid,integer,integer);

-- Create function to update match results
CREATE OR REPLACE FUNCTION update_match_result(
  p_match_id UUID,
  p_winner_id UUID,
  p_player1_score INTEGER,
  p_player2_score INTEGER
) RETURNS JSON AS $$
DECLARE
  result JSON;
  updated_count INTEGER;
BEGIN
  -- Update the match
  UPDATE matches 
  SET 
    winner_id = p_winner_id,
    player1_score = p_player1_score,
    player2_score = p_player2_score,
    status = 'completed',
    end_time = NOW(),
    updated_at = NOW()
  WHERE id = p_match_id;
  
  -- Get number of affected rows
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  
  -- Build result
  IF updated_count > 0 THEN
    result := json_build_object(
      'success', true,
      'message', 'Match updated successfully',
      'match_id', p_match_id,
      'updated_count', updated_count
    );
  ELSE
    result := json_build_object(
      'success', false,
      'message', 'Match not found or no changes made',
      'match_id', p_match_id,
      'updated_count', 0
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to public (anon users)
GRANT EXECUTE ON FUNCTION update_match_result(UUID, UUID, INTEGER, INTEGER) TO public;
GRANT EXECUTE ON FUNCTION update_match_result(UUID, UUID, INTEGER, INTEGER) TO anon;

-- Test the function (optional)
-- SELECT update_match_result(
--   'your-match-id-here'::UUID,
--   'your-winner-id-here'::UUID,
--   5,
--   3
-- );