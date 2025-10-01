-- Auto-update winner_id when match scores are updated
-- This trigger ensures winner_id is automatically set based on scores

CREATE OR REPLACE FUNCTION auto_update_match_winner()
RETURNS TRIGGER AS $$
BEGIN
  -- Only update if match is completed and scores are provided
  IF NEW.status = 'completed' AND (NEW.player1_score IS NOT NULL AND NEW.player2_score IS NOT NULL) THEN
    -- Determine winner based on scores
    IF NEW.player1_score > NEW.player2_score THEN
      NEW.winner_id = NEW.player1_id;
    ELSIF NEW.player2_score > NEW.player1_score THEN
      NEW.winner_id = NEW.player2_id;
    ELSE
      -- Tie - no winner
      NEW.winner_id = NULL;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on matches table
DROP TRIGGER IF EXISTS trigger_auto_update_match_winner ON matches;
CREATE TRIGGER trigger_auto_update_match_winner
  BEFORE UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION auto_update_match_winner();