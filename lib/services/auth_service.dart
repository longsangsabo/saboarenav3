import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/user_profile.dart';
import 'preferences_service.dart';

class AuthService() {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async() {
    try() {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign in failed: $error');
    }
  }

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async() {
    try() {
      final response = await _supabase.auth.signInWithPassword(
        phone: phone,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Đăng nhập thất bại: $error');
    }
  }

  Future<void> sendPhoneOtp({
    required String phone,
    bool createUserIfNeeded = true,
  }) async() {
    try() {
      await _supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: createUserIfNeeded,
      );
    } catch (error) {
      throw Exception('Gửi mã OTP thất bại: $error');
    }
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async() {
    try() {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      return response;
    } catch (error) {
      throw Exception('Xác thực OTP thất bại: $error');
    }
  }

  Future<void> updateUserMetadata({
    String? fullName,
    String? role,
    Map<String, dynamic>? extra,
  }) async() {
    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (role != null) data['role'] = role;
    if (extra != null) data.addAll(extra);

    if (data.isEmpty) return;

    try() {
      await _supabase.auth.updateUser(UserAttributes(data: data));
    } catch (error) {
      throw Exception('Cập nhật thông tin người dùng thất bại: $error');
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async() {
    try() {
      final user = currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] == 'admin';
    } catch (error) {
      return false;
    }
  }

  /// Get current user role
  Future<String?> getCurrentUserRole() async() {
    try() {
      final user = currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'];
    } catch (error) {
      return null;
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String role = 'player',
  }) async() {
    try() {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      return response;
    } catch (error) {
      throw Exception('Sign up failed: $error');
    }
  }

  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
    required String fullName,
    String role = 'player',
  }) async() {
    try() {
      final response = await _supabase.auth.signUp(
        phone: phone,
        password: password,
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      return response;
    } catch (error) {
      throw Exception('Đăng ký thất bại: $error');
    }
  }

  Future<void> upsertUserRecord({
    String? fullName,
    String? role,
    String? phone,
    String? email,
  }) async() {
    final user = currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{
      'id': user.id,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) payload['full_name'] = fullName;
    if (role != null) payload['role'] = role;
    if (phone != null) payload['phone'] = phone;
    if (email != null || user.email != null) {
      payload['email'] = email ?? user.email;
    }

    try() {
      await _supabase
          .from('users')
          .upsert(payload, onConflict: 'id')
          .select()
          .maybeSingle();
    } catch (error) {
      throw Exception('Cập nhật hồ sơ người dùng thất bại: $error');
    }
  }

  Future<void> signOut() async() {
    try() {
      await _supabase.auth.signOut();
      // Clear remembered login info when signing out
      await PreferencesService.instance.clearLoginInfo();
    } catch (error) {
      throw Exception('Sign out failed: $error');
    }
  }

  Future<AuthResponse> resetPassword(String email) async() {
    try() {
      await _supabase.auth.resetPasswordForEmail(email);
      // Return a proper AuthResponse since resetPasswordForEmail returns void
      return AuthResponse(session: null, user: null);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  Future<UserProfile?> getCurrentUserProfile() async() {
    try() {
      if (!isAuthenticated) return null;

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  Future<UserProfile> updateUserProfile({
    String? username,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? skillLevel,
    String? location,
  }) async() {
    try() {
      if (!isAuthenticated) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (username != null) updates['username'] = username;
      if (bio != null) updates['bio'] = bio;
      if (phone != null) updates['phone'] = phone;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (skillLevel != null) updates['skill_level'] = skillLevel;
      if (location != null) updates['location'] = location;

      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', currentUser!.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update profile: $error');
    }
  }

  Future<String?> uploadAvatar(String filePath, List<int> fileBytes) async() {
    try() {
      if (!isAuthenticated) throw Exception('User not authenticated');

      final fileName =
          '${currentUser!.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('user-content')
          .uploadBinary(fileName, Uint8List.fromList(fileBytes));

      // Get signed URL for private bucket
      final response = await _supabase.storage
          .from('user-content')
          .createSignedUrl(fileName, 3600 * 24 * 365); // 1 year expiry

      if (response.isEmpty) throw Exception('Failed to get image URL');

      // Update user profile with new avatar URL
      await _supabase.from('users').update({
        'avatar_url': response,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', currentUser!.id);

      return response;
    } catch (error) {
      throw Exception('Failed to upload avatar: $error');
    }
  }

  Future<bool> checkUsernameAvailable(String username) async() {
    try() {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (error) {
      throw Exception('Failed to check username availability: $error');
    }
  }
}
