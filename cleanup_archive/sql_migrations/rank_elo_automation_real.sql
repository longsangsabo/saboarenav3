-- ====================================================================
-- RANK/ELO AUTOMATION SYSTEM FOR SABO ARENA (UPDATED FOR REAL SCHEMA)
-- Dựa trên cấu trúc database thực tế đã phân tích
-- Copy và paste toàn bộ script này vào Supabase SQL Editor
-- ====================================================================

-- 1. Thêm cột confirmed_rank vào club_members nếu chưa có
ALTER TABLE club_members 
ADD COLUMN IF NOT EXISTS confirmed_rank VARCHAR(5);

-- Thêm cột approval_status để quản lý việc xác nhận rank
ALTER TABLE club_members 
ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending';

-- 2. Tạo function để cập nhật rank và ELO cho user
CREATE OR REPLACE FUNCTION update_user_rank_from_club_confirmation()
RETURNS TRIGGER AS $$
BEGIN  
    -- Log thông tin trigger được gọi
    RAISE LOG 'Rank trigger called: user_id=%, approval_status=%, confirmed_rank=%', 
        NEW.user_id, NEW.approval_status, NEW.confirmed_rank;
    
    -- Chỉ cập nhật khi approval_status thay đổi thành 'approved' và có confirmed_rank
    IF NEW.approval_status = 'approved' AND NEW.confirmed_rank IS NOT NULL AND NEW.confirmed_rank != '' THEN
        -- Cập nhật rank trong users table
        UPDATE users 
        SET 
            rank = NEW.confirmed_rank,
            elo_rating = CASE NEW.confirmed_rank
                WHEN 'A' THEN 1800
                WHEN 'B' THEN 1600  
                WHEN 'C' THEN 1400
                WHEN 'D' THEN 1200
                WHEN 'E' THEN 1000
                ELSE elo_rating  -- Giữ nguyên nếu rank không hợp lệ
            END,
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        -- Log thông tin cập nhật
        RAISE LOG 'Updated user % rank to % with ELO %', 
            NEW.user_id, NEW.confirmed_rank, 
            CASE NEW.confirmed_rank
                WHEN 'A' THEN 1800
                WHEN 'B' THEN 1600  
                WHEN 'C' THEN 1400
                WHEN 'D' THEN 1200
                WHEN 'E' THEN 1000
                ELSE 0
            END;
    ELSE
        RAISE LOG 'No rank update needed: approval_status=%, confirmed_rank=%', 
            NEW.approval_status, NEW.confirmed_rank;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Tạo trigger để tự động gọi function khi club_members được update
DROP TRIGGER IF EXISTS trigger_update_user_rank ON club_members;

CREATE TRIGGER trigger_update_user_rank
    AFTER UPDATE ON club_members
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rank_from_club_confirmation();

-- 4. Function để admin confirm rank cho user
CREATE OR REPLACE FUNCTION confirm_user_rank(
    p_user_id UUID,
    p_club_id UUID, 
    p_confirmed_rank VARCHAR(5)
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    elo_value INTEGER;
BEGIN
    -- Validate rank
    IF p_confirmed_rank NOT IN ('A', 'B', 'C', 'D', 'E') THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Invalid rank. Must be A, B, C, D, or E'
        );
    END IF;
    
    -- Check if membership exists
    IF NOT EXISTS (
        SELECT 1 FROM club_members 
        WHERE user_id = p_user_id AND club_id = p_club_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'User is not a member of this club'
        );
    END IF;
    
    -- Update membership with confirmed rank
    UPDATE club_members 
    SET 
        confirmed_rank = p_confirmed_rank,
        approval_status = 'approved',
        updated_at = NOW()
    WHERE user_id = p_user_id AND club_id = p_club_id;
    
    -- Calculate ELO for response
    elo_value := CASE p_confirmed_rank
        WHEN 'A' THEN 1800
        WHEN 'B' THEN 1600  
        WHEN 'C' THEN 1400
        WHEN 'D' THEN 1200
        WHEN 'E' THEN 1000
    END;
    
    RETURN json_build_object(
        'success', true,
        'message', format('User rank confirmed as %s with ELO %s', p_confirmed_rank, elo_value),
        'rank', p_confirmed_rank,
        'elo', elo_value
    );
END;
$$ LANGUAGE plpgsql;

-- 5. Function để lấy users chưa có rank
CREATE OR REPLACE FUNCTION get_users_without_rank()
RETURNS TABLE (
    user_id UUID,
    display_name TEXT,
    club_name TEXT,
    membership_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.display_name,
        c.name,
        cm.status
    FROM users u
    JOIN club_members cm ON u.id = cm.user_id
    JOIN clubs c ON cm.club_id = c.id
    WHERE u.rank IS NULL
    AND cm.status = 'active'
    ORDER BY u.display_name;
END;
$$ LANGUAGE plpgsql;

-- 6. Test data - Tạo một vài membership để test
INSERT INTO club_members (user_id, club_id, status, role)
SELECT 
    u.id,
    (SELECT id FROM clubs LIMIT 1),
    'active',
    'member'
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM club_members cm 
    WHERE cm.user_id = u.id 
    AND cm.club_id = (SELECT id FROM clubs LIMIT 1)
)
LIMIT 2;

-- 7. Test function confirm_user_rank
-- SELECT confirm_user_rank(
--     (SELECT id FROM users WHERE display_name = 'demo02'),
--     (SELECT id FROM clubs LIMIT 1),
--     'B'
-- );

-- ====================================================================
-- HƯỚNG DẪN SỬ DỤNG:
-- 
-- 1. Copy toàn bộ script này vào Supabase SQL Editor và chạy
-- 
-- 2. Để confirm rank cho user:
--    SELECT confirm_user_rank('user_id', 'club_id', 'B');
-- 
-- 3. Để xem users chưa có rank:
--    SELECT * FROM get_users_without_rank();
-- 
-- 4. Để test automation:
--    UPDATE club_members SET confirmed_rank = 'C', approval_status = 'approved' 
--    WHERE user_id = 'some_user_id';
-- 
-- CÁCH HOẠT ĐỘNG:
-- - Admin gọi confirm_user_rank() hoặc update club_members
-- - Trigger tự động cập nhật users.rank và users.elo_rating  
-- - ELO mapping: A=1800, B=1600, C=1400, D=1200, E=1000
-- ====================================================================