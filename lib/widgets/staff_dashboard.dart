import 'package:flutter/material.dart';
import '../services/club_staff_service.dart';
import '../services/commission_service.dart';

/// Widget hiển thị dashboard cho staff với earnings và analytics
class StaffDashboard extends StatefulWidget {
  const StaffDashboard({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final String staffId;
  final Map<String, dynamic> staffInfo;

  const StaffDashboard({
    Key? key,
    required this.staffId,
    required this.staffInfo,
  }) : super(key: key);

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _earnings = {};
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    setState(() => _isLoading = true);

    final earnings = await ClubStaffService.getStaffEarnings(widget.staffId);
    final analytics = await CommissionService.getStaffCommissionAnalytics(
      staffId: widget.staffId,
    );

    setState(() {
      _earnings = earnings;
      _analytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Dashboard - ${widget.staffInfo['users']['full_name']}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStaffData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStaffInfoCard(),
                    const SizedBox(height: 16),
                    _buildEarningsOverview(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildRecentCommissions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStaffInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo,
                  child: Text(
                    widget.staffInfo['users']['full_name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.staffInfo['users']['full_name'],
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Chức vụ: ${_getStaffRoleText(widget.staffInfo['staff_role'])}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Club: ${widget.staffInfo['clubs']['name']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Hoa hồng ${widget.staffInfo['commission_rate']}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsOverview() {
    if (!_earnings['success']) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Không thể tải dữ liệu thu nhập: ${_earnings['message']}'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan thu nhập',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildEarningsMetric(
                    'Tổng hoa hồng',
                    '${(_earnings['total_commissions'] ?? 0).toStringAsFixed(0)} VND',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEarningsMetric(
                    'Tháng này',
                    '${(_earnings['this_month_commissions'] ?? 0).toStringAsFixed(0)} VND',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEarningsMetric(
                    'Khách hàng active',
                    '${_earnings['active_referrals'] ?? 0}',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildEarningsMetric(
                    'Doanh thu khách',
                    '${(_earnings['total_customer_spending'] ?? 0).toStringAsFixed(0)} VND',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác nhanh',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Tạo mã QR',
                    Icons.qr_code,
                    Colors.blue,
                    () => _generateStaffQRCode(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Xem báo cáo',
                    Icons.assessment,
                    Colors.green,
                    () => _viewDetailedReport(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Khách hàng',
                    Icons.people_outline,
                    Colors.orange,
                    () => _viewCustomers(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Lịch sử HH',
                    Icons.history,
                    Colors.purple,
                    () => _viewCommissionHistory(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCommissions() {
    final recentCommissions = _earnings['recent_commissions'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hoa hồng gần đây',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _viewCommissionHistory,
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentCommissions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có hoa hồng nào'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentCommissions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final commission = recentCommissions[index];
                  return _buildCommissionItem(commission);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionItem(Map<String, dynamic> commission) {
    final amount = (commission['commission_amount'] as num).toDouble();
    final type = commission['commission_type'] ?? 'other';
    final date = DateTime.parse(commission['earned_at']);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: _getCommissionTypeColor(type).withValues(alpha: 0.2),
        child: Icon(
          _getCommissionTypeIcon(type),
          color: _getCommissionTypeColor(type),
        ),
      ),
      title: Text(
        _getCommissionTypeText(type),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year}',
        style: TextStyle(color: Colors.grey[600]),
      ),
      trailing: Text(
        '+${amount.toStringAsFixed(0)} VND',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    );
  }

  // Helper methods
  String _getStaffRoleText(String role) {
    switch (role) {
      case 'owner':
        return 'Chủ sở hữu';
      case 'manager':
        return 'Quản lý';
      case 'staff':
        return 'Nhân viên';
      case 'cashier':
        return 'Thu ngân';
      default:
        return role;
    }
  }

  Color _getCommissionTypeColor(String type) {
    switch (type) {
      case 'tournament_commission':
        return Colors.blue;
      case 'spa_commission':
        return Colors.green;
      case 'rental_commission':
        return Colors.orange;
      case 'membership_commission':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCommissionTypeIcon(String type) {
    switch (type) {
      case 'tournament_commission':
        return Icons.sports_esports;
      case 'spa_commission':
        return Icons.spa;
      case 'rental_commission':
        return Icons.sports_tennis;
      case 'membership_commission':
        return Icons.card_membership;
      default:
        return Icons.monetization_on;
    }
  }

  String _getCommissionTypeText(String type) {
    switch (type) {
      case 'tournament_commission':
        return 'Hoa hồng giải đấu';
      case 'spa_commission':
        return 'Hoa hồng SPA';
      case 'rental_commission':
        return 'Hoa hồng thuê sân';
      case 'membership_commission':
        return 'Hoa hồng thành viên';
      default:
        return 'Hoa hồng khác';
    }
  }

  // Action methods
  void _generateStaffQRCode() {
    // TODO: Implement QR code generation for staff
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng tạo mã QR đang phát triển')),
    );
  }

  void _viewDetailedReport() {
    // TODO: Navigate to detailed report screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng báo cáo chi tiết đang phát triển')),
    );
  }

  void _viewCustomers() {
    // TODO: Navigate to customers screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xem khách hàng đang phát triển')),
    );
  }

  void _viewCommissionHistory() {
    // TODO: Navigate to commission history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng lịch sử hoa hồng đang phát triển')),
    );
  }
}