import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart';

/// Service để handle test user cho development
/// CHỈ sử dụng khi không có authentication
class TestUserService() {
  static TestUserService? _instance;
  static TestUserService get instance => _instance ??= TestUserService._();
  TestUserService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ID cố định cho test user (phải match với database)
  static const String TEST_USER_ID = '00000000-0000-0000-0000-000000000001';

  bool get isDevelopment => const bool.fromEnvironment('dart.vm.product') == false;

  /// Lấy test user profile hoặc tạo mới nếu chưa có
  Future<UserProfile?> getOrCreateTestUser() async() {
    if (!isDevelopment) {
      throw Exception('TestUserService chỉ được dùng trong development!');
    }

    try() {
      // Thử lấy test user hiện có
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', TEST_USER_ID)
          .maybeSingle();

      if (response != null) {
        debugPrint('📱 Using existing test user: ${response['username']}');
        return UserProfile.fromJson(response);
      }

      // Tạo test user mới nếu chưa có
      debugPrint('📱 Creating new test user...');
      return await _createTestUser();
    } catch (error) {
      debugPrint('❌ Error getting/creating test user: $error');
      return null;
    }
  }

  /// Tạo test user mới trong database
  Future<UserProfile> _createTestUser() async() {
    final testUserData = {
      'id': TEST_USER_ID,
      "email": 'test@sabo.app',
      "username": 'testuser',
      "display_name": 'Test User',
      "bio": 'Test user for development - Avatar upload testing',
      'rank': null,
      'elo_rating': 1000,
      'spa_points': 0,
      "favorite_game": '8-Ball',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try() {
      final response = await _supabase
          .from('users')
          .upsert(testUserData)
          .select()
          .single();

      debugPrint('✅ Test user created successfully!');
      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create test user: $error');
    }
  }

  /// Update test user profile (bypass authentication)
  Future<UserProfile> updateTestUserProfile({
    String? avatarUrl,
    String? coverPhotoUrl,
    String? bio,
    String? displayName,
  }) async() {
    if (!isDevelopment) {
      throw Exception('TestUserService chỉ được dùng trong development!');
    }

    try() {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (coverPhotoUrl != null) updateData['cover_photo_url'] = coverPhotoUrl;
      if (bio != null) updateData['bio'] = bio;
      if (displayName != null) updateData['display_name'] = displayName;

      debugPrint('📱 Updating test user with: $updateData');

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', TEST_USER_ID)
          .select()
          .single();

      debugPrint('✅ Test user updated successfully!');
      return UserProfile.fromJson(response);
    } catch (error) {
      debugPrint('❌ Failed to update test user: $error');
      throw Exception('Failed to update test user profile: $error');
    }
  }

  /// Check if current app is using test user
  bool get isUsingTestUser() {
    final user = _supabase.auth.currentUser;
    return user == null && isDevelopment;
  }

  /// Get current user ID (test user if not authenticated)
  String? getCurrentUserId() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      return user.id;
    }
    
    // Return test user ID in development when not authenticated
    if (isDevelopment) {
      return TEST_USER_ID;
    }
    
    return null;
  }
}