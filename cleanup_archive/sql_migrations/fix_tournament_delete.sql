-- FIX FOREIGN KEY CONSTRAINTS VÀ ENABLE CASCADE DELETE
-- Script này sẽ fix vấn đề không thể xóa tournaments

-- 1. XÓA TOURNAMENT doublesabo1 VÀ DEPENDENCIES
DO $$
DECLARE
    tournament_uuid UUID := '468f51d5-744a-4a68-a692-fa8c7991da05';
BEGIN
    -- Xóa tất cả user_achievements liên quan
    DELETE FROM user_achievements WHERE tournament_id = tournament_uuid;
    RAISE NOTICE 'Đã xóa user_achievements cho tournament %', tournament_uuid;
    
    -- Xóa tất cả tournament_participants
    DELETE FROM tournament_participants WHERE tournament_id = tournament_uuid;
    RAISE NOTICE 'Đã xóa tournament_participants cho tournament %', tournament_uuid;
    
    -- Xóa tất cả matches
    DELETE FROM matches WHERE tournament_id = tournament_uuid;
    RAISE NOTICE 'Đã xóa matches cho tournament %', tournament_uuid;
    
    -- Cuối cùng xóa tournament
    DELETE FROM tournaments WHERE id = tournament_uuid;
    RAISE NOTICE 'Đã xóa tournament %', tournament_uuid;
    
    RAISE NOTICE 'HOÀN THÀNH: Tournament doublesabo1 đã được xóa thành công!';
END $$;

-- 2. CẤU HÌNH CASCADE DELETE CHO FOREIGN KEYS
-- Điều này sẽ cho phép xóa tournaments dễ dàng hơn trong tương lai

-- Drop existing foreign key constraints nếu có
ALTER TABLE user_achievements 
DROP CONSTRAINT IF EXISTS user_achievements_tournament_id_fkey;

ALTER TABLE tournament_participants 
DROP CONSTRAINT IF EXISTS tournament_participants_tournament_id_fkey;

ALTER TABLE matches 
DROP CONSTRAINT IF EXISTS matches_tournament_id_fkey;

-- Tạo lại với CASCADE DELETE
ALTER TABLE user_achievements 
ADD CONSTRAINT user_achievements_tournament_id_fkey 
FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;

ALTER TABLE tournament_participants 
ADD CONSTRAINT tournament_participants_tournament_id_fkey 
FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;

ALTER TABLE matches 
ADD CONSTRAINT matches_tournament_id_fkey 
FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE CASCADE;

-- 3. KIỂM TRA KẾT QUẢ
SELECT 
    'tournaments' as table_name,
    COUNT(*) as count
FROM tournaments 
WHERE title ILIKE '%doublesabo1%'

UNION ALL

SELECT 
    'user_achievements' as table_name,
    COUNT(*) as count
FROM user_achievements 
WHERE tournament_id = '468f51d5-744a-4a68-a692-fa8c7991da05'

UNION ALL

SELECT 
    'tournament_participants' as table_name,
    COUNT(*) as count
FROM tournament_participants 
WHERE tournament_id = '468f51d5-744a-4a68-a692-fa8c7991da05'

UNION ALL

SELECT 
    'matches' as table_name,
    COUNT(*) as count
FROM matches 
WHERE tournament_id = '468f51d5-744a-4a68-a692-fa8c7991da05';