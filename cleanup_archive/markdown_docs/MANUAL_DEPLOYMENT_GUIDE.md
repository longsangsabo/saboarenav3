# 🚀 MANUAL DEPLOYMENT INSTRUCTIONS

## **Step 1: Copy SQL Schema**

1. Mở file `staff_attendance_schema.sql` 
2. Copy toàn bộ nội dung (Ctrl+A, Ctrl+C)

## **Step 2: Execute in Supabase Dashboard**

1. Vào https://supabase.com/dashboard/project/mogjjvscxjwvhtpkrlqr
2. Click **SQL Editor** (bên trái)
3. Click **New Query**
4. Paste toàn bộ SQL vào editor
5. Click **Run** (hoặc Ctrl+Enter)

## **Step 3: Verify Deployment**

Sau khi chạy xong, verify bằng cách chạy queries này:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('staff_shifts', 'staff_attendance', 'staff_breaks', 'attendance_notifications');

-- Check if QR columns exist in clubs table
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'clubs' 
AND column_name IN ('attendance_qr_code', 'qr_secret_key');

-- Check if utility functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_type = 'FUNCTION' 
AND routine_name IN ('get_today_shift', 'is_staff_checked_in', 'get_club_qr_data');
```

## **Expected Results:**

- ✅ 4 new tables created
- ✅ 2 new columns in clubs table  
- ✅ 3 utility functions created
- ✅ RLS policies enabled
- ✅ Triggers activated

## **If Any Errors:**

1. **Table already exists**: Ignore (safe)
2. **Column already exists**: Ignore (safe)
3. **Function already exists**: Ignore (safe)
4. **Permission denied**: Use correct service role
5. **Syntax error**: Check SQL formatting

## **Next Steps After Success:**

1. 📱 Create Flutter attendance service
2. 🎨 Build QR scanner UI
3. 📊 Create attendance dashboard

---

**🎯 Quick Test After Deployment:**

```sql
-- Test function works
SELECT get_club_qr_data((SELECT id FROM clubs LIMIT 1));

-- Should return JSON with QR data
```