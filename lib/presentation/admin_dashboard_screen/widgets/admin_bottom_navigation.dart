import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../admin_tournament_management_screen/admin_tournament_management_screen.dart';

class AdminBottomNavigation extends StatelessWidget() {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) => _handleNavigation(context, index),
        selectedItemColor: AppTheme.primaryLight,
        unselectedItemColor: AppTheme.textSecondaryLight,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            activeIcon: Icon(Icons.approval),
            label: 'Duyệt CLB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Tournament',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Khác',
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    // Prevent navigation if already on the same tab
    if (index == currentIndex) return;

    onTap(index);

    switch (index) {
      case 0:
        // Dashboard
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardScreen);
        break;
      case 1:
        // Club Approval
        Navigator.pushReplacementNamed(context, AppRoutes.clubApprovalScreen);
        break;
      case 2:
        // Tournament Management
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AdminTournamentManagementScreen(),
          ),
        );
        break;
      case 3:
        // User Management
        _showComingSoon(context, 'Quản lý Users');
        break;
      case 4:
        // More options
        _showMoreOptions(context);
        break;
    }
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

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Thêm tùy chọn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 20),
              _buildMoreOption(
                context,
                Icons.analytics,
                'Thống kê chi tiết',
                'Xem báo cáo và phân tích',
                () => _showComingSoon(context, 'Thống kê chi tiết'),
              ),
              _buildMoreOption(
                context,
                Icons.settings,
                'Cài đặt hệ thống',
                'Cấu hình ứng dụng',
                () => _showComingSoon(context, 'Cài đặt hệ thống'),
              ),
              _buildMoreOption(
                context,
                Icons.backup,
                'Sao lưu dữ liệu',
                'Backup và restore',
                () => _showComingSoon(context, 'Sao lưu dữ liệu'),
              ),
              _buildMoreOption(
                context,
                Icons.history,
                'Nhật ký hệ thống',
                'Xem lịch sử hoạt động',
                () => _showComingSoon(context, 'Nhật ký hệ thống'),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryLight, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondaryLight,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}