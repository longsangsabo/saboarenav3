import 'package:flutter/material.dart';
import '../services/club_staff_service.dart';
import '../services/commission_service.dart';

/// Widget quản lý nhân viên club cho owner/manager
class ClubStaffManager extends StatefulWidget {
  const ClubStaffManager({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final String clubId;
  final String clubName;

  const ClubStaffManager({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  State<ClubStaffManager> createState() => _ClubStaffManagerState();
}

class _ClubStaffManagerState extends State<ClubStaffManager>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _staffList = [];
  Map<String, dynamic> _clubAnalytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClubData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClubData() async {
    setState(() => _isLoading = true);

    final staffList = await ClubStaffService.getClubStaff(widget.clubId);
    final analytics = await CommissionService.getClubCommissionAnalytics(
      clubId: widget.clubId,
    );

    setState(() {
      _staffList = staffList;
      _clubAnalytics = analytics;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý nhân viên - ${widget.clubName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Nhân viên'),
            Tab(icon: Icon(Icons.analytics), text: 'Phân tích'),
            Tab(icon: Icon(Icons.payment), text: 'Hoa hồng'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStaffTab(),
                _buildAnalyticsTab(),
                _buildCommissionTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm nhân viên'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }

  // =====================================================
  // STAFF MANAGEMENT TAB
  // =====================================================

  Widget _buildStaffTab() {
    return RefreshIndicator(
      onRefresh: _loadClubData,
      child: _staffList.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có nhân viên nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nhấn nút + để thêm nhân viên đầu tiên',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _staffList.length,
              itemBuilder: (context, index) {
                final staff = _staffList[index];
                return _buildStaffCard(staff);
              },
            ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
    final user = staff['users'];
    final role = staff['staff_role'];
    final commissionRate = staff['commission_rate'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: _getRoleColor(role),
                  backgroundImage: user['avatar_url'] != null
                      ? NetworkImage(user['avatar_url'])
                      : null,
                  child: user['avatar_url'] == null
                      ? Text(
                          user['full_name'][0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleText(role),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'HH: $commissionRate%',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleStaffAction(value, staff),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view',
                      child: ListTile(
                        leading: Icon(Icons.visibility),
                        title: Text('Xem chi tiết'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Sửa thông tin'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'qr',
                      child: ListTile(
                        leading: Icon(Icons.qr_code),
                        title: Text('Tạo mã QR'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.remove_circle, color: Colors.red),
                        title: Text('Xóa nhân viên', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPermissionChip(
                  'Nhập điểm',
                  staff['can_enter_scores'],
                  Icons.sports_score,
                ),
                const SizedBox(width: 8),
                _buildPermissionChip(
                  'Quản lý giải',
                  staff['can_manage_tournaments'],
                  Icons.sports_esports,
                ),
                const SizedBox(width: 8),
                _buildPermissionChip(
                  'Xem báo cáo',
                  staff['can_view_reports'],
                  Icons.assessment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionChip(String label, bool hasPermission, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasPermission ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPermission ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: hasPermission ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: hasPermission ? Colors.green : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ANALYTICS TAB
  // =====================================================

  Widget _buildAnalyticsTab() {
    if (!_clubAnalytics['success']) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Không thể tải dữ liệu: ${_clubAnalytics['message']}'),
          ],
        ),
      );
    }

    final summary = _clubAnalytics['summary'] ?? {};
    final staffPerformance = _clubAnalytics['staff_performance'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsSummary(summary),
          const SizedBox(height: 16),
          _buildStaffPerformanceChart(staffPerformance),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan (30 ngày qua)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Tổng hoa hồng',
                    '${(summary['total_commissions_paid'] ?? 0).toStringAsFixed(0)} VND',
                    Icons.payment,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    'Doanh thu tạo ra',
                    '${(summary['total_revenue_generated'] ?? 0).toStringAsFixed(0)} VND',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    'Tỷ lệ HH trung bình',
                    '${(summary['commission_rate_avg'] ?? 0).toStringAsFixed(1)}%',
                    Icons.percent,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryMetric(
                    'Tổng giao dịch',
                    '${summary['total_transactions'] ?? 0}',
                    Icons.receipt,
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

  Widget _buildSummaryMetric(String title, String value, IconData icon, Color color) {
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPerformanceChart(Map<String, dynamic> staffPerformance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu suất nhân viên',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (staffPerformance.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có dữ liệu hiệu suất'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staffPerformance.keys.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final staffName = staffPerformance.keys.elementAt(index);
                  final performance = staffPerformance[staffName];
                  return _buildStaffPerformanceItem(staffName, performance);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffPerformanceItem(String staffName, Map<String, dynamic> performance) {
    final commissions = (performance['total_commissions'] as num).toDouble();
    final revenue = (performance['total_revenue_generated'] as num).toDouble();
    final customers = performance['unique_customers'] ?? 0;
    final transactions = performance['transaction_count'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            staffName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoa hồng: ${commissions.toStringAsFixed(0)} VND',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Doanh thu: ${revenue.toStringAsFixed(0)} VND',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$customers khách hàng',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$transactions giao dịch',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // COMMISSION TAB
  // =====================================================

  Widget _buildCommissionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCommissionActions(),
          const SizedBox(height: 16),
          _buildRecentCommissions(),
        ],
      ),
    );
  }

  Widget _buildCommissionActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý hoa hồng',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewPendingCommissions,
                    icon: const Icon(Icons.pending_actions),
                    label: const Text('HH chờ thanh toán'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _exportCommissionReport,
                    icon: const Icon(Icons.download),
                    label: const Text('Xuất báo cáo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildRecentCommissions() {
    final recentCommissions = _clubAnalytics['recent_commissions'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoa hồng gần đây',
              style: Theme.of(context).textTheme.titleLarge,
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
    final staffName = commission['club_staff']['users']['full_name'];
    final amount = (commission['commission_amount'] as num).toDouble();
    final isPaid = commission['is_paid'] == true;
    final date = DateTime.parse(commission['earned_at']);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isPaid ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
        child: Icon(
          isPaid ? Icons.check_circle : Icons.pending,
          color: isPaid ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(
        staffName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${date.day}/${date.month}/${date.year} - ${isPaid ? "Đã thanh toán" : 'Chờ thanh toán'}',
        style: TextStyle(
          color: isPaid ? Colors.green : Colors.orange,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        '${amount.toStringAsFixed(0)} VND',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      case 'staff':
        return Colors.green;
      case 'cashier':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String role) {
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

  // =====================================================
  // ACTION METHODS
  // =====================================================

  void _showAddStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddStaffDialog(
        clubId: widget.clubId,
        onStaffAdded: _loadClubData,
      ),
    );
  }

  void _handleStaffAction(String action, Map<String, dynamic> staff) {
    switch (action) {
      case 'view':
        _viewStaffDetails(staff);
        break;
      case 'edit':
        _editStaff(staff);
        break;
      case 'qr':
        _generateStaffQR(staff);
        break;
      case 'remove':
        _removeStaff(staff);
        break;
    }
  }

  void _viewStaffDetails(Map<String, dynamic> staff) {
    // TODO: Navigate to staff details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chi tiết nhân viên ${staff['users']['full_name']}')),
    );
  }

  void _editStaff(Map<String, dynamic> staff) {
    // TODO: Show edit staff dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng sửa nhân viên đang phát triển')),
    );
  }

  void _generateStaffQR(Map<String, dynamic> staff) {
    // TODO: Generate and show QR code
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng tạo mã QR đang phát triển')),
    );
  }

  void _removeStaff(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa nhân viên'),
        content: Text('Bạn có chắc muốn xóa ${staff['users']['full_name']} khỏi danh sách nhân viên?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _confirmRemoveStaff(staff['id']),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveStaff(String staffId) async {
    Navigator.pop(context);
    
    final result = await ClubStaffService.removeStaff(
      staffId: staffId,
      reason: 'Removed by manager',
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      _loadClubData();
    } else() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewPendingCommissions() {
    // TODO: Navigate to pending commissions screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng HH chờ thanh toán đang phát triển')),
    );
  }

  void _exportCommissionReport() {
    // TODO: Generate and export commission report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng xuất báo cáo đang phát triển')),
    );
  }
}

// =====================================================
// ADD STAFF DIALOG
// =====================================================

class _AddStaffDialog extends StatefulWidget {
  final String clubId;
  final VoidCallback onStaffAdded;

  const _AddStaffDialog({
    
    required this.clubId,
    required this.onStaffAdded,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  State<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<_AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  String _selectedRole = 'staff';
  double _commissionRate = 5.0;
  bool _canEnterScores = true;
  bool _canManageTournaments = false;
  bool _canViewReports = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm nhân viên mới'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email nhân viên',
                  hintText: 'Nhập email của người dùng',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!value.contains('@')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Chức vụ'),
                items: const [
                  DropdownMenuItem(value: 'staff', child: Text('Nhân viên')),
                  DropdownMenuItem(value: 'manager', child: Text('Quản lý')),
                  DropdownMenuItem(value: 'cashier', child: Text('Thu ngân')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Tỷ lệ hoa hồng:'),
                  const Spacer(),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      value: _commissionRate.toString(),
                      decoration: const InputDecoration(suffixText: '%'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final rate = double.tryParse(value) ?? 5.0;
                        setState(() => _commissionRate = rate.clamp(0, 50));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Quyền hạn:', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Nhập điểm trận đấu'),
                value: _canEnterScores,
                onChanged: (value) => setState(() => _canEnterScores = value!),
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Quản lý giải đấu'),
                value: _canManageTournaments,
                onChanged: (value) => setState(() => _canManageTournaments = value!),
                dense: true,
              ),
              CheckboxListTile(
                title: const Text('Xem báo cáo'),
                value: _canViewReports,
                onChanged: (value) => setState(() => _canViewReports = value!),
                dense: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addStaff,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }

  Future<void> _addStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: First find user by email, then add as staff
    // For now, we'll show a placeholder
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng thêm nhân viên đang được phát triển.\nCần tích hợp tìm user theo email trước.'),
      ),
    );

    widget.onStaffAdded();
  }
}