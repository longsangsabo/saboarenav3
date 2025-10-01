
class UserPrivacyService {
  static final _supabase = Supabase.instance.client;

  // Get user privacy settings
  static Future<Map<String, dynamic>?> getUserPrivacySettings(String userId) async {
    try {
      final response = await _supabase
          .rpc('get_user_privacy_settings', params: {'target_user_id': userId});
      
      if (response != null && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
      
      // Return default settings if no settings found
      return _getDefaultPrivacySettings();
    } catch (e) {
      print('Error fetching privacy settings: $e');
      return _getDefaultPrivacySettings();
    }
  }

  // Save user privacy settings
  static Future<bool> saveUserPrivacySettings(String userId, Map<String, dynamic> settings) async {
    try {
      final response = await _supabase.rpc('save_user_privacy_settings', params: {
        'target_user_id': userId,
        'settings': settings,
      });
      
      return response == true;
    } catch (e) {
      print('Error saving privacy settings: $e');
      return false;
    }
  }

  // Check if user allows certain interactions
  static Future<bool> canUserBeChallenged(String userId, String challengerId) async {
    try {
      final settings = await getUserPrivacySettings(userId);
      if (settings == null) return true;

      // Check if user allows challenges from strangers
      final allowChallenges = settings['allow_challenges_from_strangers'] ?? true;
      
      if (!allowChallenges) {
        // Check if they are friends
        final areFriends = await _areUsersFriends(userId, challengerId);
        return areFriends;
      }
      
      return true;
    } catch (e) {
      print('Error checking challenge permission: $e');
      return true; // Default to allow
    }
  }

  // Check if user should appear in social feed
  static Future<bool> shouldShowInSocialFeed(String userId) async {
    try {
      final settings = await getUserPrivacySettings(userId);
      return settings?['show_in_social_feed'] ?? true;
    } catch (e) {
      print('Error checking social feed visibility: $e');
      return true;
    }
  }

  // Check if user should appear in challenge list
  static Future<bool> shouldShowInChallengeList(String userId) async {
    try {
      final settings = await getUserPrivacySettings(userId);
      return settings?['show_in_challenge_list'] ?? true;
    } catch (e) {
      print('Error checking challenge list visibility: $e');
      return true;
    }
  }

  // Check if user should appear in tournament participants
  static Future<bool> shouldShowInTournamentParticipants(String userId) async {
    try {
      final settings = await getUserPrivacySettings(userId);
      return settings?['show_in_tournament_participants'] ?? true;
    } catch (e) {
      print('Error checking tournament visibility: $e');
      return true;
    }
  }

  // Check if user should appear in leaderboard
  static Future<bool> shouldShowInLeaderboard(String userId) async {
    try {
      final settings = await getUserPrivacySettings(userId);
      return settings?['show_in_leaderboard'] ?? true;
    } catch (e) {
      print('Error checking leaderboard visibility: $e');
      return true;
    }
  }

  // Get filtered user info based on privacy settings
  static Future<Map<String, dynamic>> getFilteredUserInfo(
    String userId, 
    Map<String, dynamic> rawUserInfo,
    {String? viewerId}
  ) async {
    try {
      final settings = await getUserPrivacySettings(userId);
      if (settings == null) return rawUserInfo;

      final filteredInfo = Map<String, dynamic>.from(rawUserInfo);

      // Filter personal information based on privacy settings
      if (settings['show_real_name'] != true) {
        filteredInfo.remove('full_name');
        filteredInfo.remove('first_name');
        filteredInfo.remove('last_name');
      }

      if (settings['show_phone_number'] != true) {
        filteredInfo.remove('phone');
        filteredInfo.remove('phone_number');
      }

      if (settings['show_email'] != true) {
        filteredInfo.remove('email');
      }

      if (settings['show_location'] != true) {
        filteredInfo.remove('location');
        filteredInfo.remove('address');
        filteredInfo.remove('city');
      }

      if (settings['show_club_membership'] != true) {
        filteredInfo.remove('club_memberships');
        filteredInfo.remove('current_club');
      }

      if (settings['show_match_history'] != true) {
        filteredInfo.remove('match_history');
        filteredInfo.remove('recent_matches');
      }

      if (settings['show_win_loss_record'] != true) {
        filteredInfo.remove('wins');
        filteredInfo.remove('losses');
        filteredInfo.remove('win_rate');
      }

      if (settings['show_current_rank'] != true) {
        filteredInfo.remove('current_rank');
        filteredInfo.remove('elo_rating');
        filteredInfo.remove('rank_level');
      }

      if (settings['show_achievements'] != true) {
        filteredInfo.remove('achievements');
        filteredInfo.remove('badges');
        filteredInfo.remove('trophies');
      }

      if (settings['show_online_status'] != true) {
        filteredInfo.remove('online_status');
        filteredInfo.remove('last_seen');
      }

      return filteredInfo;
    } catch (e) {
      print('Error filtering user info: $e');
      return rawUserInfo;
    }
  }

  // Search users with privacy filters
  static Future<List<Map<String, dynamic>>> searchUsersWithPrivacy(
    String query, 
    {int limit = 20}
  ) async {
    try {
      // Get all users matching the query
      final response = await _supabase
          .from('users')
          .select('*')
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(limit);

      final users = List<Map<String, dynamic>>.from(response);
      final filteredUsers = <Map<String, dynamic>>[];

      for (final user in users) {
        final userId = user['id'] as String;
        final settings = await getUserPrivacySettings(userId);
        
        if (settings != null) {
          // Check if user allows being found in search
          final searchableByUsername = settings['searchable_by_username'] ?? true;
          final searchableByRealName = settings['searchable_by_real_name'] ?? false;
          final appearInSuggestions = settings['appear_in_suggestions'] ?? true;

          bool shouldInclude = false;

          if (searchableByUsername && 
              (user['username']?.toLowerCase()?.contains(query.toLowerCase()) ?? false)) {
            shouldInclude = true;
          }

          if (searchableByRealName && 
              (user['full_name']?.toLowerCase()?.contains(query.toLowerCase()) ?? false)) {
            shouldInclude = true;
          }

          if (shouldInclude && appearInSuggestions) {
            // Filter the user info based on privacy settings
            final filteredUser = await getFilteredUserInfo(userId, user);
            filteredUsers.add(filteredUser);
          }
        } else() {
          // Default behavior if no privacy settings
          filteredUsers.add(user);
        }
      }

      return filteredUsers;
    } catch (e) {
      print('Error searching users with privacy: $e');
      return [];
    }
  }

  // Helper method to check if users are friends
  static Future<bool> _areUsersFriends(String userId1, String userId2) async {
    try {
      final response = await _supabase
          .from('friendships')
          .select('id')
          .or('(user_id.eq.$userId1,friend_id.eq.$userId2),(user_id.eq.$userId2,friend_id.eq.$userId1)')
          .eq('status', 'accepted')
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking friendship: $e');
      return false;
    }
  }

  // Default privacy settings
  static Map<String, dynamic> _getDefaultPrivacySettings() {
    return() {
      'show_in_social_feed': true,
      'show_in_challenge_list': true,
      'show_in_tournament_participants': true,
      'show_in_leaderboard': true,
      'show_real_name': false,
      'show_phone_number': false,
      'show_email': false,
      'show_location': true,
      'show_club_membership': true,
      'show_match_history': true,
      'show_win_loss_record': true,
      'show_current_rank': true,
      'show_achievements': true,
      'show_online_status': true,
      'allow_challenges_from_strangers': true,
      'allow_tournament_invitations': true,
      'allow_friend_requests': true,
      'notify_on_challenge': true,
      'notify_on_tournament_invite': true,
      'notify_on_friend_request': true,
      'notify_on_match_result': true,
      'searchable_by_username': true,
      'searchable_by_real_name': false,
      'searchable_by_phone': false,
      'appear_in_suggestions': true,
    };
  }

  // Privacy setting categories for UI
  static Map<String, List<Map<String, String>>> getPrivacyCategories() {
    return() {
      'Hiển thị công cộng': [
        {
          "key": 'show_in_social_feed',
          "title": 'Hiển thị trong bảng tin giao lưu',
          "description": 'Cho phép thông tin của bạn xuất hiện trong tab giao lưu'
        },
        {
          "key": 'show_in_challenge_list',
          "title": 'Hiển thị trong danh sách thách đấu',
          "description": 'Cho phép người khác thấy bạn trong danh sách có thể thách đấu'
        },
        {
          "key": 'show_in_tournament_participants',
          "title": 'Hiển thị trong danh sách giải đấu',
          "description": 'Hiển thị thông tin khi tham gia giải đấu'
        },
        {
          "key": 'show_in_leaderboard',
          "title": 'Hiển thị trong bảng xếp hạng',
          "description": 'Cho phép xuất hiện trong bảng xếp hạng công cộng'
        },
      ],
      'Thông tin cá nhân': [
        {
          "key": 'show_real_name',
          "title": 'Hiển thị tên thật',
          "description": 'Cho phép người khác thấy tên thật của bạn'
        },
        {
          "key": 'show_phone_number',
          "title": 'Hiển thị số điện thoại',
          "description": 'Hiển thị số điện thoại trong profile'
        },
        {
          "key": 'show_email',
          "title": 'Hiển thị email',
          "description": 'Cho phép người khác thấy email của bạn'
        },
        {
          "key": 'show_location',
          "title": 'Hiển thị vị trí',
          "description": 'Hiển thị thông tin địa chỉ, vị trí'
        },
        {
          "key": 'show_club_membership',
          "title": 'Hiển thị thành viên CLB',
          "description": 'Hiển thị các CLB bạn đang tham gia'
        },
      ],
      'Hoạt động và thành tích': [
        {
          "key": 'show_match_history',
          "title": 'Hiển thị lịch sử thi đấu',
          "description": 'Cho phép xem lịch sử các trận đấu của bạn'
        },
        {
          "key": 'show_win_loss_record',
          "title": 'Hiển thị tỷ số thắng/thua',
          "description": 'Hiển thị số trận thắng, thua và tỷ lệ chiến thắng'
        },
        {
          "key": 'show_current_rank',
          "title": 'Hiển thị xếp hạng hiện tại',
          "description": 'Hiển thị rank và điểm ELO hiện tại'
        },
        {
          "key": 'show_achievements',
          "title": 'Hiển thị thành tích',
          "description": 'Hiển thị các danh hiệu, huy chương đã đạt được'
        },
        {
          "key": 'show_online_status',
          "title": 'Hiển thị trạng thái online',
          "description": 'Cho phép người khác thấy bạn đang online hay offline'
        },
      ],
      'Tương tác': [
        {
          "key": 'allow_challenges_from_strangers',
          "title": 'Cho phép thách đấu từ người lạ',
          "description": 'Cho phép những người không phải bạn bè gửi lời thách đấu'
        },
        {
          "key": 'allow_tournament_invitations',
          "title": 'Cho phép mời tham gia giải đấu',
          "description": 'Nhận lời mời tham gia các giải đấu'
        },
        {
          "key": 'allow_friend_requests',
          "title": 'Cho phép lời mời kết bạn',
          "description": 'Cho phép người khác gửi lời mời kết bạn'
        },
      ],
      'Tìm kiếm và gợi ý': [
        {
          "key": 'searchable_by_username',
          "title": 'Có thể tìm thấy qua tên người dùng',
          "description": 'Cho phép tìm thấy bạn khi search theo username'
        },
        {
          "key": 'searchable_by_real_name',
          "title": 'Có thể tìm thấy qua tên thật',
          "description": 'Cho phép tìm thấy bạn khi search theo tên thật'
        },
        {
          "key": 'appear_in_suggestions',
          "title": 'Xuất hiện trong gợi ý',
          "description": 'Hiển thị trong danh sách gợi ý kết bạn, thách đấu'
        },
      ],
    };
  }
}