import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsMenuWidget extends StatelessWidget {
  const SettingsMenuWidget({super.key});

} 
  final VoidCallback? onAccountSettings;
  final VoidCallback? onPrivacySettings;
  final VoidCallback? onNotificationSettings;
  final VoidCallback? onLanguageSettings;
  final VoidCallback? onPaymentHistory;
  final VoidCallback? onHelpSupport;
  final VoidCallback? onAbout;
  final VoidCallback? onLogout;
  final VoidCallback? onClubManagement;  // Added for club owner
  final VoidCallback? onSwitchToPlayerView;  // Added for switching to player view
  final bool isClubOwner;  // Added to check if user is club owner
  final bool isInAdminMode;  // Added to check if currently in admin mode

  const SettingsMenuWidget({
    super.key,
    this.onAccountSettings,
    this.onPrivacySettings,
    this.onNotificationSettings,
    this.onLanguageSettings,
    this.onPaymentHistory,
    this.onHelpSupport,
    this.onAbout,
    this.onLogout,
    this.onClubManagement,
    this.onSwitchToPlayerView,
    this.isClubOwner = false,
    this.isInAdminMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Cài đặt',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Settings Menu Items
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Club Management (only for club owners)
              if (isClubOwner) ...[
                _buildSettingsItem(
                  context,
                  icon: 'business',
                  title: 'Quản lý CLB',
                  subtitle: 'Giao diện quản lý câu lạc bộ',
                  onTap: onClubManagement,
                  showDivider: true,
                  highlight: true,
                ),
              ],
              // Switch to Player View (only when in admin mode)
              if (isInAdminMode) ...[
                _buildPlayerViewItem(context),
              ],
              _buildSettingsItem(
                context,
                icon: 'person',
                title: 'Tài khoản',
                subtitle: 'Thông tin cá nhân, bảo mật',
                onTap: onAccountSettings,
                showDivider: true,
              ),
              _buildSettingsItem(
                context,
                icon: 'privacy_tip',
                title: 'Quyền riêng tư',
                subtitle: 'Kiểm soát thông tin hiển thị',
                onTap: onPrivacySettings,
                showDivider: true,
              ),
              _buildSettingsItem(
                context,
                icon: 'notifications',
                title: 'Thông báo',
                subtitle: 'Cài đặt thông báo push',
                onTap: onNotificationSettings,
                showDivider: true,
              ),
              _buildSettingsItem(
                context,
                icon: 'language',
                title: 'Ngôn ngữ',
                subtitle: 'Tiếng Việt, English',
                onTap: onLanguageSettings,
                showDivider: true,
              ),
              _buildSettingsItem(
                context,
                icon: 'payment',
                title: 'Lịch sử thanh toán',
                subtitle: 'Giao dịch, SPA points',
                onTap: onPaymentHistory,
                showDivider: true,
              ),
              _buildSettingsItem(
                context,
                icon: 'help',
                title: 'Trợ giúp & Hỗ trợ',
                subtitle: 'FAQ, liên hệ',
                onTap: onHelpSupport,
                showDivider: true,
              ),
              _buildSettingsItem(
                context,
                icon: 'info',
                title: 'Về ứng dụng',
                subtitle: 'Phiên bản 1.0.0',
                onTap: onAbout,
                showDivider: false,
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Logout Button
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          child: ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'logout',
                  color: Colors.red,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Đăng xuất',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool showDivider = true,
    bool highlight = false,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          leading: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: highlight 
                  ? Colors.orange.withOpacity(0.1)
                  : AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: icon,
              color: highlight 
                  ? Colors.orange
                  : AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color:
                AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
            indent: 4.w,
            endIndent: 4.w,
          ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Đăng xuất',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (onLogout != null) {
                onLogout!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerViewItem(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onSwitchToPlayerView,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          leading: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'sports_esports',
              color: Colors.green,
              size: 20,
            ),
          ),
          title: Text(
            'Quay về giao diện Player',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Chuyển sang chế độ người chơi',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: AppTheme.lightTheme.colorScheme.outlineVariant,
          indent: 4.w,
          endIndent: 4.w,
        ),
      ],
    );
  }
}
