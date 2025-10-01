import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/rank_migration_helper.dart';

class SystemAdminRankManagementScreen extends StatefulWidget() {
  const SystemAdminRankManagementScreen({super.key});

  @override
  State<SystemAdminRankManagementScreen> createState() => _SystemAdminRankManagementScreenState();
}

class _SystemAdminRankManagementScreenState extends State<SystemAdminRankManagementScreen>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _pendingAdminRequests = [];
  List<Map<String, dynamic>> _completedRequests = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminRequests() async() {
    try() {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get all rank change requests that need admin approval
      final response = await _supabase
          .from('notifications')
          .select('''
            id,
            user_id,
            data,
            created_at,
            users!notifications_user_id_fkey (
              display_name,
              avatar_url,
              email
            )
          ''')
          .eq('type', 'rank_change_request')
          .or('data->>workflow_status.eq.pending_admin_approval,data->>workflow_status.eq.completed,data->>workflow_status.eq.rejected_by_admin')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> allRequests = response.cast<Map<String, dynamic>>();

      // Separate pending vs completed
      final pending = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];

      for (final request in allRequests) {
        final data = request['data'] as Map<String, dynamic>;
        final status = data['workflow_status'] as String;
        
        final formattedRequest = {
          'id': request['id'],
          'user_id': request['user_id'],
          'user_name': request['users']['display_name'] ?? 'Unknown User',
          'user_avatar': request['users']['avatar_url'],
          'user_email': request['users']['email'],
          'current_rank': data['current_rank'],
          'requested_rank': data['requested_rank'],
          'reason': data['reason'],
          'evidence_urls': data['evidence_urls'] ?? [],
          'submitted_at': data['submitted_at'],
          'club_approved': data['club_approved'] ?? false,
          'club_reviewed_at': data['club_reviewed_at'],
          'club_comments': data['club_comments'],
          'workflow_status': status,
          'admin_approved': data['admin_approved'],
          'admin_reviewed_at': data['admin_reviewed_at'],
          'admin_comments': data['admin_comments'],
        };

        if (status == 'pending_admin_approval') {
          pending.add(formattedRequest);
        } else() {
          completed.add(formattedRequest);
        }
      }

      setState(() {
        _pendingAdminRequests = pending;
        _completedRequests = completed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải yêu cầu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _adminReview(String requestId, bool approved, {String? comments}) async() {
    try() {
      final response = await _supabase
          .rpc('admin_approve_rank_change_request', params: {
        'p_request_id': requestId,
        'p_approved': approved,
        'p_admin_comments': comments,
      });

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? "Đã phê duyệt yêu cầu - Rank user đã được cập nhật!" : 'Đã từ chối yêu cầu'),
            backgroundColor: approved ? Colors.green : Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Reload data
        await _loadAdminRequests();
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
          'System Admin - Phê duyệt hạng',
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
                  Icon(Icons.admin_panel_settings, size: 18),
                  SizedBox(width: 8),
                  Text('Chờ phê duyệt'),
                  if (_pendingAdminRequests.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingAdminRequests.length}',
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
          labelColor: Colors.red,
          unselectedLabelColor: AppTheme.textSecondaryLight,
          indicatorColor: Colors.red,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.red))
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingTab(),
                    _buildCompletedTab(),
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
            onPressed: _loadAdminRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingAdminRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'Không có yêu cầu chờ phê duyệt',
        subtitle: 'Tất cả yêu cầu thay đổi hạng đã được xử lý',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAdminRequests,
      color: Colors.red,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _pendingAdminRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingAdminRequests[index];
          return _buildAdminRequestCard(request, isPending: true);
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    if (_completedRequests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'Chưa có yêu cầu nào được xử lý',
        subtitle: 'Các yêu cầu đã phê duyệt sẽ hiển thị ở đây',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _completedRequests.length,
      itemBuilder: (context, index) {
        final request = _completedRequests[index];
        return _buildAdminRequestCard(request, isPending: false);
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

  Widget _buildAdminRequestCard(Map<String, dynamic> request, {required bool isPending}) {
    final String userName = request['user_name'] ?? 'Unknown User';
    final String userEmail = request['user_email'] ?? '';
    final String currentRank = request['current_rank'] ?? '';
    final String requestedRank = request['requested_rank'] ?? '';
    final String reason = request['reason'] ?? '';
    final List<dynamic> evidenceUrls = request['evidence_urls'] ?? [];
    final String submittedAt = request['submitted_at'] ?? '';
    final String clubComments = request['club_comments'] ?? '';
    final bool clubApproved = request['club_approved'] ?? false;
    final String workflowStatus = request['workflow_status'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? Colors.red.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: isPending ? 2 : 1,
        ),
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
            // Admin Header
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPending ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: isPending ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    isPending ? "CHỜ ADMIN PHÊ DUYỆT" : 'ĐÃ XỬ LÝ BỞI ADMIN',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isPending ? Colors.red : Colors.grey,
                    ),
                  ),
                  Spacer(),
                  if (!isPending)
                    Icon(
                      workflowStatus == 'completed' ? Icons.check_circle : Icons.cancel,
                      color: workflowStatus == 'completed' ? Colors.green : Colors.red,
                      size: 20,
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // User Info Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
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
                        userEmail,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        'Gửi lúc: ${_formatDate(submittedAt)}',
                        style: TextStyle(
                          fontSize: 11.sp,
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
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildRankBadge(currentRank),
                  SizedBox(width: 16),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.red,
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

            // Club Review Status
            if (clubApproved) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Đã được Club chấp thuận',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (clubComments.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  'Club: $clubComments',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            
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
                      onPressed: () => _showAdminRejectDialog(request['id']),
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
                      onPressed: () => _adminReview(request['id'], true),
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
                          Text('Phê duyệt'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Show admin decision for completed requests
            if (!isPending) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: workflowStatus == 'completed' 
                      ? Colors.green.withOpacity(0.1) 
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      workflowStatus == 'completed' ? Icons.check_circle : Icons.cancel,
                      color: workflowStatus == 'completed' ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      workflowStatus == 'completed' ? "Đã phê duyệt - Rank đã cập nhật" : 'Đã từ chối',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: workflowStatus == 'completed' ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (request['admin_comments'] != null && request['admin_comments'].isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  'Admin: ${request['admin_comments']}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
        color: isRequested ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRequested ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Text(
        RankMigrationHelper.getNewDisplayName(rank),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: isRequested ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  void _showAdminRejectDialog(String requestId) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.red),
            SizedBox(width: 8),
            Text('Admin từ chối yêu cầu'),
          ],
        ),
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
              _adminReview(requestId, false, comments: reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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