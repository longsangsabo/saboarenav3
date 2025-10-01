import 'package:flutter/material.dart';
import 'package:sabo_arena/services/club_permission_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityHistoryScreen extends StatefulWidget() {
  final String clubId;

  const ActivityHistoryScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final ClubPermissionService _permissionService = ClubPermissionService();
  List<ClubActivityLog> _activities = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final List<String> _activityFilters = [
    'all',
    'member',
    'tournament',
    'post',
    'financial',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async() {
    setState(() => _isLoading = true);
    
    try() {
      // Check if user has permission to view activity history
      final canView = await _permissionService.hasPermission(
        widget.clubId,
        ClubPermission.viewActivityHistory,
      );

      if (!canView) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bạn không có quyền xem lịch sử hoạt động'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
        return;
      }

      final activities = await _fetchActivitiesFromDatabase();
      
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải lịch sử hoạt động: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<ClubActivityLog>> _fetchActivitiesFromDatabase() async() {
    try() {
      final supabase = Supabase.instance.client;
      
      // Query activity logs from database
      final response = await supabase
          .from('club_activity_logs')
          .select('''
            id,
            activity_type,
            activity_description,
            activity_data,
            created_at,
            actor_id,
            profiles:actor_id (
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('club_id', widget.clubId)
          .order('created_at', ascending: false)
          .limit(100);

      return response.map<ClubActivityLog>((item) {
        return ClubActivityLog(
          id: item['id'],
          activityType: item['activity_type'],
          description: item['activity_description'],
          actorId: item['actor_id'],
          actorName: item['profiles']?['full_name'] ?? 
                   item['profiles']?['username'] ?? 
                   'Unknown User',
          actorAvatar: item['profiles']?['avatar_url'],
          timestamp: DateTime.parse(item['created_at']),
          data: item['activity_data'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      // Return mock data for development
      return _getMockActivities();
    }
  }

  List<ClubActivityLog> _getMockActivities() {
    return [
      ClubActivityLog(
        id: '1',
        activityType: 'member_join',
        description: 'đã tham gia club',
        actorId: 'user1',
        actorName: 'Nguyễn Văn A',
        actorAvatar: null,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        data: {},
      ),
      ClubActivityLog(
        id: '2',
        activityType: 'tournament_create',
        description: 'đã tạo giải đấu "Giải mùa xuân 2024"',
        actorId: 'user2',
        actorName: 'Trần Thị B',
        actorAvatar: null,
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        data: {"tournament_name": 'Giải mùa xuân 2024'},
      ),
      ClubActivityLog(
        id: '3',
        activityType: 'post_create',
        description: 'đã đăng bài viết mới',
        actorId: 'user3',
        actorName: 'Lê Văn C',
        actorAvatar: null,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        data: {"post_title": 'Thông báo lịch tập'},
      ),
      ClubActivityLog(
        id: '4',
        activityType: 'member_promote',
        description: 'đã thăng cấp Nguyễn Văn D lên Admin',
        actorId: 'user1',
        actorName: 'Nguyễn Văn A',
        actorAvatar: null,
        timestamp: DateTime.now().subtract(Duration(days: 2)),
        data: {"promoted_user": 'Nguyễn Văn D', "new_role": 'admin'},
      ),
      ClubActivityLog(
        id: '5',
        activityType: 'tournament_end',
        description: 'đã kết thúc giải đấu "Giải tháng 12"',
        actorId: 'user2',
        actorName: 'Trần Thị B',
        actorAvatar: null,
        timestamp: DateTime.now().subtract(Duration(days: 3)),
        data: {
          "tournament_name": 'Giải tháng 12',
          "winner": 'Võ Văn E',
          'prize_pool': 5000000
        },
      ),
    ];
  }

  List<ClubActivityLog> get _filteredActivities() {
    if (_selectedFilter == 'all') return _activities;
    
    return _activities.where((activity) {
      switch (_selectedFilter) {
        case 'member':
          return activity.activityType.startsWith('member_');
        case 'tournament':
          return activity.activityType.startsWith('tournament_');
        case 'post':
          return activity.activityType.startsWith('post_');
        case 'financial':
          return activity.activityType.startsWith('financial_');
        case 'admin':
          return activity.activityType.contains('promote') || 
                 activity.activityType.contains('demote') ||
                 activity.activityType.contains('admin');
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Lịch sử hoạt động',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _activityFilters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getFilterLabel(filter)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Activities list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredActivities.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadActivities,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredActivities.length,
                          itemBuilder: (context, index) {
                            return _buildActivityItem(_filteredActivities[index], index);
                          },
                        ),
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
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có hoạt động nào',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter == 'all' 
                ? "Lịch sử hoạt động sẽ hiển thị ở đây"
                : 'Không có hoạt động nào cho bộ lọc này',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ClubActivityLog activity, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getActivityColor(activity.activityType),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getActivityIcon(activity.activityType),
                color: Colors.white,
                size: 20,
              ),
            ),
            
            SizedBox(width: 12),
            
            // Activity content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[900],
                      ),
                      children: [
                        TextSpan(
                          text: activity.actorName,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' ${activity.description}'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 4),
                  
                  Text(
                    _formatTimestamp(activity.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  
                  // Additional data if available
                  if (activity.data != null && activity.data!.isNotEmpty)
                    _buildActivityData(activity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityData(ClubActivityLog activity) {
    final data = activity.data!;
    
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((entry) {
          return Text(
            '${_formatDataKey(entry.key)}: ${entry.value}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all': return 'Tất cả';
      case 'member': return 'Thành viên';
      case 'tournament': return 'Giải đấu';
      case 'post': return 'Bài viết';
      case 'financial': return 'Tài chính';
      case 'admin': return 'Quản trị';
      default: return filter;
    }
  }

  Color _getActivityColor(String activityType) {
    if (activityType.startsWith('member_')) return Colors.green[600]!;
    if (activityType.startsWith('tournament_')) return Colors.blue[600]!;
    if (activityType.startsWith('post_')) return Colors.purple[600]!;
    if (activityType.startsWith('financial_')) return Colors.orange[600]!;
    if (activityType.contains('admin') || activityType.contains('promote')) {
      return Colors.red[600]!;
    }
    return Colors.grey[600]!;
  }

  IconData _getActivityIcon(String activityType) {
    if (activityType.startsWith('member_')) return Icons.person;
    if (activityType.startsWith('tournament_')) return Icons.sports_esports;
    if (activityType.startsWith('post_')) return Icons.article;
    if (activityType.startsWith('financial_')) return Icons.attach_money;
    if (activityType.contains('admin') || activityType.contains('promote')) {
      return Icons.admin_panel_settings;
    }
    return Icons.history;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else() {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _formatDataKey(String key) {
    switch (key) {
      case 'tournament_name': return 'Tên giải đấu';
      case 'post_title': return 'Tiêu đề bài viết';
      case 'promoted_user': return 'Người được thăng cấp';
      case 'new_role': return 'Vai trò mới';
      case 'winner': return 'Người thắng';
      case 'prize_pool': return 'Giải thưởng';
      default: return key;
    }
  }
}

class ClubActivityLog() {
  final String id;
  final String activityType;
  final String description;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  ClubActivityLog({
    required this.id,
    required this.activityType,
    required this.description,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    required this.timestamp,
    this.data,
  });
}