import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/member_analytics.dart';
import '../../models/member_data.dart';
import '../../theme/app_theme.dart';
import '../../services/member_management_service.dart';
import '../tournament_management_center/tournament_management_center_screen.dart';
import '../club_settings_screen/club_settings_screen.dart';
import 'widgets/member_search_bar.dart';
import 'widgets/member_filter_section.dart';
import 'widgets/member_list_view.dart';
import 'widgets/member_analytics_card_simple.dart';
import 'widgets/bulk_action_bar.dart';
import 'widgets/add_member_dialog.dart';

class MemberManagementScreen extends StatefulWidget() {
  final String clubId;

  const MemberManagementScreen({
    super.key,
    required this.clubId,
  });

  @override
  _MemberManagementScreenState createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _filterTabController;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _showAdvancedFilters = false;
  final List<String> _selectedMembers = [];
  
  // Real data from API
  List<MemberData> _allMembers = [];
  List<MemberData> _filteredMembers = [];
  MemberAnalytics _analytics = const MemberAnalytics(
    totalMembers: 0,
    activeMembers: 0,
    newThisMonth: 0,
    growthRate: 0.0,
  );
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: 5, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );

    _loadMemberData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _filterTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async() {
    try() {
      print('🚀 Loading member data for club: ${widget.clubId}');
      // Fetch real member data from the service - get all members first
      final membersData = await MemberManagementService.getClubMembers(
        clubId: widget.clubId,
        // Don't filter by status initially, get all members
      );
      
      print('✅ Got ${membersData.length} members from service');
      
      // Calculate real analytics
      final totalMembers = membersData.length;
      final activeMembers = membersData.where((m) => m['status'] == 'active').length;
      
      // Calculate new members this month
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final newThisMonth = membersData.where((m) {
        if (m['joined_at'] != null) {
          final joinDate = DateTime.parse(m['joined_at']);
          return joinDate.isAfter(thisMonth);
        }
        return false;
      }).length;
      
      final convertedMembers = _convertToMemberData(membersData);
      print('✅ Converted ${convertedMembers.length} members to MemberData objects');
      
      setState(() {
        _allMembers = convertedMembers;
        _filteredMembers = _allMembers;
        _analytics = MemberAnalytics(
          totalMembers: totalMembers,
          activeMembers: activeMembers,
          newThisMonth: newThisMonth,
          growthRate: totalMembers > 0 ? (newThisMonth / totalMembers * 100) : 0.0,
        );
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      print('Error loading member data: $e');
      setState(() {
        _isLoading = false;
        // Fallback to empty list or show error
        _allMembers = [];
        _filteredMembers = [];
        _analytics = const MemberAnalytics(
          totalMembers: 0,
          activeMembers: 0,
          newThisMonth: 0,
          growthRate: 0.0,
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu thành viên: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildMainContent(),
      bottomNavigationBar: _buildClubBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Quản lý thành viên',
      actions: [
        Badge(
          isLabelVisible: _selectedMembers.isNotEmpty,
          label: Text(
            '${_selectedMembers.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: () => setState(() => _selectedMembers.clear()),
            tooltip: 'Xóa lựa chọn',
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download, size: 20, color: AppTheme.textSecondaryLight),
                  const SizedBox(width: 12),
                  Text(
                    'Xuất danh sách',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'import',
              child: Row(
                children: [
                  Icon(Icons.file_upload, size: 20, color: AppTheme.textSecondaryLight),
                  const SizedBox(width: 12),
                  Text(
                    'Nhập thành viên',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20, color: AppTheme.textSecondaryLight),
                  const SizedBox(width: 12),
                  Text(
                    'Cài đặt',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: _handleMenuAction,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryLight,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Đang tải danh sách thành viên...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Analytics section
              Container(
                padding: const EdgeInsets.all(20),
                color: AppTheme.surfaceLight,
                child: MemberAnalyticsCardSimple(analytics: _analytics),
              ),
              
              // Search and filter section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    MemberSearchBar(
                      controller: _searchController,
                      onChanged: _handleSearchChanged,
                      onFilterTap: _toggleAdvancedFilters,
                      showFilterIndicator: _showAdvancedFilters,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    MemberFilterSection(
                      controller: _filterTabController,
                      selectedFilter: _selectedFilter,
                      onFilterChanged: _handleFilterChanged,
                      memberCounts: _getFilterCounts(),
                      showAdvanced: _showAdvancedFilters,
                      onAdvancedFiltersChanged: _handleAdvancedFiltersChanged,
                    ),
                  ],
                ),
              ),
              
              // Bulk actions bar
              if (_selectedMembers.isNotEmpty)
                BulkActionBar(
                  selectedCount: _selectedMembers.length,
                  onAction: _handleBulkAction,
                  onClear: () => setState(() => _selectedMembers.clear()),
                ),
              
              // Member list
              Expanded(
                child: MemberListView(
                  members: _filteredMembers,
                  selectedMembers: _selectedMembers,
                  onMemberSelected: _handleMemberSelection,
                  onMemberAction: _handleMemberAction,
                  onRefresh: _handleRefresh,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddMemberDialog,
      icon: Icon(Icons.person_add),
      label: Text('Thêm thành viên'),
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
    );
  }

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterMembers();
    });
  }

  void _handleFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterMembers();
    });
  }

  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });
  }

  void _handleAdvancedFiltersChanged(AdvancedFilters filters) {
    // Apply advanced filters
    _filterMembers();
  }

  void _handleMemberSelection(String memberId, bool selected) {
    setState(() {
      if (selected) {
        _selectedMembers.add(memberId);
      } else() {
        _selectedMembers.remove(memberId);
      }
    });
  }

  void _handleMemberAction(String action, String memberId) {
    switch (action) {
      case 'view-profile':
        _navigateToMemberDetail(memberId);
        break;
      case 'message':
        _showMessageDialog(memberId);
        break;
      case 'view-stats':
        _showMemberStats(memberId);
        break;
      case 'more':
        _showMemberMoreActions(memberId);
        break;
    }
  }

  void _handleBulkAction(String action) {
    switch (action) {
      case 'message':
        _showBulkMessageDialog();
        break;
      case 'promote':
        _showBulkPromoteDialog();
        break;
      case 'export':
        _exportSelectedMembers();
        break;
      case 'remove':
        _showBulkRemoveDialog();
        break;
    }
  }

  Future<void> _handleRefresh() async() {
    await _loadMemberData();
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportAllMembers();
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'settings':
        _navigateToMemberSettings();
        break;
    }
  }

  void _filterMembers() {
    setState(() {
      _filteredMembers = _allMembers.where((member) {
        // Text search
        final matchesSearch = _searchQuery.isEmpty ||
          member.user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          member.user.username.toLowerCase().contains(_searchQuery.toLowerCase());

        // Status filter
        final matchesStatus = _selectedFilter == 'all' ||
          (_selectedFilter == 'active' && member.membershipInfo.status == MemberStatus.active) ||
          (_selectedFilter == 'new' && _isNewMember(member)) ||
          (_selectedFilter == 'inactive' && member.membershipInfo.status == MemberStatus.inactive) ||
          (_selectedFilter == 'pending' && member.membershipInfo.status == MemberStatus.pending);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Map<String, int> _getFilterCounts() {
    return() {
      'all': _allMembers.length,
      'active': _allMembers.where((m) => m.membershipInfo.status == MemberStatus.active).length,
      'new': _allMembers.where((m) => _isNewMember(m)).length,
      'inactive': _allMembers.where((m) => m.membershipInfo.status == MemberStatus.inactive).length,
      'pending': _allMembers.where((m) => m.membershipInfo.status == MemberStatus.pending).length,
    };
  }

  bool _isNewMember(MemberData member) {
    final now = DateTime.now();
    final joinDate = member.membershipInfo.joinDate;
    return now.difference(joinDate).inDays <= 30;
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        clubId: widget.clubId,
        onMemberAdded: (member) {
          setState(() {
            _allMembers.insert(0, member);
            _filterMembers();
          });
          _loadMemberData(); // Refresh the member list from API
        },
      ),
    );
  }

  void _navigateToMemberDetail(String memberId) {
    Navigator.pushNamed(
      context,
      '/member-detail',
      arguments: {'clubId': widget.clubId, 'memberId': memberId},
    );
  }

  void _showMessageDialog(String memberId) {
    // Implementation for single member message
  }

  void _showMemberStats(String memberId) {
    // Implementation for member statistics
  }

  void _showMemberMoreActions(String memberId) {
    // Implementation for more member actions
  }

  void _showBulkMessageDialog() {
    // Implementation for bulk messaging
  }

  void _showBulkPromoteDialog() {
    // Implementation for bulk promotion
  }

  void _exportSelectedMembers() {
    // Implementation for exporting selected members
  }

  void _showBulkRemoveDialog() {
    // Implementation for bulk removal
  }

  void _exportAllMembers() {
    // Implementation for exporting all members
  }

  void _showImportDialog() {
    // Implementation for member import
  }

  void _navigateToMemberSettings() {
    Navigator.pushNamed(context, '/member-settings');
  }

  Widget _buildClubBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryLight,
      unselectedItemColor: Colors.grey[600],
      backgroundColor: Colors.white,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Thành viên',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.emoji_events),
          label: 'Giải đấu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Cài đặt',
        ),
      ],
      currentIndex: 1, // Current tab is "Thành viên"
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pop(context); // Go back to dashboard
            break;
          case 1:
            // Already on member management
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TournamentManagementCenterScreen(clubId: widget.clubId),
              ),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ClubSettingsScreen(clubId: widget.clubId),
              ),
            );
            break;
        }
      },
    );
  }

  List<MemberData> _convertToMemberData(List<Map<String, dynamic>> apiData) {
    return apiData.map((data) {
      return MemberData.fromSupabaseData(data);
    }).toList();
  }

}