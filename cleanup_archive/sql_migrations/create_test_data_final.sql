-- FINAL SAFE TEST DATA CREATION 
-- This version handles all known constraints and enum types
-- Run this AFTER: migrate_drop_user_profiles.sql AND backend_setup_complete.sql

SELECT 'Starting safe test data creation...' as step;

-- 1. Update existing users with location data (only users without location)
UPDATE users SET 
  latitude = 21.028511 + (RANDOM() - 0.5) * 0.2,
  longitude = 105.804817 + (RANDOM() - 0.5) * 0.2,
  location_name = CASE 
    WHEN RANDOM() < 0.3 THEN 'Quận Ba Đình, Hà Nội'
    WHEN RANDOM() < 0.6 THEN 'Quận Hoàn Kiếm, Hà Nội'
    WHEN RANDOM() < 0.8 THEN 'Quận Cầu Giấy, Hà Nội'
    ELSE 'Quận Đống Đa, Hà Nội'
  END,
  is_available_for_challenges = CASE WHEN RANDOM() < 0.8 THEN true ELSE false END,
  preferred_match_type = CASE 
    WHEN RANDOM() < 0.25 THEN 'giao_luu'
    WHEN RANDOM() < 0.5 THEN 'thach_dau' 
    ELSE 'both' 
  END,
  spa_points = COALESCE(spa_points, 1000) + FLOOR(RANDOM() * 1000)::INTEGER,
  challenge_win_streak = COALESCE(challenge_win_streak, 0) + FLOOR(RANDOM() * 5)::INTEGER,
  max_challenge_distance = CASE 
    WHEN RANDOM() < 0.5 THEN 5
    WHEN RANDOM() < 0.8 THEN 10
    ELSE 20
  END
WHERE latitude IS NULL;

SELECT 'Updated existing users with Hanoi location data' as step;

-- 2. Add location diversity - Simple approach without complex updates
-- Create a few users in different cities by updating specific users
DO $$
DECLARE
    user_ids UUID[];
    i INTEGER;
BEGIN
    -- Get some user IDs to update
    SELECT ARRAY(SELECT id FROM users WHERE latitude IS NOT NULL ORDER BY created_at LIMIT 6) INTO user_ids;
    
    -- Update first 2 users to HCM
    IF array_length(user_ids, 1) >= 2 THEN
        UPDATE users SET 
            latitude = 10.762622 + (RANDOM() - 0.5) * 0.05,
            longitude = 106.660172 + (RANDOM() - 0.5) * 0.05,
            location_name = 'TP. Hồ Chí Minh'
        WHERE id = ANY(user_ids[1:2]);
        RAISE NOTICE 'Updated 2 users to HCM location';
    END IF;
    
    -- Update next 2 users to Da Nang
    IF array_length(user_ids, 1) >= 4 THEN
        UPDATE users SET 
            latitude = 16.047079 + (RANDOM() - 0.5) * 0.05,
            longitude = 108.206230 + (RANDOM() - 0.5) * 0.05,
            location_name = 'Đà Nẵng'
        WHERE id = ANY(user_ids[3:4]);
        RAISE NOTICE 'Updated 2 users to Da Nang location';
    END IF;
END $$;

SELECT 'Added location diversity to users' as step;

-- 3. Create test challenges - only if we have enough users
INSERT INTO challenges (challenger_id, challenged_id, challenge_type, message, stakes_type, stakes_amount, status, created_at)
SELECT 
  u1.id as challenger_id,
  u2.id as challenged_id,
  CASE 
    WHEN RANDOM() < 0.4 THEN 'giao_luu'
    ELSE 'thach_dau'
  END as challenge_type,
  CASE 
    WHEN RANDOM() < 0.3 THEN 'Chơi cùng nhau nhé!'
    WHEN RANDOM() < 0.6 THEN 'Thách đấu cùng tôi!'
    ELSE 'Hẹn gặp tại club gần nhất!'
  END as message,
  CASE 
    WHEN RANDOM() < 0.7 THEN 'none'
    ELSE 'spa_points'
  END as stakes_type,
  CASE 
    WHEN RANDOM() < 0.7 THEN 0
    ELSE 100
  END as stakes_amount,
  CASE 
    WHEN RANDOM() < 0.4 THEN 'pending'
    WHEN RANDOM() < 0.7 THEN 'accepted'
    ELSE 'declined'
  END as status,
  NOW() - (RANDOM() * INTERVAL '5 days') as created_at
FROM (
  SELECT id FROM users 
  WHERE latitude IS NOT NULL
  AND is_active = true
  ORDER BY RANDOM() 
  LIMIT 6
) u1
CROSS JOIN (
  SELECT id FROM users 
  WHERE latitude IS NOT NULL
  AND is_active = true
  ORDER BY RANDOM() 
  LIMIT 6
) u2
WHERE u1.id != u2.id 
AND RANDOM() < 0.25  -- Create fewer challenges to avoid issues
LIMIT 10;

SELECT 'Created test challenges' as step;

-- 4. Create matches from accepted challenges - independent matches (not tournament)
INSERT INTO matches (
  tournament_id, player1_id, player2_id, challenger_id,
  round_number, match_number,
  match_type, invitation_type, stakes_type, spa_stakes_amount,
  challenge_message, match_conditions, status, scheduled_time,
  created_at
)
SELECT 
  NULL,  -- No tournament for challenge matches
  c.challenger_id,
  c.challenged_id,
  c.challenger_id,
  1,  -- Default round number (required by constraint)
  1,  -- Default match number (required by constraint)
  CASE 
    WHEN c.challenge_type = 'thach_dau' THEN 'competitive'
    ELSE 'friendly'
  END,
  'challenge_accepted',
  c.stakes_type,
  c.stakes_amount,
  c.message,
  CASE 
    WHEN c.challenge_type = 'thach_dau' THEN '{"format": "8ball", "race_to": 7, "competitive": true}'
    ELSE '{"format": "8ball", "race_to": 5, "casual": true}'
  END::JSONB,
  'completed'::match_status,  -- Use safe status
  NOW() + (RANDOM() * INTERVAL '1 day'),
  NOW() - (RANDOM() * INTERVAL '1 day')
FROM challenges c
WHERE c.status = 'accepted'
LIMIT 5;  -- Limit to avoid issues

SELECT 'Created matches from challenges' as step;

-- 5. Add SPA transactions - simple version
INSERT INTO spa_transactions (user_id, transaction_type, amount, balance_before, balance_after, description)
SELECT 
  u.id,
  'daily_bonus',
  50,
  COALESCE(u.spa_points, 1000),
  COALESCE(u.spa_points, 1000) + 50,
  'Phần thưởng đăng nhập hàng ngày'
FROM users u
WHERE u.spa_points IS NOT NULL
AND RANDOM() < 0.5
LIMIT 10;

SELECT 'Created SPA transactions' as step;

-- 6. Update some users to appear online
UPDATE users 
SET last_seen = NOW() - (RANDOM() * INTERVAL '5 minutes')
WHERE latitude IS NOT NULL
AND RANDOM() < 0.4;

SELECT 'Updated user online status' as step;

-- 7. Final verification with safe queries
SELECT 'TEST DATA CREATION COMPLETED SUCCESSFULLY!' as status;

SELECT 
  'Users with location data' as info,
  COUNT(*) as count
FROM users 
WHERE latitude IS NOT NULL;

SELECT 
  'Location distribution' as info,
  location_name,
  COUNT(*) as count
FROM users 
WHERE latitude IS NOT NULL
GROUP BY location_name
ORDER BY count DESC;

SELECT 
  'Challenges created' as info,
  challenge_type,
  status,
  COUNT(*) as count
FROM challenges
GROUP BY challenge_type, status
ORDER BY challenge_type, status;

SELECT 
  'Users available for challenges' as info,
  COUNT(*) as count
FROM users 
WHERE is_available_for_challenges = true
AND latitude IS NOT NULL;

SELECT 
  'Recently online users' as info,
  COUNT(*) as count
FROM users 
WHERE last_seen > NOW() - INTERVAL '10 minutes'
AND latitude IS NOT NULL;

SELECT 'All test data created successfully! Backend is ready for opponent tab.' as final_status;