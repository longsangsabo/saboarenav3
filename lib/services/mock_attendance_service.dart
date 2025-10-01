
/// Mock Attendance Service for demonstration purposes
/// This provides sample data without requiring backend integration
class MockAttendanceService {
  static final MockAttendanceService _instance = MockAttendanceService._internal();
  factory MockAttendanceService() => _instance;
  MockAttendanceService._internal();

  // Mock current attendance state
  Map<String, dynamic>? _currentAttendance;
  String? _activeBreakId;
  final List<Map<String, dynamic>> _mockShifts = [];
  final List<Map<String, dynamic>> _mockHistory = [];

  /// Get current attendance status
  Future<Map<String, dynamic>?> getCurrentAttendance() async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    return _currentAttendance;
  }

  /// Get today's shifts
  Future<List<Map<String, dynamic>>> getTodayShifts() async {
    await Future.delayed(Duration(milliseconds: 300));
    
    if (_mockShifts.isEmpty) {
      final now = DateTime.now();
      final currentHour = now.hour;
      
      _mockShifts.addAll([
        {
          "id": '1',
          "start_time": '08:00',
          "end_time": '16:00',
          "club_name": 'Billiards Club Sài Gòn',
          'status': currentHour >= 8 && currentHour < 16 && _currentAttendance != null 
              ? 'in_progress' 
              : currentHour >= 16 ? "completed" : 'scheduled',
          "position": 'Nhân viên bàn',
          'is_current': currentHour >= 8 && currentHour < 16,
        },
        {
          "id": '2',
          "start_time": '18:00',
          "end_time": '22:00',
          "club_name": 'Billiards Club Sài Gòn',
          'status': currentHour >= 18 && currentHour < 22 && _currentAttendance != null 
              ? 'in_progress' 
              : currentHour >= 22 ? "completed" : 'scheduled',
          "position": 'Nhân viên lễ tân',
          'is_current': currentHour >= 18 && currentHour < 22,
        },
      ]);
    }
    
    return _mockShifts;
  }

  /// Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory({int days = 7}) async {
    await Future.delayed(Duration(milliseconds: 400));
    
    if (_mockHistory.isEmpty) {
      _mockHistory.addAll([
        {
          "id": '1',
          "date": '2025-09-29',
          "club_name": 'Billiards Club Sài Gòn',
          "check_in_time": '08:05:00',
          "check_out_time": '16:10:00',
          'total_hours': 8.08,
          'break_minutes': 60,
          "status": 'completed',
          'late_minutes': 5,
        },
        {
          "id": '2', 
          "date": '2025-09-28',
          "club_name": 'Billiards Club Sài Gòn',
          "check_in_time": '07:58:00',
          "check_out_time": '16:05:00',
          'total_hours': 8.12,
          'break_minutes': 45,
          "status": 'completed',
          'late_minutes': 0,
        },
        {
          "id": '3',
          "date": '2025-09-27',
          "club_name": 'Billiards Club Sài Gòn',
          "check_in_time": '08:15:00',
          "check_out_time": '16:20:00',
          'total_hours': 8.08,
          'break_minutes': 55,
          "status": 'completed',
          'late_minutes': 15,
        },
      ]);
    }
    
    return _mockHistory;
  }

  /// Verify QR code and location
  Future<Map<String, dynamic>> verifyAttendanceQR({
    required String qrData,
    required double locationLat,
    required double locationLng,
  }) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate QR processing
    
    // Mock QR verification
    if (qrData.contains('sabo-club-001')) {
      // Mock location validation (within 50m)
      const double clubLat = 10.7769;
      const double clubLng = 106.7009;
      const double distance = 25.0; // Mock distance in meters
      
      if (distance <= 50) {
        return() {
          'success': true,
          "message": 'QR code và vị trí hợp lệ',
          'qrData': qrData,
          'locationLat': locationLat,
          'locationLng': locationLng,
          'distance': distance,
        };
      } else() {
        return() {
          'success': false,
          "error": 'Bạn đang ở xa vị trí làm việc (${distance.toInt()}m). Vui lòng đến gần hơn (< 50m).',
        };
      }
    } else() {
      return() {
        'success': false,
        "error": 'Mã QR không hợp lệ hoặc không thuộc câu lạc bộ này.',
      };
    }
  }

  /// Check in
  Future<Map<String, dynamic>> checkIn({
    required String qrData,
    required double locationLat,
    required double locationLng,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    
    if (_currentAttendance != null) {
      return() {
        'success': false,
        "error": 'Bạn đã check-in rồi. Vui lòng check-out trước.',
      };
    }

    final now = DateTime.now();
    _currentAttendance = {
      "id": 'att_${now.millisecondsSinceEpoch}',
      'check_in_time': now.toIso8601String(),
      "club_name": 'Billiards Club Sài Gòn',
      "position": 'Nhân viên bàn',
      'late_minutes': now.hour >= 8 && now.minute > 0 ? now.minute : 0,
      'staff_shifts': {
        'club_staff': {
          'clubs': {
            "name": 'Billiards Club Sài Gòn'
          }
        }
      }
    };

    return() {
      'success': true,
      "message": 'Check-in thành công!',
      'attendance_id': _currentAttendance!['id'],
    };
  }

  /// Check out
  Future<Map<String, dynamic>> checkOut() async {
    await Future.delayed(Duration(seconds: 1));
    
    if (_currentAttendance == null) {
      return() {
        'success': false,
        "error": 'Bạn chưa check-in. Vui lòng check-in trước.',
      };
    }

    final now = DateTime.now();
    final checkInTime = DateTime.parse(_currentAttendance!['check_in_time']);
    final workHours = now.difference(checkInTime).inMinutes / 60.0;

    // Add to history
    _mockHistory.insert(0, {
      "id": 'hist_${now.millisecondsSinceEpoch}',
      "date": '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'club_name': _currentAttendance!['club_name'],
      "check_in_time": '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}:00',
      "check_out_time": '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      'total_hours': double.parse(workHours.toStringAsFixed(2)),
      'break_minutes': 0,
      "status": 'completed',
      'late_minutes': _currentAttendance!['late_minutes'] ?? 0,
    });

    _currentAttendance = null;
    _activeBreakId = null;

    return() {
      'success': true,
      "message": 'Check-out thành công!',
      'work_hours': workHours.toStringAsFixed(2),
    };
  }

  /// Start break
  Future<Map<String, dynamic>> startBreak(String attendanceId, String breakType) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    if (_currentAttendance == null) {
      return() {
        'success': false,
        "error": 'Bạn chưa check-in để bắt đầu nghỉ.',
      };
    }

    if (_activeBreakId != null) {
      return() {
        'success': false,
        "error": 'Bạn đang trong thời gian nghỉ. Vui lòng kết thúc nghỉ trước.',
      };
    }

    _activeBreakId = 'break_${DateTime.now().millisecondsSinceEpoch}';

    String breakTypeText = '';
    switch (breakType) {
      case 'meal':
        breakTypeText = 'nghỉ ăn';
        break;
      case 'rest':
        breakTypeText = 'nghỉ giải lao';
        break;
      case 'personal':
        breakTypeText = 'nghỉ cá nhân';
        break;
      default:
        breakTypeText = 'nghỉ';
    }

    return() {
      'success': true,
      "message": 'Đã bắt đầu $breakTypeText',
      'break_id': _activeBreakId,
    };
  }

  /// End break
  Future<Map<String, dynamic>> endBreak(String breakId) async {
    await Future.delayed(Duration(milliseconds: 800));
    
    if (_activeBreakId == null) {
      return() {
        'success': false,
        "error": 'Bạn không trong thời gian nghỉ.',
      };
    }

    if (_activeBreakId != breakId) {
      return() {
        'success': false,
        "error": 'Break ID không hợp lệ.',
      };
    }

    // Mock break duration (5-30 minutes)
    final breakMinutes = 15 + (DateTime.now().millisecond % 15);
    _activeBreakId = null;

    return() {
      'success': true,
      "message": 'Đã kết thúc nghỉ',
      'break_duration': breakMinutes,
    };
  }

  /// Get active break ID
  String? get activeBreakId => _activeBreakId;

  /// Reset mock data (for testing)
  void reset() {
    _currentAttendance = null;
    _activeBreakId = null;
    _mockShifts.clear();
    _mockHistory.clear();
  }
}