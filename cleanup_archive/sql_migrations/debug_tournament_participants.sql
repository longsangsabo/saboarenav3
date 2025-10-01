-- Debug script để kiểm tra tournament participants trong database
-- Copy và chạy trong Supabase SQL Editor

-- 1. Kiểm tra tổng số participants trong tournament 
SELECT 
    t.title as tournament_name,
    tp.tournament_id,
    COUNT(*) as total_participants,
    COUNT(CASE WHEN tp.payment_status = 'confirmed' THEN 1 END) as confirmed_participants,
    COUNT(CASE WHEN tp.payment_status = 'pending' THEN 1 END) as pending_participants
FROM tournament_participants tp
JOIN tournaments t ON t.id = tp.tournament_id
GROUP BY tp.tournament_id, t.title
ORDER BY tp.tournament_id;

-- 2. Xem chi tiết từng participant
SELECT 
    tp.id,
    tp.tournament_id,
    tp.user_id,
    u.full_name,
    u.email,
    tp.payment_status,
    tp.status,
    tp.registered_at
FROM tournament_participants tp
JOIN users u ON u.id = tp.user_id
WHERE tp.tournament_id = 'YOUR_TOURNAMENT_ID_HERE'  -- Thay thế bằng ID của tournament
ORDER BY tp.registered_at;

-- 3. Kiểm tra tournament info
SELECT 
    id,
    title,
    max_participants,
    current_participants,
    status,
    created_at
FROM tournaments 
WHERE id = 'YOUR_TOURNAMENT_ID_HERE';  -- Thay thế bằng ID của tournament