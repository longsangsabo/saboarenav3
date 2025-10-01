-- =====================================================
-- RESET ALL USER RANKS FOR TESTING
-- Script để reset rank của tất cả users về rank mặc định
-- =====================================================

-- 1. BACKUP DỮ LIỆU HIỆN TẠI (để an toàn)
DROP TABLE IF EXISTS users_rank_reset_backup;
CREATE TABLE users_rank_reset_backup AS 
SELECT id, rank, elo_rating, total_wins, total_losses, created_at, updated_at
FROM users 
WHERE rank IS NOT NULL;

-- 2. RESET TẤT CẢ USER RANKS VỀ RANK MẶC ĐỊNH
UPDATE users 
SET 
    rank = 'K',                    -- Rank mặc định: Người mới
    elo_rating = 1000,             -- ELO mặc định cho rank K
    total_wins = 0,                -- Reset wins về 0
    total_losses = 0,              -- Reset losses về 0
    updated_at = NOW()             -- Update timestamp
WHERE id IS NOT NULL;

-- 3. RESET CÁC BẢNG LIÊN QUAN (nếu tồn tại)

-- Reset rank_requests table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'rank_requests') THEN
        DELETE FROM rank_requests;
        RAISE NOTICE 'Đã xóa tất cả rank requests';
    ELSE
        RAISE NOTICE 'Bảng rank_requests không tồn tại';
    END IF;
END $$;

-- Reset tournament_participants (nếu có rank data)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tournament_participants' AND column_name = 'current_rank'
    ) THEN
        UPDATE tournament_participants 
        SET current_rank = 'K'
        WHERE current_rank IS NOT NULL;
        RAISE NOTICE 'Đã reset rank trong tournament_participants';
    ELSE
        RAISE NOTICE 'Cột current_rank không tồn tại trong tournament_participants';
    END IF;
END $$;

-- Reset notifications liên quan đến rank
UPDATE notifications 
SET data = jsonb_set(
    jsonb_set(
        data,
        '{current_rank}',
        '"K"'::jsonb
    ),
    '{requested_rank}',
    '"K"'::jsonb
)
WHERE type LIKE '%rank%' 
AND (data ? 'current_rank' OR data ? 'requested_rank');

-- 4. CẬP NHẬT TIMESTAMPS
UPDATE users 
SET updated_at = NOW() 
WHERE rank = 'K';

-- 5. VALIDATION - Kiểm tra kết quả reset
CREATE OR REPLACE FUNCTION validate_rank_reset()
RETURNS TABLE (
    status TEXT,
    total_users INTEGER,
    users_with_rank_k INTEGER,
    users_with_elo_1000 INTEGER,
    users_with_zero_wins INTEGER,
    backup_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_users INTEGER;
    v_users_k INTEGER;
    v_users_elo INTEGER;
    v_users_wins INTEGER;
    v_backup_count INTEGER;
BEGIN
    -- Count totals
    SELECT COUNT(*) INTO v_total_users FROM users;
    
    SELECT COUNT(*) INTO v_users_k 
    FROM users 
    WHERE rank = 'K';
    
    SELECT COUNT(*) INTO v_users_elo 
    FROM users 
    WHERE elo_rating = 1000;
    
    SELECT COUNT(*) INTO v_users_wins 
    FROM users 
    WHERE total_wins = 0 AND total_losses = 0;
    
    SELECT COUNT(*) INTO v_backup_count 
    FROM users_rank_reset_backup;
    
    RETURN QUERY SELECT 
        'RESET_SUCCESS'::TEXT,
        v_total_users,
        v_users_k,
        v_users_elo,
        v_users_wins,
        v_backup_count;
END;
$$;

-- 6. CHẠY VALIDATION
SELECT * FROM validate_rank_reset();

-- 7. HIỂN thị THỐNG KÊ SAU RESET
SELECT 
    'THỐNG KÊ SAU KHI RESET' as title,
    COUNT(*) as total_users,
    COUNT(CASE WHEN rank = 'K' THEN 1 END) as users_rank_k,
    COUNT(CASE WHEN elo_rating = 1000 THEN 1 END) as users_elo_1000,
    COUNT(CASE WHEN total_wins = 0 THEN 1 END) as users_zero_wins,
    COUNT(CASE WHEN total_losses = 0 THEN 1 END) as users_zero_losses
FROM users;

-- 8. HIỂN THỊ MẪU VÀI USER SAU RESET
SELECT 
    id,
    email,
    username,
    rank,
    elo_rating,
    total_wins,
    total_losses,
    updated_at
FROM users 
ORDER BY updated_at DESC 
LIMIT 5;

-- 9. CLEAN UP VALIDATION FUNCTION
DROP FUNCTION IF EXISTS validate_rank_reset();

-- =====================================================
-- RANK RESET COMPLETED!
-- =====================================================
-- 
-- Đã thực hiện:
-- ✅ Backup dữ liệu cũ vào bảng users_rank_reset_backup
-- ✅ Reset tất cả users về rank 'K' (Người mới)
-- ✅ Reset ELO về 1000 (ELO mặc định cho rank K)
-- ✅ Reset total_wins và total_losses về 0
-- ✅ Xóa tất cả rank_requests
-- ✅ Reset rank data trong các bảng liên quan
-- ✅ Cập nhật timestamps
-- ✅ Validation và reporting
--
-- LƯU Ý CHO TESTING:
-- 🎯 Tất cả users giờ sẽ bắt đầu với rank "K" (Người mới)
-- 🎯 App sẽ hiển thị "Người mới" cho tất cả users
-- 🎯 ELO bắt đầu từ 1000 - phù hợp với Vietnamese ranking system
-- 🎯 Users có thể request rank mới thông qua rank registration
-- 🎯 Có thể restore data từ bảng users_rank_reset_backup nếu cần
-- =====================================================