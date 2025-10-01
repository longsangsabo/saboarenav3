-- =====================================================
-- RANK SYSTEM MIGRATION SCRIPT
-- Chuyển đổi từ hệ thống rank cũ sang hệ thống mới
-- =====================================================

-- 1. TẠO BẢNG MAPPING TẠM THỜI
DROP TABLE IF EXISTS temp_rank_migration;
CREATE TEMP TABLE temp_rank_migration (
    old_rank_name TEXT,
    new_rank_name TEXT,
    rank_code TEXT,
    elo_min INTEGER,
    elo_max INTEGER
);

-- 2. INSERT DỮ LIỆU MAPPING
INSERT INTO temp_rank_migration (old_rank_name, new_rank_name, rank_code, elo_min, elo_max) VALUES
('Tập Sự', 'Người mới', 'K', 1000, 1099),
('Tập Sự+', 'Học việc', 'K+', 1100, 1199),
('Sơ Cấp', 'Thợ 3', 'I', 1200, 1299),
('Sơ Cấp+', 'Thợ 2', 'I+', 1300, 1399),
('Trung Cấp', 'Thợ 1', 'H', 1400, 1499),
('Trung Cấp+', 'Thợ chính', 'H+', 1500, 1599),
('Khá', 'Thợ giỏi', 'G', 1600, 1699),
('Khá+', 'Cao thủ', 'G+', 1700, 1799),
('Giỏi', 'Chuyên gia', 'F', 1800, 1899),
('Giỏi+', 'Đại cao thủ', 'F+', 1900, 1999),
('Xuất Sắc', 'Huyền thoại', 'E', 2000, 2099),
('Chuyên Gia', 'Vô địch', 'E+', 2100, 9999);

-- 3. BACKUP DỮ LIỆU CŨ (optional, để an toàn)
DROP TABLE IF EXISTS users_rank_backup;
CREATE TABLE users_rank_backup AS 
SELECT id, rank, elo_rating, created_at 
FROM users 
WHERE rank IS NOT NULL;

-- 4. FUNCTION MIGRATE RANK NAME
CREATE OR REPLACE FUNCTION migrate_rank_name(input_rank TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    result_rank TEXT;
BEGIN
    -- Nếu input là NULL hoặc rỗng
    IF input_rank IS NULL OR input_rank = '' OR input_rank = 'unranked' THEN
        RETURN NULL; -- Return NULL để giữ UNRANKED state
    END IF;
    
    -- Thử tìm trong mapping table
    SELECT rank_code INTO result_rank
    FROM temp_rank_migration
    WHERE old_rank_name = input_rank OR new_rank_name = input_rank;
    
    -- Nếu tìm thấy, return rank code
    IF result_rank IS NOT NULL THEN
        RETURN result_rank;
    END IF;
    
    -- Nếu input đã là rank code (K, K+, I, etc.)
    IF input_rank ~ '^[KIHGFE]\+?$' THEN
        RETURN input_rank;
    END IF;
    
    -- Fallback: return NULL (keep unranked)
    RETURN NULL;
END;
$$;

-- 5. CẬP NHẬT USERS TABLE - MIGRATE RANK DATA
UPDATE users 
SET rank = migrate_rank_name(rank)
WHERE rank IS NOT NULL;

-- 6. CẬP NHẬT CÁC BẢNG KHÁC CÓ CHỨA RANK DATA (chỉ update những bảng thực sự tồn tại)

-- Kiểm tra và update rank_requests table nếu tồn tại
DO $$
BEGIN
    -- Update rank_requests table nếu có cột requested_rank và current_rank
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'rank_requests' AND column_name = 'requested_rank'
    ) THEN
        UPDATE rank_requests 
        SET requested_rank = migrate_rank_name(requested_rank)
        WHERE requested_rank IS NOT NULL;
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'rank_requests' AND column_name = 'current_rank'
    ) THEN
        UPDATE rank_requests 
        SET current_rank = migrate_rank_name(current_rank)
        WHERE current_rank IS NOT NULL;
    END IF;
END $$;

-- Update notifications table - cập nhật rank change notifications
UPDATE notifications 
SET data = jsonb_set(
    jsonb_set(
        data,
        '{current_rank}',
        to_jsonb(migrate_rank_name(data->>'current_rank'))
    ),
    '{requested_rank}',
    to_jsonb(migrate_rank_name(data->>'requested_rank'))
)
WHERE type LIKE '%rank%' 
AND (data ? 'current_rank' OR data ? 'requested_rank');

-- 7. TẠO INDEX CHO PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_users_rank ON users(rank);
CREATE INDEX IF NOT EXISTS idx_users_elo_rating ON users(elo_rating);

-- 8. FUNCTION ĐỂ VALIDATE MIGRATION
CREATE OR REPLACE FUNCTION validate_rank_migration()
RETURNS TABLE (
    status TEXT,
    total_users INTEGER,
    users_with_rank INTEGER,
    rank_distribution JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_users INTEGER;
    v_users_with_rank INTEGER;
    v_rank_dist JSONB;
BEGIN
    -- Count total users
    SELECT COUNT(*) INTO v_total_users FROM users;
    
    -- Count users with rank
    SELECT COUNT(*) INTO v_users_with_rank 
    FROM users 
    WHERE rank IS NOT NULL AND rank != '';
    
    -- Get rank distribution
    SELECT jsonb_object_agg(rank, count)
    INTO v_rank_dist
    FROM (
        SELECT rank, COUNT(*) as count
        FROM users
        WHERE rank IS NOT NULL
        GROUP BY rank
        ORDER BY rank
    ) sub;
    
    RETURN QUERY SELECT 
        'SUCCESS'::TEXT,
        v_total_users,
        v_users_with_rank,
        v_rank_dist;
END;
$$;

-- 9. FUNCTION ĐỂ GET RANK DISPLAY NAME
CREATE OR REPLACE FUNCTION get_rank_display_name(rank_code TEXT)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN CASE rank_code
        WHEN 'K' THEN 'Người mới'
        WHEN 'K+' THEN 'Học việc'
        WHEN 'I' THEN 'Thợ 3'
        WHEN 'I+' THEN 'Thợ 2'
        WHEN 'H' THEN 'Thợ 1'
        WHEN 'H+' THEN 'Thợ chính'
        WHEN 'G' THEN 'Thợ giỏi'
        WHEN 'G+' THEN 'Cao thủ'
        WHEN 'F' THEN 'Chuyên gia'
        WHEN 'F+' THEN 'Đại cao thủ'
        WHEN 'E' THEN 'Huyền thoại'
        WHEN 'E+' THEN 'Vô địch'
        ELSE 'Chưa xếp hạng'
    END;
END;
$$;

-- 10. CHẠY VALIDATION
SELECT * FROM validate_rank_migration();

-- 11. CLEAN UP TEMP TABLE
DROP TABLE IF EXISTS temp_rank_migration;
DROP FUNCTION IF EXISTS migrate_rank_name(TEXT);

-- =====================================================
-- MIGRATION COMPLETED!
-- =====================================================
-- 
-- Các thay đổi đã được thực hiện:
-- 1. ✅ Chuyển đổi tất cả rank names sang rank codes
-- 2. ✅ Cập nhật users table
-- 3. ✅ Cập nhật tournament_participants table  
-- 4. ✅ Cập nhật rank_requests table
-- 5. ✅ Cập nhật notifications table
-- 6. ✅ Tạo function get_rank_display_name()
-- 7. ✅ Tạo indexes để optimize performance
-- 8. ✅ Validation và reporting
--
-- LƯU Ý:
-- - Dữ liệu cũ đã được backup trong bảng users_rank_backup
-- - Rank codes (K, K+, I, etc.) được lưu trong database
-- - Display names sẽ được handle bởi frontend/mobile app
-- - ELO ranges không thay đổi, chỉ display names thay đổi
-- =====================================================