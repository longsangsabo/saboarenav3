import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SocialFeaturesWidget extends StatelessWidget {
  const SocialFeaturesWidget({super.key});

} 
  final Map<String, dynamic> socialData;
  final VoidCallback? onFriendsListTap;
  final VoidCallback? onRecentChallengesTap;
  final VoidCallback? onTournamentHistoryTap;

  const SocialFeaturesWidget({
    super.key,
    required this.socialData,
    this.onFriendsListTap,
    this.onRecentChallengesTap,
    this.onTournamentHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Hoạt động xã hội',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Social Stats Row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              Expanded(
                child: _buildSocialStatCard(
                  context,
                  title: 'Bạn bè',
                  count: '${socialData["friendsCount"] ?? 127}',
                  icon: 'people',
                  onTap: onFriendsListTap,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSocialStatCard(
                  context,
                  title: 'Thách đấu',
                  count: '${socialData["challengesCount"] ?? 45}',
                  icon: 'sports_martial_arts',
                  onTap: onRecentChallengesTap,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildSocialStatCard(
                  context,
                  title: 'Giải đấu',
                  count: '${socialData["tournamentsCount"] ?? 23}',
                  icon: 'emoji_events',
                  onTap: onTournamentHistoryTap,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Recent Friends Section
        _buildRecentFriendsSection(context),

        SizedBox(height: 3.h),

        // Recent Challenges Section
        _buildRecentChallengesSection(context),
      ],
    );
  }

  Widget _buildSocialStatCard(
    BuildContext context, {
    required String title,
    required String count,
    required String icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow
                  .withOpacity(0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 24,
            ),
            SizedBox(height: 1.h),
            Text(
              count,
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFriendsSection(BuildContext context) {
    final recentFriends =
        (socialData["recentFriends"] as List?)?.cast<Map<String, dynamic>>() ??
            [];

    if (recentFriends.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bạn bè gần đây',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: onFriendsListTap,
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
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 12.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: recentFriends.length > 5 ? 5 : recentFriends.length,
            itemBuilder: (context, index) {
              final friend = recentFriends[index];
              return _buildFriendCard(context, friend);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend) {
    return Container(
      width: 20.w,
      margin: EdgeInsets.only(right: 3.w),
      child: Column(
        children: [
          // Avatar with Online Status
          Stack(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CustomImageWidget(
                    imageUrl: friend["avatar"] as String? ??
                        "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                    width: 15.w,
                    height: 15.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Online Status Indicator
              if (friend["isOnline"] as bool? ?? false)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 4.w,
                    height: 4.w,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 1.h),

          // Friend Name
          Text(
            friend["name"] as String? ?? "Unknown",
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChallengesSection(BuildContext context) {
    final recentChallenges = (socialData["recentChallenges"] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    if (recentChallenges.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thách đấu gần đây',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              GestureDetector(
                onTap: onRecentChallengesTap,
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
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          itemCount: recentChallenges.length > 3 ? 3 : recentChallenges.length,
          itemBuilder: (context, index) {
            final challenge = recentChallenges[index];
            return _buildChallengeCard(context, challenge);
          },
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
      BuildContext context, Map<String, dynamic> challenge) {
    final status = challenge["status"] as String? ?? "completed";
    final statusColor = _getChallengeStatusColor(status);
    final statusText = _getChallengeStatusText(status);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Opponent Avatar
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl: challenge["opponentAvatar"] as String? ??
                    "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                width: 12.w,
                height: 12.w,
                fit: BoxFit.cover,
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Challenge Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${challenge["opponentName"] as String? ?? "Unknown"}',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${challenge["gameType"] as String? ?? "8-Ball"} • ${challenge["date"] as String? ?? "Hôm nay"}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getChallengeStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getChallengeStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'won':
        return 'Thắng';
      case 'lost':
        return 'Thua';
      case 'pending':
        return 'Chờ';
      case 'ongoing':
        return 'Đang đấu';
      default:
        return 'Hoàn thành';
    }
  }
}
