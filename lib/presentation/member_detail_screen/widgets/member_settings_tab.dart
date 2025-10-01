import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../member_management_screen/member_management_screen.dart';

class MemberSettingsTab extends StatefulWidget() {
  final MemberData memberData;
  final Function(MemberData) onMemberUpdated;

  const MemberSettingsTab({
    super.key,
    required this.memberData,
    required this.onMemberUpdated,
  });

  @override
  _MemberSettingsTabState createState() => _MemberSettingsTabState();
}

class _MemberSettingsTabState extends State<MemberSettingsTab>
    with AutomaticKeepAliveClientMixin() {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMembershipManagementSection(),
          SizedBox(height: 24),
          _buildPermissionsSection(),
          SizedBox(height: 24),
          _buildAccountActionsSection(),
          SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildMembershipManagementSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Quản lý thành viên',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            _buildSettingItem(
              title: 'Loại thành viên',
              subtitle: _getMembershipTypeLabel(widget.memberData.membershipInfo.type),
              icon: Icons.workspace_premium,
              onTap: _changeMembershipType,
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMembershipColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMembershipTypeLabel(widget.memberData.membershipInfo.type),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getMembershipColor(),
                  ),
                ),
              ),
            ),
            
            Divider(),
            
            _buildSettingItem(
              title: 'Trạng thái thành viên',
              subtitle: _getMembershipStatusLabel(widget.memberData.membershipInfo.status),
              icon: Icons.circle,
              onTap: _changeMembershipStatus,
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getMembershipStatusLabel(widget.memberData.membershipInfo.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ),
            
            Divider(),
            
            _buildSettingItem(
              title: 'Tự động gia hạn',
              subtitle: widget.memberData.membershipInfo.autoRenewal 
                  ? "Bật - Tự động gia hạn khi hết hạn"
                  : 'Tắt - Cần gia hạn thủ công',
              icon: Icons.autorenew,
              onTap: _toggleAutoRenewal,
              trailing: Switch(
                value: widget.memberData.membershipInfo.autoRenewal,
                onChanged: (_) => _toggleAutoRenewal(),
              ),
            ),
            
            if (widget.memberData.membershipInfo.expiryDate != null) ...[
              Divider(),
              
              _buildSettingItem(
                title: 'Gia hạn thành viên',
                subtitle: 'Hết hạn: ${_formatDate(widget.memberData.membershipInfo.expiryDate!)}',
                icon: Icons.date_range,
                onTap: _extendMembership,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Quyền hạn',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            _buildPermissionItem(
              title: 'Tham gia giải đấu',
              description: 'Có thể đăng ký và tham gia các giải đấu',
              enabled: true,
              onChanged: (value) => _updatePermission('tournaments', value),
            ),
            
            _buildPermissionItem(
              title: 'Đăng bài và bình luận',
              description: 'Có thể tạo bài đăng và bình luận',
              enabled: true,
              onChanged: (value) => _updatePermission('posts', value),
            ),
            
            _buildPermissionItem(
              title: 'Tham gia phòng chat',
              description: 'Có thể tham gia và gửi tin nhắn',
              enabled: true,
              onChanged: (value) => _updatePermission('chat', value),
            ),
            
            _buildPermissionItem(
              title: 'Mời thành viên mới',
              description: 'Có thể mời người khác tham gia CLB',
              enabled: false,
              onChanged: (value) => _updatePermission('invite', value),
            ),
            
            _buildPermissionItem(
              title: 'Xem thông tin liên hệ',
              description: 'Có thể xem email và số điện thoại của thành viên khác',
              enabled: false,
              onChanged: (value) => _updatePermission('contact', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Hành động quản trị',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            _buildActionItem(
              title: 'Gửi tin nhắn',
              subtitle: 'Gửi tin nhắn riêng cho thành viên',
              icon: Icons.message,
              onTap: _sendMessage,
              color: Colors.blue,
            ),
            
            Divider(),
            
            _buildActionItem(
              title: 'Đặt lại mật khẩu',
              subtitle: 'Tạo mật khẩu mới cho thành viên',
              icon: Icons.lock_reset,
              onTap: _resetPassword,
              color: Colors.orange,
            ),
            
            Divider(),
            
            _buildActionItem(
              title: 'Xem nhật ký hoạt động',
              subtitle: 'Xem lịch sử hoạt động chi tiết',
              icon: Icons.history,
              onTap: _viewActivityLog,
              color: Colors.purple,
            ),
            
            Divider(),
            
            _buildActionItem(
              title: 'Xuất dữ liệu thành viên',
              subtitle: 'Tải về tất cả dữ liệu của thành viên',
              icon: Icons.download,
              onTap: _exportMemberData,
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Card(
      elevation: 0,
      color: Colors.red.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.2)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Vùng nguy hiểm',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            _buildActionItem(
              title: 'Tạm khóa tài khoản',
              subtitle: 'Tạm thời khóa tài khoản thành viên',
              icon: Icons.block,
              onTap: _suspendMember,
              color: Colors.orange,
            ),
            
            Divider(color: Colors.red.withOpacity(0.3)),
            
            _buildActionItem(
              title: 'Xóa khỏi câu lạc bộ',
              subtitle: 'Loại bỏ thành viên khỏi CLB (không thể hoàn tác)',
              icon: Icons.person_remove,
              onTap: _removeMember,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _getMembershipTypeLabel(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return 'Thường';
      case MembershipType.vip:
        return 'VIP';
      case MembershipType.premium:
        return 'Premium';
    }
  }

  String _getMembershipStatusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Hoạt động';
      case MemberStatus.inactive:
        return 'Không hoạt động';
      case MemberStatus.suspended:
        return 'Tạm khóa';
      case MemberStatus.pending:
        return 'Chờ duyệt';
    }
  }

  Color _getMembershipColor() {
    switch (widget.memberData.membershipInfo.type) {
      case MembershipType.regular:
        return Colors.grey;
      case MembershipType.vip:
        return Colors.amber;
      case MembershipType.premium:
        return Colors.purple;
    }
  }

  Color _getStatusColor() {
    switch (widget.memberData.membershipInfo.status) {
      case MemberStatus.active:
        return Colors.green;
      case MemberStatus.inactive:
        return Colors.grey;
      case MemberStatus.suspended:
        return Colors.orange;
      case MemberStatus.pending:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _changeMembershipType() {
    showDialog(
      context: context,
      builder: (context) => _MembershipTypeDialog(
        currentType: widget.memberData.membershipInfo.type,
        onChanged: (newType) {
          // Update membership type
          final updatedMember = MemberData(
            id: widget.memberData.id,
            user: widget.memberData.user,
            membershipInfo: MembershipInfo(
              type: newType,
              status: widget.memberData.membershipInfo.status,
              joinDate: widget.memberData.membershipInfo.joinDate,
              membershipId: widget.memberData.membershipInfo.membershipId,
              expiryDate: widget.memberData.membershipInfo.expiryDate,
              autoRenewal: widget.memberData.membershipInfo.autoRenewal,
            ),
            activityStats: widget.memberData.activityStats,
            engagement: widget.memberData.engagement,
          );
          widget.onMemberUpdated(updatedMember);
        },
      ),
    );
  }

  void _changeMembershipStatus() {
    // Implementation for changing membership status
  }

  void _toggleAutoRenewal() {
    // Implementation for toggling auto renewal
  }

  void _extendMembership() {
    // Implementation for extending membership
  }

  void _updatePermission(String permission, bool enabled) {
    // Implementation for updating permission
  }

  void _sendMessage() {
    // Implementation for sending message
  }

  void _resetPassword() {
    // Implementation for resetting password
  }

  void _viewActivityLog() {
    // Implementation for viewing activity log
  }

  void _exportMemberData() {
    // Implementation for exporting member data
  }

  void _suspendMember() {
    // Implementation for suspending member
  }

  void _removeMember() {
    // Implementation for removing member
  }
}

class _MembershipTypeDialog extends StatelessWidget() {
  final MembershipType currentType;
  final Function(MembershipType) onChanged;

  const _MembershipTypeDialog({
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Thay đổi loại thành viên'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: MembershipType.values.map((type) {
          return RadioListTile<MembershipType>(
            value: type,
            groupValue: currentType,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
                Navigator.pop(context);
              }
            },
            title: Text(_getMembershipTypeLabel(type)),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
      ],
    );
  }

  String _getMembershipTypeLabel(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return 'Thường';
      case MembershipType.vip:
        return 'VIP';
      case MembershipType.premium:
        return 'Premium';
    }
  }
}