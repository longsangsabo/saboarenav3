-- ====================================================================
-- RANK/ELO AUTOMATION SYSTEM FOR SABO ARENA
-- Copy và paste toàn bộ script này vào Supabase SQL Editor
-- ====================================================================

-- 1. Tạo function để cập nhật rank và ELO cho user
CREATE OR REPLACE FUNCTION update_user_rank_from_club_confirmation()
RETURNS TRIGGER AS $$
BEGIN  
    -- Log thông tin trigger được gọi
    RAISE LOG 'Trigger called: user_id=%, status=%, confirmed_rank=%', 
        NEW.user_id, NEW.status, NEW.confirmed_rank;
    
    -- Chỉ cập nhật khi status thay đổi thành 'approved' và có confirmed_rank
    IF NEW.status = 'approved' AND NEW.confirmed_rank IS NOT NULL AND NEW.confirmed_rank != '' THEN
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
        RAISE LOG 'No update needed: status=%, confirmed_rank=%', NEW.status, NEW.confirmed_rank;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Tạo trigger để tự động gọi function khi club_members được update
DROP TRIGGER IF EXISTS trigger_update_user_rank ON club_members;

CREATE TRIGGER trigger_update_user_rank
    AFTER UPDATE ON club_members
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rank_from_club_confirmation();

-- 3. Function để đồng bộ dữ liệu có sẵn (chạy thủ công)
CREATE OR REPLACE FUNCTION sync_existing_approved_ranks()
RETURNS TEXT AS $$
DECLARE
    member_record RECORD;
    updated_count INTEGER := 0;
    elo_value INTEGER;
BEGIN
    -- Lặp qua tất cả membership đã approved với confirmed_rank
    FOR member_record IN 
        SELECT user_id, confirmed_rank 
        FROM club_members 
        WHERE status = 'approved' 
        AND confirmed_rank IS NOT NULL 
        AND confirmed_rank != ''
        AND confirmed_rank IN ('A', 'B', 'C', 'D', 'E')
    LOOP
        -- Tính ELO theo rank
        elo_value := CASE member_record.confirmed_rank
            WHEN 'A' THEN 1800
            WHEN 'B' THEN 1600  
            WHEN 'C' THEN 1400
            WHEN 'D' THEN 1200
            WHEN 'E' THEN 1000
            ELSE 1000
        END;
        
        -- Update user
        UPDATE users 
        SET 
            rank = member_record.confirmed_rank,
            elo_rating = elo_value,
            updated_at = NOW()
        WHERE id = member_record.user_id;
        
        updated_count := updated_count + 1;
        
        RAISE LOG 'Synced user % to rank % (ELO: %)', 
            member_record.user_id, member_record.confirmed_rank, elo_value;
    END LOOP;
    
    RETURN format('Successfully synced %s users with approved ranks', updated_count);
END;
$$ LANGUAGE plpgsql;

-- 4. Chạy đồng bộ dữ liệu có sẵn
SELECT sync_existing_approved_ranks();

-- 5. Test trigger với một user mẫu (tùy chọn)
-- Uncomment các dòng dưới để test:

-- INSERT INTO club_members (user_id, club_id, status, confirmed_rank) 
-- VALUES (
--     (SELECT id FROM users LIMIT 1),
--     (SELECT id FROM clubs LIMIT 1), 
--     'approved',
--     'B'
-- )
-- ON CONFLICT (user_id, club_id) DO UPDATE SET
--     status = 'approved',
--     confirmed_rank = 'B';

-- ====================================================================
-- HƯỚNG DẪN SỬ DỤNG:
-- 
-- 1. Copy toàn bộ script này
-- 2. Vào Supabase Dashboard → SQL Editor
-- 3. Paste và chạy script
-- 4. Kiểm tra kết quả:
--    - Function và trigger đã được tạo
--    - Dữ liệu existing đã được sync
-- 
-- CÁCH HOẠT ĐỘNG:
-- - Khi admin approve user trong club_members với confirmed_rank
-- - Trigger tự động cập nhật users.rank và users.elo_rating
-- - ELO mapping: A=1800, B=1600, C=1400, D=1200, E=1000
-- ====================================================================