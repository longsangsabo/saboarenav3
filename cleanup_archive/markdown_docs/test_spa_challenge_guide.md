# 🎯 HƯỚNG DẪN TEST SPA CHALLENGE SYSTEM

## Chuẩn bị Test:
1. **Đăng nhập app** - Đảm bảo có user account
2. **Tham gia club** - Cần ít nhất 1 club có SPA balance
3. **Tìm opponent** - Cần có đối thủ để tạo challenge match
4. **Tạo challenge** - Với điều kiện SPA bonus

## Test Cases chính:

### 🏆 **TEST 1: Challenge Match với SPA Bonus**
**Mục tiêu:** Kiểm tra winner nhận SPA bonus từ club pool

**Các bước:**
1. Vào tab "Thách Đấu" hoặc "Challenge"
2. Tạo challenge match mới với SPA bonus (nếu có option)
3. Hoàn thành match và declare winner
4. **Kiểm tra:** Winner có nhận được SPA bonus không?
5. **Kiểm tra:** Club balance có bị trừ không?

**Expected Results:**
- ✅ Winner nhận SPA bonus
- ✅ Club pool bị trừ tương ứng  
- ✅ Không có double payment
- ✅ Transaction được ghi vào database

### 💰 **TEST 2: Club SPA Balance**
**Mục tiêu:** Xác minh club có đủ SPA để award

**Các bước:**
1. Vào club management/profile
2. Kiểm tra SPA balance hiện tại
3. Thực hiện challenge match
4. Xem balance thay đổi như thế nào

### 🔄 **TEST 3: Error Handling**
**Mục tiêu:** Test khi club không đủ SPA

**Các bước:**
1. Tìm club có SPA balance = 0 hoặc thấp
2. Thử tạo challenge với SPA bonus cao
3. **Kiểm tra:** System có prevent và báo lỗi không?

## 🔍 Debug Information:
Khi test, để ý các log messages:
- `🎯 SPA Challenge: Processing SPA bonuses for match...`
- `✅ SPA Challenge: Bonus awarded successfully`
- `❌ SPA Challenge: Error - insufficient club balance`

## 📱 Navigation trong App:
1. **Challenge Tab** - Tạo và quản lý challenges
2. **Club Tab** - Xem SPA balance và transactions
3. **Profile Tab** - Xem personal SPA balance
4. **Match History** - Xem completed matches và payouts