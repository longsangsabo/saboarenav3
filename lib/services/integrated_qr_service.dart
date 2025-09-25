import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/models/user_profile.dart';
import 'package:sabo_arena/services/user_code_service.dart';
import 'basic_referral_service.dart';

class IntegratedQRService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _baseUrl = 'https://saboarena.com';
  
  /// Generate integrated QR data that contains both profile and referral info
  static String generateIntegratedQRData({
    required String userId,
    required String userCode,
    required String referralCode,
  }) {
    // URL format: https://saboarena.com/user/SABO123456?ref=SABO-USERNAME
    return '$_baseUrl/user/$userCode?ref=$referralCode';
  }
  
  /// Generate complete QR data with referral for a user
  static Future<Map<String, dynamic>> generateQRDataWithReferral(UserProfile user) async {
    try {
      // 1. Get or generate user code
      String userCode = await UserCodeService.getUserCode(user.id) ?? 
                       await UserCodeService.generateUniqueUserCode(user.id);
      
      // 2. Get or create referral code
      String referralCode = await _ensureUserHasReferralCode(user);
      
      // 3. Generate integrated URL
      final profileUrl = generateIntegratedQRData(
        userId: user.id,
        userCode: userCode,
        referralCode: referralCode,
      );
      
      return {
        'user_code': userCode,
        'user_id': user.id,
        'referral_code': referralCode,
        'profile_url': profileUrl,
        'qr_data': profileUrl,
        'display_name': user.fullName,
        'elo_rating': user.eloRating,
        'rank': user.rank,
      };
      
    } catch (e) {
      print('❌ Error generating QR data with referral: $e');
      rethrow;
    }
  }
  
  /// Ensure user has a referral code, create if doesn't exist
  static Future<String> _ensureUserHasReferralCode(UserProfile user) async {
    try {
      // Check if user already has a referral code
      final existingCode = await BasicReferralService.getUserReferralCode(user.id);
      if (existingCode != null) return existingCode;
      
      // Create new referral code based on username
      final username = user.username ?? 'USER${user.id.substring(0, 6)}';
      final referralCode = 'SABO-${username.toUpperCase()}';
      
      // Create the referral code in database
      await BasicReferralService.createReferralCode(
        userId: user.id,
        code: referralCode,
      );
      
      print('✅ Created new referral code: $referralCode for user: ${user.fullName}');
      return referralCode;
      
    } catch (e) {
      print('❌ Error ensuring referral code: $e');
      // Fallback to basic format
      return 'SABO-${user.id.substring(0, 6).toUpperCase()}';
    }
  }
  
  /// Update user's QR data in database with integrated format
  static Future<bool> updateUserIntegratedQR(String userId) async {
    try {
      // Get user profile
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      final user = UserProfile.fromJson(userResponse);
      
      // Generate integrated QR data
      final qrData = await generateQRDataWithReferral(user);
      
      // Update database with new QR data
      await _supabase
          .from('users')
          .update({
            'user_code': qrData['user_code'],
            'qr_data': qrData['qr_data'],
            'qr_generated_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      
      print('✅ Updated integrated QR for user: $userId');
      print('   QR Data: ${qrData['qr_data']}');
      print('   Referral Code: ${qrData['referral_code']}');
      
      return true;
      
    } catch (e) {
      print('❌ Error updating integrated QR: $e');
      return false;
    }
  }
  
  /// Scan integrated QR code and return profile + referral info
  static Future<Map<String, dynamic>?> scanIntegratedQR(String qrData) async {
    try {
      print('🔍 Scanning integrated QR: $qrData');
      
      // Parse URL: https://saboarena.com/user/SABO123456?ref=SABO-USERNAME
      final uri = Uri.tryParse(qrData);
      
      if (uri != null && uri.host.contains('saboarena.com') && uri.pathSegments.length >= 2) {
        final userCode = uri.pathSegments[1]; // SABO123456
        final referralCode = uri.queryParameters['ref']; // SABO-USERNAME
        
        print('   User Code: $userCode');
        print('   Referral Code: $referralCode');
        
        // Find user by user_code
        final userProfile = await _findUserByCode(userCode);
        
        if (userProfile != null) {
          return {
            'type': 'integrated_profile',
            'scan_success': true,
            'user_profile': userProfile,
            'user_code': userCode,
            'referral_code': referralCode,
            'profile_url': qrData,
            'actions': {
              'view_profile': true,
              'open_app': true,
              'apply_referral': referralCode != null,
              'connect_user': true,
            },
            'display_data': {
              'name': userProfile['full_name'],
              'rank': userProfile['rank'],
              'elo': userProfile['elo_rating'],
              'user_code': userCode,
            }
          };
        } else {
          return {
            'type': 'invalid_qr',
            'scan_success': false,
            'message': 'User not found for code: $userCode',
          };
        }
      }
      
      // Try parsing as direct user code (SABO123456)
      if (qrData.startsWith('SABO') && qrData.length >= 10) {
        final userProfile = await _findUserByCode(qrData);
        
        if (userProfile != null) {
          return {
            'type': 'user_code_only',
            'scan_success': true,
            'user_profile': userProfile,
            'user_code': qrData,
            'referral_code': null,
            'actions': {
              'view_profile': true,
              'open_app': true,
              'apply_referral': false,
              'connect_user': true,
            }
          };
        }
      }
      
      return null;
      
    } catch (e) {
      print('❌ Error scanning integrated QR: $e');
      return null;
    }
  }
  
  /// Find user by user_code
  static Future<Map<String, dynamic>?> _findUserByCode(String userCode) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('user_code', userCode)
          .single();
      
      return response;
    } catch (e) {
      print('❌ User not found by code: $userCode');
      return null;
    }
  }
  
  /// Get user's current integrated QR data
  static Future<Map<String, dynamic>?> getUserIntegratedQR(String userId) async {
    try {
      final userResponse = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      final user = UserProfile.fromJson(userResponse);
      return await generateQRDataWithReferral(user);
      
    } catch (e) {
      print('❌ Error getting integrated QR: $e');
      return null;
    }
  }
  
  /// Apply referral code from scanned QR during registration
  static Future<Map<String, dynamic>> applyQRReferralDuringRegistration({
    required String newUserId,
    required String scannedQRData,
  }) async {
    try {
      // Parse referral code from QR data
      final uri = Uri.tryParse(scannedQRData);
      final referralCode = uri?.queryParameters['ref'];
      
      if (referralCode == null) {
        return {
          'success': false,
          'message': 'No referral code found in QR data',
        };
      }
      
      // Apply the referral code
      final result = await BasicReferralService.applyReferralCode(
        code: referralCode,
        newUserId: newUserId,
      );
      
      if (result?['success'] == true) {
        return {
          'success': true,
          'referral_code': referralCode,
          'referrer_reward': result!['referrer_reward'],
          'referred_reward': result['referred_reward'],
          'message': 'Referral code applied successfully! You received ${result['referred_reward']} SPA points!',
        };
      } else {
        return {
          'success': false,
          'message': result?['message'] ?? 'Failed to apply referral code',
        };
      }
      
    } catch (e) {
      print('❌ Error applying QR referral: $e');
      return {
        'success': false,
        'message': 'Error applying referral: $e',
      };
    }
  }
}