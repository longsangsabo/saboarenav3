-- ===================================
-- SCRIPT 5: VERIFY TOURNAMENT DATA
-- ===================================
-- Run this to check current tournament and match data

-- Check tournament
SELECT 
  id,
  title,
  status,
  format,
  start_date,
  max_participants,
  current_participants
FROM tournaments 
WHERE id = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';

-- First check tournament_participants table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'tournament_participants' 
ORDER BY ordinal_position;

-- Check tournament participants (simplified)
SELECT 
  tp.user_id,
  u.full_name,
  tp.payment_status
FROM tournament_participants tp
JOIN users u ON u.id = tp.user_id
WHERE tp.tournament_id = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6';

-- Check matches with player info
SELECT 
  m.id as match_id,
  m.round_number,
  m.match_number,
  m.status,
  m.player1_score,
  m.player2_score,
  p1.full_name as player1_name,
  p2.full_name as player2_name,
  CASE 
    WHEN m.winner_id = m.player1_id THEN p1.full_name
    WHEN m.winner_id = m.player2_id THEN p2.full_name
    ELSE 'No winner yet'
  END as winner_name
FROM matches m
LEFT JOIN users p1 ON p1.id = m.player1_id
LEFT JOIN users p2 ON p2.id = m.player2_id
WHERE m.tournament_id = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6'
ORDER BY m.round_number, m.match_number;

-- Count matches by status
SELECT 
  status,
  COUNT(*) as count
FROM matches 
WHERE tournament_id = '20e4493c-c163-43c3-9d4d-58a5d7f59ec6'
GROUP BY status;