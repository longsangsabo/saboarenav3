# 💰 CƠ CHẾ NHẬN HOA HỒNG CỦA NHÂN VIÊN

## 🔄 QUY TRÌNH HOẠT ĐỘNG

### **Bước 1: Nhân viên giới thiệu khách hàng**
```sql
-- Tạo liên kết giới thiệu
INSERT INTO staff_referrals (staff_id, customer_id, club_id, commission_rate)
VALUES ('staff-123', 'customer-456', 'club-789', 5.0);
```

### **Bước 2: Khách hàng thực hiện giao dịch**
```sql
-- Ghi nhận giao dịch (có staff_referral_id)
INSERT INTO customer_transactions (
    customer_id, club_id, staff_referral_id,
    transaction_type, amount, commission_eligible
) VALUES (
    'customer-456', 'club-789', 'referral-id',
    'tournament_fee', 100000, true
);
```

### **Bước 3: TRIGGER tự động tính hoa hồng**
```sql
-- TRIGGER này chạy TỰ ĐỘNG khi có transaction mới
CREATE TRIGGER calculate_commission_trigger
    AFTER INSERT ON customer_transactions
    FOR EACH ROW
    EXECUTE FUNCTION calculate_commission();
```

## ⚡ TRIGGER FUNCTIONS HOẠT ĐỘNG

### **1. Function `calculate_commission()`**
```sql
CREATE OR REPLACE FUNCTION calculate_commission()
RETURNS TRIGGER AS $$
DECLARE
    staff_record RECORD;
    commission_amount_calc NUMERIC;
BEGIN
    -- Chỉ tính hoa hồng nếu đủ điều kiện
    IF NEW.commission_eligible = true AND NEW.staff_referral_id IS NOT NULL THEN
        
        -- Lấy thông tin nhân viên và tỷ lệ hoa hồng
        SELECT cs.id, cs.commission_rate, sr.commission_rate as referral_rate
        INTO staff_record
        FROM club_staff cs
        JOIN staff_referrals sr ON sr.staff_id = cs.id
        WHERE sr.id = NEW.staff_referral_id;
        
        -- Tính hoa hồng: amount × commission_rate / 100
        commission_amount_calc := NEW.amount * (staff_record.referral_rate / 100);
        
        -- Tự động tạo record hoa hồng
        INSERT INTO staff_commissions (
            staff_id, customer_transaction_id,
            commission_rate, transaction_amount, commission_amount
        ) VALUES (
            staff_record.id, NEW.id,
            staff_record.referral_rate, NEW.amount, commission_amount_calc
        );
        
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 📊 VÍ DỤ CỤ THỂ

### **Scenario**: Nhân viên Minh giới thiệu khách Hùng

1. **Setup ban đầu:**
   - Nhân viên Minh có commission_rate = 5%
   - Khách Hùng được Minh giới thiệu

2. **Khách Hùng đăng ký giải đấu phí 200,000 VND:**
```sql
INSERT INTO customer_transactions (
    customer_id: 'hung-123',
    amount: 200000,
    transaction_type: 'tournament_fee',
    staff_referral_id: 'minh-referral-456'
)
```

3. **TRIGGER tự động chạy:**
   - Tính hoa hồng: 200,000 × 5% = 10,000 VND
   - Tạo record trong `staff_commissions`
   - Cập nhật tổng earnings của Minh

4. **Kết quả:**
   - Minh nhận 10,000 VND hoa hồng
   - Có thể check trong app hoặc dashboard

## 🎯 LOẠI GIAO DỊCH CÓ HOA HỒNG

### **Có hoa hồng:**
- `tournament_fee` - Phí tham gia giải đấu
- `table_booking` - Đặt bàn chơi  
- `membership_fee` - Phí thành viên
- `merchandise` - Mua đồ tại club

### **Không có hoa hồng:**
- `refund` - Hoàn tiền
- `penalty` - Phí phạt
- `internal_transfer` - Chuyển khoản nội bộ

## 🔥 CÁC TRIGGER KHÁC

### **2. Update Staff Referral Totals**
```sql
-- Cập nhật tổng earnings khi có commission mới
CREATE TRIGGER trigger_update_staff_referral_totals_on_commission
    AFTER INSERT ON staff_commissions
    FOR EACH ROW
    EXECUTE FUNCTION update_staff_referral_totals();
```

### **3. Performance Tracking**
```sql  
-- Cập nhật performance stats theo thời gian thực
CREATE TRIGGER trigger_calculate_staff_commission
    AFTER INSERT ON customer_transactions
    FOR EACH ROW  
    EXECUTE FUNCTION calculate_staff_commission();
```

## 💸 THANH TOÁN HOA HỒNG

### **Tracking trạng thái:**
```sql
-- Hoa hồng chưa thanh toán
SELECT * FROM staff_commissions WHERE is_paid = false;

-- Đánh dấu đã thanh toán
UPDATE staff_commissions 
SET is_paid = true, paid_at = NOW(), payment_method = 'bank_transfer'
WHERE id = 'commission-id';
```

### **Báo cáo cho nhân viên:**
```sql
-- Tổng hoa hồng tháng này
SELECT SUM(commission_amount) as total_earnings
FROM staff_commissions  
WHERE staff_id = 'staff-id' 
AND earned_at >= date_trunc('month', CURRENT_DATE);
```

## 🚀 TÓM TẮT

**Nhân viên nhận hoa hồng HOÀN TOÀN TỰ ĐỘNG:**

1. ✅ **Real-time**: Ngay khi khách giao dịch
2. ✅ **Accurate**: Trigger đảm bảo không bỏ sót  
3. ✅ **Transparent**: Có thể track mọi giao dịch
4. ✅ **Flexible**: Tỷ lệ hoa hồng linh hoạt theo vai trò
5. ✅ **Secure**: RLS policies bảo vệ dữ liệu

**Nhân viên chỉ cần:**
- Giới thiệu khách hàng bằng QR code
- Hệ thống tự động tính và ghi nhận hoa hồng
- Xem báo cáo trong app để theo dõi earnings! 💰