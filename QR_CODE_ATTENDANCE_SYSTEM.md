# 📱 QR CODE SYSTEM CHO CHẤM CÔNG NHÂN VIÊN

## 🎯 TỔNG QUAN HỆ THỐNG QR

### **Có 2 cách tiếp cận QR Code:**

```
🏢 CÁCH 1: QR Code cố định tại club (Static QR)
📱 CÁCH 2: QR Code động từ app manager (Dynamic QR)
```

---

## 🏢 PHƯƠNG ÁN 1: STATIC QR CODE (Khuyên dùng)

### **1.1 Setup ban đầu:**
```sql
-- Tạo QR code cho mỗi club
ALTER TABLE clubs ADD COLUMN attendance_qr_code TEXT;
ALTER TABLE clubs ADD COLUMN qr_secret_key TEXT;

-- Generate QR cho club
UPDATE clubs 
SET attendance_qr_code = 'SABO_ATTENDANCE_' || id || '_' || EXTRACT(EPOCH FROM NOW()),
    qr_secret_key = gen_random_uuid()::TEXT
WHERE id = 'your-club-id';
```

### **1.2 QR Code content:**
```json
{
  "type": "attendance",
  "club_id": "club-uuid-here",
  "location": {
    "lat": 10.7769,
    "lng": 106.7009
  },
  "secret": "club-secret-key",
  "expires": null,
  "created_at": "2025-09-30T10:00:00Z"
}
```

### **1.3 Physical placement:**
- 🏢 **Tại quầy lễ tân** - vị trí chính
- 🚪 **Gần cửa ra vào** - backup location  
- 📋 **Ốp tường cố định** - không di chuyển được
- 🔐 **Có khung bảo vệ** - chống vandalism

### **1.4 Quy trình scan:**
```dart
// 1. Staff mở app
// 2. Chọn "Chấm công"  
// 3. Camera scan QR
// 4. System verify:

Future<bool> verifyAttendanceQR(String qrData) async {
  try {
    // Parse QR data
    final qrContent = jsonDecode(qrData);
    
    // Verify type
    if (qrContent['type'] != 'attendance') {
      throw Exception('QR code không hợp lệ');
    }
    
    // Verify club exists
    final club = await supabase
      .from('clubs')
      .select('id, qr_secret_key, name')
      .eq('id', qrContent['club_id'])
      .single();
    
    // Verify secret
    if (club['qr_secret_key'] != qrContent['secret']) {
      throw Exception('QR code đã bị thay đổi hoặc giả mạo');
    }
    
    // Verify location (GPS distance)
    final currentLocation = await getCurrentLocation();
    final clubLocation = LatLng(
      qrContent['location']['lat'], 
      qrContent['location']['lng']
    );
    
    final distance = calculateDistance(currentLocation, clubLocation);
    if (distance > 50) { // 50m radius
      throw Exception('Bạn phải ở trong khu vực club để chấm công');
    }
    
    return true;
    
  } catch (e) {
    print('QR verification failed: $e');
    return false;
  }
}
```

---

## 📱 PHƯƠNG ÁN 2: DYNAMIC QR CODE 

### **2.1 Manager generates QR:**
```dart
// Club manager/owner tạo QR theo session
Future<String> generateSessionQR(String clubId) async {
  final session = {
    'type': 'attendance_session',
    'club_id': clubId,
    'session_id': Uuid().v4(),
    'created_by': currentUserId,
    'expires_at': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
    'location': await getCurrentLocation(),
  };
  
  // Save to database
  await supabase.from('attendance_sessions').insert(session);
  
  // Generate QR string
  return jsonEncode(session);
}
```

### **2.2 QR có thời hạn:**
```sql
-- Bảng lưu session
CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID REFERENCES clubs(id),
    session_id TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    location GEOGRAPHY(POINT),
    
    -- Tracking
    total_checkins INTEGER DEFAULT 0
);

-- Auto cleanup expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS VOID AS $$
BEGIN
    UPDATE attendance_sessions 
    SET is_active = false 
    WHERE expires_at < NOW() AND is_active = true;
END;
$$ LANGUAGE plpgsql;
```

---

## ⚖️ SO SÁNH 2 PHƯƠNG ÁN

| Tiêu chí | Static QR | Dynamic QR |
|----------|-----------|------------|
| **Setup** | ✅ Đơn giản, 1 lần | 🔶 Phức tạp, nhiều bước |
| **Security** | 🔶 Cố định, dễ copy | ✅ Thay đổi, khó fake |
| **Convenience** | ✅ Luôn có sẵn | 🔶 Manager phải tạo |
| **Maintenance** | ✅ Không cần bảo trì | 🔶 Cần cleanup sessions |
| **Cost** | ✅ Rẻ (in 1 lần) | 🔶 Tốn tài nguyên server |
| **User Experience** | ✅ Nhanh, đơn giản | 🔶 Phải đợi manager |

---

## 🎯 KHUYẾN NGHỊ: HYBRID APPROACH

### **Kết hợp cả 2 để tối ưu:**

```dart
class AttendanceQRService {
  
  // Method 1: Static QR (primary)
  Future<bool> scanStaticQR(String qrData) async {
    // Verify như ở trên
    final isValid = await verifyAttendanceQR(qrData);
    
    if (isValid) {
      await recordAttendance(qrData, 'static_qr');
      return true;
    }
    return false;
  }
  
  // Method 2: Dynamic QR (backup/special cases)
  Future<bool> scanDynamicQR(String qrData) async {
    final session = jsonDecode(qrData);
    
    // Check session validity
    final sessionRecord = await supabase
      .from('attendance_sessions')
      .select()
      .eq('session_id', session['session_id'])
      .eq('is_active', true)
      .single();
    
    if (sessionRecord == null) {
      throw Exception('Session đã hết hạn');
    }
    
    await recordAttendance(qrData, 'dynamic_qr');
    return true;
  }
  
  // Smart scanner - tự detect loại QR
  Future<bool> smartScan(String qrData) async {
    try {
      final content = jsonDecode(qrData);
      
      if (content['type'] == 'attendance') {
        return await scanStaticQR(qrData);
      } else if (content['type'] == 'attendance_session') {
        return await scanDynamicQR(qrData);
      }
      
      throw Exception('QR code không được hỗ trợ');
      
    } catch (e) {
      print('Smart scan failed: $e');
      return false;
    }
  }
}
```

---

## 🖼️ QR CODE DESIGN

### **Thiết kế QR vật lý:**

```
┌─────────────────────────────────┐
│  🏢 SABO ARENA - CHẤM CÔNG      │
│                                 │
│  ████████████████████████████   │
│  ██ ▄▄▄▄▄ █▀█ █▄█ █ ▄▄▄▄▄ ██   │
│  ██ █   █ █▄▄ ▄ ▄█ █ █   █ ██   │
│  ██ █▄▄▄█ █ █▀▀█▀█ █ █▄▄▄█ ██   │
│  ██▄▄▄▄▄▄▄█ █ █ █▄█▄▄▄▄▄▄▄██   │
│  ██▄▄█▀▄▄▄▀▀█▄█▄▄▄█▄▄▄ ▀▄▄██   │
│  ████████████████████████████   │
│                                 │
│  📱 Mở SABO Arena App           │
│  👆 Chọn "Chấm công"           │
│  📸 Quét mã này                 │
│                                 │
│  ⚠️  CHỈ DÀNH CHO NHÂN VIÊN     │
└─────────────────────────────────┘
```

### **Thông tin bảo mật:**
- ✅ **Watermark logo** SABO Arena
- ✅ **Unique club identifier** 
- ✅ **Secret verification key**
- ✅ **GPS coordinates** embedded
- ✅ **Tamper-evident** material

---

## 🛡️ SECURITY MEASURES

### **Chống gian lận:**

```dart
class AttendanceSecurityService {
  
  // 1. Location verification (multiple checks)
  Future<bool> verifyLocation(LatLng qrLocation) async {
    final currentLocation = await getCurrentLocation();
    final distance = calculateDistance(currentLocation, qrLocation);
    
    // Check GPS accuracy
    final accuracy = await LocationAccuracy.get();
    if (accuracy > 10) { // >10m accuracy = suspicious
      await logSecurityEvent('low_gps_accuracy', accuracy);
    }
    
    return distance <= 50; // 50m radius
  }
  
  // 2. Time-based validation
  Future<bool> validateTimeWindow(String staffId) async {
    final lastCheckin = await getLastCheckin(staffId);
    
    // Prevent multiple checkins within 1 hour
    if (lastCheckin != null) {
      final timeDiff = DateTime.now().difference(lastCheckin.checkInTime);
      if (timeDiff.inMinutes < 60) {
        throw Exception('Bạn đã chấm công rồi, không thể chấm lại trong 1 giờ');
      }
    }
    
    return true;
  }
  
  // 3. Device fingerprinting
  Future<String> getDeviceFingerprint() async {
    final deviceId = await DeviceInfo.getDeviceId();
    final model = await DeviceInfo.getModel();
    final os = await DeviceInfo.getOS();
    
    return '$deviceId-$model-$os';
  }
  
  // 4. Anomaly detection
  Future<void> detectAnomalies(String staffId, Map<String, dynamic> checkinData) async {
    // Check unusual patterns
    final history = await getAttendanceHistory(staffId, days: 30);
    
    // Pattern analysis
    if (isUnusualTime(checkinData['time'], history)) {
      await flagForReview(staffId, 'unusual_time_pattern');
    }
    
    if (isUnusualLocation(checkinData['location'], history)) {
      await flagForReview(staffId, 'unusual_location_pattern');
    }
  }
}
```

---

## 🎛️ ADMIN CONTROLS

### **Club owner dashboard:**
```dart
class QRManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current QR status
        _buildQRStatus(),
        
        // Regenerate QR (if needed)
        _buildRegenerateButton(),
        
        // Recent scans
        _buildRecentScans(),
        
        // Security alerts
        _buildSecurityAlerts(),
      ],
    );
  }
  
  Widget _buildRegenerateButton() {
    return ElevatedButton(
      onPressed: () async {
        // Only in emergency cases
        final confirm = await showConfirmDialog(
          'Tạo mã QR mới sẽ vô hiệu hóa mã cũ. Tiếp tục?'
        );
        
        if (confirm) {
          await regenerateQRCode(clubId);
          await notifyAllStaff('QR code đã được cập nhật');
        }
      },
      child: Text('🔄 Tạo mã QR mới'),
    );
  }
}
```

**Vậy bạn thích phương án nào? Static QR đơn giản hay Dynamic QR bảo mật hơn?** 🤔