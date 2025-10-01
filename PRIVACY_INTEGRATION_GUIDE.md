# Privacy System Integration Guide

## Tổng quan
Privacy system đã được tạo với 3 components chính:
1. **Database Schema** (`user_privacy_settings_schema.sql`) - Cấu trúc database với bảng privacy settings
2. **Service Layer** (`user_privacy_service.dart`) - Xử lý logic privacy
3. **UI Components** (`privacy_settings_screen.dart`, `privacy_status_widget.dart`) - Giao diện người dùng
4. **Helper Utilities** (`privacy_helper.dart`) - Utilities để tích hợp vào screens khác

## Bước 1: Deploy Database Schema

```bash
# Chạy SQL script để tạo privacy tables
supabase db reset --db-url "your-supabase-url"
# Hoặc execute file user_privacy_settings_schema.sql trong Supabase Dashboard
```

## Bước 2: Thêm Privacy Settings vào User Profile

### Trong User Profile Screen:

```dart
// Import privacy components
import 'package:sabo_arena/screens/privacy_settings_screen.dart';
import 'package:sabo_arena/widgets/privacy_status_widget.dart';

// Thêm vào profile screen
Widget _buildPrivacySection() {
  return Card(
    child: ListTile(
      leading: const Icon(Icons.privacy_tip),
      title: const Text('Cài đặt riêng tư'),
      subtitle: PrivacyStatusWidget(
        userId: widget.userId,
        isOwnProfile: true,
        onPrivacyTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrivacySettingsScreen(userId: widget.userId),
            ),
          );
        },
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivacySettingsScreen(userId: widget.userId),
          ),
        );
      },
    ),
  );
}
```

## Bước 3: Tích hợp vào Social Feed (Tab "Giao lưu")

### Trong Social Feed Screen:

```dart
import 'package:sabo_arena/helpers/privacy_helper.dart';

class SocialFeedScreen extends StatefulWidget {
  // ... existing code
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSocialFeedUsers();
  }

  Future<void> _loadSocialFeedUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy danh sách users từ database (như cũ)
      final rawUsers = await _getUsersFromDatabase();
      
      // Áp dụng privacy filters
      final filteredUsers = await PrivacyHelper.filterUsersForPublicDisplay(
        rawUsers,
        'social_feed', // Context là social feed
      );

      setState(() {
        _users = filteredUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['avatar_url'] != null 
              ? NetworkImage(user['avatar_url'])
              : null,
          child: user['avatar_url'] == null 
              ? Text(user['username']?.substring(0, 1).toUpperCase() ?? '?')
              : null,
        ),
        title: Text(user['display_name'] ?? user['username'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user['club_name'] != null)
              Text('🏟️ ${user['club_name']}'),
            if (user['current_rank'] != null)
              Text('🏆 Rank: ${user['current_rank']}'),
            // Privacy status indicator
            PrivacyStatusWidget(
              userId: user['id'],
              isOwnProfile: false,
            ),
          ],
        ),
        onTap: () => _viewUserProfile(user['id']),
      ),
    );
  }

  // Mock function - replace with your actual data loading
  Future<List<Map<String, dynamic>>> _getUsersFromDatabase() async {
    // Your existing code to load users
    return [];
  }

  void _viewUserProfile(String userId) {
    // Navigate to user profile
  }
}
```

## Bước 4: Tích hợp vào Challenge List (Tab "Thách đấu")

### Trong Challenge Screen:

```dart
import 'package:sabo_arena/helpers/privacy_helper.dart';

class ChallengeScreen extends StatefulWidget {
  // ... existing code
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  List<Map<String, dynamic>> _availableOpponents = [];

  Future<void> _loadAvailableOpponents() async {
    try {
      // Lấy danh sách users có thể thách đấu
      final rawUsers = await _getChallengableUsers();
      
      // Áp dụng privacy filters cho challenge list
      final filteredUsers = await PrivacyHelper.filterUsersForPublicDisplay(
        rawUsers,
        'challenge_list',
      );

      setState(() {
        _availableOpponents = filteredUsers;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _sendChallenge(String targetUserId) async {
    // Kiểm tra quyền thách đấu
    final permission = await PrivacyHelper.checkChallengePermission(
      getCurrentUserId(), // Your function to get current user ID
      targetUserId,
    );

    if (!permission['allowed']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(permission['message']),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Proceed with sending challenge
    try {
      await _sendChallengeRequest(targetUserId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi lời thách đấu!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi khi gửi thách đấu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOpponentCard(Map<String, dynamic> opponent) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: opponent['avatar_url'] != null 
              ? NetworkImage(opponent['avatar_url'])
              : null,
          child: opponent['avatar_url'] == null 
              ? Text(opponent['username']?.substring(0, 1).toUpperCase() ?? '?')
              : null,
        ),
        title: Text(opponent['display_name'] ?? opponent['username'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (opponent['current_rank'] != null)
              Text('🏆 ${opponent['current_rank']}'),
            if (opponent['win_rate'] != null)
              Text('📊 Tỷ lệ thắng: ${opponent['win_rate']}%'),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _sendChallenge(opponent['id']),
          child: const Text('Thách đấu'),
        ),
      ),
    );
  }

  // Mock functions - replace with your actual implementations
  Future<List<Map<String, dynamic>>> _getChallengableUsers() async => [];
  String getCurrentUserId() => '';
  Future<void> _sendChallengeRequest(String targetUserId) async {}
}
```

## Bước 5: Tích hợp User Search với Privacy

### Trong Search Screen:

```dart
import 'package:sabo_arena/helpers/privacy_helper.dart';

class UserSearchScreen extends StatefulWidget {
  // ... existing code
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Sử dụng privacy-aware search
      final results = await PrivacyHelper.searchUsersWithPrivacy(
        query,
        limit: 20,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm người chơi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Tìm theo tên hoặc username...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultCard(_searchResults[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> user) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user['avatar_url'] != null 
              ? NetworkImage(user['avatar_url'])
              : null,
          child: user['avatar_url'] == null 
              ? Text(user['username']?.substring(0, 1).toUpperCase() ?? '?')
              : null,
        ),
        title: Text(user['display_name'] ?? user['username'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user['club_name'] != null)
              Text('🏟️ ${user['club_name']}'),
            PrivacyStatusWidget(
              userId: user['id'],
              isOwnProfile: false,
            ),
          ],
        ),
        onTap: () => _viewUserProfile(user['id']),
      ),
    );
  }

  void _viewUserProfile(String userId) {
    // Navigate to user profile
  }
}
```

## Bước 6: Update User Profile View với Privacy Filters

### Trong User Profile View Screen:

```dart
import 'package:sabo_arena/helpers/privacy_helper.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? viewerId; // ID của user đang xem profile

  const UserProfileViewScreen({
    Key? key,
    required this.userId,
    this.viewerId,
  }) : super(key: key);

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy profile với privacy filters applied
      final profile = await PrivacyHelper.getPrivacyAwareUserProfile(
        widget.userId,
        viewerId: widget.viewerId,
      );

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return const Scaffold(
        body: Center(child: Text('Không thể tải thông tin người dùng')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile!['display_name'] ?? 'Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBasicInfo(),
            const SizedBox(height: 16),
            _buildPersonalInfo(),
            const SizedBox(height: 16),
            _buildMatchHistory(),
            const SizedBox(height: 16),
            _buildAchievements(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _userProfile!['avatar_url'] != null 
                  ? NetworkImage(_userProfile!['avatar_url'])
                  : null,
              child: _userProfile!['avatar_url'] == null 
                  ? Text(
                      _userProfile!['username']?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              _userProfile!['display_name'] ?? _userProfile!['username'] ?? 'Unknown',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            PrivacyStatusWidget(
              userId: widget.userId,
              isOwnProfile: widget.userId == widget.viewerId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return FutureBuilder<bool>(
      future: PrivacyHelper.shouldShowProfileSection(widget.userId, 'personal_info'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_userProfile!['real_name'] != null)
                  _buildInfoRow('Tên thật', _userProfile!['real_name']),
                if (_userProfile!['location'] != null)
                  _buildInfoRow('Địa điểm', _userProfile!['location']),
                if (_userProfile!['club_name'] != null)
                  _buildInfoRow('Câu lạc bộ', _userProfile!['club_name']),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchHistory() {
    return FutureBuilder<bool>(
      future: PrivacyHelper.shouldShowProfileSection(widget.userId, 'match_history'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.privacy_tip, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Lịch sử thi đấu được ẩn',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch sử thi đấu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_userProfile!['total_matches'] != null)
                  _buildInfoRow('Tổng số trận', '${_userProfile!['total_matches']}'),
                if (_userProfile!['wins'] != null)
                  _buildInfoRow('Thắng', '${_userProfile!['wins']}'),
                if (_userProfile!['losses'] != null)
                  _buildInfoRow('Thua', '${_userProfile!['losses']}'),
                if (_userProfile!['win_rate'] != null)
                  _buildInfoRow('Tỷ lệ thắng', '${_userProfile!['win_rate']}%'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievements() {
    return FutureBuilder<bool>(
      future: PrivacyHelper.shouldShowProfileSection(widget.userId, 'achievements'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thành tích',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_userProfile!['current_rank'] != null)
                  _buildInfoRow('Xếp hạng hiện tại', _userProfile!['current_rank']),
                if (_userProfile!['tournaments_won'] != null)
                  _buildInfoRow('Tournament thắng', '${_userProfile!['tournaments_won']}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Bước 7: Testing Privacy System

### Test Cases cần kiểm tra:

1. **Database Schema**:
   ```sql
   -- Test create privacy settings
   SELECT * FROM get_user_privacy_settings('user-id');
   
   -- Test save privacy settings
   SELECT save_user_privacy_settings('user-id', '{"show_in_social_feed": false}'::jsonb);
   ```

2. **Service Layer**:
   ```dart
   // Test privacy service
   final settings = await UserPrivacyService.getUserPrivacySettings('user-id');
   print('Privacy settings: $settings');
   
   final canShow = await UserPrivacyService.shouldShowInSocialFeed('user-id');
   print('Should show in social feed: $canShow');
   ```

3. **UI Components**:
   - Test privacy settings screen
   - Test privacy status widget display
   - Test quick privacy presets

## Bước 8: Production Deployment

1. **Deploy database schema** lên Supabase production
2. **Update app version** với privacy features
3. **Test thoroughly** trên production environment
4. **Monitor privacy settings** usage và performance

## Notes

- Privacy settings được cache trong service để improve performance
- RLS policies đảm bảo users chỉ có thể edit privacy settings của chính họ
- Default privacy settings được set khi user đăng ký lần đầu
- Privacy system hoạt động với existing features không cần major refactoring

Bạn có muốn tôi implement thêm phần nào hoặc tạo specific integration cho screen nào không?