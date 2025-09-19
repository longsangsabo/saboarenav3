import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'test_user_service.dart';

/// Simple Challenge Service for basic challenge functionality
/// This version doesn't depend on advanced challenge rules
class SimpleChallengeService {
  static SimpleChallengeService? _instance;
  static SimpleChallengeService get instance => _instance ??= SimpleChallengeService._();
  SimpleChallengeService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send a simple challenge without advanced validation
  Future<Map<String, dynamic>?> sendChallenge({
    required String challengedUserId,
    required String challengeType, // 'giao_luu' or 'thach_dau'
    required String gameType, // '8-ball', '9-ball', '10-ball'
    required DateTime scheduledTime,
    required String location,
    int handicap = 0,
    int spaPoints = 0,
    String? message,
  }) async {
    try {
      print('🚀 SimpleChallengeService.sendChallenge called');
      print('📊 Parameters:');
      print('   challengedUserId: $challengedUserId');
      print('   challengeType: $challengeType');
      print('   gameType: $gameType');
      print('   spaPoints: $spaPoints');
      print('   location: $location');
      
      final currentUser = _supabase.auth.currentUser;
      String? userId;
      
      if (currentUser != null) {
        userId = currentUser.id;
        print('🔐 Using authenticated user: $userId');
      } else {
        // Try to use test user for development
        userId = TestUserService.instance.getCurrentUserId();
        if (userId == null) {
          print('❌ No user ID available (not authenticated and not in development)');
          throw Exception('User not authenticated');
        }
        print('🧪 Using test user for development: $userId');
        
        // Ensure test user exists in database
        await TestUserService.instance.getOrCreateTestUser();
      }

      print('🎯 Sending challenge...');
      print('Challenger: $userId');
      print('Challenged: $challengedUserId');
      print('Type: $challengeType');
      print('SPA Points: $spaPoints');

      // Get current user details
      final userResponse = await _supabase
          .from('users')
          .select('display_name, elo_rating')
          .eq('id', userId)
          .single();

      print('✅ Current user: ${userResponse['display_name']}');

      // Get challenged user details
      final challengedUserResponse = await _supabase
          .from('users')
          .select('display_name, elo_rating')
          .eq('id', challengedUserId)
          .single();

      print('✅ Challenged user: ${challengedUserResponse['display_name']}');

      // Create challenge record using existing table schema
      // Map our data to the existing challenges table structure
      Map<String, dynamic> challengeData = {
        'challenger_id': userId,
        'challenged_id': challengedUserId,
        'challenge_type': challengeType,
        'message': message ?? '',
        'stakes_type': spaPoints > 0 ? 'spa_points' : 'none', // Map spa betting
        'stakes_amount': spaPoints, // Map spa_points to stakes_amount
        'match_conditions': { // Store additional data as JSON
          'game_type': gameType,
          'location': location,
          'scheduled_time': scheduledTime.toIso8601String(),
          'handicap': handicap,
        },
        'status': 'pending',
        'handicap_challenger': 0.0,
        'handicap_challenged': handicap.toDouble(), // Map handicap
        'rank_difference': 0,
        // expires_at will be set automatically by database default
      };

      print('📋 Challenge data: $challengeData');

      final challengeResponse = await _supabase
          .from('challenges')
          .insert(challengeData)
          .select()
          .single();

      print('✅ Challenge created: ${challengeResponse['id']}');

      // Send notification (optional - may fail if notification service has issues)
      try {
        await _sendChallengeNotification(
          challengeId: challengeResponse['id'],
          challengerName: userResponse['display_name'] ?? 'Người chơi',
          challengedUserId: challengedUserId,
          challengeType: challengeType,
          gameType: gameType,
          scheduledTime: scheduledTime,
          location: location,
          spaPoints: spaPoints,
        );
        print('✅ Notification sent');
      } catch (notificationError) {
        print('⚠️ Notification failed: $notificationError');
        // Don't fail the whole challenge if notification fails
      }

      return challengeResponse;
    } catch (error) {
      print('❌ Challenge failed: $error');
      throw Exception('Không thể gửi thách đấu: $error');
    }
  }

  /// Send notification to challenged user
  Future<void> _sendChallengeNotification({
    required String challengeId,
    required String challengerName,
    required String challengedUserId,
    required String challengeType,
    required String gameType,
    required DateTime scheduledTime,
    required String location,
    required int spaPoints,
  }) async {
    try {
      final challengeTypeVi = challengeType == 'thach_dau' ? 'thách đấu' : 'giao lưu';
      final spaInfo = spaPoints > 0 ? ' ($spaPoints SPA)' : '';
      
      final message = '''
🎱 Lời mời $challengeTypeVi!

👤 Từ: $challengerName
🎮 Game: $gameType$spaInfo
📅 Thời gian: ${_formatDateTime(scheduledTime)}
📍 Địa điểm: $location

Hãy vào ứng dụng để phản hồi!
      ''';

      await NotificationService.instance.sendNotification(
        userId: challengedUserId,
        title: '🎱 Lời mời $challengeTypeVi!',
        message: message,
        type: 'challenge',
        data: {'challenge_id': challengeId},
      );
    } catch (error) {
      print('❌ Failed to send notification: $error');
      // Don't throw - notification failure shouldn't fail the challenge
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[dateTime.weekday % 7];
    return '$weekday, ${dateTime.day}/${dateTime.month} lúc ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get SPA betting options (simplified)
  List<Map<String, dynamic>> getSpaBettingOptions() {
    return [
      {'amount': 100, 'raceTo': 8, 'description': 'Thách đấu sơ cấp'},
      {'amount': 200, 'raceTo': 12, 'description': 'Thách đấu cơ bản'},
      {'amount': 300, 'raceTo': 14, 'description': 'Thách đấu trung bình'},
      {'amount': 400, 'raceTo': 16, 'description': 'Thách đấu trung cấp'},
      {'amount': 500, 'raceTo': 18, 'description': 'Thách đấu trung cao'},
      {'amount': 600, 'raceTo': 22, 'description': 'Thách đấu cao cấp'},
    ];
  }

  /// Simple validation (always returns true for now)
  Future<bool> canPlayersChallenge(String challengerId, String challengedId) async {
    try {
      // Basic check - make sure both users exist
      await _supabase
          .from('users')
          .select('id')
          .eq('id', challengerId)
          .single();
      
      await _supabase
          .from('users')
          .select('id')
          .eq('id', challengedId)
          .single();

      return true; // Both users exist
    } catch (error) {
      print('❌ Validation error: $error');
      return false;
    }
  }
}