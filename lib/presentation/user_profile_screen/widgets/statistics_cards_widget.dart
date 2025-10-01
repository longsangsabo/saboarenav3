import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../widgets/rank_change_request_dialog.dart';
import '../../../core/utils/rank_migration_helper.dart';
import '../../../core/app_export.dart';

class StatisticsCardsWidget extends StatefulWidget {
  const StatisticsCardsWidget({super.key});

} 
  final String userId;

  const StatisticsCardsWidget({
    super.key,
    required this.userId,
  });

  @override
  State<StatisticsCardsWidget> createState() => _StatisticsCardsWidgetState();
}

class _StatisticsCardsWidgetState extends State<StatisticsCardsWidget> {
  bool _isLoading = true;
  UserProfile? _userProfile;
  Map<String, int> _userStats = {};
  int _userRanking = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userProfile =
          await UserService.instance.getUserProfileById(widget.userId);
      final userStats = await UserService.instance.getUserStats(widget.userId);
      final ranking = await UserService.instance.getUserRanking(widget.userId);

      setState(() {
        _userProfile = userProfile;
        _userStats = userStats;
        _userRanking = ranking;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load statistics: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Text(
          'Không thể tải thống kê',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.red,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Thắng',
                  value: '${_userProfile!.totalWins}',
                  subtitle:
                      '${_userProfile!.winRate.toStringAsFixed(1)}% tỷ lệ',
                  color: Colors.green,
                  icon: 'emoji_events',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  title: 'Thua',
                  value: '${_userProfile!.totalLosses}',
                  subtitle: '${_userStats['total_matches'] ?? 0} trận',
                  color: Colors.red,
                  icon: 'trending_down',
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Giải đấu',
                  value: '${_userProfile!.totalTournaments}',
                  subtitle: '0 chiến thắng',
                  color: Colors.orange,
                  icon: 'military_tech',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildRankingCard(),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'ELO Rating',
                  value: '${_userProfile!.rankingPoints}',
                  subtitle: 'Ranking Points',
                  color: Colors.blue,
                  icon: 'trending_up',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildStatCard(
                  title: 'Win Streak',
                  value: '0',
                  subtitle: 'Liên tiếp',
                  color: Colors.amber,
                  icon: 'local_fire_department',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard() {
    // Kiểm tra xem user có rank từ database hay không
    final userRank = _userProfile?.rank;
    final hasRank = userRank != null && userRank.isNotEmpty && userRank != 'unranked';
    
    if (!hasRank) {
      // User chưa có rank - hiển thị card đăng ký rank
      return GestureDetector(
        onTap: () => _showRankRegistrationDialog(),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Xếp hạng',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'leaderboard',
                        color: Colors.grey.shade500,
                        size: 18,
                      ),
                      SizedBox(width: 1.w),
                      Container(
                        padding: EdgeInsets.all(0.5.w),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: 2.w,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                'Chưa đăng ký',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Nhấn để đăng ký',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User có rank - hiển thị card với option thay đổi rank
    return GestureDetector(
      onTap: () => _showRankChangeDialog(),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
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
                Text(
                  'Xếp hạng',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'leaderboard',
                      color: Colors.purple,
                      size: 18,
                    ),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.swap_vert,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${_userRanking > 0 ? _userRanking : 'N/A'}',
                        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${_userProfile!.rankingPoints} điểm',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified, color: Colors.green.shade600, size: 16),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      'Hạng: ${RankMigrationHelper.getNewDisplayName(userRank)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                  Text(
                    'Nhấn để thay đổi',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRankRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Đăng ký Rank',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn chưa có rank chính thức. Để xem thống kê xếp hạng chính xác và tham gia các trận đấu ranked, hãy đăng ký rank ngay!',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Sau khi đăng ký, bạn sẽ có thể theo dõi xếp hạng chính xác của mình.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Để sau',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRankRegistration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng ký ngay'),
          ),
        ],
      ),
    );
  }

  void _navigateToRankRegistration() {
    // Since this is user profile, we need to show club selection first
    // For now show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vui lòng vào trang club cụ thể để đăng ký rank'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required String icon,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              CustomIconWidget(
                iconName: icon,
                color: color,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showRankChangeDialog() {
    if (_userProfile == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RankChangeRequestDialog(
          userProfile: _userProfile!,
          onRequestSubmitted: () {
            // Optional: Refresh data
            _loadStatistics();
          },
        );
      },
    );
  }
}
