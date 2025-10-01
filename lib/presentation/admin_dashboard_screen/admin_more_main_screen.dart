import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import './widgets/admin_scaffold_wrapper.dart';

class AdminMoreMainScreen extends StatelessWidget {
  const AdminMoreMainScreen({super.key});

} 
  const AdminMoreMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWrapper(
      title: 'Thêm tùy chọn',
      currentIndex: 4,
      onBottomNavTap: (index) => _onNavTap(context, index),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            'Quản lý hệ thống',
            [
              _buildMoreItem(
                'Cài đặt hệ thống',
                'Cấu hình và thiết lập hệ thống',
                Icons.settings,
                AppTheme.primaryLight,
                () {
                  // Navigate to system settings
                },
              ),
              _buildMoreItem(
                'Backup & Restore',
                'Sao lưu và khôi phục dữ liệu',
                Icons.backup,
                Colors.blue,
                () {
                  // Navigate to backup settings
                },
              ),
              _buildMoreItem(
                'Logs & Analytics',
                'Xem nhật ký hoạt động và thống kê',
                Icons.analytics,
                Colors.green,
                () {
                  // Navigate to analytics
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildMoreSection(
            'Nội dung & Thông báo',
            [
              _buildMoreItem(
                'Quản lý thông báo',
                'Gửi thông báo cho người dùng',
                Icons.notifications,
                Colors.orange,
                () {
                  // Navigate to notifications
                },
              ),
              _buildMoreItem(
                'Nội dung trang chủ',
                'Quản lý banner và nội dung hiển thị',
                Icons.home,
                Colors.purple,
                () {
                  // Navigate to content management
                },
              ),
              _buildMoreItem(
                'Báo cáo vi phạm',
                'Xử lý báo cáo từ người dùng',
                Icons.report,
                Colors.red,
                () {
                  // Navigate to reports
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildMoreSection(
            'Tài khoản & Bảo mật',
            [
              _buildMoreItem(
                'Quản lý Admin',
                'Thêm/xóa quyền admin',
                Icons.admin_panel_settings,
                Colors.indigo,
                () {
                  // Navigate to admin management
                },
              ),
              _buildMoreItem(
                'Nhật ký truy cập',
                'Xem lịch sử đăng nhập admin',
                Icons.history,
                Colors.grey,
                () {
                  // Navigate to access logs
                },
              ),
              _buildMoreItem(
                'Thay đổi mật khẩu',
                'Đổi mật khẩu tài khoản admin',
                Icons.lock,
                Colors.brown,
                () {
                  // Navigate to change password
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildMoreSection(
            'Trợ giúp & Hỗ trợ',
            [
              _buildMoreItem(
                'Hướng dẫn sử dụng',
                'Xem tài liệu hướng dẫn chi tiết',
                Icons.help,
                Colors.teal,
                () {
                  // Navigate to help
                },
              ),
              _buildMoreItem(
                'Liên hệ hỗ trợ',
                'Gửi yêu cầu hỗ trợ kỹ thuật',
                Icons.support_agent,
                Colors.cyan,
                () {
                  // Navigate to support
                },
              ),
              _buildMoreItem(
                'Thông tin phiên bản',
                'Xem thông tin về ứng dụng',
                Icons.info,
                Colors.amber,
                () {
                  // Show app info
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreSection(String title, List<Widget> items) {
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
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerLight),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMoreItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index != 4) {
      _navigateToTab(context, index);
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = [
      '/admin_dashboard', // Dashboard
      '/admin_club_approval', // Duyệt CLB
      '/admin_tournament', // Tournament
      '/admin_user_management', // Users
      '/admin_more', // Khác - current
    ];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}
