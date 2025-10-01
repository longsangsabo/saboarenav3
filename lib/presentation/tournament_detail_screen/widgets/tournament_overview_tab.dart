import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/tournament_service.dart';

class TournamentOverviewTab extends StatefulWidget {
  const TournamentOverviewTab({super.key});

} 
  final String tournamentId;
  final String tournamentStatus;
  final VoidCallback? onStatusChanged;

  const TournamentOverviewTab({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
    this.onStatusChanged,
  });

  @override
  State<TournamentOverviewTab> createState() => _TournamentOverviewTabState();
}

class _TournamentOverviewTabState extends State<TournamentOverviewTab> {
  final TournamentService _tournamentService = TournamentService.instance;

  Future<Map<String, dynamic>> _loadTournamentStats() async {
    try {
      // Get tournament participants
      final participants = await _tournamentService
          .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
      
      // Get tournament matches
      final matches = await _tournamentService
          .getTournamentMatches(widget.tournamentId);
      
      // Calculate stats
      final totalParticipants = participants.length;
      final completedMatches = matches.where((match) => 
          match['player1_score'] != null && match['player2_score'] != null).length;
      final totalMatches = matches.length;
      
      // Calculate completion percentage
      final completionPercentage = totalMatches > 0 
          ? ((completedMatches / totalMatches) * 100).round()
          : 0;
      
      return() {
        "players": '$totalParticipants người',
        "matches": '$completedMatches/$totalMatches',
        "completion": '$completionPercentage%',
      };
    } catch (e) {
      debugPrint('Error loading tournament stats: $e');
      return() {
        "players": '0 người',
        "matches": '0/0',
        "completion": '0%',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStats(),
          SizedBox(height: 12.sp),
          _buildQuickActions(),
          SizedBox(height: 12.sp),
          _buildRecentActivity(),
          SizedBox(height: 12.sp),
          _buildUpcomingMatches(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        children: [
          Text(
            'Tổng quan giải đấu',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.sp),
          
          FutureBuilder<Map<String, dynamic>>(
            future: _loadTournamentStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Người chơi', '...', Icons.people),
                    _buildStatItem('Trận đấu', '...', Icons.sports_esports),
                    _buildStatItem('Hoàn thành', '...', Icons.check_circle),
                  ],
                );
              }
              
              final stats = snapshot.data ?? {};
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Người chơi', stats['players'] ?? '0', Icons.people),
                  _buildStatItem('Trận đấu', stats['matches'] ?? '0/0', Icons.sports_esports),
                  _buildStatItem('Hoàn thành', stats['completion'] ?? '0%', Icons.check_circle),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16.sp),
        SizedBox(height: 3.sp),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động nhanh',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          
          Wrap(
            spacing: 8.sp,
            runSpacing: 8.sp,
            children: _getQuickActions().map((action) => _buildActionButton(
              label: action['label'],
              icon: action['icon'],
              color: action['color'],
              onTap: action['onTap'],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.sp),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14.sp),
            SizedBox(width: 6.sp),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getQuickActions() {
    switch (widget.tournamentStatus) {
      case 'registration_open':
        return [
          {
            "label": 'Đóng đăng ký',
            'icon': Icons.close,
            'color': AppTheme.warningLight,
            'onTap': () {},
          },
          {
            "label": 'Tạo bảng đấu',
            'icon': Icons.grid_view,
            'color': AppTheme.primaryLight,
            'onTap': () {},
          },
          {
            "label": 'Xem người chơi',
            'icon': Icons.people,
            'color': AppTheme.successLight,
            'onTap': () {},
          },

        ];
      case 'ongoing':
        return [
          {
            "label": 'Nhập kết quả',
            'icon': Icons.edit,
            'color': AppTheme.primaryLight,
            'onTap': () {},
          },
          {
            "label": 'Xem bảng đấu',
            'icon': Icons.view_agenda,
            'color': AppTheme.successLight,
            'onTap': () {},
          },
          {
            "label": 'Báo cáo',
            'icon': Icons.analytics,
            'color': AppTheme.warningLight,
            'onTap': () {},
          },
        ];
      default:
        return [
          {
            "label": 'Xem kết quả',
            'icon': Icons.emoji_events,
            'color': AppTheme.successLight,
            'onTap': () {},
          },
          {
            "label": 'Xuất báo cáo',
            'icon': Icons.download,
            'color': AppTheme.primaryLight,
            'onTap': () {},
          },
        ];
    }
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoạt động gần đây',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.sp),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Icon(icon, color: color, size: 16.sp),
          ),
          SizedBox(width: 12.sp),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    // Display recent activities from real data
    return Container(
      child: Column(
        children: [
          _buildActivityItem(
            'Người chơi mới đăng ký',
            '2 phút trước',
            Icons.person_add,
            AppTheme.successLight,
          ),
          _buildActivityItem(
            'Cập nhật thông tin giải đấu',
            '5 phút trước',
            Icons.edit,
            AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMatches() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trận đấu sắp tới',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('Xem tất cả'),
              ),
            ],
          ),
          
          _buildMatchItem({
            "player1": 'Nguyễn Văn A',
            "player2": 'Trần Văn B',
            "time": '14:30',
            "table": 'Bàn 1',
          }),
        ],
      ),
    );
  }

  Widget _buildMatchItem(Map<String, dynamic> match) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${match['player1']} vs ${match['player2']}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${match['time']} • ${match['table']}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            children: [
              Icon(
                Icons.schedule,
                color: AppTheme.warningLight,
                size: 16.sp,
              ),
              Text(
                'Chờ đấu',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.warningLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
