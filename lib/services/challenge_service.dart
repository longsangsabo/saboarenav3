
class ChallengeService {
  static ChallengeService? _instance;
  static ChallengeService get instance => _instance ??= ChallengeService._();
  ChallengeService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ChallengeRulesService _rulesService = ChallengeRulesService.instance;

  /// Send a challenge to another player with full validation
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
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // 🔍 STEP 1: Validate challenge using rules service
      if (challengeType == 'thach_dau' && spaPoints > 0) {
        final validationResult = await _rulesService.validateChallenge(
          challengerId: currentUser.id,
          challengedId: challengedUserId,
          spaBetAmount: spaPoints,
        );

        if (!validationResult.isValid) {
          throw Exception('Challenge validation failed: ${validationResult.errorMessage}');
        }

        // Calculate handicap for competitive challenges
        final handicapResult = validationResult.handicapResult;
        if (handicapResult != null && handicapResult.isValid) {
          handicap = (handicapResult.challengerHandicap > 0) 
              ? handicapResult.challengerHandicap.toInt()
              : -(handicapResult.challengedHandicap.toInt());
        }
      }

      // Get current user details
      final userResponse = await _supabase
          .from('users')
          .select('display_name, elo_rating, ranking')
          .eq('id', currentUser.id)
          .single();

      // Get challenged user details
      await _supabase
          .from('users')
          .select('display_name, elo_rating, ranking')
          .eq('id', challengedUserId)
          .single();

      // 🎯 STEP 2: Create challenge in database with enhanced data
      Map<String, dynamic> challengeData = {
        'challenger_id': currentUser.id,
        'challenged_id': challengedUserId,
        'challenge_type': challengeType,
        'game_type': gameType,
        'scheduled_time': scheduledTime.toIso8601String(),
        'location': location,
        'handicap': handicap,
        'spa_points': spaPoints,
        'message': message ?? '',
        "status": 'pending',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add handicap details for competitive challenges
      if (challengeType == 'thach_dau' && spaPoints > 0) {
        final validationResult = await _rulesService.validateChallenge(
          challengerId: currentUser.id,
          challengedId: challengedUserId,
          spaBetAmount: spaPoints,
        );

        if (validationResult.isValid && validationResult.handicapResult != null) {
          final handicapResult = validationResult.handicapResult!;
          challengeData.addAll({
            'handicap_challenger': handicapResult.challengerHandicap,
            'handicap_challenged': handicapResult.challengedHandicap,
            'rank_difference': handicapResult.rankDifference,
          });
        }
      }

      final challengeResponse = await _supabase
          .from('challenges')
          .insert(challengeData)
          .select()
          .single();

      // Send notification to challenged user
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

      return challengeResponse;
    } catch (error) {
      debugPrint('❌ Failed to send challenge: $error');
      throw Exception('Không thể gửi thách đấu: $error');
    }
  }

  /// Send a schedule request (hẹn lịch)
  Future<Map<String, dynamic>?> sendScheduleRequest({
    required String targetUserId,
    required DateTime scheduledDate,
    required String timeSlot,
    String? message,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current user details
      final userResponse = await _supabase
          .from('users')
          .select('display_name, club')
          .eq('id', currentUser.id)
          .single();

      // Create schedule request in challenges table with special type
      final scheduleResponse = await _supabase
          .from('challenges')
          .insert({
            'challenger_id': currentUser.id,
            'challenged_id': targetUserId,
            "challenge_type": 'schedule_request',
            'scheduled_time': scheduledDate.toIso8601String(),
            'time_slot': timeSlot,
            'message': message ?? 'Lời mời hẹn lịch chơi bida',
            "status": 'pending',
            'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Send notification to target user
      await _sendScheduleNotification(
        scheduleId: scheduleResponse['id'],
        senderName: userResponse['display_name'] ?? 'Người chơi',
        senderClub: userResponse['club'] ?? 'Unknown Club',
        targetUserId: targetUserId,
        scheduledDate: scheduledDate,
        timeSlot: timeSlot,
      );

      return scheduleResponse;
    } catch (error) {
      debugPrint('❌ Failed to send schedule request: $error');
      throw Exception('Không thể gửi lời mời hẹn lịch: $error');
    }
  }

  /// Accept a challenge
  Future<void> acceptChallenge(String challengeId) async {
    try {
      await _supabase
          .from('challenges')
          .update({
            "status": 'accepted',
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', challengeId);

      // Get challenge details to send notification back to challenger
      final challenge = await _supabase
          .from('challenges')
          .select('*, challenger:users!challenger_id(display_name), challenged:users!challenged_id(display_name)')
          .eq('id', challengeId)
          .single();

      // Notify challenger that challenge was accepted
      await NotificationService.instance.sendNotification(
        userId: challenge['challenger_id'],
        title: 'Thách đấu được chấp nhận! ⚔️',
        message: '${challenge['challenged']['display_name']} đã chấp nhận thách đấu của bạn. Hãy chuẩn bị cho trận đấu!',
        type: 'challenge_accepted',
        data: {'challenge_id': challengeId},
      );
    } catch (error) {
      throw Exception('Không thể chấp nhận thách đấu: $error');
    }
  }

  /// Decline a challenge
  Future<void> declineChallenge(String challengeId, {String? reason}) async {
    try {
      await _supabase
          .from('challenges')
          .update({
            "status": 'declined',
            'declined_at': DateTime.now().toIso8601String(),
            'decline_reason': reason,
          })
          .eq('id', challengeId);

      // Get challenge details to send notification back to challenger
      final challenge = await _supabase
          .from('challenges')
          .select('*, challenger:users!challenger_id(display_name), challenged:users!challenged_id(display_name)')
          .eq('id', challengeId)
          .single();

      // Notify challenger that challenge was declined
      await NotificationService.instance.sendNotification(
        userId: challenge['challenger_id'],
        title: 'Thách đấu bị từ chối 😔',
        message: '${challenge['challenged']['display_name']} đã từ chối thách đấu của bạn. ${reason ?? 'Không lý do cụ thể.'}',
        type: 'challenge_declined',
        data: {'challenge_id': challengeId},
      );
    } catch (error) {
      throw Exception('Không thể từ chối thách đấu: $error');
    }
  }

  /// Get user's challenges (sent and received)
  Future<List<Map<String, dynamic>>> getUserChallenges({
    String? type, // 'sent', 'received', null for all
    String? status, // 'pending', 'accepted', 'declined', null for all
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = _supabase
          .from('challenges')
          .select('''
            *,
            challenger:users!challenger_id(id, display_name, club, elo_rating),
            challenged:users!challenged_id(id, display_name, club, elo_rating)
          ''');

      if (type == 'sent') {
        query = query.eq('challenger_id', currentUser.id);
      } else if (type == 'received') {
        query = query.eq('challenged_id', currentUser.id);
      } else() {
        query = query.or('challenger_id.eq.${currentUser.id},challenged_id.eq.${currentUser.id}');
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      return await query.order('created_at', ascending: false);
    } catch (error) {
      throw Exception('Không thể lấy danh sách thách đấu: $error');
    }
  }

  /// Send challenge notification
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
    final title = challengeType == 'thach_dau' 
        ? "⚔️ Thách đấu mới!" 
        : '🎱 Lời mời giao lưu!';
    
    final message = '''
$challengerName đã ${challengeType == 'thach_dau' ? "thách đấu" : 'mời giao lưu'} bạn!

🎮 Loại game: $gameType
📅 Thời gian: ${_formatDateTime(scheduledTime)}
📍 Địa điểm: $location
${spaPoints > 0 ? "💰 Điểm SPA: $spaPoints" : ''}

Hãy vào ứng dụng để chấp nhận hoặc từ chối!
    ''';

    await NotificationService.instance.sendNotification(
      userId: challengedUserId,
      title: title,
      message: message,
      type: challengeType == 'thach_dau' ? "challenge_received" : 'friendly_match_invitation',
      data: {'challenge_id': challengeId},
    );
  }

  /// Send schedule notification
  Future<void> _sendScheduleNotification({
    required String scheduleId,
    required String senderName,
    required String senderClub,
    required String targetUserId,
    required DateTime scheduledDate,
    required String timeSlot,
  }) async {
    final message = '''
📅 Lời mời hẹn lịch chơi bida!

👤 Từ: $senderName ($senderClub)
📅 Ngày: ${_formatDate(scheduledDate)}
⏰ Giờ: $timeSlot

Hãy vào ứng dụng để xác nhận lịch hẹn!
    ''';

    await NotificationService.instance.sendNotification(
      userId: targetUserId,
      title: '📅 Lời mời hẹn lịch!',
      message: message,
      type: 'schedule_request',
      data: {'schedule_id': scheduleId},
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[dateTime.weekday % 7];
    return '$weekday, ${dateTime.day}/${dateTime.month} lúc ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Chủ nhật', 'Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }
}