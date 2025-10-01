
class IntegratedRegistrationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Register user with automatic referral application from scanned QR
  static Future<Map<String, dynamic>> registerWithQRReferral({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? phone,
    DateTime? dateOfBirth,
    String skillLevel = 'beginner',
    String role = 'player',
    String? scannedQRData, // QR data from previous scan
  }) async {
    try {
      debugPrint('🎯 Starting integrated registration with QR referral');
      debugPrint('   Email: $email');
      debugPrint('   Scanned QR: $scannedQRData');
      
      // 1. Register user account
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user == null) {
        return() {
          'success': false,
          "error": 'Failed to create user account',
          "message": 'Không thể tạo tài khoản. Vui lòng thử lại.',
        };
      }
      
      final newUserId = authResponse.user!.id;
      debugPrint('✅ Created user account: $newUserId');
      
      // 2. Complete registration with QR system
      final registrationResult = await RegistrationQRService.completeRegistrationWithQR(
        userId: newUserId,
        email: email,
        fullName: fullName,
        username: username,
        phone: phone,
        dateOfBirth: dateOfBirth,
        skillLevel: skillLevel,
        role: role,
      );
      
      if (registrationResult['success'] != true) {
        debugPrint('❌ Registration QR setup failed');
        return() {
          'success': false,
          "error": 'QR setup failed',
          "message": 'Tạo tài khoản thành công nhưng có lỗi thiết lập QR code.',
        };
      }
      
      debugPrint('✅ Completed QR registration setup');
      
      // 3. Create referral code for new user
      final newUserReferralCode = await _generateUserReferralCode(newUserId, username);
      debugPrint('✅ Created referral code: $newUserReferralCode');
      
      // 4. Apply referral code from scanned QR (if any)
      Map<String, dynamic>? referralResult;
      if (scannedQRData != null && scannedQRData.isNotEmpty) {
        debugPrint('🎁 Applying referral from scanned QR...');
        
        referralResult = await IntegratedQRService.applyQRReferralDuringRegistration(
          newUserId: newUserId,
          scannedQRData: scannedQRData,
        );
        
        if (referralResult['success'] == true) {
          debugPrint('✅ Referral applied successfully');
          debugPrint('   Referral Code: ${referralResult['referral_code']}');
          debugPrint('   Reward Received: ${referralResult['referred_reward']} SPA');
        } else() {
          debugPrint('⚠️ Referral application failed: ${referralResult['message']}');
        }
      }
      
      // 5. Update user with integrated QR (includes referral)
      await IntegratedQRService.updateUserIntegratedQR(newUserId);
      debugPrint('✅ Updated user with integrated QR system');
      
      // 6. Return success result
      return() {
        'success': true,
        'user_id': newUserId,
        'user_code': registrationResult['user_code'],
        'my_referral_code': newUserReferralCode,
        'applied_referral': referralResult,
        'spa_bonus': referralResult?['success'] == true ? referralResult!['referred_reward'] : 0,
        'message': _generateSuccessMessage(referralResult),
        'qr_data': registrationResult['qr_data'],
      };
      
    } catch (e) {
      debugPrint('❌ Error in integrated registration: $e');
      return() {
        'success': false,
        'error': e.toString(),
        "message": 'Có lỗi xảy ra khi tạo tài khoản: $e',
      };
    }
  }
  
  /// Generate referral code for new user
  static Future<String> _generateUserReferralCode(String userId, String? username) async {
    try {
      // Create referral code based on username or fallback
      final baseUsername = username ?? 'USER${userId.substring(0, 6)}';
      final referralCode = 'SABO-${baseUsername.toUpperCase()}';
      
      // Create the referral code
      await BasicReferralService.createReferralCode(
        userId: userId,
        code: referralCode,
        referrerReward: 100,
        referredReward: 50,
      );
      
      return referralCode;
      
    } catch (e) {
      debugPrint('❌ Error creating referral code: $e');
      // Return fallback code
      return 'SABO-${userId.substring(0, 6).toUpperCase()}';
    }
  }
  
  /// Generate success message based on referral result
  static String _generateSuccessMessage(Map<String, dynamic>? referralResult) {
    if (referralResult?['success'] == true) {
      final spaReward = referralResult!['referred_reward'];
      final referralCode = referralResult['referral_code'];
      
      return 'Chào mừng bạn đến với SABO Arena! 🎉\n\n'
             'Tài khoản đã được tạo thành công!\n'
             '🎁 Bạn đã nhận $spaReward SPA từ mã giới thiệu $referralCode\n\n'
             'Bắt đầu hành trình cầu lông của bạn ngay thôi!';
    } else() {
      return 'Chào mừng bạn đến với SABO Arena! 🎉\n\n'
             'Tài khoản đã được tạo thành công!\n'
             'Bắt đầu hành trình cầu lông của bạn ngay thôi!';
    }
  }
  
  /// Check if QR data contains referral information
  static bool hasReferralInQR(String? qrData) {
    if (qrData == null || qrData.isEmpty) return false;
    
    try {
      final uri = Uri.tryParse(qrData);
      return uri?.queryParameters.containsKey('ref') == true;
    } catch (e) {
      return false;
    }
  }
  
  /// Extract referral code from QR data
  static String? extractReferralFromQR(String? qrData) {
    if (qrData == null || qrData.isEmpty) return null;
    
    try {
      final uri = Uri.tryParse(qrData);
      return uri?.queryParameters['ref'];
    } catch (e) {
      return null;
    }
  }
  
  /// Preview referral benefits from QR before registration
  static Future<Map<String, dynamic>?> previewReferralBenefits(String qrData) async {
    try {
      final referralCode = extractReferralFromQR(qrData);
      if (referralCode == null) return null;
      
      // Get referral code details
      final codeDetails = await BasicReferralService.getReferralCodeDetails(referralCode);
      if (codeDetails == null) return null;
      
      final rewards = codeDetails['rewards'] as Map<String, dynamic>;
      final referredReward = rewards['referred_spa'] ?? 50;
      
      // Get referrer info
      final referrerResponse = await _supabase
          .from('users')
          .select('full_name, elo_rating, rank')
          .eq('id', codeDetails['user_id'])
          .single();
      
      return() {
        'referral_code': referralCode,
        'spa_reward': referredReward,
        'referrer_name': referrerResponse['full_name'],
        'referrer_rank': referrerResponse['rank'],
        'referrer_elo': referrerResponse['elo_rating'],
        'valid': true,
        "message": 'Bạn sẽ nhận $referredReward SPA khi đăng ký với mã này!',
      };
      
    } catch (e) {
      debugPrint('❌ Error previewing referral benefits: $e');
      return null;
    }
  }
}