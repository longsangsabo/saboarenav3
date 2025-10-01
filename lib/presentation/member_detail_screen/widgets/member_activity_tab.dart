import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../member_management_screen/member_management_screen.dart';

class MemberActivityTab extends StatefulWidget {
  const MemberActivityTab({super.key});

} 
  final MemberData memberData;

  const MemberActivityTab({
    super.key,
    required this.memberData,
  });

  @override
  _MemberActivityTabState createState() => _MemberActivityTabState();
}

class _MemberActivityTabState extends State<MemberActivityTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<ActivityItem> _activities = [];
  String _selectedTimeframe = 'week'; // week, month, quarter, year

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _loadActivities() {
    // Generate mock activity data
    _activities = _generateMockActivities();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEngagementMetrics(),
          SizedBox(height: 24),
          _buildActivityChart(),
          SizedBox(height: 24),
          _buildActivityTimeline(),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Chỉ số tương tác',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                DropdownButton<String>(
                  value: _selectedTimeframe,
                  items: [
                    DropdownMenuItem(value: 'week', child: Text('7 ngày')),
                    DropdownMenuItem(value: 'month', child: Text('30 ngày')),
                    DropdownMenuItem(value: 'quarter', child: Text('90 ngày')),
                    DropdownMenuItem(value: 'year', child: Text('1 năm')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeframe = value!;
                    });
                  },
                  underline: SizedBox.shrink(),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Bài đăng',
                    '${widget.memberData.engagement.postsCount}',
                    Icons.article,
                    Colors.blue,
                    '+12% so với tháng trước',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Bình luận',
                    '${widget.memberData.engagement.commentsCount}',
                    Icons.comment,
                    Colors.green,
                    '+8% so với tháng trước',
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Lượt thích',
                    '${widget.memberData.engagement.likesReceived}',
                    Icons.favorite,
                    Colors.red,
                    '+15% so với tháng trước',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Điểm tương tác',
                    '${widget.memberData.engagement.socialScore}',
                    Icons.psychology,
                    Colors.purple,
                    'Xếp hạng #12 trong CLB',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Biểu đồ hoạt động',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Mock chart visualization
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Biểu đồ hoạt động theo thời gian',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChartLegend('Trận đấu', Colors.blue),
                _buildChartLegend('Bài đăng', Colors.green),
                _buildChartLegend('Tương tác', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Hoạt động gần đây',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _viewAllActivities,
                  child: Text('Xem tất cả'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _activities.take(5).length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = _activities[index];
                return _buildActivityItem(activity);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8),
          
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          
          SizedBox(height: 4),
          
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: activity.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            activity.icon,
            size: 20,
            color: activity.color,
          ),
        ),
        
        SizedBox(width: 12),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                activity.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        
        Text(
          _formatActivityTime(activity.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  String _formatActivityTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}p';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _viewAllActivities() {
    // Navigate to full activity list
  }

  List<ActivityItem> _generateMockActivities() {
    final now = DateTime.now();
    return [
      ActivityItem(
        title: 'Thắng trận đấu',
        description: 'Đã thắng trong trận đấu với @user456',
        timestamp: now.subtract(Duration(minutes: 30)),
        icon: Icons.emoji_events,
        color: Colors.green,
      ),
      ActivityItem(
        title: 'Đăng bài mới',
        description: 'Đã đăng bài "Kinh nghiệm chơi cho người mới"',
        timestamp: now.subtract(Duration(hours: 2)),
        icon: Icons.article,
        color: Colors.blue,
      ),
      ActivityItem(
        title: 'Tham gia giải đấu',
        description: 'Đã đăng ký tham gia "Giải đấu mùa Thu 2024"',
        timestamp: now.subtract(Duration(hours: 5)),
        icon: Icons.military_tech,
        color: Colors.orange,
      ),
      ActivityItem(
        title: 'Bình luận',
        description: 'Đã bình luận trên bài đăng của @admin',
        timestamp: now.subtract(Duration(days: 1)),
        icon: Icons.comment,
        color: Colors.purple,
      ),
      ActivityItem(
        title: 'Cập nhật hồ sơ',
        description: 'Đã cập nhật ảnh đại diện và thông tin cá nhân',
        timestamp: now.subtract(Duration(days: 2)),
        icon: Icons.person,
        color: Colors.grey,
      ),
      ActivityItem(
        title: 'Thăng hạng',
        description: 'Đã thăng lên hạng Trung bình với ELO 1450',
        timestamp: now.subtract(Duration(days: 3)),
        icon: Icons.trending_up,
        color: Colors.green,
      ),
    ];
  }
}

class ActivityItem {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  ActivityItem({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
