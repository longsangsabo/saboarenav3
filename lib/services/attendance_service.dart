import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:math';

class AttendanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =============================================
  // QR CODE VERIFICATION
  // =============================================

  /// Verify attendance QR code and location
  Future<Map<String, dynamic>> verifyAttendanceQR(String qrData) async {
    try {
      // Parse QR data
      final qrContent = jsonDecode(qrData);
      
      // Verify QR type
      if (qrContent['type'] != 'attendance') {
        throw Exception('QR code không hợp lệ cho chấm công');
      }

      final clubId = qrContent['club_id'];
      final qrSecret = qrContent['secret'];
      final qrLocation = qrContent['location'];

      // Verify club exists and secret matches
      final clubResponse = await _supabase
          .from('clubs')
          .select('id, name, qr_secret_key, latitude, longitude')
          .eq('id', clubId)
          .single();

      if (clubResponse['qr_secret_key'] != qrSecret) {
        throw Exception('QR code đã bị thay đổi hoặc giả mạo');
      }

      // Verify GPS location (within 50m radius)
      final currentLocation = await _getCurrentLocation();
      final clubLocation = Position(
        latitude: qrLocation['lat'].toDouble(),
        longitude: qrLocation['lng'].toDouble(),
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        clubLocation.latitude,
        clubLocation.longitude,
      );

      if (distance > 50) {
        throw Exception('Bạn phải ở trong khu vực club để chấm công (khoảng cách: ${distance.toInt()}m)');
      }

      return {
        'success': true,
        'club_id': clubId,
        'club_name': clubResponse['name'],
        'distance': distance.toInt(),
        'location': {
          'lat': currentLocation.latitude,
          'lng': currentLocation.longitude,
        }
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // =============================================
  // CHECK-IN/OUT OPERATIONS
  // =============================================

  /// Check in to work
  Future<Map<String, dynamic>> checkIn(String clubId, Map<String, dynamic> locationData) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Bạn cần đăng nhập để chấm công');
      }

      // Get staff record
      final staffResponse = await _supabase
          .from('club_staff')
          .select('id, user_id, club_id')
          .eq('user_id', currentUser.id)
          .eq('club_id', clubId)
          .eq('is_active', true)
          .single();

      final staffId = staffResponse['id'];

      // Check if already checked in today
      final isAlreadyCheckedIn = await _supabase.rpc('is_staff_checked_in', {
        'p_staff_id': staffId,
      });

      if (isAlreadyCheckedIn == true) {
        throw Exception('Bạn đã chấm công hôm nay rồi');
      }

      // Get today's shift
      final todayShiftResponse = await _supabase.rpc('get_today_shift', {
        'p_staff_id': staffId,
      });

      if (todayShiftResponse == null || (todayShiftResponse as List).isEmpty) {
        throw Exception('Bạn không có ca làm việc hôm nay');
      }

      final todayShift = (todayShiftResponse as List).first;
      final shiftId = todayShift['shift_id'];

      // Record check-in
      final checkInResponse = await _supabase
          .from('staff_attendance')
          .insert({
            'shift_id': shiftId,
            'staff_id': staffId,
            'club_id': clubId,
            'check_in_time': DateTime.now().toIso8601String(),
            'check_in_method': 'qr_code',
            'check_in_location': 'POINT(${locationData['lng']} ${locationData['lat']})',
            'check_in_device_info': await _getDeviceInfo(),
          })
          .select()
          .single();

      // Update shift status
      await _supabase
          .from('staff_shifts')
          .update({'shift_status': 'in_progress'})
          .eq('id', shiftId);

      return {
        'success': true,
        'message': 'Chấm công thành công!',
        'attendance_id': checkInResponse['id'],
        'check_in_time': checkInResponse['check_in_time'],
        'late_minutes': checkInResponse['late_minutes'] ?? 0,
        'shift_info': todayShift,
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Check out from work
  Future<Map<String, dynamic>> checkOut(String attendanceId, Map<String, dynamic> locationData) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Bạn cần đăng nhập để chấm công');
      }

      // Update check-out time
      final checkOutResponse = await _supabase
          .from('staff_attendance')
          .update({
            'check_out_time': DateTime.now().toIso8601String(),
            'check_out_method': 'qr_code',
            'check_out_location': 'POINT(${locationData['lng']} ${locationData['lat']})',
            'check_out_device_info': await _getDeviceInfo(),
          })
          .eq('id', attendanceId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Kết thúc ca làm việc thành công!',
        'check_out_time': checkOutResponse['check_out_time'],
        'total_hours': checkOutResponse['total_hours_worked'],
        'early_departure_minutes': checkOutResponse['early_departure_minutes'] ?? 0,
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // =============================================
  // BREAK MANAGEMENT
  // =============================================

  /// Start break
  Future<Map<String, dynamic>> startBreak(String attendanceId, String breakType, {String? reason}) async {
    try {
      final breakResponse = await _supabase
          .from('staff_breaks')
          .insert({
            'attendance_id': attendanceId,
            'break_start': DateTime.now().toIso8601String(),
            'break_type': breakType,
            'break_reason': reason,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'Bắt đầu nghỉ giải lao',
        'break_id': breakResponse['id'],
        'break_start': breakResponse['break_start'],
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// End break
  Future<Map<String, dynamic>> endBreak(String breakId) async {
    try {
      final breakResponse = await _supabase
          .from('staff_breaks')
          .update({
            'break_end': DateTime.now().toIso8601String(),
          })
          .eq('id', breakId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Kết thúc nghỉ giải lao',
        'break_end': breakResponse['break_end'],
        'break_duration': breakResponse['break_duration_minutes'],
      };

    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // =============================================
  // ATTENDANCE QUERIES
  // =============================================

  /// Get current attendance status
  Future<Map<String, dynamic>?> getCurrentAttendanceStatus() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('staff_attendance')
          .select('''
            id, check_in_time, check_out_time, attendance_status,
            total_hours_worked, late_minutes,
            staff_shifts!inner(
              id, shift_date, scheduled_start_time, scheduled_end_time,
              club_staff!inner(
                user_id,
                clubs!inner(id, name)
              )
            )
          ''')
          .eq('staff_shifts.club_staff.user_id', currentUser.id)
          .gte('check_in_time', DateTime.now().subtract(Duration(days: 1)).toIso8601String())
          .eq('attendance_status', 'checked_in')
          .order('check_in_time', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;

    } catch (e) {
      print('Error getting attendance status: $e');
      return null;
    }
  }

  /// Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory({int days = 30}) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('staff_attendance')
          .select('''
            id, check_in_time, check_out_time, 
            total_hours_worked, late_minutes, early_departure_minutes,
            staff_shifts!inner(
              shift_date, scheduled_start_time, scheduled_end_time,
              club_staff!inner(
                user_id,
                clubs!inner(id, name)
              )
            )
          ''')
          .eq('staff_shifts.club_staff.user_id', currentUser.id)
          .gte('check_in_time', DateTime.now().subtract(Duration(days: days)).toIso8601String())
          .order('check_in_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  /// Get today's shifts for staff member
  Future<List<Map<String, dynamic>>> getTodayShifts() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('staff_shifts')
          .select('''
            id, shift_date, scheduled_start_time, scheduled_end_time, shift_status,
            club_staff!inner(
              user_id,
              clubs!inner(id, name)
            )
          ''')
          .eq('club_staff.user_id', currentUser.id)
          .eq('shift_date', DateTime.now().toIso8601String().split('T')[0])
          .order('scheduled_start_time');

      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      print('Error getting today shifts: $e');
      return [];
    }
  }

  // =============================================
  // UTILITY FUNCTIONS
  // =============================================

  /// Get current GPS location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị chưa được bật');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get device information for security
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // Simple device info for now
    return {
      'platform': 'flutter',
      'timestamp': DateTime.now().toIso8601String(),
      'user_agent': 'SABO Arena Mobile App',
    };
  }

  /// Calculate distance between two points
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}