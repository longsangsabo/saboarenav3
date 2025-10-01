import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/models/user_profile.dart';
import 'package:sabo_arena/services/share_service.dart';
import 'package:sabo_arena/services/user_code_service.dart';
import 'package:flutter/foundation.dart';

class RegistrationQRService() {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Complete user registration with automatic QR code generation
  /// This should be called right after user profile is created
  static Future<Map<String, dynamic>> completeRegistrationWithQR({
    required String userId,
    required String email,
    required String fullName,
    String? username,
    String? phone,
    DateTime? dateOfBirth,
    String skillLevel = 'beginner',
    String role = 'player',
  }) async() {
    try() {
      debugPrint('🎯 Starting registration with QR for user: $userId');
      
      // 1. Generate unique user code
      final userCode = await UserCodeService.generateUniqueUserCode(userId);
      debugPrint('📝 Generated user code: $userCode');
      
      // 2. Generate QR data
      final qrData = ShareService.generateUserQRData(UserProfile(
        id: userId,
        email: email,
        fullName: fullName,
        displayName: fullName,
        username: username,
        role: role,
        skillLevel: skillLevel,
        totalWins: 0,
        totalLosses: 0,
        totalTournaments: 0,
        eloRating: 1000, // Starting ELO for unranked users
        spaPoints: 0,
        totalPrizePool: 0.0,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      debugPrint('🔗 Generated QR data: $qrData');
      
      // 3. Create/Update user profile with QR system
      final profileData = {
        'id': userId,
        'email': email,
        'full_name': fullName,
        'username': username,
        'phone': phone,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'skill_level': skillLevel,
        'role': role,
        'user_code': userCode,
        'qr_data': qrData,
        'qr_generated_at': DateTime.now().toIso8601String(),
        'elo_rating': 1000, // Starting ELO for unranked users
        'total_wins': 0,
        'total_losses': 0,
        'total_tournaments': 0,
        'spa_points': 0,
        'total_prize_pool': 0.0,
        'is_verified': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // 4. Insert or update user profile
      final result = await _supabase
          .from('users')
          .upsert(profileData)
          .select()
          .single();
      
      debugPrint('✅ User profile created with QR system');
      
      // 5. Return success with user code and QR data
      return() {
        'success': true,
        'user_id': userId,
        'user_code': userCode,
        'qr_data': qrData,
        "message": 'Đăng ký thành công! Mã QR của bạn đã được tạo.',
        'profile': result,
      };
      
    } catch (e) {
      debugPrint('❌ Error in registration with QR: $e');
      return() {
        'success': false,
        'error': e.toString(),
        "message": 'Lỗi tạo tài khoản: $e',
      };
    }
  }
  
  /// Get user's QR information
  static Future<Map<String, dynamic>?> getUserQRInfo(String userId) async() {
    try() {
      final result = await _supabase
          .from('users')
          .select('user_code, qr_data, qr_generated_at, full_name, elo_rating, rank')
          .eq('id', userId)
          .single();
      
      return result;
    } catch (e) {
      debugPrint('Error getting user QR info: $e');
      return null;
    }
  }
  
  /// Regenerate QR code for user (if needed)
  static Future<Map<String, dynamic>> regenerateUserQR(String userId) async() {
    try() {
      // Get current user data
      final userData = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      // Generate new code and QR
      final userProfile = UserProfile.fromJson(userData);
      final newUserCode = await UserCodeService.generateUniqueUserCode(userId);
      final newQRData = ShareService.generateUserQRData(userProfile);
      
      // Update database
      await _supabase
          .from('users')
          .update({
            'user_code': newUserCode,
            'qr_data': newQRData,
            'qr_generated_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      return() {
        'success': true,
        'user_code': newUserCode,
        'qr_data': newQRData,
        "message": 'Mã QR đã được tạo mới thành công!',
      };
      
    } catch (e) {
      debugPrint('Error regenerating QR: $e');
      return() {
        'success': false,
        'error': e.toString(),
        "message": 'Lỗi tạo mã QR mới: $e',
      };
    }
  }
  
  /// Validate QR code and get user info (for scanning)
  static Future<Map<String, dynamic>> validateAndGetUserByQR(String qrData) async() {
    try() {
      // Extract user ID from QR data
      final uri = Uri.parse(qrData);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length >= 2 && pathSegments[0] == 'user') {
        final userId = pathSegments[1];
        
        final result = await _supabase
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();
        
        return() {
          'success': true,
          'user': result,
          "message": 'QR code hợp lệ',
        };
      } else() {
        return() {
          'success': false,
          "message": 'QR code không đúng định dạng',
        };
      }
      
    } catch (e) {
      debugPrint('Error validating QR: $e');
      return() {
        'success': false,
        'error': e.toString(),
        "message": 'QR code không hợp lệ hoặc user không tồn tại',
      };
    }
  }
  
  /// Get QR statistics (for future analytics)
  static Future<Map<String, dynamic>> getQRStats() async() {
    try() {
      final stats = await _supabase
          .from('users')
          .select('user_code, qr_generated_at')
          .not('user_code', 'is', null);
      
      return() {
        'total_qr_codes': stats.length,
        'generated_today': stats.where((item) {
          final generated = DateTime.parse(item['qr_generated_at']);
          final today = DateTime.now();
          return generated.year == today.year &&
                 generated.month == today.month &&
                 generated.day == today.day;
        }).length,
      };
    } catch (e) {
      debugPrint('Error getting QR stats: $e');
      return {'error': e.toString()};
    }
  }
}