-- ===================================
-- SCRIPT 3: TEST MATCH UPDATE FUNCTION
-- ===================================
-- Run this to test the match update function

-- Get a test match from tournament
SELECT 
  id as match_id,
  player1_id,
  player2_id,
  status,
  player1_score,
  player2_score,
  winner_id
FROM matches 
WHERE tournament_id = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6'
  AND status = 'in_progress'
LIMIT 1;

-- Test update (replace the UUIDs with actual values from above query)
-- SELECT update_match_result(
--   'YOUR_MATCH_ID_HERE'::UUID,
--   'YOUR_WINNER_ID_HERE'::UUID,
--   5,
--   3
-- );

-- Verify the update
-- SELECT 
--   id,
--   status,
--   player1_score,
--   player2_score,
--   winner_id,
--   updated_at
-- FROM matches 
-- WHERE id = 'YOUR_MATCH_ID_HERE'::UUID;

-- Revert the test (optional)
-- UPDATE matches 
-- SET 
--   winner_id = NULL,
--   player1_score = 0,
--   player2_score = 0,
--   status = 'in_progress',
--   end_time = NULL
-- WHERE id = 'YOUR_MATCH_ID_HERE'::UUID;