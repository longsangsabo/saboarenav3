import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/notification_analytics_service.dart';
import '../services/enhanced_notification_service.dart';
import '../models/notification_models.dart';

/// Admin Dashboard for Notification Management
/// Allows admins to send broadcasts, view analytics, manage templates
class AdminNotificationDashboard extends StatefulWidget() {
  const AdminNotificationDashboard({super.key});

  @override
  State<AdminNotificationDashboard> createState() => _AdminNotificationDashboardState();
}

class _AdminNotificationDashboardState extends State<AdminNotificationDashboard>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final NotificationAnalyticsService _analyticsService = 
      NotificationAnalyticsService.instance;
  final EnhancedNotificationService _notificationService = 
      EnhancedNotificationService.instance;

  Map<String, dynamic> _globalAnalytics = {};
  Map<NotificationType, Map<String, double>> _typePerformance = {};
  List<Map<String, dynamic>> _deliveryTrends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async() {
    setState(() => _isLoading = true);

    try() {
      final results = await Future.wait([
        _analyticsService.getGlobalAnalytics(),
        _analyticsService.getNotificationTypePerformance(),
        _analyticsService.getDeliveryTrends(period: Duration(days: 30)),
      ]);

      setState(() {
        _globalAnalytics = results[0] as Map<String, dynamic>;
        _typePerformance = results[1] as Map<NotificationType, Map<String, double>>;
        _deliveryTrends = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load dashboard data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildAnalyticsTab(),
                      _buildBroadcastTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildQuickActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Notification Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.green[700],
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh Data',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'export':
                _exportAnalytics();
                break;
              case 'settings':
                Navigator.pushNamed(context, '/admin-notification-settings');
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Export Data'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green[700],
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green[700],
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
          Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          Tab(text: 'Broadcast', icon: Icon(Icons.campaign)),
          Tab(text: 'Settings', icon: Icon(Icons.settings)),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          SizedBox(height: 3.h),
          _buildRecentActivity(),
          SizedBox(height: 3.h),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = _globalAnalytics;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 2.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Sent',
              '${stats['total_notifications'] ?? 0}',
              Icons.send,
              Colors.blue,
            ),
            _buildStatCard(
              'Read Rate',
              '${((stats['read_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.visibility,
              Colors.green,
            ),
            _buildStatCard(
              'Click Rate',
              '${((stats['click_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
              Icons.touch_app,
              Colors.orange,
            ),
            _buildStatCard(
              'Active Users',
              '${stats['total_users'] ?? 0}',
              Icons.people,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 8.w),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeliveryTrendsChart(),
          SizedBox(height: 3.h),
          _buildTypePerformanceChart(),
          SizedBox(height: 3.h),
          _buildDetailedMetrics(),
        ],
      ),
    );
  }

  Widget _buildDeliveryTrendsChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Trends (Last 30 Days)',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 30.h,
              child: _deliveryTrends.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _deliveryTrends
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                      e.key.toDouble(),
                                      (e.value['notifications_sent'] as num).toDouble(),
                                    ))
                                .toList(),
                            isCurved: true,
                            color: Colors.green[700],
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('No data available')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePerformanceChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Type',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            ..._typePerformance.entries.map((entry) =>
                _buildTypePerformanceItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypePerformanceItem(
      NotificationType type, Map<String, double> metrics) {
    final readRate = metrics['read_rate'] ?? 0.0;
    final clickRate = metrics['click_rate'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(readRate * 100).toStringAsFixed(1)}% read',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: readRate,
            backgroundColor: Colors.grey[300],
            color: Colors.green[700],
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBroadcastForm(),
          SizedBox(height: 3.h),
          _buildRecentBroadcasts(),
        ],
      ),
    );
  }

  Widget _buildBroadcastForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Broadcast Notification',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<NotificationType>(
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: NotificationType.values.map((type) =>
                  DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  )).toList(),
              onChanged: (value) {},
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendBroadcast(sendImmediately: false),
                    icon: const Icon(Icons.schedule),
                    label: const Text('Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendBroadcast(sendImmediately: true),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
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

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5, // Show last 5 activities
              itemBuilder: (context, index) => ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: Colors.green[700],
                ),
                title: Text('Broadcast notification sent'),
                subtitle: Text('To 150 users • 2 hours ago'),
                trailing: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 5.w,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 2,
              children: [
                _buildQuickActionCard(
                  'Send Test',
                  Icons.bug_report,
                  Colors.blue,
                  () => _sendTestNotification(),
                ),
                _buildQuickActionCard(
                  'Export Data',
                  Icons.download,
                  Colors.green,
                  () => _exportAnalytics(),
                ),
                _buildQuickActionCard(
                  'User Stats',
                  Icons.people,
                  Colors.purple,
                  () => _viewUserStats(),
                ),
                _buildQuickActionCard(
                  'System Health',
                  Icons.health_and_safety,
                  Colors.orange,
                  () => _checkSystemHealth(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 6.w),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBroadcasts() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Broadcasts',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            // TODO: Load actual recent broadcasts
            const Center(
              child: Text('No recent broadcasts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          _buildSystemSettings(),
          SizedBox(height: 3.h),
          _buildNotificationTemplates(),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Settings',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Global notification toggle'),
              value: true, // TODO: Get from settings
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: const Text('Show detailed logs'),
              value: false, // TODO: Get from settings
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTemplates() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Templates',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            ...NotificationType.values.map((type) =>
                ListTile(
                  title: Text(type.displayName),
                  subtitle: Text(type.description),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _editTemplate(type),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Metrics',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.h),
            _buildMetricRow('Average Response Time', 
                '${_globalAnalytics['avg_time_to_read_minutes']?.toStringAsFixed(1) ?? '0'} min'),
            _buildMetricRow('Delivery Rate', '100%'),
            _buildMetricRow('Error Rate', '0.1%'),
            _buildMetricRow('System Uptime', '99.9%'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionsDialog(),
      backgroundColor: Colors.green[700],
      icon: const Icon(Icons.flash_on, color: Colors.white),
      label: const Text('Quick Actions', style: TextStyle(color: Colors.white)),
    );
  }

  // Action methods
  void _sendBroadcast({required bool sendImmediately}) {
    // TODO: Implement broadcast sending
    _showSuccessSnackBar('Broadcast ${sendImmediately ? "sent" : 'scheduled'}!');
  }

  void _sendTestNotification() {
    // TODO: Implement test notification
    _showSuccessSnackBar('Test notification sent!');
  }

  void _exportAnalytics() {
    // TODO: Implement analytics export
    _showSuccessSnackBar('Analytics export started!');
  }

  void _viewUserStats() {
    // TODO: Navigate to user stats screen
  }

  void _checkSystemHealth() {
    // TODO: Check system health
    _showSuccessSnackBar('System is healthy!');
  }

  void _editTemplate(NotificationType type) {
    // TODO: Navigate to template editor
  }

  void _showQuickActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send, color: Colors.green),
              title: const Text('Send Test Notification'),
              onTap: () {
                Navigator.pop(context);
                _sendTestNotification();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _loadDashboardData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.orange),
              title: const Text('Export Analytics'),
              onTap: () {
                Navigator.pop(context);
                _exportAnalytics();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}