import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';
import '../../routes/app_routes.dart';
import './widgets/admin_scaffold_wrapper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

@override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
    return AdminScaffoldWrapper(
      title: 'Dashboard',
      currentIndex: 0,
      onBottomNavTap: _onNavTap,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionCard(
              'Duyệt CLB',
              Icons.approval,
              Colors.blue,
              () => _navigateToTab(1),
            ),
            _buildQuickActionCard(
              'Quản lý User',
              Icons.people_alt,
              Colors.green,
              () => _navigateToTab(3),
            ),
            _buildQuickActionCard(
              'Tournament',
              Icons.emoji_events,
              Colors.orange,
              () => _navigateToTab(2),
            ),
            _buildQuickActionCard(
              'Cài đặt',
              Icons.settings,
              Colors.grey,
              () => _navigateToTab(4),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerLight),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerLight),
          ),
          child: _recentActivities.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: AppTheme.textSecondaryLight),
                        SizedBox(height: 8),
                        Text(
                          'Chưa có hoạt động gần đây',
                          style: TextStyle(color: AppTheme.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                        child: Icon(
                          Icons.notifications,
                          color: AppTheme.primaryLight,
                          size: 20,
                        ),
                      ),
                      title: Text(activity['title'] ?? ''),
                      subtitle: Text(activity['description'] ?? ''),
                      trailing: Text(
                        activity['time'] ?? '',
                        style: TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _onNavTap(int index) {
    if (index != 0) {
      _navigateToTab(index);
    }
  }

  void _navigateToTab(int index) {
    final routes = [
      AppRoutes.adminDashboardScreen, // Dashboard - current
      AppRoutes.clubApprovalScreen, // Duyệt CLB  
      AppRoutes.adminTournamentScreen, // Tournament
      AppRoutes.adminUserManagementScreen, // Users
      AppRoutes.adminMoreScreen, // Khác
    ];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}

