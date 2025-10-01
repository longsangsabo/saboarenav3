-- Create a function to update match results bypassing RLS
CREATE OR REPLACE FUNCTION update_match_result(
  p_match_id UUID,
  p_winner_id UUID,
  p_player1_score INTEGER,
  p_player2_score INTEGER
) RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  -- Update the match
  UPDATE matches 
  SET 
    winner_id = p_winner_id,
    player1_score = p_player1_score,
    player2_score = p_player2_score,
    status = 'completed',
    end_time = NOW()
  WHERE id = p_match_id;
  
  -- Check if update was successful
  IF FOUND THEN
    result := json_build_object(
      'success', true,
      'message', 'Match updated successfully',
      'match_id', p_match_id
    );
  ELSE
    result := json_build_object(
      'success', false,
      'message', 'Match not found',
      'match_id', p_match_id
    );
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;