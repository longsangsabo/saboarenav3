import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/services/auth_service.dart';
// import 'package:sabo_arena/services/club_dashboard_service.dart';
import '../member_management_screen/member_management_screen.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import '../tournament_management_center/tournament_management_center_screen.dart';
import '../club_notification_screen/club_notification_screen_simple.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../club_reports_screen/club_reports_screen.dart';
import '../activity_history_screen/activity_history_screen.dart';
import '../admin_dashboard_screen/club_rank_change_management_screen.dart';
import '../../services/club_permission_service.dart';
import '../../routes/app_routes.dart';

// Temporary mock classes
class ClubDashboardStats() {
  final int totalMembers;
  final int activeMembers;
  final double monthlyRevenue;
  final int totalTournaments;
  final int tournaments;
  final int ranking;
  
  ClubDashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.monthlyRevenue,
    required this.totalTournaments,
    required this.tournaments,
    required this.ranking,
  });
}

class ClubActivity() {
  final String title;
  final String subtitle;
  final String type;
  final DateTime timestamp;
  
  ClubActivity({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
  });
}

class ClubDashboardScreenSimple extends StatefulWidget() {
  final String clubId;

  const ClubDashboardScreenSimple({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubDashboardScreenSimple> createState() => _ClubDashboardScreenSimpleState();
}

class _ClubDashboardScreenSimpleState extends State<ClubDashboardScreenSimple> {
  bool _isLoading = true;
  Club? _club;
  bool _isOwner = false;
  
  // Dashboard data
  ClubDashboardStats? _dashboardStats;
  List<ClubActivity> _recentActivities = [];
  
  // Permission service
  final ClubPermissionService _permissionService = ClubPermissionService();

  Future<ClubDashboardStats> _loadRealClubStats(String clubId) async() {
    try() {
      // Get real member count
      final memberCount = await Supabase.instance.client
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('status', 'active')
          .count();

      // Get tournament count (if tournaments table exists)
      int tournamentCount = 0;
      try() {
        final tournamentResult = await Supabase.instance.client
            .from('tournaments')
            .select('id')
            .eq('club_id', clubId)
            .count();
        tournamentCount = tournamentResult.count;
      } catch (e) {
        // Tournaments table might not exist, use 0
        tournamentCount = 0;
      }

      return ClubDashboardStats(
        totalMembers: memberCount.count,
        activeMembers: memberCount.count,
        monthlyRevenue: 0.0, // Can be calculated later if needed
        totalTournaments: tournamentCount,
        tournaments: tournamentCount,
        ranking: 0, // Can be calculated later if needed
      );
    } catch (e) {
      // Fallback to zero values if error
      return ClubDashboardStats(
        totalMembers: 0,
        activeMembers: 0,
        monthlyRevenue: 0.0,
        totalTournaments: 0,
        tournaments: 0,
        ranking: 0,
      );
    }
  }

  Future<List<ClubActivity>> _loadRecentActivities(String clubId) async() {
    try() {
      final activities = <ClubActivity>[];
      
      // Get recent member joins
      final recentJoins = await Supabase.instance.client
          .from('club_members')
          .select('''
            joined_at,
            users!inner(display_name)
          ''')
          .eq('club_id', clubId)
          .order('joined_at', ascending: false)
          .limit(5);

      for (final join in recentJoins) {
        final userName = join['users']['display_name'] ?? 'Thành viên mới';
        activities.add(ClubActivity(
          title: 'Thành viên mới tham gia',
          subtitle: '$userName đã tham gia club',
          type: 'member_join',
          timestamp: DateTime.parse(join['joined_at']),
        ));
      }

      return activities;
    } catch (e) {
      // Return empty list if error
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async() {
    try() {
      final club = await ClubService.instance.getClubById(widget.clubId);
      final currentUserId = AuthService.instance.currentUser?.id;
      final isOwner = club.ownerId == currentUserId;
      
      // If user is club owner, ensure they have a membership record
      if (isOwner && currentUserId != null) {
        await _ensureOwnerMembership(widget.clubId, currentUserId);
      }
      
      setState(() {
        _club = club;
        _isOwner = isOwner;
        // Store user role for future use if needed
      });

      if (isOwner) {
        // Load dashboard data for club owner
        final results = await Future.wait([
          // Real data for club stats
          _loadRealClubStats(widget.clubId),
          // Real data for recent activities  
          _loadRecentActivities(widget.clubId),
        ]);

        setState(() {
          _dashboardStats = results[0] as ClubDashboardStats;
          _recentActivities = results[1] as List<ClubActivity>;
          _isLoading = false;
        });
      } else() {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  /// Ensure club owner has membership record
  Future<void> _ensureOwnerMembership(String clubId, String userId) async() {
    try() {
      final supabase = Supabase.instance.client;
      
      // Check if owner already has membership record
      final existing = await supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing == null) {
        // Add owner to club_members
        await supabase.from('club_members').insert({
          'club_id': clubId,
          'user_id': userId,
          "role": 'owner',
          "status": 'active',
          'joined_at': DateTime.now().toIso8601String(),
        });
        
        debugPrint('✅ Added owner to club_members table');
        
        // Clear permission cache to force refresh
        _permissionService.clearCache(clubId: clubId, userId: userId);
      } else() {
        debugPrint('✅ Owner membership record already exists');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring owner membership: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Club Dashboard'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isOwner) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Club Dashboard'),
        body: const Center(
          child: Text(
            'Bạn không có quyền truy cập vào dashboard này.\nChỉ chủ club mới có thể xem.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildModernAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with club info
            _buildClubHeader(),
            
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats section - compact
                  _buildCompactStats(),
                  const SizedBox(height: 24),
                  
                  // Quick actions - modern grid
                  _buildSectionHeader('Quản lý nhanh', Icons.speed),
                  const SizedBox(height: 16),
                  _buildModernQuickActions(),
                  const SizedBox(height: 24),
                  
                  // Recent activities - improved
                  _buildSectionHeader('Hoạt động gần đây', Icons.timeline, onViewAll: _navigateToActivityHistory),
                  const SizedBox(height: 16),
                  _buildImprovedActivities(),
                  const SizedBox(height: 100), // Space for bottom navigation
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Modern AppBar
  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Club Dashboard',
        style: TextStyle(
          color: Colors.grey[800],
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
          onPressed: _navigateToNotifications,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Colors.grey[600]),
          onPressed: _showSettings,
        ),
      ],
    );
  }

  // Club header section
  Widget _buildClubHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.8),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage: _club?.logoUrl != null 
                      ? NetworkImage(_club!.logoUrl!) 
                      : null,
                  child: _club?.logoUrl == null 
                      ? Icon(
                          Icons.sports_tennis,
                          size: 30,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _club?.name ?? 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dashboard quản lý',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Compact stats section
  Widget _buildCompactStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCompactStatItem(
              'Thành viên',
              _dashboardStats?.activeMembers.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
          ),
          Container(width: 0.5, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'Giải đấu',
              _dashboardStats?.totalTournaments.toString() ?? '0',
              Icons.emoji_events,
              Colors.orange,
            ),
          ),
          Container(width: 0.5, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'Doanh thu',
              _formatRevenue(_dashboardStats?.monthlyRevenue ?? 0),
              Icons.monetization_on,
              Colors.green,
            ),
          ),
          Container(width: 0.5, height: 30, color: Colors.grey[300]),
          Expanded(
            child: _buildCompactStatItem(
              'Hoạt động',
              _recentActivities.length.toString(),
              Icons.trending_up,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Section header with icon
  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'Xem tất cả',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // Modern quick actions
  Widget _buildModernQuickActions() {
    final actions = [
      {
        "title": 'Thành viên',
        'icon': Icons.people_outline,
        'color': Colors.blue,
        'onTap': _navigateToMemberManagement,
      },
      {
        "title": 'Nhân viên',
        'icon': Icons.badge_outlined,
        'color': Colors.indigo,
        'onTap': _navigateToStaffManagement,
      },
      {
        "title": 'Giải đấu',
        'icon': Icons.add_circle_outline,
        'color': Colors.green,
        'onTap': _navigateToTournamentCreate,
      },
      {
        "title": 'Thông báo',
        'icon': Icons.notifications_outlined,
        'color': Colors.orange,
        'onTap': _navigateToNotifications,
      },
      {
        "title": 'Báo cáo',
        'icon': Icons.bar_chart,
        'color': Colors.purple,
        'onTap': _showReports,
      },
      {
        "title": 'Cài đặt',
        'icon': Icons.settings_outlined,
        'color': Colors.grey,
        'onTap': _showSettings,
      },
      {
        "title": 'Lịch sử',
        'icon': Icons.history,
        'color': Colors.teal,
        'onTap': _navigateToActivityHistory,
      },
      {
        "title": 'Quản lý hạng',
        'icon': Icons.military_tech,
        'color': Colors.amber,
        'onTap': _navigateToRankManagement,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _buildModernActionCard(
          action['title'] as String,
          action['icon'] as IconData,
          action['color'] as Color,
          action['onTap'] as VoidCallback,
        );
      },
    );
  }

  Widget _buildModernActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Improved activities section
  Widget _buildImprovedActivities() {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.timeline_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có hoạt động',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Các hoạt động của club sẽ hiển thị ở đây',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentActivities.length > 5 ? 5 : _recentActivities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final activity = _recentActivities[index];
        return _buildImprovedActivityItem(activity);
      },
    );
  }

  Widget _buildImprovedActivityItem(ClubActivity activity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getActivityIcon(activity.type),
              color: _getActivityColor(activity.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimeAgo(activity.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'member_join':
        return Colors.green;
      case 'tournament_end':
        return Colors.blue;
      case 'tournament_start':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'member_join':
        return Icons.person_add;
      case 'tournament_end':
        return Icons.emoji_events;
      case 'tournament_start':
        return Icons.play_arrow;
      default:
        return Icons.info;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else() {
      return '${difference.inDays}d';
    }
  }







  void _navigateToMemberManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberManagementScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToStaffManagement() {
    Navigator.pushNamed(
      context,
      AppRoutes.clubStaffManagementScreen,
      arguments: {'clubId': widget.clubId},
    );
  }

  void _navigateToTournamentManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentManagementCenterScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToTournamentCreate() async() {
    try() {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      debugPrint('🔍 Checking tournament creation permission for club: ${widget.clubId}');
      
      // Get current user ID
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng đăng nhập để tiếp tục'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      debugPrint('🔍 Current user ID: ${currentUser.id}');
      
      // Debug membership first
      final membershipDebug = await _permissionService.debugMembership(widget.clubId);
      debugPrint('🔍 Membership debug: $membershipDebug');

      // Force refresh user role to get latest data from database
      final userRole = await _permissionService.refreshUserRole(widget.clubId);
      debugPrint('🔍 User role in club (refreshed): $userRole');
      
      Navigator.pop(context); // Close loading dialog
      
      // Check if user has permission to create tournaments
      bool hasPermission = false;
      String errorMessage = '';
      
      switch (userRole) {
        case ClubRole.owner:
        case ClubRole.admin:
          hasPermission = true;
          break;
        case ClubRole.member:
          // Members can create tournaments too based on permissions
          hasPermission = await _permissionService.canManageTournaments(widget.clubId);
          errorMessage = 'Thành viên thường không có quyền tạo giải đấu';
          break;
        case ClubRole.none:
          hasPermission = false;
          errorMessage = 'Bạn không phải là thành viên của club này';
          break;
      }
      
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage. Role hiện tại: $userRole'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: () => _navigateToTournamentCreate(),
            ),
          ),
        );
        return;
      }
      
      debugPrint('✅ User has permission - navigating to tournament creation');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TournamentCreationWizard(
            clubId: widget.clubId,
          ),
        ),
      ).then((result) {
        if (result != null && result is Map<String, dynamic>) {
          // Refresh dashboard if tournament was created successfully
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Giải đấu đã được tạo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
      
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      debugPrint('❌ Error checking permissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kiểm tra quyền: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () => _navigateToTournamentCreate(),
          ),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentCreationWizard(
          clubId: widget.clubId,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        // Refresh dashboard if tournament was created successfully
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giải đấu đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubNotificationScreenSimple(clubId: widget.clubId),
      ),
    );
  }

  void _showReports() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubReportsScreen(clubId: widget.clubId),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryLight,
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Thành viên',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Giải đấu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Cài đặt',
        ),
      ],
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            _navigateToMemberManagement();
            break;
          case 2:
            _navigateToTournamentManagement();
            break;
          case 3:
            _navigateToClubSettings();
            break;
        }
      },
    );
  }

  void _navigateToClubSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSettingsScreen(clubId: widget.clubId),
      ),
    );
  }

  void _showSettings() {
    _navigateToClubSettings();
  }

  void _navigateToActivityHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(clubId: widget.clubId),
      ),
    );
  }

  void _navigateToRankManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClubRankChangeManagementScreen(),
      ),
    );
  }

  String _formatRevenue(double revenue) {
    if (revenue >= 1000000) {
      return '${(revenue / 1000000).toStringAsFixed(1)}M';
    } else if (revenue >= 1000) {
      return '${(revenue / 1000).toStringAsFixed(1)}K';
    } else() {
      return revenue.toStringAsFixed(0);
    }
  }


}