import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../routes/app_routes.dart';
import './admin_navigation_drawer.dart';
import './admin_bottom_navigation.dart';

class AdminScaffoldWrapper extends StatelessWidget {
  const AdminScaffoldWrapper({super.key});

} 
  final Widget body;
  final String title;
  final int currentIndex;
  final Function(int) onBottomNavTap;
  final List<Widget>? actions;
  final bool showBottomNavigation;

  const AdminScaffoldWrapper({
    super.key,
    required this.body,
    required this.title,
    required this.currentIndex,
    required this.onBottomNavTap,
    this.actions,
    this.showBottomNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: _buildAppBar(context),
      drawer: const AdminNavigationDrawer(),
      body: body,
      bottomNavigationBar: showBottomNavigation 
        ? AdminBottomNavigation(
            currentIndex: currentIndex,
            onTap: onBottomNavTap,
          )
        : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: AppTheme.textPrimaryLight),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimaryLight,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        ...?actions,
        IconButton(
          icon: Icon(Icons.switch_account, color: AppTheme.textPrimaryLight),
          onPressed: () => _showAccountSwitchDialog(context),
          tooltip: 'Chuyển đổi tài khoản',
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: AppTheme.textPrimaryLight),
          onPressed: () {
            // Trigger refresh callback if provided
            // This should be handled by the parent widget
          },
          tooltip: 'Làm mới',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.textPrimaryLight),
          onSelected: (action) => _handleMenuAction(context, action),
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'switch_to_user',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Chuyển sang giao diện người dùng'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAccountSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Icon(Icons.switch_account, color: AppTheme.primaryLight),
              SizedBox(width: 8.0),
              Text('Chuyển đổi tài khoản'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bạn muốn chuyển sang chế độ nào?'),
              SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _switchToUserMode(context);
                      },
                      icon: Icon(Icons.person),
                      label: Text('Người dùng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.admin_panel_settings),
                      label: Text('Admin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action) async {
    switch (action) {
      case 'switch_to_user':
        _switchToUserMode(context);
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  void _switchToUserMode(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.homeFeedScreen,
      (route) => false,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chuyển sang giao diện người dùng'),
        backgroundColor: AppTheme.primaryLight,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8.0),
              Text('Xác nhận đăng xuất'),
            ],
          ),
          content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                try {
                  await AuthService.instance.signOut();
                  
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.loginScreen,
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi đăng xuất: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }
}
