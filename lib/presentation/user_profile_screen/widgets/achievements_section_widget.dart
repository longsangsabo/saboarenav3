import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/achievement.dart';
import '../../../services/achievement_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

class AchievementsSectionWidget extends StatefulWidget {
  const AchievementsSectionWidget({super.key});

} 
  final String userId;
  final VoidCallback? onViewAll; // Add optional callback

  const AchievementsSectionWidget({
    super.key,
    required this.userId,
    this.onViewAll,
  });

  @override
  State<AchievementsSectionWidget> createState() =>
      _AchievementsSectionWidgetState();
}

class _AchievementsSectionWidgetState extends State<AchievementsSectionWidget> {
  final AchievementService _achievementService = AchievementService.instance;
  List<Achievement> _achievements = [];
  Map<String, int> _achievementStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      setState(() => _isLoading = true);

      final achievements = await _achievementService.getUserAchievements(
        widget.userId,
      );
      final stats = await _achievementService.getAchievementStats(
        widget.userId,
      );

      setState(() {
        _achievements = achievements.take(6).toList(); // Limit to 6 achievements
        _achievementStats = stats;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      debugPrint('Failed to load achievements: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thành tích',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              if (widget.onViewAll != null)
                TextButton(
                  onPressed: widget.onViewAll,
                  child: Text(
                    'Xem tất cả',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (_isLoading) ...[
            SizedBox(height: 2.h),
            Center(
              child: CircularProgressIndicator(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ] else if (_achievements.isEmpty) ...[
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CustomIconWidget(
                    iconName: 'emoji_events_outlined',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Chưa có thành tích nào',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Tham gia trận đấu và giải đấu để mở khóa thành tích!',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Achievement stats summary
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Đã mở khóa',
                    '${_achievementStats['unlocked'] ?? 0}',
                    AppTheme.lightTheme.colorScheme.primary,
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withOpacity(0.3),
                  ),
                  _buildStatItem(
                    'Tổng cộng',
                    '${_achievementStats['total'] ?? 0}',
                    AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                  ),
                ],
              ),
            ),

            // Achievement grid
            SizedBox(height: 3.h),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
              ),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(_achievements[index]);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      padding: EdgeInsets.all(3.w),
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
          color: _getBorderColor(achievement.category),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Achievement icon with badge color
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: _getBadgeColor(achievement.category),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: achievement.iconUrl ?? 'emoji_events',
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          SizedBox(height: 1.h),

          // Achievement name
          Text(
            achievement.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),

          SizedBox(height: 0.5.h),

          // Achievement category
          Text(
            _getCategoryDisplayName(achievement.category),
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String category) {
    switch (category.toLowerCase()) {
      case 'victory':
        return Colors.green;
      case 'participation':
        return Colors.blue;
      case 'social':
        return Colors.purple;
      case 'skill':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getBorderColor(String category) {
    return _getBadgeColor(category).withOpacity(0.3);
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'victory':
        return 'Chiến thắng';
      case 'participation':
        return 'Tham gia';
      case 'social':
        return 'Xã hội';
      case 'skill':
        return 'Kỹ năng';
      default:
        return 'Khác';
    }
  }
}
