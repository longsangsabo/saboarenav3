import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../admin_tournament_management_screen/admin_tournament_management_screen.dart';
import '../club_rank_change_management_screen.dart';
import '../system_admin_rank_management_screen.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({super.key});

} 
  const AdminNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavigationSection(
                  context,
                  'DASHBOARD',
                  [
                    _NavigationItem(
                      icon: Icons.dashboard,
                      title: 'Tổng quan',
                      route: AppRoutes.adminDashboardScreen,
                      isCurrentRoute: true,
                    ),
                    _NavigationItem(
                      icon: Icons.analytics,
                      title: 'Thống kê',
                      onTap: () => _showComingSoon(context, 'Thống kê'),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildNavigationSection(
                  context,
                  'QUẢN LÝ NGƯỜI DÙNG',
                  [
                    _NavigationItem(
                      icon: Icons.people,
                      title: 'Quản lý User',
                      onTap: () => _showComingSoon(context, 'Quản lý User'),
                    ),
                    _NavigationItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Phân quyền',
                      onTap: () => _showComingSoon(context, 'Phân quyền'),
                    ),
                    _NavigationItem(
                      icon: Icons.person_add,
                      title: 'Tạo tài khoản',
                      onTap: () => _showComingSoon(context, 'Tạo tài khoản'),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildNavigationSection(
                  context,
                  'QUẢN LÝ CLB',
                  [
                    _NavigationItem(
                      icon: Icons.approval,
                      title: 'Duyệt CLB',
                      route: AppRoutes.clubApprovalScreen,
                    ),
                    _NavigationItem(
                      icon: Icons.grade,
                      title: 'Thay đổi hạng (Club)',
                      onTap: () => _navigateToRankChangeManagement(context),
                    ),
                    _NavigationItem(
                      icon: Icons.admin_panel_settings,
                      title: 'System Admin Rank',
                      onTap: () => _navigateToSystemAdminRankManagement(context),
                    ),
                    _NavigationItem(
                      icon: Icons.sports,
                      title: 'Quản lý CLB',
                      onTap: () => _showComingSoon(context, 'Quản lý CLB'),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildNavigationSection(
                  context,
                  'QUẢN LÝ GIẢI ĐẤU',
                  [
                    _NavigationItem(
                      icon: Icons.emoji_events,
                      title: 'Quản lý Tournament',
                      onTap: () => _navigateToTournamentManagement(context),
                    ),
                    _NavigationItem(
                      icon: Icons.schedule,
                      title: 'Lịch thi đấu',
                      onTap: () => _showComingSoon(context, 'Lịch thi đấu'),
                    ),
                    _NavigationItem(
                      icon: Icons.leaderboard,
                      title: 'Bảng xếp hạng',
                      onTap: () => _showComingSoon(context, 'Bảng xếp hạng'),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildNavigationSection(
                  context,
                  'QUẢN LÝ NỘI DUNG',
                  [
                    _NavigationItem(
                      icon: Icons.post_add,
                      title: 'Quản lý Post',
                      onTap: () => _showComingSoon(context, 'Quản lý Post'),
                    ),
                    _NavigationItem(
                      icon: Icons.comment,
                      title: 'Quản lý Comment',
                      onTap: () => _showComingSoon(context, 'Quản lý Comment'),
                    ),
                    _NavigationItem(
                      icon: Icons.flag,
                      title: 'Báo cáo vi phạm',
                      onTap: () => _showComingSoon(context, 'Báo cáo vi phạm'),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildNavigationSection(
                  context,
                  'HỆ THỐNG',
                  [
                    _NavigationItem(
                      icon: Icons.settings,
                      title: 'Cài đặt hệ thống',
                      onTap: () => _showComingSoon(context, 'Cài đặt hệ thống'),
                    ),
                    _NavigationItem(
                      icon: Icons.backup,
                      title: 'Sao lưu dữ liệu',
                      onTap: () => _showComingSoon(context, 'Sao lưu dữ liệu'),
                    ),
                    _NavigationItem(
                      icon: Icons.history,
                      title: 'Nhật ký hệ thống',
                      onTap: () => _showComingSoon(context, 'Nhật ký hệ thống'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildDrawerFooter(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: DrawerHeader(
        margin: EdgeInsets.zero,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SABO ARENA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSection(
    BuildContext context,
    String title,
    List<_NavigationItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) => _buildNavigationTile(context, item)),
      ],
    );
  }

  Widget _buildNavigationTile(BuildContext context, _NavigationItem item) {
    final isSelected = item.isCurrentRoute ?? false;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? AppTheme.primaryLight.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
          size: 22,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.primaryLight : AppTheme.textPrimaryLight,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (item.onTap != null) {
            item.onTap!();
          } else if (item.route != null) {
            Navigator.pushNamed(context, item.route!);
          }
        },
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.dividerLight,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildDrawerFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.dividerLight, width: 1),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person, color: AppTheme.primaryLight),
            title: Text(
              'Chuyển sang User',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _switchToUserMode(context);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _handleLogout(context);
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _navigateToTournamentManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminTournamentManagementScreen(),
      ),
    );
  }

  void _navigateToRankChangeManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ClubRankChangeManagementScreen(),
      ),
    );
  }

  void _navigateToSystemAdminRankManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SystemAdminRankManagementScreen(),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.construction, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text('Đang phát triển'),
            ],
          ),
          content: Text(
            'Tính năng "$feature" đang được phát triển.\nSẽ sớm có trong phiên bản tiếp theo!',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Đã hiểu',
                style: TextStyle(color: AppTheme.primaryLight),
              ),
            ),
          ],
        );
      },
    );
  }

  void _switchToUserMode(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(AppRoutes.userProfileScreen);
  }

  void _handleLogout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16.0),
                Text('Đang đăng xuất...'),
              ],
            ),
          );
        },
      );

      await AuthService.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng xuất: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _NavigationItem {
  final IconData icon;
  final String title;
  final String? route;
  final VoidCallback? onTap;
  final bool? isCurrentRoute;

  _NavigationItem({
    required this.icon,
    required this.title,
    this.route,
    this.onTap,
    this.isCurrentRoute = false,
  });
}
