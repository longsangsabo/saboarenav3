import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/admin_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/custom_app_bar.dart';
import 'package:flutter/foundation.dart';

/// DEMO: User Management Screen for Admin
/// This is a proposal/mockup for future implementation
class UserManagementScreen extends StatefulWidget() {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminService _adminService = AdminService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<UserProfile> _users = [];
  List<UserProfile> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, banned, suspended, verified
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _filterUsers();
    });
  }

  Future<void> _loadUsers() async() {
    try() {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final users = await _adminService.getUsersForAdmin();

      setState(() {
        _users = users;
        _isLoading = false;
      });
      
      _filterUsers();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách users: $e';
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredUsers = _users.where((user) {
        // Search filter
        final matchesSearch = query.isEmpty ||
            user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
        
        // Status filter
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'banned':
            matchesFilter = false; // Mock data - user.isBanned not implemented
            break;
          case 'suspended':
            matchesFilter = false; // Mock data - user.isSuspended not implemented
            break;
          case 'verified':
            matchesFilter = user.isVerified ?? false;
            break;
          case 'all':
          default:
            matchesFilter = true;
        }
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildUserStats(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      height: 60.h,
      leadingWidth: 52.h,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        'Quản lý Users',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadUsers,
          tooltip: 'Làm mới',
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm user...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          
          SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả', Icons.people),
                SizedBox(width: 8),
                _buildFilterChip('banned', 'Bị ban', Icons.block),
                SizedBox(width: 8),
                _buildFilterChip('suspended', 'Bị tạm khóa', Icons.pause_circle),
                SizedBox(width: 8),
                _buildFilterChip('verified', 'Đã verify', Icons.verified),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _filterUsers();
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : appTheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : appTheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isSelected ? appTheme.primary : Colors.grey[100],
      selectedColor: appTheme.primary,
    );
  }

  Widget _buildUserStats() {
    final totalUsers = _users.length;
    final bannedUsers = _users.where((u) => u.isBanned ?? false).length;
    final verifiedUsers = _users.where((u) => u.isVerified ?? false).length;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip('Tổng cộng', totalUsers, Colors.blue),
          _buildStatChip('Bị ban', bannedUsers, Colors.red),
          _buildStatChip('Verified', verifiedUsers, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          return _buildUserCard(_filteredUsers[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Không tìm thấy user nào',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // User Info Row
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                
                SizedBox(width: 12),
                
                // User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.fullName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (user.isVerified ?? false) ...[
                            SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.blue,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Role: ${user.role ?? 'user'}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badges
                Column(
                  children: [
                    if (false)
                      _buildStatusBadge('Banned', Colors.red),
                    if (false)
                      _buildStatusBadge('Suspended', Colors.orange),
                    if (!(false) && !(false))
                      _buildStatusBadge('Active', Colors.green),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showUserDetails(user),
                    icon: Icon(Icons.info_outline, size: 16),
                    label: Text('Chi tiết'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showUserActions(user),
                    icon: Icon(Icons.admin_panel_settings, size: 16),
                    label: Text('Hành động'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showUserDetails(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết User'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${user.id}'),
              SizedBox(height: 8),
              Text('Tên: ${user.fullName}'),
              SizedBox(height: 8),
              Text('Email: ${user.email}'),
              SizedBox(height: 8),
              Text('Role: ${user.role ?? 'user'}'),
              SizedBox(height: 8),
              Text('Ngày tạo: ${user.createdAt}'),
              // Add more details as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showUserActions(UserProfile user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hành động với ${user.fullName}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            
            // Action buttons
            if (!(false))
              ListTile(
                leading: Icon(Icons.block, color: Colors.red),
                title: Text('Ban User'),
                onTap: () {
                  Navigator.pop(context);
                  _showBanDialog(user);
                },
              ),
            
            if (!(false) && !(false))
              ListTile(
                leading: Icon(Icons.pause_circle, color: Colors.orange),
                title: Text('Suspend User'),
                onTap: () {
                  Navigator.pop(context);
                  _showSuspendDialog(user);
                },
              ),
            
            if (user.isBanned ?? false)
              ListTile(
                leading: Icon(Icons.restore, color: Colors.green),
                title: Text('Khôi phục User'),
                onTap: () {
                  Navigator.pop(context);
                  _restoreUser(user);
                },
              ),
            
            if (!(user.isVerified ?? false))
              ListTile(
                leading: Icon(Icons.verified, color: Colors.blue),
                title: Text('Verify User'),
                onTap: () {
                  Navigator.pop(context);
                  _verifyUser(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showBanDialog(UserProfile user) {
    // Implementation for ban dialog
    debugPrint('Ban user: ${user.fullName}');
  }

  void _showSuspendDialog(UserProfile user) {
    // Implementation for suspend dialog
    debugPrint('Suspend user: ${user.fullName}');
  }

  void _restoreUser(UserProfile user) {
    // Implementation for restore user
    debugPrint('Restore user: ${user.fullName}');
  }

  void _verifyUser(UserProfile user) {
    // Implementation for verify user
    debugPrint('Verify user: ${user.fullName}');
  }
}
