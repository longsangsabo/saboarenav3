# 🧪 HƯỚNG DẪN TEST REFERRAL SYSTEM - SABO ARENA

## 📋 CÁC SCENARIO TEST TRƯỚC KHI PHÁT HÀNH

### **Scenario 1: Test Flow Cơ Bản** ⭐
```
1️⃣ Tạo User A (Referrer):
   - Email: userA@test.com
   - Password: testA123
   - Đăng ký → tự động có mã referral (VD: SABO-USERA123)

2️⃣ Tạo User B (Referred):  
   - Email: userB@test.com
   - Password: testB123
   - Đăng ký với mã của A → nhập "SABO-USERA123"
   
3️⃣ Kiểm tra kết quả:
   ✅ User A nhận +100 SPA
   ✅ User B nhận +50 SPA  
   ✅ Database ghi nhận 1 lượt sử dụng
```

### **Scenario 2: Test Error Cases** ⚠️
```
1️⃣ Test mã không tồn tại:
   - Nhập: "SABO-NOTEXIST"
   - Expected: Hiển thị "Mã không hợp lệ"

2️⃣ Test mã của chính mình:
   - User A nhập mã của chính A
   - Expected: Hiển thị "Không thể sử dụng mã của bản thân"

3️⃣ Test mã hết hạn:
   - Tạo mã với expires_at < hiện tại
   - Expected: Hiển thị "Mã đã hết hạn"

4️⃣ Test mã đã đạt giới hạn:
   - Tạo mã với max_uses = 1
   - 2 user sử dụng → user thứ 2 báo lỗi
```

### **Scenario 3: Test UI/UX** 🎨
```
1️⃣ Trang Referral Dashboard:
   - Hiển thị mã referral của user
   - Hiển thị số lượt đã sử dụng
   - Hiển thị tổng SPA đã kiếm được
   - Nút share hoạt động

2️⃣ Trang Đăng Ký:
   - Có ô nhập mã referral
   - Preview phần thưởng khi nhập mã hợp lệ
   - Hiển thị lỗi khi mã không hợp lệ

3️⃣ Notifications:
   - Thông báo khi được referral
   - Thông báo khi có người dùng mã của mình
```

## 🛠️ CÁCH TEST TRÊN DEVELOPMENT

### **Method 1: Sử dụng Test Script Python** 
```bash
# Chạy trong terminal
cd /workspaces/saboarenav3
python3 test_referral_script.py

# Chọn option:
# 1 = Auto test (test tất cả tự động)  
# 2 = Manual test (test từng bước)
```

### **Method 2: Test trên Flutter App**
```dart
// Thêm vào main.dart hoặc tạo test page
import 'test_referral_system.dart';

// Thêm route
'/test-referral': (context) => ReferralTestScreen(),

// Hoặc chạy trực tiếp
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ReferralTestScreen()
));
```

### **Method 3: Test Database trực tiếp**
```sql
-- Trong Supabase SQL Editor

-- 1. Kiểm tra referral codes
SELECT * FROM referral_codes 
WHERE is_active = true 
ORDER BY created_at DESC;

-- 2. Kiểm tra usage
SELECT ru.*, rc.code, u1.full_name as referrer, u2.full_name as referred
FROM referral_usage ru
JOIN referral_codes rc ON ru.referral_code_id = rc.id  
JOIN users u1 ON ru.referrer_id = u1.id
JOIN users u2 ON ru.referred_user_id = u2.id
ORDER BY ru.used_at DESC;

-- 3. Kiểm tra SPA balance
SELECT id, full_name, spa_balance, referral_code 
FROM users 
WHERE spa_balance > 0
ORDER BY spa_balance DESC;
```

## 🎯 CHECKLIST TRƯỚC KHI PHÁT HÀNH

### ✅ **Database & Backend**
- [ ] Bảng `referral_codes` hoạt động
- [ ] Bảng `referral_usage` ghi nhận chính xác
- [ ] SPA balance được cập nhật đúng
- [ ] RLS policies bảo mật
- [ ] Trigger tự động tạo mã cho user mới

### ✅ **API & Services**  
- [ ] `BasicReferralService.createReferralCode()` 
- [ ] `BasicReferralService.applyReferralCode()`
- [ ] `BasicReferralService.getReferralStats()`
- [ ] Error handling đầy đủ
- [ ] Validation mã referral

### ✅ **UI & UX**
- [ ] Referral dashboard hiển thị đúng
- [ ] Share functionality hoạt động  
- [ ] Registration form có ô referral
- [ ] Preview phần thưởng real-time
- [ ] Error messages rõ ràng

### ✅ **Edge Cases**
- [ ] Mã không tồn tại
- [ ] Mã hết hạn
- [ ] Mã đạt giới hạn
- [ ] User tự referral
- [ ] Network timeout
- [ ] Duplicate usage

## 📊 TEST DATA MẪU

### **Tạo Test Users:**
```
User A (Referrer):
├── Email: alice@sabotest.com
├── Username: ALICE2025
├── Referral Code: SABO-ALICE2025
└── Initial SPA: 1000

User B (Referred):
├── Email: bob@sabotest.com  
├── Username: BOB2025
├── Sử dụng mã: SABO-ALICE2025
└── Nhận được: +50 SPA

Expected Results:
├── Alice SPA: 1000 + 100 = 1100 
├── Bob SPA: 0 + 50 = 50
└── Usage record: 1 entry
```

### **Test Limits:**
```
Limited Code:
├── Code: SABO-LIMITED
├── Max Uses: 2
├── Test với 3 users
└── User thứ 3 phải báo lỗi
```

## 🚀 PRODUCTION READINESS

### **Performance Metrics:**
- Mỗi referral code generation < 500ms
- Mỗi referral application < 1s  
- Database queries optimized với indexes
- Error rate < 1%

### **Security Measures:**
- RLS policies prevent unauthorized access
- Referral code format validation
- Rate limiting cho API calls
- Audit logs cho mọi transactions

### **Monitoring:**
- Track referral success rate
- Monitor SPA distribution
- Alert cho unusual patterns
- Dashboard cho admin theo dõi

---

## 📞 SUPPORT

Nếu gặp issue trong quá trình test:

1. **Check Database**: Xem logs trong Supabase Dashboard
2. **Check Flutter Logs**: `flutter logs` để xem errors  
3. **Check Test Scripts**: Chạy Python script để verify backend
4. **Manual Verification**: Test thủ công với UI

**Happy Testing! 🧪✨**