import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';

import 'package:sizer/sizer.dart';
import '../member_management_screen/member_management_screen.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import '../tournament_detail_screen/widgets/tournament_management_panel.dart';
import '../tournament_detail_screen/widgets/tournament_stats_view.dart';
import '../club_profile_edit_screen/club_profile_edit_screen.dart';
import '../activity_history_screen/activity_history_screen.dart';
import '../club_settings_screen/club_settings_screen.dart';
import '../shift_reporting/shift_reporting_dashboard.dart';
import '../club_owner/club_attendance_dashboard.dart';
import '../../services/club_service.dart';
import '../../services/auth_service.dart';
import '../../models/club.dart';
import 'import '../task_verification_screen/demo/task_verification_demo.dart';';

// Temporary mock classes
class ClubDashboardStats {
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

class ClubActivity {
  final String title;
  final String subtitle;
  final String type;
  final DateTime timestamp;
  final String? avatar;
  final String? icon;
  
  ClubActivity({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.timestamp,
    this.avatar,
    this.icon,
  });
}

class ClubDashboardScreen extends StatefulWidget {
  const ClubDashboardScreen({super.key});

@override
  _ClubDashboardScreenState createState() => _ClubDashboardScreenState();
}

class _ClubDashboardScreenState extends State<ClubDashboardScreen> {
  Club? _currentClub;
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;
  
  // Dashboard Data
  ClubDashboardStats? _dashboardStats;
  List<ClubActivity> _recentActivities = [];
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _verifyClubOwnership();
    if (_hasPermission && _currentClub != null) {
      await _loadDashboardData();
    }
  }

  Future<void> _verifyClubOwnership() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      if (!AuthService.instance.isAuthenticated) {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Vui lòng đăng nhập để truy cập';
          _isLoading = false;
        });
        return;
      }

      // Get current user's club
      final currentClub = await ClubService.instance.getCurrentUserClub();
      
      if (currentClub == null) {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Bạn chưa có câu lạc bộ nào được duyệt. Vui lòng đăng ký câu lạc bộ trước.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentClub = currentClub;
        _hasPermission = true;
        _isLoading = false;
      });

    } catch (error) {
      setState(() {
        _hasPermission = false;
        _errorMessage = 'Có lỗi xảy ra khi kiểm tra quyền truy cập: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (!_hasPermission) {
      return _buildPermissionDeniedScreen();
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStatsSection(),
              SizedBox(height: 24.h),
              _buildQuickActionsSection(),
              SizedBox(height: 24.h),
              _buildRecentActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Widget - App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.h),
          child: CustomImageWidget(
            imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=100&h=100&fit=crop',
            height: 40.sp,
            width: 40.sp,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _currentClub?.name ?? "CLB của tôi",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 4.h),
              if (_currentClub?.isVerified == true)
                Icon(
                  Icons.verified,
                  color: AppTheme.primaryLight,
                  size: 20.sp,
                ),
            ],
          ),
          Text(
            "@${_currentClub?.name.toLowerCase().replaceAll(' ', '_') ?? 'club'}",
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: AppTheme.textPrimaryLight),
              onPressed: () => _onNotificationPressed(),
            ),
            if (_getNotificationCount() > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16.h,
                    minHeight: 16.h,
                  ),
                  child: Text(
                    '${_getNotificationCount()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: AppTheme.textPrimaryLight),
          onPressed: () => _onSettingsPressed(),
        ),
        SizedBox(width: 8.h),
      ],
    );
  }

  /// Section Widget - Quick Stats
  Widget _buildQuickStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tổng quan CLB",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        if (_isLoadingData)
          Row(
            children: [
              Expanded(child: _buildLoadingStatsCard()),
              SizedBox(width: 12.h),
              Expanded(child: _buildLoadingStatsCard()),
            ],
          )
        else if (_dashboardStats != null) ...[
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: "Thành viên",
                  value: "${_dashboardStats!.activeMembers}",
                  trend: _dashboardStats!.activeMembers > 0 ? "up" : null,
                  trendValue: _dashboardStats!.activeMembers > 0 ? "+${_dashboardStats!.activeMembers}" : null,
                  icon: Icons.people_outline,
                  color: AppTheme.successLight,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: _buildStatsCard(
                  title: "Giải đấu",
                  value: "${_dashboardStats!.tournaments}",
                  icon: Icons.emoji_events_outlined,
                  color: AppTheme.accentLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatsCard(
                  title: "Doanh thu tháng",
                  value: _formatCurrency(_dashboardStats!.monthlyRevenue),
                  trend: _dashboardStats!.monthlyRevenue > 0 ? "up" : null,
                  trendValue: _dashboardStats!.monthlyRevenue > 0 ? "+${_formatCurrency(_dashboardStats!.monthlyRevenue)}" : null,
                  icon: Icons.attach_money_outlined,
                  color: AppTheme.primaryLight,
                  subtitle: "VND",
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: _buildStatsCard(
                  title: "Xếp hạng CLB",
                  value: _dashboardStats!.ranking > 0 ? "#${_dashboardStats!.ranking}" : "N/A",
                  icon: Icons.military_tech_outlined,
                  color: AppTheme.primaryLight,
                  subtitle: "Khu vực",
                ),
              ),
            ],
          ),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildErrorStatsCard()),
              SizedBox(width: 12.h),
              Expanded(child: _buildErrorStatsCard()),
            ],
          ),
        ],
      ],
    );
  }

  /// Section Widget - Quick Actions
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thao tác nhanh",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: "Tạo giải đấu",
                subtitle: "Tổ chức giải đấu mới",
                icon: Icons.add_circle_outline,
                color: AppTheme.successLight,
                onPress: () => _onCreateTournament(),
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: _buildQuickActionCard(
                title: "Quản lý thành viên",
                subtitle: "Xem và quản lý thành viên",
                icon: Icons.people_outline,
                color: AppTheme.primaryLight,
                badge: 3,
                onPress: () => _onManageMembers(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: "Cập nhật thông tin",
                subtitle: "Chỉnh sửa thông tin CLB",
                icon: Icons.edit_outlined,
                color: AppTheme.accentLight,
                onPress: () => _onEditProfile(),
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: _buildQuickActionCard(
                title: "Thông báo",
                subtitle: "Gửi thông báo đến thành viên",
                icon: Icons.notifications_outlined,
                color: AppTheme.primaryLight,
                onPress: () => _onSendNotification(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: "Quản lý giải đấu",
                subtitle: "Xem và quản lý giải đấu",
                icon: Icons.emoji_events_outlined,
                color: AppTheme.warningLight,
                onPress: () => _onManageTournaments(),
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: _buildQuickActionCard(
                title: "Thống kê giải đấu",
                subtitle: "Xem thống kê và báo cáo",
                icon: Icons.analytics_outlined,
                color: Colors.blue.shade100,
                onPress: () => _onViewTournamentStats(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: "Báo cáo ca",
                subtitle: "Quản lý ca làm việc & doanh thu",
                icon: Icons.receipt_long,
                color: Colors.green.shade100,
                onPress: () => _onManageShiftReports(),
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: _buildQuickActionCard(
                title: "Chấm công nhân viên",
                subtitle: "Theo dõi giờ làm việc",
                icon: Icons.access_time,
                color: Colors.purple.shade100,
                onPress: () => _onManageAttendance(),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // Row 3: Task Verification System
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: "🔐 Xác minh nhiệm vụ",
                subtitle: "Hệ thống chống gian lận với ảnh trực tiếp",
                icon: Icons.verified_user,
                color: Colors.deepPurple.shade100,
                onPress: () => _onOpenTaskVerificationDemo(),
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.h),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, 
                         color: Colors.grey.shade400, size: 32),
                    SizedBox(height: 8.h),
                    Text("Tính năng mới", 
                         style: TextStyle(color: Colors.grey.shade500)),
                    Text("Sớm ra mắt", 
                         style: TextStyle(color: Colors.grey.shade400, fontSize: 12.sp)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Section Widget - Recent Activity
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hoạt động gần đây",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _onViewAllActivity(),
              child: Text(
                "Xem tất cả",
                style: const TextStyle(fontSize: 14).copyWith(
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimaryLight.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: _isLoadingData
              ? _buildLoadingActivities()
              : _recentActivities.isEmpty
                  ? _buildEmptyActivities()
                  : Column(
                      children: _buildActivityList(),
                    ),
        ),
      ],
    );
  }

  /// Component - Stats Card
  Widget _buildStatsCard({
    required String title,
    required String value,
    String? trend,
    String? trendValue,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.sp,
                ),
              ),
              Spacer(),
              if (trend != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: trend == "up" ? AppTheme.backgroundLight : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12.h),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend == "up" ? Icons.trending_up : Icons.trending_down,
                        color: trend == "up" ? AppTheme.successLight : AppTheme.errorLight,
                        size: 12.sp,
                      ),
                      SizedBox(width: 2.h),
                      Text(
                        trendValue ?? "",
                        style: TextStyle(
                          color: trend == "up" ? AppTheme.successLight : AppTheme.errorLight,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Component - Quick Action Card  
  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    int? badge,
    required VoidCallback onPress,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.h),
      child: InkWell(
        onTap: onPress,
        borderRadius: BorderRadius.circular(12.h),
        child: Container(
          padding: EdgeInsets.all(16.h),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: color, width: 4.h),
            ),
            borderRadius: BorderRadius.circular(12.h),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textPrimaryLight.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.h),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.h),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20.sp,
                    ),
                  ),
                  Spacer(),
                  if (badge != null && badge > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppTheme.errorLight,
                        borderRadius: BorderRadius.circular(10.h),
                      ),
                      child: Text(
                        badge.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Component - Activity Item
  Widget _buildActivityItem({
    required String type,
    required String title,
    required String subtitle,
    required DateTime timestamp,
    String? avatar,
    IconData? icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          // Avatar or Icon
          Container(
            width: 40.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.h),
              color: avatar != null ? null : color.withOpacity(0.1),
            ),
            child: avatar != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20.h),
                    child: CustomImageWidget(
                      imageUrl: avatar,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    icon,
                    color: color,
                    size: 20.sp,
                  ),
          ),
          SizedBox(width: 12.h),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Timestamp
          Text(
            _formatRelativeTime(timestamp),
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.backgroundLight,
            ),
          ),
        ],
      ),
    );
  }

  /// Component - Divider
  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Divider(
        color: AppTheme.dividerLight,
        thickness: 1,
      ),
    );
  }

  // Helper Methods
  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return '${difference.inDays} ngày trước';
    }
  }

  int _getNotificationCount() => 5; // TODO: Connect to real notification service

  // Event Handlers
  void _onNotificationPressed() {
    // Navigate to notifications management screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Quản lý thông báo'),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications, size: 64, color: Colors.green[700]),
                SizedBox(height: 16),
                Text(
                  'Tính năng quản lý thông báo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Đã được thiết kế và sẵn sành để triển khai',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Quay lại Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSettingsPressed() {
    // Navigate to club settings screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSettingsScreen(
          clubId: _getCurrentClubId(),
        ),
      ),
    );
  }

  void _onCreateTournament() {
    // Check if user has permission to create tournaments
    if (!_canManageTournaments()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ chủ CLB và quản trị viên mới có thể tạo giải đấu'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    // Navigate to tournament creation wizard
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentCreationWizard(
          clubId: _currentClub?.id,
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        // Refresh dashboard if tournament was created successfully
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giải đấu đã được tạo thành công!'),
            backgroundColor: AppTheme.successLight,
          ),
        );
      }
    });
  }

  void _onManageMembers() {
    // Navigate to manage members screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberManagementScreen(
          clubId: _getCurrentClubId(), // TODO: Get actual club ID
        ),
      ),
    );
  }

  void _onEditProfile() {
    // Navigate to edit profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubProfileEditScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh dashboard data if profile was updated
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin CLB thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _onSendNotification() {
    // Navigate to notification management screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Gửi thông báo'),
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 64, color: Colors.green[700]),
                SizedBox(height: 16),
                Text(
                  'Tính năng gửi thông báo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Đã được thiết kế và sẵn sành để triển khai',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(Icons.check),
                  label: Text('Mô phỏng gửi thành công'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thông báo đã được gửi thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _onViewAllActivity() {
    // Navigate to activity history screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(
          clubId: _getCurrentClubId(),
        ),
      ),
    );
  }

  void _onManageTournaments() {
    // Check if user has permission to manage tournaments
    if (!_canManageTournaments()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ chủ CLB và quản trị viên mới có thể quản lý giải đấu'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    // Show tournament management panel
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentManagementPanel(
        tournamentId: 'club_tournaments', // Mock ID for club tournaments
        tournamentStatus: 'active',
        onStatusChanged: () {
          // Refresh dashboard data
          _loadDashboardData();
        },
      ),
    );
  }

  void _onViewTournamentStats() {
    // Show tournament statistics view
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TournamentStatsView(
        tournamentId: 'club_tournaments_stats', // Mock ID for club tournament stats
        tournamentStatus: 'active',
      ),
    );
  }

  void _onManageShiftReports() {
    if (_currentClub?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể truy cập báo cáo ca'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShiftReportingDashboard(
          clubId: _currentClub!.id,
        ),
      ),
    );
  }

  void _onManageAttendance() {
    if (_currentClub?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể truy cập chấm công'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubAttendanceDashboard(
          clubId: _currentClub!.id,
        ),
      ),
    );
  }

  void _onOpenTaskVerificationDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskVerificationDemo(),
      ),
    );
  }

  // Helper Methods
  String _getCurrentClubId() {
    return _currentClub?.id ?? '';
  }

  bool _canManageTournaments() {
    // Check if current user has permission to manage tournaments
    // For now, assume all dashboard users can manage (since they can access dashboard)
    // In real implementation, check if user role is 'owner' or 'admin'
    final currentUserId = AuthService.instance.currentUser?.id;
    return currentUserId != null && _currentClub != null && 
           (_currentClub!.ownerId == currentUserId || _isClubAdmin());
  }

  bool _isClubAdmin() {
    // TODO: Implement actual admin role check
    // This should check if current user is admin of this club
    return false; // Placeholder - implement when club roles are available
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return "${(amount / 1000000).toStringAsFixed(1)}M";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  Widget _buildLoadingStatsCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimaryLight.withOpacity(0.05),
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
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 20,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            height: 16,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 4.h),
          Container(
            width: 80,
            height: 12,
            color: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatsCard() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimaryLight.withOpacity(0.05),
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
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.error_outline, color: Colors.red.shade400),
              ),
              const Spacer(),
              Text(
                'N/A',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.errorLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Không thể tải',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Thử lại sau',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    if (_currentClub == null) return;
    
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load dashboard stats and recent activities in parallel
      final results = await Future.wait([
        // Mock data for club stats
        Future.value(ClubDashboardStats(
          totalMembers: 25,
          activeMembers: 18,
          monthlyRevenue: 15000000,
          totalTournaments: 3,
          tournaments: 3,
          ranking: 5,
        )),
        // Mock data for recent activities
        Future.value([
          ClubActivity(
            title: 'Thành viên mới tham gia',
            subtitle: 'Nguyễn Văn A đã tham gia club',
            type: 'member_join',
            timestamp: DateTime.now().subtract(Duration(hours: 2)),
          ),
          ClubActivity(
            title: 'Giải đấu kết thúc',
            subtitle: 'Giải đấu tháng 12 đã hoàn thành',
            type: 'tournament_end',
            timestamp: DateTime.now().subtract(Duration(days: 1)),
          ),
        ]),
      ]);

      if (mounted) {
        setState(() {
          _dashboardStats = results[0] as ClubDashboardStats;
          _recentActivities = results[1] as List<ClubActivity>;
          _isLoadingData = false;
        });
      }
    } catch (error) {
      debugPrint('Error loading dashboard data: $error');
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryLight),
            SizedBox(height: 16.h),
            Text(
              'Đang tải dashboard...',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Không có quyền truy cập',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outlined,
                size: 64.sp,
                color: AppTheme.errorLight,
              ),
              SizedBox(height: 24.h),
              Text(
                'Truy cập bị từ chối',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Text(
                _errorMessage ?? 'Bạn không có quyền truy cập vào trang này.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              if (_errorMessage?.contains('đăng nhập') == true) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.loginScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                  icon: Icon(Icons.login, color: Colors.white),
                  label: Text(
                    'Đăng nhập',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.clubRegistrationScreen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                  icon: Icon(Icons.add_business, color: Colors.white),
                  label: Text(
                    'Đăng ký CLB',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.myClubsScreen);
                  },
                  child: Text(
                    'Xem CLB của tôi',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingActivities() {
    return Column(
      children: List.generate(3, (index) => 
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      width: 200,
                      height: 12,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              Container(
                width: 60,
                height: 11,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivities() {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Column(
        children: [
          Icon(
            Icons.timeline,
            size: 48.sp,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(height: 16.h),
          Text(
            'Chưa có hoạt động nào',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Các hoạt động gần đây của CLB sẽ hiển thị ở đây',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityList() {
    List<Widget> widgets = [];
    
    for (int i = 0; i < _recentActivities.length; i++) {
      final activity = _recentActivities[i];
      
      widgets.add(_buildActivityItemFromData(activity));
      
      // Add divider except for last item
      if (i < _recentActivities.length - 1) {
        widgets.add(_buildDivider());
      }
    }
    
    return widgets;
  }

  Widget _buildActivityItemFromData(ClubActivity activity) {
    Color color;
    IconData? iconData;
    
    switch (activity.type) {
      case 'member_joined':
        color = AppTheme.successLight;
        iconData = Icons.person_add;
        break;
      case 'tournament_created':
        color = AppTheme.accentLight;
        iconData = Icons.emoji_events;
        break;
      case 'match_completed':
        color = AppTheme.primaryLight;
        iconData = Icons.sports_esports;
        break;
      case 'payment_received':
        color = AppTheme.primaryLight;
        iconData = Icons.payment;
        break;
      default:
        color = AppTheme.primaryLight;
        iconData = Icons.info;
    }

    return _buildActivityItem(
      type: activity.type,
      title: activity.title,
      subtitle: activity.subtitle,
      timestamp: activity.timestamp,
      avatar: activity.avatar,
      icon: activity.icon != null ? _getIconFromString(activity.icon!) : iconData,
      color: color,
    );
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'emoji_events':
        return Icons.emoji_events;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'payment':
        return Icons.payment;
      case 'person_add':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }
}

