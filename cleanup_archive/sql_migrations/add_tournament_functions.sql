-- Add RPC functions for tournament participant management
CREATE OR REPLACE FUNCTION increment_tournament_participants(tournament_id UUID)
RETURNS void 
LANGUAGE sql
AS $$
  UPDATE tournaments 
  SET current_participants = current_participants + 1,
      updated_at = NOW()
  WHERE id = tournament_id;
$$;

CREATE OR REPLACE FUNCTION decrement_tournament_participants(tournament_id UUID)
RETURNS void
LANGUAGE sql  
AS $$
  UPDATE tournaments 
  SET current_participants = GREATEST(current_participants - 1, 0),
      updated_at = NOW()
  WHERE id = tournament_id;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION increment_tournament_participants(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION decrement_tournament_participants(UUID) TO authenticated;