import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class MembershipRequestScreen extends StatefulWidget() {
  const MembershipRequestScreen({super.key});

  @override
  _MembershipRequestScreenState createState() => _MembershipRequestScreenState();
}

class _MembershipRequestScreenState extends State<MembershipRequestScreen>
    with TickerProviderStateMixin() {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<MembershipRequest> _pendingRequests = [];
  List<MembershipRequest> _approvedRequests = [];
  List<MembershipRequest> _rejectedRequests = [];

  bool _isLoading = false;
  String _searchQuery = '';
  RequestFilter _currentFilter = RequestFilter.all;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadRequests();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchAndFilter(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllRequestsTab(),
                  _buildPendingRequestsTab(),
                  _buildApprovedRequestsTab(),
                  _buildRejectedRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteMemberDialog,
        icon: Icon(Icons.person_add),
        label: Text('Mời thành viên'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Yêu cầu thành viên',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _refreshRequests,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download, size: 20),
                  SizedBox(width: 8),
                  Text('Xuất danh sách'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Cài đặt'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm kiếm yêu cầu...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Lọc: ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: RequestFilter.values.map((filter) {
                      final isSelected = _currentFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getFilterLabel(filter)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _currentFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            text: 'Tất cả',
            icon: Badge(
              label: Text('${_getAllRequests().length}'),
              child: Icon(Icons.list),
            ),
          ),
          Tab(
            text: 'Chờ duyệt',
            icon: Badge(
              label: Text('${_pendingRequests.length}'),
              backgroundColor: Colors.orange,
              child: Icon(Icons.pending),
            ),
          ),
          Tab(
            text: 'Đã duyệt',
            icon: Badge(
              label: Text('${_approvedRequests.length}'),
              backgroundColor: Colors.green,
              child: Icon(Icons.check_circle),
            ),
          ),
          Tab(
            text: 'Từ chối',
            icon: Badge(
              label: Text('${_rejectedRequests.length}'),
              backgroundColor: Colors.red,
              child: Icon(Icons.cancel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    final allRequests = _getAllRequests();
    return _buildRequestsList(allRequests);
  }

  Widget _buildPendingRequestsTab() {
    return _buildRequestsList(_pendingRequests);
  }

  Widget _buildApprovedRequestsTab() {
    return _buildRequestsList(_approvedRequests);
  }

  Widget _buildRejectedRequestsTab() {
    return _buildRequestsList(_rejectedRequests);
  }

  Widget _buildRequestsList(List<MembershipRequest> requests) {
    final filteredRequests = _filterRequests(requests);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (filteredRequests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestItem(filteredRequests[index], index);
        },
      ),
    );
  }

  Widget _buildRequestItem(MembershipRequest request, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: () => _viewRequestDetails(request),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(request.applicant.avatar),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.applicant.displayName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            request.applicant.email,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(request.status),
                  ],
                ),
                
                if (request.message.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(request.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Spacer(),
                    if (request.status == RequestStatus.pending)
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _rejectRequest(request),
                            icon: Icon(Icons.close, size: 16),
                            label: Text('Từ chối'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _approveRequest(request),
                            icon: Icon(Icons.check, size: 16),
                            label: Text('Duyệt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(RequestStatus status) {
    Color color;
    IconData icon;
    String label;

    switch (status) {
      case RequestStatus.pending:
        color = Colors.orange;
        icon = Icons.pending;
        label = 'Chờ duyệt';
        break;
      case RequestStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Đã duyệt';
        break;
      case RequestStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        label = 'Từ chối';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: 16),
          Text(
            'Không có yêu cầu nào',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Các yêu cầu gia nhập sẽ xuất hiện ở đây',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<MembershipRequest> _getAllRequests() {
    return [..._pendingRequests, ..._approvedRequests, ..._rejectedRequests];
  }

  List<MembershipRequest> _filterRequests(List<MembershipRequest> requests) {
    var filtered = requests.where((request) {
      final matchesSearch = _searchQuery.isEmpty ||
          request.applicant.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          request.applicant.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _currentFilter == RequestFilter.all ||
          (_currentFilter == RequestFilter.pending && request.status == RequestStatus.pending) ||
          (_currentFilter == RequestFilter.approved && request.status == RequestStatus.approved) ||
          (_currentFilter == RequestFilter.rejected && request.status == RequestStatus.rejected) ||
          (_currentFilter == RequestFilter.recent && _isRecent(request.createdAt));

      return matchesSearch && matchesFilter;
    }).toList();

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  bool _isRecent(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    return difference <= 7; // Within 7 days
  }

  String _getFilterLabel(RequestFilter filter) {
    switch (filter) {
      case RequestFilter.all:
        return 'Tất cả';
      case RequestFilter.pending:
        return 'Chờ duyệt';
      case RequestFilter.approved:
        return 'Đã duyệt';
      case RequestFilter.rejected:
        return 'Từ chối';
      case RequestFilter.recent:
        return 'Gần đây';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else() {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Event handlers
  Future<void> _loadRequests() async() {
    setState(() {
      _isLoading = true;
    });

    try() {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));

      // Mock data
      _pendingRequests = _generateMockRequests(RequestStatus.pending, 5);
      _approvedRequests = _generateMockRequests(RequestStatus.approved, 12);
      _rejectedRequests = _generateMockRequests(RequestStatus.rejected, 3);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally() {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshRequests() async() {
    await _loadRequests();
  }

  void _viewRequestDetails(MembershipRequest request) {
    showDialog(
      context: context,
      builder: (context) => _RequestDetailDialog(request: request),
    );
  }

  Future<void> _approveRequest(MembershipRequest request) async() {
    final confirmed = await _showConfirmationDialog(
      title: 'Duyệt yêu cầu',
      content: 'Bạn có chắc muốn duyệt yêu cầu của ${request.applicant.displayName}?',
      confirmText: 'Duyệt',
      confirmColor: Colors.green,
    );

    if (confirmed == true) {
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == request.id);
        _approvedRequests.add(request.copyWith(status: RequestStatus.approved));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã duyệt yêu cầu của ${request.applicant.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rejectRequest(MembershipRequest request) async() {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectRequestDialog(),
    );

    if (result != null) {
      setState(() {
        _pendingRequests.removeWhere((r) => r.id == request.id);
        _rejectedRequests.add(request.copyWith(
          status: RequestStatus.rejected,
          rejectReason: result,
        ));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối yêu cầu của ${request.applicant.displayName}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInviteMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => _InviteMemberDialog(),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportRequests();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _exportRequests() {
    // Implementation for exporting requests
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  void _showSettings() {
    // Implementation for showing settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // Mock data generation
  List<MembershipRequest> _generateMockRequests(RequestStatus status, int count) {
    final names = [
      'Nguyễn Văn A', 'Trần Thị B', 'Lê Văn C', 'Phạm Thị D', 'Hoàng Văn E',
      'Vũ Thị F', 'Đặng Văn G', 'Bùi Thị H', 'Đỗ Văn I', 'Ngô Thị J'
    ];

    final messages = [
      'Tôi rất yêu thích môn cờ và muốn tham gia CLB để học hỏi thêm.',
      'Đã chơi cờ được 3 năm, mong muốn tham gia các giải đấu.',
      'Tôi là người mới bắt đầu, mong được học hỏi từ các anh chị.',
      'Có kinh nghiệm thi đấu, muốn đóng góp cho CLB.',
      '',
    ];

    return List.generate(count, (index) {
      final name = names[index % names.length];
      final email = '${name.toLowerCase().replaceAll(' ', '').replaceAll('ă', 'a').replaceAll('â', 'a').replaceAll('đ', 'd').replaceAll('ê', 'e').replaceAll('ô', 'o').replaceAll('ơ', 'o').replaceAll('ư', 'u')}@email.com';
      
      return MembershipRequest(
        id: 'req_$index',
        applicant: User(
          id: 'user_$index',
          displayName: name,
          email: email,
          avatar: 'https://i.pravatar.cc/150?img=${index + 1}',
          rank: RankType.values[index % RankType.values.length],
        ),
        message: messages[index % messages.length],
        status: status,
        createdAt: DateTime.now().subtract(Duration(days: index * 2)),
        rejectReason: status == RequestStatus.rejected ? 'Không đủ điều kiện' : null,
      );
    });
  }
}

// Supporting classes and enums
enum RequestStatus { pending, approved, rejected }
enum RequestFilter { all, pending, approved, rejected, recent }

class MembershipRequest() {
  final String id;
  final User applicant;
  final String message;
  final RequestStatus status;
  final DateTime createdAt;
  final String? rejectReason;

  const MembershipRequest({
    required this.id,
    required this.applicant,
    required this.message,
    required this.status,
    required this.createdAt,
    this.rejectReason,
  });

  MembershipRequest copyWith({
    String? id,
    User? applicant,
    String? message,
    RequestStatus? status,
    DateTime? createdAt,
    String? rejectReason,
  }) {
    return MembershipRequest(
      id: id ?? this.id,
      applicant: applicant ?? this.applicant,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}

// Dialog widgets
class _RequestDetailDialog extends StatelessWidget() {
  final MembershipRequest request;

  const _RequestDetailDialog({required this.request});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Chi tiết yêu cầu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Implementation for request details
          Text('Tính năng đang phát triển'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đóng'),
        ),
      ],
    );
  }
}

class _RejectRequestDialog extends StatelessWidget() {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Từ chối yêu cầu'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Vui lòng nhập lý do từ chối:'),
          SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Lý do từ chối...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Từ chối'),
        ),
      ],
    );
  }
}

class _InviteMemberDialog extends StatelessWidget() {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mời thành viên'),
      content: Text('Tính năng đang phát triển'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đóng'),
        ),
      ],
    );
  }
}