import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../routes/app_routes.dart';
import './widgets/admin_scaffold_wrapper.dart';
import '../admin_tournament_management_screen/admin_tournament_management_screen.dart';
import './club_approval_screen.dart';
import './admin_user_management_screen.dart';


class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

} 
  final int initialIndex;
  
  const AdminMainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWrapper(
      title: _getTitleForIndex(_currentIndex),
      currentIndex: _currentIndex,
      onBottomNavTap: _onNavTap,
      body: _getCurrentScreen(),
    );
  }

  String _getTitleForIndex(int index) {
    final titles = [
      'Dashboard',
      'Duyệt CLB',
      'Tournament',
      'Quản lý Users',
      'Thêm tùy chọn',
    ];
    return titles[index];
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _AdminDashboardTab();
      case 1:
        return _AdminClubApprovalTab();
      case 2:
        return _AdminTournamentTab();
      case 3:
        return AdminUserManagementScreen();
      case 4:
        return _AdminMoreTab();
      default:
        return _AdminDashboardTab();
    }
  }



  void _onNavTap(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }


}

// Individual tab widgets
class _AdminDashboardTab extends StatefulWidget {
  @override
  State<_AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<_AdminDashboardTab> {
  final AdminService _adminService = AdminService.instance;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _adminService.getAdminStats(),
        _adminService.getRecentActivities(limit: 10),
      ]);

      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _recentActivities = results[1] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải dữ liệu dashboard: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.errorLight),
            SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            SizedBox(height: 24),
            _buildStatsCards(),
            SizedBox(height: 24),
            _buildQuickActions(),
            SizedBox(height: 24),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng Admin!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Quản lý hệ thống Sabo Arena',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onPrimaryLight.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.onPrimaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: AppTheme.onPrimaryLight,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_stats == null) return Container();

    final userStats = _stats!['users'] as Map<String, dynamic>;
    final clubStats = _stats!['clubs'] as Map<String, dynamic>;
    final tournamentStats = _stats!['tournaments'] as Map<String, dynamic>;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('${userStats['total_users']}', 'Tổng người dùng', Icons.people, AppTheme.primaryLight),
        _buildStatCard('${clubStats['total_clubs']}', 'Tổng CLB', Icons.sports, Colors.orange),
        _buildStatCard('${tournamentStats['total_tournaments']}', 'Giải đấu', Icons.emoji_events, Colors.green),
        _buildStatCard('${clubStats['pending_approvals']}', 'Chờ duyệt', Icons.pending, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Duyệt CLB',
                icon: Icons.approval,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.clubApprovalScreen),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Quản lý Tournament',
                icon: Icons.emoji_events,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminTournamentManagementScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hoạt động gần đây',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        if (_recentActivities.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Chưa có hoạt động nào',
                style: TextStyle(color: AppTheme.textSecondaryLight),
              ),
            ),
          )
        else
          ...(_recentActivities.take(5).map((activity) => _buildActivityTile(activity)).toList()),
      ],
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.info, color: AppTheme.primaryLight, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'] ?? 'Hoạt động không xác định',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTimeAgo(activity['created_at']),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Không xác định';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Không xác định';
    }
  }
}

class _AdminClubApprovalTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ClubApprovalScreen();
  }
}

class _AdminTournamentTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AdminTournamentManagementScreen();
  }
}



class _AdminMoreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm tùy chọn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 24),
          _buildMoreSection(
            'Thống kê & Báo cáo',
            [
              _MoreOption(Icons.analytics, 'Thống kê chi tiết', 'Phân tích dữ liệu hệ thống'),
              _MoreOption(Icons.assessment, 'Báo cáo tài chính', 'Doanh thu và chi phí'),
              _MoreOption(Icons.trending_up, 'Xu hướng người dùng', 'Phân tích hành vi user'),
            ],
          ),
          SizedBox(height: 24),
          _buildMoreSection(
            'Quản lý hệ thống',
            [
              _MoreOption(Icons.settings, 'Cài đặt hệ thống', 'Cấu hình ứng dụng'),
              _MoreOption(Icons.backup, 'Sao lưu dữ liệu', 'Backup và restore'),
              _MoreOption(Icons.security, 'Bảo mật', 'Quản lý quyền và bảo mật'),
            ],
          ),
          SizedBox(height: 24),
          _buildMoreSection(
            'Hỗ trợ & Khác',
            [
              _MoreOption(Icons.help, 'Trung tâm trợ giúp', 'Hướng dẫn sử dụng'),
              _MoreOption(Icons.history, 'Nhật ký hệ thống', 'Xem lịch sử hoạt động'),
              _MoreOption(Icons.info, 'Thông tin phiên bản', 'Chi tiết ứng dụng'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSection(String title, List<_MoreOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerLight),
          ),
          child: Column(
            children: options
                .map((option) => _buildMoreOptionTile(option))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMoreOptionTile(_MoreOption option) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(option.icon, color: AppTheme.primaryLight, size: 20),
      ),
      title: Text(
        option.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        option.subtitle,
        style: TextStyle(
          color: AppTheme.textSecondaryLight,
          fontSize: 12,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondaryLight),
      onTap: () {
        // Show coming soon dialog
      },
    );
  }
}

class _MoreOption {
  final IconData icon;
  final String title;
  final String subtitle;

  _MoreOption(this.icon, this.title, this.subtitle);
}
