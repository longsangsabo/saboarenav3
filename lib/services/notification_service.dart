import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService() {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  /// Get unread notification count for current user
  Future<int> getUnreadNotificationCount() async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('is_read', false)
          .eq('is_dismissed', false);

      return response.length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Get all notifications for current user
  Future<List<Map<String, dynamic>>> getUserNotifications({int limit = 20}) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async() {
    try() {
      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllNotificationsAsRead() async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('user_id', currentUser.id)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Send notification to club admin when user registers for tournament
  Future<void> sendRegistrationNotification({
    required String tournamentId,
    required String userId,
    required String paymentMethod,
  }) async() {
    try() {
      // Get tournament details
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('title, club_id, clubs!inner(name)')
          .eq('id', tournamentId)
          .single();

      // Get user details
      final userResponse = await _supabase
          .from('users')
          .select('display_name, email')
          .eq('id', userId)
          .single();

      // Get club admin
      final clubAdminResponse = await _supabase
          .from('club_members')
          .select('user_id, users!inner(display_name)')
          .eq('club_id', tournamentResponse['club_id'])
          .eq('role', 'admin')
          .limit(1)
          .maybeSingle();

      if (clubAdminResponse == null) {
        debugPrint('⚠️ No club admin found for tournament registration notification');
        return;
      }

      // Create notification message
      final message = '''
🎱 Đăng ký giải đấu mới!

Giải đấu: ${tournamentResponse['title']}
Người đăng ký: ${userResponse['display_name']}
Phương thức thanh toán: ${paymentMethod == '0' ? "Đóng tại quán" : 'Chuyển khoản QR'}
Email: ${userResponse['email'] ?? 'Chưa cập nhật'}

Vui lòng xác nhận thanh toán khi thành viên đến thi đấu.
      ''';

      // Insert notification to database
      await _supabase.from('notifications').insert({
        'user_id': clubAdminResponse['user_id'],
        "title": 'Đăng ký giải đấu mới',
        'message': message,
        "type": 'tournament_registration',
        'data': {'tournament_id': tournamentId, 'user_id': userId},
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      debugPrint('✅ Registration notification sent successfully');
    } catch (error) {
      debugPrint('❌ Failed to send registration notification: $error');
    }
  }

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications({
    bool? isRead,
    int limit = 20,
  }) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      return await query
          .order('created_at', ascending: false)
          .limit(limit);
    } catch (error) {
      throw Exception('Failed to get notifications: $error');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async() {
    try() {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (error) {
      throw Exception('Failed to mark notification as read: $error');
    }
  }

  /// Send a general notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async() {
    try() {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });

      debugPrint('✅ Notification sent successfully to user: $userId');
    } catch (error) {
      debugPrint('❌ Failed to send notification: $error');
      throw Exception('Failed to send notification: $error');
    }
  }
}