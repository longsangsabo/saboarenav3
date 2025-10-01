class UserCodeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate unique user code when user registers
  static Future<String> generateUniqueUserCode(String userId) async {
    try {
      // Generate base code from user ID
      String baseCode = ShareService.generateUserCode(userId);

      // Check if code already exists (collision detection)
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .eq('user_code', baseCode)
          .maybeSingle();

      if (existingUser != null) {
        // If collision, add random suffix
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        baseCode = 'SABO${timestamp.toString().substring(7)}';
      }

      return baseCode;
    } catch (e) {
      debugPrint('Error generating user code: $e');
      // Fallback: use timestamp-based code
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'SABO${timestamp.toString().substring(7)}';
    }
  }

  /// Create user code in database during registration
  static Future<bool> createUserCodeOnRegistration(String userId) async {
    try {
      // Generate unique code
      final userCode = await generateUniqueUserCode(userId);

      // Update user profile with generated code
      await _supabase.from('users').update({
        'user_code': userCode,
        'qr_data': ShareService.generateUserQRData(UserProfile(
          id: userId,
          email: '', // Temp values for QR generation
          fullName: '',
          displayName: '',
          role: 'player',
          skillLevel: 'beginner',
          totalWins: 0,
          totalLosses: 0,
          totalTournaments: 0,
          eloRating: 1000,
          spaPoints: 0,
          totalPrizePool: 0.0,
          isVerified: false,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        )),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      debugPrint('✅ User code created: $userCode for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating user code: $e');
      return false;
    }
  }

  /// Get user code from database
  static Future<String?> getUserCode(String userId) async {
    try {
      final result = await _supabase
          .from('users')
          .select('user_code')
          .eq('id', userId)
          .single();

      return result['user_code'] as String?;
    } catch (e) {
      debugPrint('Error getting user code: $e');
      return null;
    }
  }

  /// Update QR data when user profile changes
  static Future<bool> updateUserQRData(UserProfile user) async {
    try {
      final qrData = ShareService.generateUserQRData(user);

      await _supabase.from('users').update({
        'qr_data': qrData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error updating QR data: $e');
      return false;
    }
  }

  /// Find user by user code (for QR scanning)
  static Future<UserProfile?> findUserByCode(String userCode) async {
    try {
      final result = await _supabase
          .from('users')
          .select('*')
          .eq('user_code', userCode)
          .single();

      return UserProfile.fromJson(result);
    } catch (e) {
      debugPrint('Error finding user by code: $e');
      return null;
    }
  }

  /// Regenerate user code (if user wants new code)
  static Future<String?> regenerateUserCode(String userId) async {
    try {
      final newCode = await generateUniqueUserCode(userId);

      await _supabase.from('users').update({
        'user_code': newCode,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return newCode;
    } catch (e) {
      debugPrint('Error regenerating user code: $e');
      return null;
    }
  }

  /// Check if user code is available
  static Future<bool> isUserCodeAvailable(String userCode) async {
    try {
      final result = await _supabase
          .from('users')
          .select('id')
          .eq('user_code', userCode)
          .maybeSingle();

      return result == null; // Available if no user found
    } catch (e) {
      debugPrint('Error checking user code availability: $e');
      return false;
    }
  }
}
