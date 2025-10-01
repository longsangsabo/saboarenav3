import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_service.dart';

class AdminUserManagementScreen extends StatefulWidget() {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final AdminService _adminService = AdminService.instance;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async() {
    try() {
      setState(() {
        _isLoading = true;
      });

      // Using mock data for now since we don't have user management in AdminService yet
      await Future.delayed(Duration(seconds: 1)); // Simulate API call
      
      _users = [
        {
          "id": '1',
          "email": 'admin@saboarena.com',
          "full_name": 'Admin User',
          "rank": 'F+',
          'elo': 1982,
          "status": 'active',
          'created_at': DateTime.now().subtract(Duration(days: 30)),
          "role": 'admin',
          'is_verified': true,
        },
        {
          "id": '2',
          "email": 'longsang063@gmail.com',
          "full_name": 'Hồ Minh',
          "rank": 'E+',
          'elo': 2156,
          "status": 'active',
          'created_at': DateTime.now().subtract(Duration(days: 15)),
          "role": 'user',
          'is_verified': true,
        },
        {
          "id": '3',
          "email": 'player1@example.com',
          "full_name": 'Hoàng Trang',
          "rank": 'H+',
          'elo': 1594,
          "status": 'active',
          'created_at': DateTime.now().subtract(Duration(days: 7)),
          "role": 'user',
          'is_verified': true,
        },
        {
          "id": '4',
          "email": 'player2@example.com',
          "full_name": 'Lý Hải',
          "rank": 'G+',
          'elo': 1729,
          "status": 'blocked',
          'created_at': DateTime.now().subtract(Duration(days: 3)),
          "role": 'user',
          'is_verified': false,
        },
        // Add more demo users...
        for (int i = 5; i <= 20; i++)
          {
            "id": '$i',
            "email": 'demo$i@saboarena.com',
            "full_name": 'Demo User $i',
            'rank': ['K', 'K+', 'I', 'I+', 'H', 'H+', 'G', 'G+', 'F', 'F+', 'E', 'E+'][(i - 5) % 12],
            'elo': 1200 + (i * 50),
            'status': ['active', 'inactive', 'blocked'][i % 3],
            'created_at': DateTime.now().subtract(Duration(days: i)),
            "role": 'user',
            'is_verified': i % 2 == 0,
          }
      ];

      _filterUsers();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _filterUsers() {
    _filteredUsers = _users.where((user) {
      final matchesSearch = user['full_name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          user['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && user['status'] == 'active') ||
          (_selectedFilter == 'inactive' && user['status'] == 'inactive') ||
          (_selectedFilter == 'blocked' && user['status'] == 'blocked') ||
          (_selectedFilter == 'admin' && user['role'] == 'admin') ||
          (_selectedFilter == 'verified' && user['is_verified'] == true) ||
          (_selectedFilter == 'unverified' && user['is_verified'] == false);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quản lý Users',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primaryLight),
            onPressed: _showCreateUserDialog,
            tooltip: 'Tạo user mới',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.textPrimaryLight),
            onPressed: _loadUsers,
            tooltip: 'Làm mới',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          indicatorColor: AppTheme.primaryLight,
          tabs: const [
            Tab(text: 'Tất cả Users'),
            Tab(text: 'Thống kê'),
            Tab(text: 'Hoạt động'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildStatsTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm user...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textSecondaryLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.dividerLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.dividerLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryLight),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _filterUsers();
              });
            },
          ),
          SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả'),
                _buildFilterChip('active', 'Hoạt động'),
                _buildFilterChip('inactive', 'Không hoạt động'),
                _buildFilterChip('blocked', 'Bị khóa'),
                _buildFilterChip('admin', 'Admin'),
                _buildFilterChip('verified', 'Đã xác thực'),
                _buildFilterChip('unverified', 'Chưa xác thực'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            _filterUsers();
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppTheme.primaryLight.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryLight : AppTheme.textSecondaryLight,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(user['status']).withOpacity(0.1),
          child: Text(
            user['full_name'].toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: _getStatusColor(user['status']),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['full_name'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ),
            if (user['role'] == 'admin')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            if (user['is_verified'])
              Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              user['email'],
              style: TextStyle(color: AppTheme.textSecondaryLight),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('Rank ${user['rank']}', Colors.purple),
                SizedBox(width: 8),
                _buildInfoChip('ELO ${user['elo']}', Colors.green),
                SizedBox(width: 8),
                _buildInfoChip(
                  _getStatusText(user['status']),
                  _getStatusColor(user['status']),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(user, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility, size: 20),
                title: Text('Xem chi tiết'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit, size: 20),
                title: Text('Chỉnh sửa'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (user['status'] == 'active')
              PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block, size: 20, color: Colors.red),
                  title: Text('Khóa tài khoản', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            if (user['status'] == 'blocked')
              PopupMenuItem(
                value: 'unblock',
                child: ListTile(
                  leading: Icon(Icons.lock_open, size: 20, color: Colors.green),
                  title: Text('Mở khóa', style: TextStyle(color: Colors.green)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 20, color: Colors.red),
                title: Text('Xóa user', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondaryLight),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy user nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc tìm kiếm',
            style: TextStyle(color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((u) => u['status'] == 'active').length;
    final blockedUsers = _users.where((u) => u['status'] == 'blocked').length;
    final adminUsers = _users.where((u) => u['role'] == 'admin').length;
    final verifiedUsers = _users.where((u) => u['is_verified'] == true).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê Users',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('$totalUsers', 'Tổng Users', Icons.people, AppTheme.primaryLight),
              _buildStatCard('$activeUsers', 'Hoạt động', Icons.check_circle, Colors.green),
              _buildStatCard('$blockedUsers', 'Bị khóa', Icons.block, Colors.red),
              _buildStatCard('$adminUsers', 'Admin', Icons.admin_panel_settings, Colors.orange),
              _buildStatCard('$verifiedUsers', 'Đã xác thực', Icons.verified, Colors.blue),
              _buildStatCard('${totalUsers - verifiedUsers}', 'Chưa xác thực', Icons.error, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppTheme.textSecondaryLight),
          SizedBox(height: 16),
          Text(
            'Lịch sử hoạt động',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tính năng đang được phát triển',
            style: TextStyle(color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      case 'blocked':
        return 'Bị khóa';
      default:
        return 'Không xác định';
    }
  }

  void _handleUserAction(Map<String, dynamic> user, String action) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'block':
        _confirmBlockUser(user);
        break;
      case 'unblock':
        _confirmUnblockUser(user);
        break;
      case 'delete':
        _confirmDeleteUser(user);
        break;
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text('Chi tiết User'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Tên:', user['full_name']),
              _buildDetailRow('Email:', user['email']),
              _buildDetailRow('Rank:', user['rank']),
              _buildDetailRow('ELO:', user['elo'].toString()),
              _buildDetailRow('Trạng thái:', _getStatusText(user['status'])),
              _buildDetailRow('Vai trò:', user['role'] == 'admin' ? "Admin" : 'User'),
              _buildDetailRow('Xác thực:', user['is_verified'] ? "Đã xác thực" : 'Chưa xác thực'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Chỉnh sửa User'),
          content: Text('Tính năng đang được phát triển'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _confirmBlockUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Khóa tài khoản'),
          content: Text('Bạn có chắc muốn khóa tài khoản "${user['full_name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _blockUser(user);
              },
              child: Text('Khóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmUnblockUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Mở khóa tài khoản'),
          content: Text('Bạn có chắc muốn mở khóa tài khoản "${user['full_name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unblockUser(user);
              },
              child: Text('Mở khóa', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Xóa User'),
          content: Text('Bạn có chắc muốn xóa user "${user['full_name']}"? Hành động này không thể hoàn tác.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteUser(user);
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.person_add, color: AppTheme.primaryLight),
              SizedBox(width: 8),
              Text('Tạo User mới'),
            ],
          ),
          content: Text('Tính năng đang được phát triển'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _blockUser(Map<String, dynamic> user) {
    setState(() {
      user['status'] = 'blocked';
      _filterUsers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã khóa tài khoản ${user['full_name']}')),
    );
  }

  void _unblockUser(Map<String, dynamic> user) {
    setState(() {
      user['status'] = 'active';
      _filterUsers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã mở khóa tài khoản ${user['full_name']}')),
    );
  }

  void _deleteUser(Map<String, dynamic> user) {
    setState(() {
      _users.removeWhere((u) => u['id'] == user['id']);
      _filterUsers();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa user ${user['full_name']}')),
    );
  }
}