-- =====================================================
-- SIMPLE MATCHES CREATION FOR TESTING
-- Execute this MANUALLY in Supabase Dashboard > SQL Editor
-- =====================================================

-- Create matches manually for tournament fb65c535-5de3-4451-9831-4deee7ccd3cc (15 participants)
INSERT INTO matches (
    id,
    tournament_id,
    player1_id,
    player2_id,
    round_number,
    match_number,
    status,
    created_at,
    updated_at
) VALUES 
-- Round 1 matches (8 matches for 15 participants)
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', '60259d5f-c25b-4b46-8fd3-fbf4d3a766f7', '18e75c21-0c4c-4742-88f9-6dff6e71fe28', 1, 1, 'pending', now(), now()),
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', 'cf74dd69-41e5-4f04-a8a3-b206f8a1f8ad', '7caf29dc-d63b-4e6f-aeb4-d8f6a3b4b9fb', 1, 2, 'pending', now(), now()),
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', '8cb41f50-d328-4f25-8189-852fec3bb25e', '06383c68-2d2c-42de-bc9d-cd8489410d28', 1, 3, 'pending', now(), now()),
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', '035930e1-31de-421e-b5d6-1377703c99b1', 'b662ca1e-b12d-4d88-a2c4-25e0238568d5', 1, 4, 'pending', now(), now()),
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', 'ecfae4ae-ddc5-42cb-86cb-effd9db5bbe7', 'd5b07080-3a24-48ab-967e-67ae2fdca9bc', 1, 5, 'pending', now(), now()),
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', 'f4771650-8840-4f5c-8c29-8d8b8836d571', 'dc504afc-a62f-4dc6-bfca-c026391f2316', 1, 6, 'pending', now(), now()),
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', 'a7cb0488-ea98-44f0-aad0-9160ef6e70c5', '734f24dd-db05-4b56-bc68-7221cca4c4c5', 1, 7, 'pending', now(), now()),
-- BYE match - player advances automatically
(gen_random_uuid(), 'fb65c535-5de3-4451-9831-4deee7ccd3cc', '01a9d4bd-ce9c-4e00-bfa8-f1a947b411d9', NULL, 1, 8, 'completed', now(), now());

-- Update the BYE match to mark winner
UPDATE matches 
SET winner_id = '01a9d4bd-ce9c-4e00-bfa8-f1a947b411d9', 
    player1_score = 2, 
    player2_score = 0
WHERE tournament_id = 'fb65c535-5de3-4451-9831-4deee7ccd3cc' 
    AND player2_id IS NULL;

-- Update tournament status
UPDATE tournaments 
SET status = 'in_progress', 
    updated_at = now()
WHERE id = 'fb65c535-5de3-4451-9831-4deee7ccd3cc';

-- Verify matches created
SELECT 
    m.id,
    m.round_number,
    m.match_number,
    p1.full_name as player1,
    p2.full_name as player2,
    m.status,
    'Match created successfully' as result
FROM matches m
LEFT JOIN users p1 ON p1.id = m.player1_id
LEFT JOIN users p2 ON p2.id = m.player2_id
WHERE m.tournament_id = 'fb65c535-5de3-4451-9831-4deee7ccd3cc'
ORDER BY m.round_number, m.match_number;