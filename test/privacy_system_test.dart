import 'package:flutter_test/flutter_test.dart';
import 'package:sabo_arena/services/user_privacy_service.dart';
import 'package:sabo_arena/helpers/privacy_helper.dart';

void main() {
  group('Privacy System Tests', () {
    // Test UserPrivacyService
    group('UserPrivacyService', () {
      test('should get default privacy settings for non-existent user', () async {
        // This should return default settings even if user doesn't exist
        final settings = await UserPrivacyService.getUserPrivacySettings('fake-user-id');
        
        // Should return default values
        expect(settings, isNotNull);
        if (settings != null) {
          expect(settings['show_in_social_feed'], true);
          expect(settings['show_in_challenge_list'], true);
          expect(settings['show_real_name'], false);
          expect(settings['allow_challenges_from_strangers'], true);
        }
      });

      test('should check social feed visibility correctly', () async {
        // Test with fake user ID - should return default (true)
        final shouldShow = await UserPrivacyService.shouldShowInSocialFeed('fake-user-id');
        expect(shouldShow, true);
      });

      test('should check challenge list visibility correctly', () async {
        // Test with fake user ID - should return default (true)
        final shouldShow = await UserPrivacyService.shouldShowInChallengeList('fake-user-id');
        expect(shouldShow, true);
      });

      test('should filter user info based on privacy settings', () async {
        final userData = {
          'id': 'test-user',
          'username': 'testuser',
          'real_name': 'Test User',
          'phone_number': '123456789',
          'email': 'test@example.com',
          'location': 'Test City',
          'club_membership': 'Test Club',
          'match_history': [{'match': 'data'}],
          'win_rate': 75.5,
          'current_rank': 'Gold',
          'achievements': ['Achievement 1']
        };

        final filteredData = await UserPrivacyService.getFilteredUserInfo(
          'test-user',
          userData,
        );

        expect(filteredData, isNotNull);
        expect(filteredData['username'], 'testuser');
        // Real name should be hidden by default
        expect(filteredData.containsKey('real_name'), false);
        // Phone and email should be hidden by default
        expect(filteredData.containsKey('phone_number'), false);
        expect(filteredData.containsKey('email'), false);
        // Public info should be visible
        expect(filteredData['location'], 'Test City');
        expect(filteredData['club_membership'], 'Test Club');
      });
    });

    // Test PrivacyHelper
    group('PrivacyHelper', () {
      test('should filter users list for public display', () async {
        final usersList = [
          {
            'id': 'user1',
            'username': 'user1',
            'real_name': 'User One',
            'location': 'City 1'
          },
          {
            'id': 'user2', 
            'username': 'user2',
            'real_name': 'User Two',
            'location': 'City 2'
          }
        ];

        final filteredUsers = await PrivacyHelper.filterUsersForPublicDisplay(
          usersList,
          'social_feed',
        );

        expect(filteredUsers, isNotNull);
        expect(filteredUsers.length, lessThanOrEqualTo(usersList.length));
        
        // Check that filtered users have expected structure
        for (final user in filteredUsers) {
          expect(user.containsKey('id'), true);
          expect(user.containsKey('username'), true);
          // Real name should be filtered out by default
          expect(user.containsKey('real_name'), false);
        }
      });

      test('should check challenge permission correctly', () async {
        final permission = await PrivacyHelper.checkChallengePermission(
          'challenger-id',
          'target-id',
        );

        expect(permission, isNotNull);
        expect(permission.containsKey('allowed'), true);
        expect(permission.containsKey('message'), true);
        
        // Should allow challenges by default
        expect(permission['allowed'], true);
      });

      test('should get privacy level correctly', () {
        // Test open settings
        final openSettings = {
          'show_in_social_feed': true,
          'show_in_challenge_list': true,
          'show_real_name': true,
          'show_phone_number': false,
          'show_email': false,
          'allow_challenges_from_strangers': true,
          'searchable_by_real_name': true,
        };
        expect(PrivacyHelper.getPrivacyLevel(openSettings), 'open');

        // Test private settings
        final privateSettings = {
          'show_in_social_feed': false,
          'show_in_challenge_list': false,
          'show_real_name': false,
          'show_phone_number': false,
          'show_email': false,
          'allow_challenges_from_strangers': false,
          'searchable_by_real_name': false,
        };
        expect(PrivacyHelper.getPrivacyLevel(privateSettings), 'private');
      });

      test('should get privacy status text correctly', () {
        final publicSettings = {
          'show_in_social_feed': true,
          'show_in_challenge_list': true,
          'show_in_tournament_participants': true,
          'show_in_leaderboard': true,
        };
        expect(PrivacyHelper.getPrivacyStatusText(publicSettings), 'Công khai');

        final privateSettings = {
          'show_in_social_feed': false,
          'show_in_challenge_list': false,
          'show_in_tournament_participants': false,
          'show_in_leaderboard': false,
        };
        expect(PrivacyHelper.getPrivacyStatusText(privateSettings), 'Riêng tư');
      });

      test('should have valid quick privacy presets', () {
        final presets = PrivacyHelper.getQuickPrivacyPresets();
        
        expect(presets, isNotNull);
        expect(presets.containsKey('public'), true);
        expect(presets.containsKey('friends_only'), true);
        expect(presets.containsKey('private'), true);

        // Check preset structure
        for (final preset in presets.values) {
          expect(preset.containsKey('name'), true);
          expect(preset.containsKey('description'), true);
          expect(preset.containsKey('icon'), true);
          expect(preset.containsKey('settings'), true);
          
          final settings = preset['settings'] as Map<String, dynamic>;
          expect(settings.containsKey('show_in_social_feed'), true);
          expect(settings.containsKey('show_in_challenge_list'), true);
          expect(settings.containsKey('allow_challenges_from_strangers'), true);
        }
      });
    });

    // Integration Tests
    group('Privacy Integration Tests', () {
      test('privacy system end-to-end flow', () async {
        const testUserId = 'integration-test-user';
        
        // 1. Get initial settings (should be defaults)
        final initialSettings = await UserPrivacyService.getUserPrivacySettings(testUserId);
        expect(initialSettings, isNotNull);
        
        // 2. Test privacy checking functions
        final showInSocial = await UserPrivacyService.shouldShowInSocialFeed(testUserId);
        final showInChallenge = await UserPrivacyService.shouldShowInChallengeList(testUserId);
        
        expect(showInSocial, true); // Default should be true
        expect(showInChallenge, true); // Default should be true
        
        // 3. Test user filtering
        final testUserData = {
          'id': testUserId,
          'username': 'testuser',
          'real_name': 'Test User',
          'location': 'Test Location'
        };
        
        final filteredData = await UserPrivacyService.getFilteredUserInfo(
          testUserId,
          testUserData,
        );
        
        expect(filteredData, isNotNull);
        expect(filteredData['username'], 'testuser');
        expect(filteredData['location'], 'Test Location');
        
        // 4. Test privacy helper integration
        final users = [testUserData];
        final filteredUsers = await PrivacyHelper.filterUsersForPublicDisplay(
          users,
          'social_feed',
        );
        
        expect(filteredUsers, isNotNull);
        expect(filteredUsers.length, 1);
      });
    });
  });
}