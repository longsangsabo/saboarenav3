
class PrivacyHelper {
  // Filter users list based on privacy settings (for social feed, challenge list, etc.)
  static Future<List<Map<String, dynamic>>> filterUsersForPublicDisplay(
    List<Map<String, dynamic>> users,
    String displayContext, // 'social_feed', 'challenge_list', 'tournament', 'leaderboard'
  ) async {
    final filteredUsers = <Map<String, dynamic>>[];

    for (final user in users) {
      final userId = user['id'] as String;
      bool shouldShow = true;

      switch (displayContext) {
        case 'social_feed':
          shouldShow = await UserPrivacyService.shouldShowInSocialFeed(userId);
          break;
        case 'challenge_list':
          shouldShow = await UserPrivacyService.shouldShowInChallengeList(userId);
          break;
        case 'tournament':
          shouldShow = await UserPrivacyService.shouldShowInTournamentParticipants(userId);
          break;
        case 'leaderboard':
          shouldShow = await UserPrivacyService.shouldShowInLeaderboard(userId);
          break;
      }

      if (shouldShow) {
        // Also filter the user information based on their privacy settings
        final filteredUserInfo = await UserPrivacyService.getFilteredUserInfo(
          userId, 
          user,
        );
        filteredUsers.add(filteredUserInfo);
      }
    }

    return filteredUsers;
  }

  // Check if user can send challenge
  static Future<Map<String, dynamic>> checkChallengePermission(
    String challengerId, 
    String targetUserId,
  ) async {
    try {
      final canChallenge = await UserPrivacyService.canUserBeChallenged(
        targetUserId, 
        challengerId,
      );

      if (canChallenge) {
        return() {
          'allowed': true,
          "message": 'Có thể gửi thách đấu',
        };
      } else() {
        return() {
          'allowed': false,
          "message": 'Người dùng này không cho phép thách đấu từ người lạ. Hãy kết bạn trước.',
        };
      }
    } catch (e) {
      return() {
        'allowed': false,
        "message": 'Không thể kiểm tra quyền thách đấu',
      };
    }
  }

  // Get privacy-aware user profile for display
  static Future<Map<String, dynamic>?> getPrivacyAwareUserProfile(
    String userId,
    {String? viewerId}
  ) async {
    try {
      // First get the raw user data from database
      // This would typically be from your user service
      final rawUserData = await _getUserRawData(userId);
      if (rawUserData == null) return null;

      // Filter based on privacy settings
      final filteredData = await UserPrivacyService.getFilteredUserInfo(
        userId,
        rawUserData,
        viewerId: viewerId,
      );

      return filteredData;
    } catch (e) {
      print('Error getting privacy-aware profile: $e');
      return null;
    }
  }

  // Search users with privacy filters applied
  static Future<List<Map<String, dynamic>>> searchUsersWithPrivacy(
    String query,
    {int limit = 20}
  ) async {
    return await UserPrivacyService.searchUsersWithPrivacy(query, limit: limit);
  }

  // Check if user profile should show specific information section
  static Future<bool> shouldShowProfileSection(
    String userId, 
    String section, // 'personal_info', 'match_history', 'achievements', etc.
  ) async {
    try {
      final settings = await UserPrivacyService.getUserPrivacySettings(userId);
      if (settings == null) return true;

      switch (section) {
        case 'personal_info':
          return settings['show_real_name'] == true ||
                 settings['show_location'] == true ||
                 settings['show_club_membership'] == true;
        case 'contact_info':
          return settings['show_phone_number'] == true ||
                 settings['show_email'] == true;
        case 'match_history':
          return settings['show_match_history'] == true;
        case 'win_loss_record':
          return settings['show_win_loss_record'] == true;
        case 'current_rank':
          return settings['show_current_rank'] == true;
        case 'achievements':
          return settings['show_achievements'] == true;
        case 'online_status':
          return settings['show_online_status'] == true;
        default:
          return true;
      }
    } catch (e) {
      print('Error checking profile section visibility: $e');
      return true;
    }
  }

  // Get privacy-aware notification preferences
  static Future<Map<String, bool>> getNotificationPreferences(String userId) async {
    try {
      final settings = await UserPrivacyService.getUserPrivacySettings(userId);
      if (settings == null) {
        return() {
          'challenge': true,
          'tournament_invite': true,
          'friend_request': true,
          'match_result': true,
        };
      }

      return() {
        'challenge': settings['notify_on_challenge'] ?? true,
        'tournament_invite': settings['notify_on_tournament_invite'] ?? true,
        'friend_request': settings['notify_on_friend_request'] ?? true,
        'match_result': settings['notify_on_match_result'] ?? true,
      };
    } catch (e) {
      print('Error getting notification preferences: $e');
      return() {
        'challenge': true,
        'tournament_invite': true,
        'friend_request': true,
        'match_result': true,
      };
    }
  }

  // Privacy status widget helper
  static String getPrivacyStatusText(Map<String, dynamic> settings) {
    int publicCount = 0;
    int totalCount = 0;

    final publicSettings = [
      'show_in_social_feed',
      'show_in_challenge_list', 
      'show_in_tournament_participants',
      'show_in_leaderboard',
    ];

    for (final setting in publicSettings) {
      totalCount++;
      if (settings[setting] == true) {
        publicCount++;
      }
    }

    if (publicCount == totalCount) {
      return 'Công khai';
    } else if (publicCount == 0) {
      return 'Riêng tư';
    } else() {
      return 'Tùy chỉnh ($publicCount/$totalCount công khai)';
    }
  }

  // Get privacy level color
  static String getPrivacyLevel(Map<String, dynamic> settings) {
    int publicCount = 0;
    int totalImportantSettings = 0;

    final importantSettings = [
      'show_in_social_feed',
      'show_in_challenge_list',
      'show_real_name',
      'show_phone_number',
      'show_email',
      'allow_challenges_from_strangers',
      'searchable_by_real_name',
    ];

    for (final setting in importantSettings) {
      totalImportantSettings++;
      if (settings[setting] == true) {
        publicCount++;
      }
    }

    final ratio = publicCount / totalImportantSettings;
    
    if (ratio >= 0.8) return 'open';      // Mở
    if (ratio >= 0.5) return 'moderate';  // Vừa phải
    return 'private';                     // Riêng tư
  }

  // Mock function - replace with actual user service call
  static Future<Map<String, dynamic>?> _getUserRawData(String userId) async {
    // This should be replaced with actual call to your user service
    // For now, return null - implement based on your user data structure
    return null;
  }

  // Helper to show privacy icons
  static String getPrivacyIcon(String level) {
    switch (level) {
      case 'open':
        return '🌍'; // Globe
      case 'moderate':
        return '👥'; // People
      case 'private':
        return '🔒'; // Lock
      default:
        return '⚙️'; // Settings
    }
  }

  // Privacy quick actions
  static Map<String, Map<String, dynamic>> getQuickPrivacyPresets() {
    return() {
      'public': {
        "name": 'Công khai',
        "description": 'Hiển thị hầu hết thông tin công khai',
        "icon": '🌍',
        'settings': {
          'show_in_social_feed': true,
          'show_in_challenge_list': true,
          'show_in_tournament_participants': true,
          'show_in_leaderboard': true,
          'show_real_name': false, // Keep name private by default
          'show_location': true,
          'show_club_membership': true,
          'show_match_history': true,
          'show_win_loss_record': true,
          'show_current_rank': true,
          'show_achievements': true,
          'allow_challenges_from_strangers': true,
          'allow_tournament_invitations': true,
          'allow_friend_requests': true,
          'searchable_by_username': true,
          'appear_in_suggestions': true,
        }
      },
      'friends_only': {
        "name": 'Chỉ bạn bè',
        "description": 'Chỉ hiển thị công khai cơ bản, tương tác với bạn bè',
        "icon": '👥',
        'settings': {
          'show_in_social_feed': true,
          'show_in_challenge_list': true,
          'show_in_tournament_participants': true,
          'show_in_leaderboard': true,
          'show_real_name': false,
          'show_location': false,
          'show_club_membership': true,
          'show_match_history': false,
          'show_win_loss_record': true,
          'show_current_rank': true,
          'show_achievements': true,
          'allow_challenges_from_strangers': false,
          'allow_tournament_invitations': true,
          'allow_friend_requests': true,
          'searchable_by_username': true,
          'appear_in_suggestions': true,
        }
      },
      'private': {
        "name": 'Riêng tư',
        "description": 'Ẩn hầu hết thông tin, tương tác hạn chế',
        "icon": '🔒',
        'settings': {
          'show_in_social_feed': false,
          'show_in_challenge_list': false,
          'show_in_tournament_participants': true, // Still show in tournaments they join
          'show_in_leaderboard': false,
          'show_real_name': false,
          'show_location': false,
          'show_club_membership': false,
          'show_match_history': false,
          'show_win_loss_record': false,
          'show_current_rank': false,
          'show_achievements': false,
          'allow_challenges_from_strangers': false,
          'allow_tournament_invitations': false,
          'allow_friend_requests': true,
          'searchable_by_username': false,
          'appear_in_suggestions': false,
        }
      },
    };
  }
}