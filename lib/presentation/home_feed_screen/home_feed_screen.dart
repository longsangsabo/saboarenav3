import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/player_welcome_guide.dart';

import '../../models/post_model.dart';
import '../../services/post_repository.dart';
import '../../services/auth_service.dart';
import '../../services/club_service.dart';
import '../club_registration_screen/club_registration_screen.dart';
import '../../            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home screen, maybe refresh
                  break;
                case 1:
                  _handleNavigation(AppRoutes.findOpponentsScreen);
                  break;
                case 2:
                  _handleNavigation(AppRoutes.attendanceScreen);
                  break;
                case 3:
                  _handleNavigation(AppRoutes.tournamentListScreen);
                  break;
                case 4:
                  _handleNavigation(AppRoutes.clubMainScreen);
                  break;
                case 5:
                  _handleNavigation(AppRoutes.userProfileScreen);
                  break;
              }
            },dal.dart';
import '../../widgets/share_bottom_sheet.dart';
import './widgets/create_post_modal_widget.dart';
import './widgets/empty_feed_widget.dart';
import './widgets/feed_tab_widget.dart';
import './widgets/feed_post_card_widget.dart';

class HomeFeedScreen extends StatefulWidget() {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen>
    with TickerProviderStateMixin() {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _logoRotationController;
  late Animation<double> _logoRotationAnimation;

  // Real Supabase data
  final PostRepository _postRepository = PostRepository();
  List<PostModel> _nearbyPosts = [];
  List<PostModel> _followingPosts = [];
  String? _errorMessage;

  // Club owner status
  bool _isClubOwner = false;
  bool _hasClub = false;
  
  // Player status
  bool _isPlayer = false;
  bool _showPlayerQuickActions = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers FIRST
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Logo rotation animation for loading
    _logoRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoRotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _logoRotationController, curve: Curves.linear),
    );

    _fabAnimationController.forward();
    
    // Setup scroll listener
    _scrollController.addListener(_onScroll);
    
    // Load posts AFTER animation controllers are initialized
    _loadPosts();
    // Check club owner status
    _checkClubOwnerStatus();
  }

  Future<void> _loadPosts() async() {
    try() {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
        // Start logo rotation when loading starts
        _logoRotationController.repeat();
      }

      // Load posts for both tabs using getFeedPosts
      final posts = await _postRepository.getPosts(limit: 20);
      
      if (mounted) {
        setState(() {
          _nearbyPosts = posts;
          _followingPosts = posts; // Use same posts for both tabs for now
          _isLoading = false;
        });
        // Stop logo rotation when loading finishes
        _logoRotationController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải bài đăng: $e';
        });
        // Stop logo rotation when loading finishes with error
        _logoRotationController.stop();
      }
    }
  }

  // Convert PostModel to Map for backwards compatibility
  Map<String, dynamic> _postToMap(PostModel post) {
    return() {
      'id': post.id,
      'userName': post.authorName, // Use authorName from PostModel
      'userAvatar': post.authorAvatarUrl ?? 'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'userRank': null, // TODO: Get user rank
      'content': post.content,
      'imageUrl': post.imageUrl, // Use imageUrl from PostModel
      "location": '', // PostModel doesn't have location
      'hashtags': post.tags ?? [], // Use tags from PostModel
      'timestamp': post.createdAt,
      'likeCount': post.likeCount,
      'commentCount': post.commentCount,
      'shareCount': post.shareCount,
      'isLiked': post.isLiked, // Use isLiked from PostModel
    };
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _logoRotationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async() {
    if (_isLoading) return;

    if (mounted) setState(() => _isLoading = true);

    try() {
      // Load more posts using getFeedPosts
      final currentList = _selectedTabIndex == 0 ? _nearbyPosts : _followingPosts;
      final morePosts = await _postRepository.getPosts(
        offset: currentList.length,
        limit: 5,
      );
      
      if (_selectedTabIndex == 0) {
        _nearbyPosts.addAll(morePosts);
      } else() {
        _followingPosts.addAll(morePosts);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thêm bài đăng: $e')),
        );
      }
    } finally() {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshFeed() async() {
    if (mounted) setState(() => _isLoading = true);

    try() {
      await _loadPosts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật bảng tin'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally() {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostModalWidget(
        onPostCreated: () {
          _refreshFeed();
        },
      ),
    );
  }

  Future<void> _handlePostAction(String action, Map<String, dynamic> post) async() {
    switch (action) {
      case 'like':
        await _handleLikeToggle(post);
        break;
      case 'comment':
        _showCommentsModal(post);
        break;
      case 'share':
        await _handleSharePost(post);
        break;
    }
  }

  Future<void> _handleLikeToggle(Map<String, dynamic> post) async() {
    try() {
      final postId = post['id'];
      final currentlyLiked = post['isLiked'] ?? false;
      
      // Optimistic update
      if (mounted) {
        setState(() {
          post['isLiked'] = !currentlyLiked;
          post['likeCount'] = (post['likeCount'] ?? 0) + (!currentlyLiked ? 1 : -1);
        });
      }

      // Call backend
      if (!currentlyLiked) {
        await _postRepository.likePost(postId);
      } else() {
        await _postRepository.unlikePost(postId);
      }
      
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          post['isLiked'] = !post['isLiked'];
          post['likeCount'] = (post['likeCount'] ?? 0) + (post['isLiked'] ? -1 : 1);
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  void _showCommentsModal(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsModal(
        postId: post['id'],
        postTitle: post['content'] ?? 'Bài viết',
        onCommentAdded: () {
          // Update comment count when new comment is added
          if (mounted) {
            setState(() {
              post['commentCount'] = (post['commentCount'] ?? 0) + 1;
            });
          }
        },
        onCommentDeleted: () {
          // Update comment count when comment is deleted
          if (mounted) {
            setState(() {
              post['commentCount'] = ((post['commentCount'] ?? 0) - 1).clamp(0, double.infinity).toInt();
            });
          }
        },
      ),
    );
  }

  Future<void> _handleSharePost(Map<String, dynamic> post) async() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareBottomSheet(
        postId: post['id'],
        postTitle: post['content'] ?? 'Bài viết',
        postContent: post['content'],
        postImageUrl: post['imageUrl'],
      ),
    );
  }

  void _handleUserTap(Map<String, dynamic> post) {
    Navigator.pushNamed(context, AppRoutes.userProfileScreen);
  }

  void _handleNavigation(String route) {
    if (route != AppRoutes.homeFeedScreen) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  List<Map<String, dynamic>> get _currentPosts() {
    final postModels = _selectedTabIndex == 0 ? _nearbyPosts : _followingPosts;
    return postModels.map((post) => _postToMap(post)).toList();
  }

  bool get _isEmpty() {
    return _currentPosts.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar.homeFeed(
        onNotificationTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mở trang thông báo')),
          );
        },
        onSearchTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mở trang tìm kiếm')),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Feed tabs
            FeedTabWidget(
              selectedIndex: _selectedTabIndex,
              onTabChanged: (index) {
                if (mounted) setState(() => _selectedTabIndex = index);
              },
            ),

            // Feed content
            Expanded(
              child: _isLoading && _currentPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rotating Logo Loading
                          Container(
                            width: 60,
                            height: 60,
                            padding: const EdgeInsets.all(8.0),
                            child: AnimatedBuilder(
                              animation: _logoRotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _logoRotationAnimation.value,
                                  child: SvgPicture.asset(
                                    'assets/images/logo.svg',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Đang tải bảng tin...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Vui lòng đợi một chút',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red[400],
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.red[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 3.h),
                              ElevatedButton(
                                onPressed: _loadPosts,
                                child: Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _isEmpty
                          ? EmptyFeedWidget(
                              isNearbyTab: _selectedTabIndex == 0,
                              onCreatePost: _showCreatePostModal,
                              onFindFriends: () {
                                Navigator.pushNamed(context, AppRoutes.findOpponentsScreen);
                              },
                            )
                          : RefreshIndicator(
                      onRefresh: _refreshFeed,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: 1.h),
                        itemCount: (_isClubOwner && !_hasClub ? 1 : 0) + (_isPlayer && _showPlayerQuickActions ? 1 : 0) + _currentPosts.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show club owner banner first if applicable
                          if (_isClubOwner && !_hasClub && index == 0) {
                            return _buildClubOwnerBanner();
                          }
                          
                          // Show player quick actions if applicable
                          if (_isPlayer && _showPlayerQuickActions) {
                            if ((_isClubOwner && !_hasClub && index == 1) || (!_isClubOwner && index == 0)) {
                              return _buildPlayerQuickActions();
                            }
                          }
                          
                          // Adjust index for actual posts
                          int adjustedIndex = index;
                          if (_isClubOwner && !_hasClub) adjustedIndex--;
                          if (_isPlayer && _showPlayerQuickActions) adjustedIndex--;
                          final postIndex = adjustedIndex;
                          if (postIndex == _currentPosts.length) {
                            return Container(
                              padding: EdgeInsets.all(4.w),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = _currentPosts[postIndex];
                          return FeedPostCardWidget(
                            post: post,
                            onLike: () => _handlePostAction('like', post),
                            onComment: () => _handlePostAction('comment', post),
                            onShare: () => _handlePostAction('share', post),
                            onUserTap: () => _handleUserTap(post),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _showCreatePostModal,
                tooltip: 'Tạo bài viết',
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 0, // Home tab
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: Colors.grey[500],
              backgroundColor: Colors.white,
              elevation: 0,
              selectedFontSize: 12,
              unselectedFontSize: 11,
            onTap: (index) {
              switch (index) {
                case 0:
                  // Already on home
                  break;
                case 1:
                  _handleNavigation(AppRoutes.findOpponentsScreen);
                  break;
                case 2:
                  _handleNavigation(AppRoutes.tournamentListScreen);
                  break;
                case 3:
                  _handleNavigation(AppRoutes.clubMainScreen);
                  break;
                case 4:
                  _handleNavigation(AppRoutes.userProfileScreen);
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 24),
                activeIcon: Icon(Icons.home_rounded, size: 26),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_outlined, size: 24),
                activeIcon: Icon(Icons.sports_rounded, size: 26),
                label: 'Đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.access_time_outlined, size: 24),
                activeIcon: Icon(Icons.access_time_rounded, size: 26),
                label: 'Chấm công',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined, size: 24),
                activeIcon: Icon(Icons.emoji_events_rounded, size: 26),
                label: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined, size: 24),
                activeIcon: Icon(Icons.groups_rounded, size: 26),
                label: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded, size: 24),
                activeIcon: Icon(Icons.person_rounded, size: 26),
                label: 'Cá nhân',
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkClubOwnerStatus() async() {
    try() {
      final user = AuthService.instance.currentUser;
      if (user == null) return;

      // Check user role
      final userRole = await AuthService.instance.getCurrentUserRole();
      
      if (userRole == 'club_owner') {
        // Check if user has any clubs
        final club = await ClubService.instance.getFirstClubForUser(user.id);
        
        if (mounted) {
          setState(() {
            _isClubOwner = true;
            _hasClub = club != null;
            _isPlayer = false;
          });
        }
      } else if (userRole == 'player') {
        // Check if we should show quick actions (e.g., for new users)
        final prefs = await SharedPreferences.getInstance();
        final showQuickActions = prefs.getBool('show_player_quick_actions_${user.id}') ?? true;
        
        if (mounted) {
          setState(() {
            _isPlayer = true;
            _showPlayerQuickActions = showQuickActions;
            _isClubOwner = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking user status: $e');
    }
  }

  Widget _buildClubOwnerBanner() {
    if (!_isClubOwner || _hasClub) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_soccer,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chủ CLB',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Bạn chưa đăng ký câu lạc bộ',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClubRegistrationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Đăng ký CLB',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '🏢 Tạo và quản lý câu lạc bộ của bạn\n'
            '🎯 Tổ chức giải đấu và sự kiện\n'
            '👥 Thu hút thành viên mới',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerQuickActions() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with close button
          Row(
            children: [
              Icon(
                Icons.sports_handball,
                color: Colors.green.shade600,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bắt đầu hành trình bida! 🎱',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Khám phá tính năng hữu ích cho người chơi mới',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _hidePlayerQuickActions(),
                icon: Icon(
                  Icons.close,
                  color: Colors.grey.shade500,
                  size: 5.w,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.group_add,
                  label: 'Tìm đối thủ',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.findOpponentsScreen),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.military_tech,
                  label: 'Xếp hạng',
                  color: Colors.purple,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.userProfileScreen),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.emoji_events,
                  label: 'Giải đấu',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tournamentListScreen),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Show guide button
          Center(
            child: TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => const PlayerWelcomeGuide(),
                );
              },
              icon: Icon(
                Icons.help_outline,
                color: Colors.green.shade600,
                size: 4.w,
              ),
              label: Text(
                'Xem hướng dẫn đầy đủ',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 6.w,
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _hidePlayerQuickActions() async() {
    try() {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('show_player_quick_actions_${user.id}', false);
        
        setState(() {
          _showPlayerQuickActions = false;
        });
      }
    } catch (e) {
      debugPrint('Error hiding player quick actions: $e');
    }
  }
}
