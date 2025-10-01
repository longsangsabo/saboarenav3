# 🧪 MANUAL TESTING GUIDE - RANK REGISTRATION APPROVAL FLOW

## ✅ CURRENT STATUS
- ✅ **Database migrations** applied: rank_requests table + RPC functions
- ✅ **1 pending request** exists in database (ID: deb7fa56-baf2-4a97-9b29-fe8e29969986)
- ✅ **App running** on Chrome: http://127.0.0.1:54476
- ✅ **Supabase connection** established successfully
- ✅ **All code** implementation completed

---

## 🎯 TESTING FLOW: ADMIN APPROVAL → SYSTEM UPDATE

### **Step 1: Access Admin Screen**
1. **Open app** in browser (already running)
2. **Login with admin account** or account có quyền club admin
3. **Navigate to**: Admin Dashboard → Club Management → "Rank Change Requests"

### **Step 2: Review Pending Request**
✅ **Expected to see:**
```
- User request from: deb7fa56-baf2-4a97-9b29-fe8e29969986
- User: (User details will be displayed)
- Status: pending
- Notes: "Yêu cầu đăng ký rank từ ứng dụng SABO Arena"
- Evidence URLs: null (no images yet)
```

### **Step 3: Test Approval Action**
1. **Click "Chấp thuận" button** on the pending request
2. **Watch for success notification**: "Đã chấp thuận yêu cầu"
3. **Verify UI updates**: Request should disappear from pending list

### **Step 4: Verify Database Updates**
Run these SQL queries in Supabase Dashboard:

```sql
-- Check request status updated
SELECT id, status, reviewed_at, reviewed_by, club_comments 
FROM rank_requests 
WHERE id = 'deb7fa56-baf2-4a97-9b29-fe8e29969986';

-- Check user rank updated
SELECT id, full_name, rank, updated_at 
FROM users 
WHERE id = '8dc68b2e-8c94-47d7-a2d7-a70b218c32a8';

-- Check rank change log created
SELECT * FROM rank_change_logs 
WHERE user_id = '8dc68b2e-8c94-47d7-a2d7-a70b218c32a8'
ORDER BY created_at DESC 
LIMIT 1;
```

### **Step 5: Test Full User Flow (Optional)**
1. **Login as regular user**
2. **Go to Profile → "Đăng ký thay đổi hạng"**
3. **Select desired rank** from dropdown
4. **Upload evidence images** (1-5 photos)
5. **Submit request**
6. **Switch back to admin account**
7. **Repeat approval process**

---

## 🔍 VERIFICATION CHECKLIST

### ✅ **Frontend Verification**
- [ ] Pending requests display correctly in admin UI
- [ ] Evidence images show in preview grid
- [ ] Approve/Reject buttons work
- [ ] Success/Error notifications appear
- [ ] UI updates after approval action

### ✅ **Backend Verification**
- [ ] RPC function `get_pending_rank_change_requests()` returns data
- [ ] RPC function `club_review_rank_change_request()` executes successfully
- [ ] Request status changes from 'pending' → 'approved'
- [ ] User rank field gets updated
- [ ] Rank change log entry created

### ✅ **System Integration**
- [ ] Real-time updates (if implemented)
- [ ] User profile shows new rank
- [ ] Any related UI components reflect new rank
- [ ] Notifications sent to user (if implemented)

---

## 🐛 TROUBLESHOOTING

### **If Admin UI doesn't show pending requests:**
```sql
-- Manually check database
SELECT * FROM rank_requests WHERE status = 'pending';

-- Test RPC function directly
SELECT get_pending_rank_change_requests();
```

### **If Approval fails:**
1. Check browser console for errors
2. Verify user has admin/club_admin role
3. Test RPC function with direct SQL:
```sql
SELECT club_review_rank_change_request(
    'deb7fa56-baf2-4a97-9b29-fe8e29969986', 
    true, 
    'Manual test approval'
);
```

### **If Database updates fail:**
- Check RLS policies on rank_requests table
- Verify users table allows rank updates
- Check rank_change_logs table exists and is accessible

---

## 📱 NAVIGATION PATHS

### **Admin Access Path:**
```
App → Login (admin) → Dashboard → Club Management → Rank Change Requests
```

### **User Registration Path:**
```
App → Profile → Đăng ký thay đổi hạng → Fill form → Submit
```

---

## 🎯 SUCCESS CRITERIA

✅ **Complete success means:**
1. **UI Flow**: Admin can see, review, and approve requests
2. **Database Updates**: All tables updated correctly
3. **User Experience**: User sees rank change reflected
4. **System Integrity**: Logs maintained, notifications work

---

## 📊 TEST DATA OVERVIEW

**Existing Request:**
- ID: `deb7fa56-baf2-4a97-9b29-fe8e29969986`
- User: `8dc68b2e-8c94-47d7-a2d7-a70b218c32a8`
- Club: `4efdd198-c2b7-4428-a6f8-3cf132fc71f7`
- Status: `pending`

**Ready to test end-to-end approval workflow! 🚀**