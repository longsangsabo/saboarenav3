# 🕐 TÍNH NĂNG CHẤM CÔNG NHÂN VIÊN - ANALYSIS & PROPOSAL

## 🎯 WHY THIS FEATURE IS GREAT

### **Perfect Integration với hệ thống hiện tại:**
- ✅ Đã có `club_staff` table với nhân viên
- ✅ Đã có staff roles và permissions
- ✅ Có thể liên kết với commission system
- ✅ Club owner dashboard đã sẵn sàng

### **Business Value:**
- 📊 **Theo dõi hiệu suất**: Giờ làm việc vs doanh thu/hoa hồng
- 💰 **Tính lương chính xác**: Base salary + commission
- 📈 **KPI Management**: Đánh giá nhân viên dựa trên data
- 🔒 **Compliance**: Tuân thủ luật lao động

## 🏗️ TECHNICAL ARCHITECTURE

### **Database Schema Mở Rộng:**

```sql
-- 1. Bảng ca làm việc
CREATE TABLE staff_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id),
    staff_id UUID REFERENCES club_staff(id),
    shift_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    actual_start_time TIME,
    actual_end_time TIME,
    break_duration_minutes INTEGER DEFAULT 0,
    overtime_hours NUMERIC(4,2) DEFAULT 0,
    shift_status VARCHAR(20) DEFAULT 'scheduled', -- scheduled, in_progress, completed, absent, late
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Bảng chấm công chi tiết  
CREATE TABLE staff_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shift_id UUID REFERENCES staff_shifts(id),
    staff_id UUID REFERENCES club_staff(id),
    club_id UUID REFERENCES clubs(id),
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    check_in_method VARCHAR(20), -- qr_code, manual, biometric, gps
    check_out_method VARCHAR(20),
    check_in_location POINT, -- GPS coordinates
    check_out_location POINT,
    total_hours_worked NUMERIC(4,2),
    late_minutes INTEGER DEFAULT 0,
    early_leave_minutes INTEGER DEFAULT 0,
    is_approved BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES club_staff(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Bảng lương và thưởng
CREATE TABLE staff_payroll (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES club_staff(id),
    club_id UUID REFERENCES clubs(id),
    pay_period_start DATE NOT NULL,
    pay_period_end DATE NOT NULL,
    regular_hours NUMERIC(6,2) DEFAULT 0,
    overtime_hours NUMERIC(6,2) DEFAULT 0,
    hourly_rate NUMERIC(10,2),
    base_salary NUMERIC(12,2),
    commission_total NUMERIC(12,2) DEFAULT 0,
    bonus NUMERIC(12,2) DEFAULT 0,
    deductions NUMERIC(12,2) DEFAULT 0,
    gross_pay NUMERIC(12,2),
    net_pay NUMERIC(12,2),
    pay_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, paid
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### **Triggers & Functions:**

```sql
-- Tự động tính giờ làm khi check-out
CREATE OR REPLACE FUNCTION calculate_attendance_hours()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_out_time IS NOT NULL AND NEW.check_in_time IS NOT NULL THEN
        NEW.total_hours_worked := EXTRACT(EPOCH FROM (NEW.check_out_time - NEW.check_in_time)) / 3600;
        
        -- Tính late/early leave
        SELECT scheduled_start_time, scheduled_end_time
        INTO NEW.late_minutes, NEW.early_leave_minutes  
        FROM staff_shifts WHERE id = NEW.shift_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_attendance_trigger
    BEFORE UPDATE ON staff_attendance
    FOR EACH ROW
    EXECUTE FUNCTION calculate_attendance_hours();
```

## 📱 FLUTTER IMPLEMENTATION

### **Service Layer:**

```dart
class StaffAttendanceService {
  // Chấm công check-in
  Future<void> checkIn({
    required String staffId,
    required String clubId,
    String method = 'manual',
    LatLng? location,
  }) async {
    await _supabase.from('staff_attendance').insert({
      'staff_id': staffId,
      'club_id': clubId,
      'check_in_time': DateTime.now().toIso8601String(),
      'check_in_method': method,
      'check_in_location': location != null 
        ? 'POINT(${location.longitude} ${location.latitude})' 
        : null,
    });
  }

  // Chấm công check-out
  Future<void> checkOut({
    required String attendanceId,
    LatLng? location,
  }) async {
    await _supabase.from('staff_attendance')
      .update({
        'check_out_time': DateTime.now().toIso8601String(),
        'check_out_method': 'manual',
        'check_out_location': location != null 
          ? 'POINT(${location.longitude} ${location.latitude})' 
          : null,
      })
      .eq('id', attendanceId);
  }

  // Lấy báo cáo chấm công
  Future<List<Map<String, dynamic>>> getAttendanceReport({
    required String clubId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = _supabase
      .from('staff_attendance')
      .select('''
        *, 
        staff:club_staff(user_id, users(full_name)),
        shift:staff_shifts(shift_date, scheduled_start_time, scheduled_end_time)
      ''')
      .eq('club_id', clubId);
      
    if (startDate != null) {
      query.gte('check_in_time', startDate.toIso8601String());
    }
    
    return await query;
  }
}
```

### **UI Components:**

```dart
class StaffAttendanceScreen extends StatefulWidget {
  final String clubId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chấm công nhân viên')),
      body: TabBarView(
        children: [
          // Tab 1: Real-time attendance
          _buildRealTimeAttendance(),
          
          // Tab 2: Attendance reports  
          _buildAttendanceReports(),
          
          // Tab 3: Shift management
          _buildShiftManagement(),
          
          // Tab 4: Payroll calculation
          _buildPayrollSummary(),
        ],
      ),
    );
  }
}
```

## 🎯 CORE FEATURES

### **1. Multiple Check-in Methods:**
- ✅ **QR Code**: Scan QR tại club (most secure)
- ✅ **GPS Location**: Check-in trong radius club
- ✅ **Manual**: Club owner/manager approve
- ✅ **Biometric**: Face/fingerprint (future)

### **2. Smart Attendance Tracking:**
- ⏰ **Auto-calculate hours**: Regular + Overtime
- 🚨 **Late/Early alerts**: Real-time notifications
- 📍 **Location verification**: GPS fence around club
- 🔄 **Shift swapping**: Staff can exchange shifts

### **3. Advanced Analytics:**
- 📊 **Attendance rate**: Per staff, per period
- 💰 **Cost analysis**: Labor cost vs revenue
- 📈 **Performance correlation**: Hours worked vs commission earned
- 🎯 **Scheduling optimization**: Best staff for peak hours

### **4. Payroll Integration:**
- 💵 **Auto-calculate salary**: Base + Commission + Overtime
- 📋 **Export payslips**: PDF generation
- 🏦 **Payment tracking**: Integration with banking
- 📊 **Tax reporting**: Compliance features

## 🚀 IMPLEMENTATION PHASES

### **Phase 1: Basic Attendance (2-3 days)**
- Database schema
- Check-in/Check-out functionality  
- Basic reporting

### **Phase 2: Advanced Features (3-4 days)**
- QR Code integration
- GPS location verification
- Shift scheduling system

### **Phase 3: Analytics & Payroll (2-3 days)** 
- Advanced reporting dashboard
- Payroll calculation
- Performance analytics

### **Phase 4: Mobile App Integration (2-3 days)**
- Staff mobile check-in app
- Push notifications
- Offline capability

## 💡 BUSINESS IMPACT

### **For Club Owners:**
- 📉 **Reduce labor costs**: Eliminate time theft
- 📊 **Data-driven decisions**: Staff performance insights  
- ⏱️ **Save admin time**: Automated payroll
- 🎯 **Optimize scheduling**: Right staff at right time

### **For Staff:**
- 📱 **Convenient check-in**: Quick QR scan
- 💰 **Transparent pay**: See earnings real-time
- 🔄 **Flexible scheduling**: Shift swapping
- 🏆 **Performance tracking**: Personal KPIs

## 🎯 RECOMMENDATION

**TÔI HIGHLY RECOMMEND phát triển tính năng này vì:**

1. ✅ **Perfect fit**: Bổ sung tự nhiên cho staff management system
2. ✅ **High ROI**: Giải quyết pain point thực tế của club owners
3. ✅ **Technical synergy**: Leverage existing infrastructure
4. ✅ **Scalable**: Có thể mở rộng thành HR suite hoàn chỉnh
5. ✅ **Competitive advantage**: Ít competitor có feature này

**Bạn có muốn bắt đầu implement không?** 🚀