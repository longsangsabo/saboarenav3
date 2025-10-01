import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../core/utils/rank_migration_helper.dart';
import '../../services/admin_rank_approval_service.dart';

class ClubRankChangeManagementScreen extends StatefulWidget() {
  const ClubRankChangeManagementScreen({super.key});

  @override
  State<ClubRankChangeManagementScreen> createState() => _ClubRankChangeManagementScreenState();
}

class _ClubRankChangeManagementScreenState extends State<ClubRankChangeManagementScreen>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final AdminRankApprovalService _adminService = AdminRankApprovalService();
  
  List<Map<String, dynamic>> _pendingRequests = [];
  final List<Map<String, dynamic>> _reviewedRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRankChangeRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankChangeRequests() async() {
    try() {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Use new service instead of RPC function
      final requests = await _adminService.getPendingRankRequests();
      
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải yêu cầu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewRequest(String requestId, bool approved, {String? comments}) async() {
    try() {
      // Use new service instead of RPC function
      final response = await _adminService.approveRankRequest(
        requestId: requestId,
        approved: approved,
        comments: comments,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? "Đã chấp thuận yêu cầu" : 'Đã từ chối yêu cầu'),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        
        // Reload data
        await _loadRankChangeRequests();
      } else() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${response['error'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Quản lý thay đổi hạng',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimaryLight),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions, size: 18),
                  SizedBox(width: 8),
                  Text('Chờ duyệt'),
                  if (_pendingRequests.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingRequests.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('Đã xử lý'),
                ],
              ),
            ),
          ],
          labelColor: AppTheme.accentLight,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          indicatorColor: AppTheme.accentLight,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accentLight))
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingTab(),
                    _buildReviewedTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.textSecondaryLight,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 16.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRankChangeRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
              foregroundColor: Colors.white,
            ),
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'Không có yêu cầu chờ duyệt',
        subtitle: 'Tất cả yêu cầu thay đổi hạng đã được xử lý',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRankChangeRequests,
      color: AppTheme.accentLight,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return _buildRequestCard(request, isPending: true);
        },
      ),
    );
  }

  Widget _buildReviewedTab() {
    if (_reviewedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Chưa có yêu cầu nào được xử lý',
        subtitle: 'Các yêu cầu đã xử lý sẽ hiển thị ở đây',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _reviewedRequests.length,
      itemBuilder: (context, index) {
        final request = _reviewedRequests[index];
        return _buildRequestCard(request, isPending: false);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.textSecondaryLight.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request, {required bool isPending}) {
    final String userName = request['user_name'] ?? 'Unknown User';
    final String currentRank = request['current_rank'] ?? '';
    final String requestedRank = _extractRequestedRank(request['notes']);
    final String reason = request['notes'] ?? '';
    final List<dynamic> evidenceUrls = request['evidence_urls'] ?? [];
    final String submittedAt = request['requested_at'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.accentLight.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: AppTheme.accentLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      Text(
                        'Gửi lúc: ${_formatDate(submittedAt)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Rank Change Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentLight.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildRankBadge(currentRank),
                  SizedBox(width: 16),
                  Icon(
                    Icons.arrow_forward,
                    color: AppTheme.accentLight,
                    size: 20,
                  ),
                  SizedBox(width: 16),
                  _buildRankBadge(requestedRank, isRequested: true),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Reason
            Text(
              'Lý do:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 4),
            Text(
              reason,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            
            // Evidence
            if (evidenceUrls.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Bằng chứng (${evidenceUrls.length} ảnh):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: evidenceUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: 8),
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          evidenceUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.surfaceLight,
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppTheme.textSecondaryLight,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Action Buttons (only for pending requests)
            if (isPending) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectDialog(request['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, size: 16),
                          SizedBox(width: 8),
                          Text('Từ chối'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _reviewRequest(request['id'], true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 8),
                          Text('Chấp thuận'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge(String rank, {bool isRequested = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isRequested ? Colors.green.withOpacity(0.1) : AppTheme.accentLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRequested ? Colors.green : AppTheme.accentLight,
          width: 1,
        ),
      ),
      child: Text(
        RankMigrationHelper.getNewDisplayName(rank),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: isRequested ? Colors.green : AppTheme.accentLight,
        ),
      ),
    );
  }

  void _showRejectDialog(String requestId) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Từ chối yêu cầu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bạn có chắc muốn từ chối yêu cầu này?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Lý do từ chối (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              Navigator.pop(context);
              _reviewRequest(requestId, false, comments: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _extractRequestedRank(String? notes) {
    if (notes == null || notes.isEmpty) return 'K';
    
    // Try to extract rank from notes format: "Rank mong muốn: E+"
    final RegExp rankPattern = RegExp(r'Rank mong muốn:\s*([A-Z+]+)');
    final match = rankPattern.firstMatch(notes);
    
    return match?.group(1) ?? 'K';
  }

  String _formatDate(String dateString) {
    try() {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}