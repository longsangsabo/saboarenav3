# 🔄 QUY TRÌNH HOẠT ĐỘNG HỆ THỐNG CHẤM CÔNG NHÂN VIÊN

## 🎯 TỔNG QUAN QUY TRÌNH

### **Flow từ Setup → Check-in → Payroll → Analytics**

```
📋 Setup Shifts → 🕐 Check-in/out → 📊 Track Hours → 💰 Calculate Pay → 📈 Analytics
```

---

## 📅 PHASE 1: THIẾT LẬP CA LÀM VIỆC

### **1.1 Club Owner tạo ca làm việc:**
```sql
-- Tạo ca sáng (6:00-14:00)
INSERT INTO staff_shifts (
    club_id, staff_id, shift_date,
    scheduled_start_time, scheduled_end_time
) VALUES (
    'club-123', 'staff-456', '2025-10-01',
    '06:00:00', '14:00:00'
);

-- Tạo ca chiều (14:00-22:00)  
INSERT INTO staff_shifts (
    club_id, staff_id, shift_date,
    scheduled_start_time, scheduled_end_time
) VALUES (
    'club-123', 'staff-789', '2025-10-01', 
    '14:00:00', '22:00:00'
);
```

### **1.2 Gửi thông báo cho nhân viên:**
```dart
// Tự động gửi notification
await NotificationService.sendShiftNotification(
  staffId: 'staff-456',
  message: 'Bạn có ca làm việc ngày mai 6:00-14:00',
  shiftId: 'shift-123'
);
```

---

## 🚪 PHASE 2: CHECK-IN PROCESS

### **2.1 Nhân viên đến club:**
- Mở SABO Arena app
- Chọn "Chấm công"
- Scan QR code tại quầy lễ tân

### **2.2 System xử lý check-in:**
```dart
Future<void> checkIn() async {
  // 1. Verify location (GPS trong bán kính 50m)
  final location = await getCurrentLocation();
  final isAtClub = await verifyClubLocation(location, clubId);
  
  if (!isAtClub) {
    throw Exception('Bạn phải ở trong khu vực club để chấm công');
  }
  
  // 2. Check if có shift hôm nay
  final todayShift = await getTodayShift(staffId);
  if (todayShift == null) {
    throw Exception('Bạn không có ca làm việc hôm nay');
  }
  
  // 3. Record check-in
  await supabase.from('staff_attendance').insert({
    'shift_id': todayShift.id,
    'staff_id': staffId,
    'club_id': clubId,
    'check_in_time': DateTime.now().toIso8601String(),
    'check_in_method': 'qr_code',
    'check_in_location': 'POINT(${location.lng} ${location.lat})',
  });
  
  // 4. Update shift status
  await supabase.from('staff_shifts')
    .update({'shift_status': 'in_progress'})
    .eq('id', todayShift.id);
}
```

### **2.3 Kiểm tra late/on-time:**
```sql
-- Trigger tự động tính late
CREATE OR REPLACE FUNCTION check_late_arrival()
RETURNS TRIGGER AS $$
DECLARE
    scheduled_start TIME;
    actual_start TIME;
    late_mins INTEGER;
BEGIN
    -- Lấy giờ scheduled
    SELECT scheduled_start_time INTO scheduled_start
    FROM staff_shifts WHERE id = NEW.shift_id;
    
    -- So sánh với actual check-in
    actual_start := NEW.check_in_time::TIME;
    late_mins := EXTRACT(EPOCH FROM (actual_start - scheduled_start)) / 60;
    
    -- Update late minutes nếu > 0
    IF late_mins > 0 THEN
        NEW.late_minutes := late_mins;
        
        -- Gửi notification cho manager
        INSERT INTO notifications (
            recipient_id, message, type
        ) VALUES (
            (SELECT owner_id FROM clubs WHERE id = NEW.club_id),
            NEW.staff_id || ' đã đi muộn ' || late_mins || ' phút',
            'late_arrival'
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## ⏰ PHASE 3: THEO DÕI GIỜ LÀM VIỆC

### **3.1 Real-time tracking:**
```dart
class AttendanceTracker {
  Timer? _timer;
  
  void startTracking(String attendanceId) {
    _timer = Timer.periodic(Duration(minutes: 15), (timer) async {
      // Update current status
      await updateWorkingStatus(attendanceId);
      
      // Check if still at location
      final location = await getCurrentLocation();
      final isStillAtClub = await verifyClubLocation(location, clubId);
      
      if (!isStillAtClub) {
        await recordLocationViolation(attendanceId, location);
      }
    });
  }
}
```

### **3.2 Break time tracking:**
```dart
Future<void> startBreak(String attendanceId) async {
  await supabase.from('staff_breaks').insert({
    'attendance_id': attendanceId,
    'break_start': DateTime.now().toIso8601String(),
    'break_type': 'lunch', // lunch, rest, emergency
  });
}

Future<void> endBreak(String breakId) async {
  await supabase.from('staff_breaks')
    .update({
      'break_end': DateTime.now().toIso8601String(),
    })
    .eq('id', breakId);
    
  // Auto-calculate break duration
  await calculateBreakDuration(breakId);
}
```

---

## 🚪 PHASE 4: CHECK-OUT PROCESS

### **4.1 Nhân viên check-out:**
```dart
Future<void> checkOut(String attendanceId) async {
  // 1. Verify location again
  final location = await getCurrentLocation();
  final isAtClub = await verifyClubLocation(location, clubId);
  
  // 2. Record check-out
  await supabase.from('staff_attendance')
    .update({
      'check_out_time': DateTime.now().toIso8601String(),
      'check_out_method': 'qr_code',
      'check_out_location': 'POINT(${location.lng} ${location.lat})',
    })
    .eq('id', attendanceId);
    
  // 3. Trigger sẽ tự động tính total hours
}
```

### **4.2 Trigger tự động tính giờ:**
```sql
CREATE OR REPLACE FUNCTION calculate_work_hours()
RETURNS TRIGGER AS $$
DECLARE
    total_hours NUMERIC;
    scheduled_hours NUMERIC;
    overtime_hours NUMERIC;
    break_time INTEGER;
BEGIN
    -- Tính tổng giờ làm
    total_hours := EXTRACT(EPOCH FROM (NEW.check_out_time - NEW.check_in_time)) / 3600;
    
    -- Trừ break time
    SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (break_end - break_start)) / 3600), 0)
    INTO break_time
    FROM staff_breaks WHERE attendance_id = NEW.id;
    
    total_hours := total_hours - break_time;
    
    -- Tính overtime (nếu > 8 giờ)
    scheduled_hours := 8; -- Default 8h/day
    overtime_hours := GREATEST(0, total_hours - scheduled_hours);
    
    -- Update record
    NEW.total_hours_worked := total_hours;
    UPDATE staff_shifts 
    SET overtime_hours = overtime_hours,
        shift_status = 'completed'
    WHERE id = NEW.shift_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 💰 PHASE 5: PAYROLL CALCULATION

### **5.1 Tính lương cuối tháng:**
```sql
-- Procedure tự động chạy cuối tháng
CREATE OR REPLACE FUNCTION calculate_monthly_payroll(p_club_id UUID, p_month INTEGER, p_year INTEGER)
RETURNS VOID AS $$
DECLARE
    staff_record RECORD;
    regular_hours NUMERIC;
    overtime_hours NUMERIC;
    commission_total NUMERIC;
    gross_pay NUMERIC;
BEGIN
    -- Loop qua tất cả nhân viên
    FOR staff_record IN 
        SELECT id, user_id, hourly_rate, base_salary 
        FROM club_staff 
        WHERE club_id = p_club_id AND is_active = true
    LOOP
        -- Tổng giờ regular trong tháng
        SELECT COALESCE(SUM(total_hours_worked), 0)
        INTO regular_hours
        FROM staff_attendance sa
        JOIN staff_shifts ss ON ss.id = sa.shift_id
        WHERE sa.staff_id = staff_record.id
        AND EXTRACT(MONTH FROM sa.check_in_time) = p_month
        AND EXTRACT(YEAR FROM sa.check_in_time) = p_year
        AND total_hours_worked <= 8;
        
        -- Tổng overtime
        SELECT COALESCE(SUM(overtime_hours), 0) 
        INTO overtime_hours
        FROM staff_shifts ss
        JOIN staff_attendance sa ON sa.shift_id = ss.id
        WHERE ss.staff_id = staff_record.id
        AND EXTRACT(MONTH FROM sa.check_in_time) = p_month
        AND EXTRACT(YEAR FROM sa.check_in_time) = p_year;
        
        -- Tổng commission trong tháng
        SELECT COALESCE(SUM(commission_amount), 0)
        INTO commission_total
        FROM staff_commissions
        WHERE staff_id = staff_record.id
        AND EXTRACT(MONTH FROM earned_at) = p_month
        AND EXTRACT(YEAR FROM earned_at) = p_year;
        
        -- Tính gross pay
        gross_pay := (regular_hours * staff_record.hourly_rate) + 
                     (overtime_hours * staff_record.hourly_rate * 1.5) + 
                     commission_total;
        
        -- Insert payroll record
        INSERT INTO staff_payroll (
            staff_id, club_id, pay_period_start, pay_period_end,
            regular_hours, overtime_hours, hourly_rate,
            commission_total, gross_pay, net_pay
        ) VALUES (
            staff_record.id, p_club_id,
            DATE(p_year || '-' || p_month || '-01'),
            (DATE(p_year || '-' || p_month || '-01') + INTERVAL '1 MONTH - 1 DAY'),
            regular_hours, overtime_hours, staff_record.hourly_rate,
            commission_total, gross_pay, gross_pay * 0.9 -- Giả sử tax 10%
        );
        
    END LOOP;
END;
$$ LANGUAGE plpgsql;
```

---

## 📊 PHASE 6: REAL-TIME ANALYTICS

### **6.1 Dashboard cho Club Owner:**
```dart
class AttendanceDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Real-time status
        _buildRealTimeStatus(),
        
        // Today's summary  
        _buildTodaySummary(),
        
        // Weekly trends
        _buildWeeklyTrends(),
        
        // Cost analysis
        _buildCostAnalysis(),
      ],
    );
  }
  
  Widget _buildRealTimeStatus() {
    return StreamBuilder<List<AttendanceStatus>>(
      stream: AttendanceService.getRealTimeStatus(clubId),
      builder: (context, snapshot) {
        final currentlyWorking = snapshot.data?.where((s) => s.isWorking).length ?? 0;
        final onBreak = snapshot.data?.where((s) => s.onBreak).length ?? 0;
        
        return Row(
          children: [
            StatusCard(
              title: 'Đang làm việc',
              value: '$currentlyWorking',
              color: Colors.green,
            ),
            StatusCard(
              title: 'Đang nghỉ',
              value: '$onBreak', 
              color: Colors.orange,
            ),
          ],
        );
      },
    );
  }
}
```

### **6.2 Performance correlation:**
```sql
-- View kết hợp attendance và commission
CREATE VIEW staff_performance_analysis AS
SELECT 
    cs.user_id,
    u.full_name,
    DATE_TRUNC('month', sa.check_in_time) as month,
    SUM(sa.total_hours_worked) as total_hours,
    COUNT(sa.id) as days_worked,
    SUM(sc.commission_amount) as total_commission,
    ROUND(SUM(sc.commission_amount) / SUM(sa.total_hours_worked), 2) as commission_per_hour,
    ROUND(AVG(sa.total_hours_worked), 2) as avg_hours_per_day
FROM staff_attendance sa
JOIN club_staff cs ON cs.id = sa.staff_id
JOIN users u ON u.id = cs.user_id
LEFT JOIN staff_commissions sc ON sc.staff_id = cs.id 
    AND DATE_TRUNC('month', sc.earned_at) = DATE_TRUNC('month', sa.check_in_time)
GROUP BY cs.user_id, u.full_name, DATE_TRUNC('month', sa.check_in_time)
ORDER BY month DESC, commission_per_hour DESC;
```

---

## 🔄 QUY TRÌNH TỔNG HỢP

### **Luồng hoạt động hàng ngày:**

```
🌅 06:00 - Setup: Club owner tạo shifts
🚪 06:00 - Check-in: Staff scan QR + GPS verify
⏰ 06:00-22:00 - Tracking: Real-time location + break time
🚪 22:00 - Check-out: Auto calculate hours + overtime
📊 22:30 - Analytics: Update dashboard + performance metrics
💰 Month-end - Payroll: Auto calculate salary + commission
```

### **Automation Points:**
- ✅ **Auto late detection** khi check-in
- ✅ **Real-time GPS tracking** trong ca làm
- ✅ **Auto calculate hours** khi check-out  
- ✅ **Auto overtime calculation**
- ✅ **Monthly payroll generation**
- ✅ **Performance analytics update**

### **Notifications:**
- 🔔 **Shift reminders** (1 ngày trước)
- 🔔 **Late arrival alerts** (cho manager)
- 🔔 **Long break warnings** (>30 phút)  
- 🔔 **End shift reminders** (15 phút trước kết ca)
- 🔔 **Payroll ready** (đầu tháng)

**Hệ thống hoạt động hoàn toàn tự động với minimal manual intervention!** 🤖✨