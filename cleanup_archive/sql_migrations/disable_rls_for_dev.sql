-- ==========================================
-- DISABLE RLS FOR DEVELOPMENT 
-- ==========================================
-- Copy và paste vào Supabase SQL Editor để fix lỗi upload
-- Go to: https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr/sql

-- 🚨 CHỈ DÙNG CHO DEVELOPMENT - TRÁNH DÙNG TRONG PRODUCTION

-- Tắt Row Level Security tạm thời
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- Kiểm tra trạng thái RLS
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'storage' AND tablename IN ('objects', 'buckets');

-- ==========================================
-- KẾT QUẢ MONG ĐỢI:
-- ==========================================
-- storage | objects | f  (false = disabled)
-- storage | buckets | f  (false = disabled)

-- ==========================================
-- SAU KHI CHẠY SQL NÀY:
-- ==========================================
-- ✅ App có thể upload images mà không cần policies
-- ✅ Bucket public sẽ cho phép tất cả operations  
-- ✅ Lỗi "row-level security policy" sẽ biến mất

-- ==========================================
-- LƯU Ý:
-- ==========================================
-- 🔄 Để bật lại RLS trong production:
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;