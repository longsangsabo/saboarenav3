import 'package:flutter/material.dart';
import 'package:sabo_arena/models/user_profile.dart';
import 'package:sabo_arena/services/ranking_service.dart';
import 'package:sabo_arena/services/user_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'widgets/member_overview_tab.dart';
// import 'widgets/member_activity_tab.dart';
// import 'widgets/member_matches_tab.dart';
// import 'widgets/member_tournaments_tab.dart';
// import 'widgets/member_settings_tab.dart';

class MemberDetailScreen extends StatefulWidget() {
  final String clubId;
  final String memberId;
  final UserProfile? initialUserProfile;

  const MemberDetailScreen({
    super.key,
    required this.clubId,
    required this.memberId,
    this.initialUserProfile,
  });

  @override
  _MemberDetailScreenState createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen>
    with TickerProviderStateMixin() {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final UserService _userService = UserService.instance;
  final RankingService _rankingService = RankingService();

  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _loadUserProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try() {
      UserProfile? profile;
      if (widget.initialUserProfile != null) {
        profile = widget.initialUserProfile;
      } else() {
        profile = await _userService.getUserProfileById(widget.memberId);
      }
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = "Lỗi tải thông tin thành viên: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_userProfile == null) {
      return _buildEmptyState();
    }
    return _buildMainContent();
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: _userProfile?.fullName ?? 'Chi tiết thành viên',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareMemberProfile,
          tooltip: 'Chia sẻ hồ sơ',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message, size: 20),
                  SizedBox(width: 8),
                  Text('Nhắn tin'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa khỏi CLB', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Đang tải thông tin thành viên...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Thử lại'),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy thông tin thành viên.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                _buildMemberHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      MemberOverviewTab(user: _userProfile!),
                      // TODO: Refactor other tabs
                      const Center(child: Text('Hoạt động - Sắp có')),
                      const Center(child: Text('Trận đấu - Sắp có')),
                      const Center(child: Text('Giải đấu - Sắp có')),
                      const Center(child: Text('Cài đặt - Sắp có')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberHeader() {
    final user = _userProfile!;
    final rankInfo = _rankingService.getRankDisplayInfo(user.displayRank);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildRankBadge(rankInfo),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.person), text: 'Tổng quan'),
          Tab(icon: Icon(Icons.timeline), text: 'Hoạt động'),
          Tab(icon: Icon(Icons.sports_esports), text: 'Trận đấu'),
          Tab(icon: Icon(Icons.emoji_events), text: 'Giải đấu'),
          Tab(icon: Icon(Icons.settings), text: 'Cài đặt'),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _toggleEditMode,
      icon: Icon(_isEditing ? Icons.save : Icons.edit),
      label: Text(_isEditing ? "Lưu" : 'Chỉnh sửa'),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Widget _buildRankBadge(RankDisplayInfo rankInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: rankInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(rankInfo.icon, size: 14, color: rankInfo.color),
          const SizedBox(width: 6),
          Text(
            rankInfo.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: rankInfo.color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _toggleEditMode();
        break;
      case 'message':
        _sendMessage();
        break;
      case 'remove':
        _removeMember();
        break;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
    // TODO: Implement actual editing logic
  }

  void _sendMessage() {
    // TODO: Implementation for sending message
  }

  void _shareMemberProfile() {
    // TODO: Implementation for sharing member profile
  }

  void _removeMember() {
    // TODO: Implementation for removing member
  }
}