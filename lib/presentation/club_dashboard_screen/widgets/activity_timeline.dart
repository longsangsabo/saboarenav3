import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';

enum ActivityType {
  memberJoined,
  memberLeft,
  tournamentCreated,
  tournamentEnded,
  matchCompleted,
  paymentReceived,
  profileUpdated,
  notificationSent,
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? avatar;
  final IconData? customIcon;
  final Color? customColor;
  final Map<String, dynamic>? metadata;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.avatar,
    this.customIcon,
    this.customColor,
    this.metadata,
  });
}

class ActivityTimeline extends StatefulWidget {
  const ActivityTimeline({super.key});

} 
  final List<ActivityItem> activities;
  final VoidCallback? onViewAll;
  final Function(ActivityItem)? onActivityTap;
  final Function(ActivityItem, String)? onSwipeAction;
  final bool showTimeline;
  final int? maxDisplayItems;

  const ActivityTimeline({
    super.key,
    required this.activities,
    this.onViewAll,
    this.onActivityTap,
    this.onSwipeAction,
    this.showTimeline = true,
    this.maxDisplayItems,
  });

  @override
  _ActivityTimelineState createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends State<ActivityTimeline>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _initializeItemAnimations();
    _controller.forward();
  }

  void _initializeItemAnimations() {
    final itemCount = widget.maxDisplayItems != null
        ? widget.activities.length.clamp(0, widget.maxDisplayItems!)
        : widget.activities.length;

    _itemControllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _slideAnimations = _itemControllers
        .asMap()
        .map((index, controller) => MapEntry(
              index,
              Tween<double>(
                begin: 50.0,
                end: 0.0,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index * 0.1,
                  0.6 + (index * 0.1),
                  curve: Curves.easeOutCubic,
                ),
              )),
            ))
        .values
        .toList();

    _fadeAnimations = _itemControllers
        .asMap()
        .map((index, controller) => MapEntry(
              index,
              Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  index * 0.1,
                  0.6 + (index * 0.1),
                  curve: Curves.easeOut,
                ),
              )),
            ))
        .values
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 16.v),
        _buildActivityList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Hoạt động gần đây",
          style: CustomTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.onViewAll != null)
          TextButton(
            onPressed: widget.onViewAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Xem tất cả",
                  style: CustomTextStyles.bodyMedium.copyWith(
                    color: appTheme.blue600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4.h),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: appTheme.blue600,
                  size: 12.adaptSize,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActivityList() {
    final displayActivities = widget.maxDisplayItems != null
        ? widget.activities.take(widget.maxDisplayItems!).toList()
        : widget.activities;

    if (displayActivities.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: AppDecoration.fillWhite.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder16,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < displayActivities.length; i++)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_slideAnimations[i].value, 0),
                  child: Opacity(
                    opacity: _fadeAnimations[i].value,
                    child: Column(
                      children: [
                        _buildActivityItemWidget(
                          displayActivities[i],
                          i,
                          i == displayActivities.length - 1,
                        ),
                        if (i < displayActivities.length - 1)
                          _buildDivider(),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItemWidget(
    ActivityItem activity,
    int index,
    bool isLast,
  ) {
    return Dismissible(
      key: Key(activity.id),
      direction: DismissDirection.endToStart,
      background: _buildSwipeBackground(),
      confirmDismiss: (direction) async {
        if (widget.onSwipeAction != null) {
          widget.onSwipeAction!(activity, 'dismiss');
          return false; // Don't actually dismiss
        }
        return true;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onActivityTap?.call(activity),
          child: Padding(
            padding: EdgeInsets.all(20.h),
            child: Row(
              children: [
                if (widget.showTimeline) ...[
                  _buildTimelineIndicator(activity, index, isLast),
                  SizedBox(width: 16.h),
                ],
                _buildActivityAvatar(activity),
                SizedBox(width: 16.h),
                Expanded(child: _buildActivityContent(activity)),
                _buildActivityTimestamp(activity),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineIndicator(
    ActivityItem activity,
    int index,
    bool isLast,
  ) {
    final color = _getActivityColor(activity);
    
    return SizedBox(
      width: 20.h,
      child: Column(
        children: [
          Container(
            width: 12.adaptSize,
            height: 12.adaptSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              width: 2.h,
              height: 40.v,
              color: appTheme.gray200,
              margin: EdgeInsets.only(top: 8.v),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityAvatar(ActivityItem activity) {
    final color = _getActivityColor(activity);
    final icon = _getActivityIcon(activity);

    return Container(
      width: 48.adaptSize,
      height: 48.adaptSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.h),
        color: activity.avatar != null ? null : color.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: activity.avatar != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(22.h),
              child: CustomImageWidget(
                imagePath: activity.avatar!,
                fit: BoxFit.cover,
              ),
            )
          : Icon(
              icon,
              color: color,
              size: 24.adaptSize,
            ),
    );
  }

  Widget _buildActivityContent(ActivityItem activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.title,
          style: TextStyle(
            fontSize: 15.fSize,
            fontWeight: FontWeight.w600,
            color: appTheme.gray900,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.v),
        Text(
          activity.subtitle,
          style: TextStyle(
            fontSize: 13.fSize,
            color: appTheme.gray600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (activity.metadata != null)
          _buildActivityMetadata(activity.metadata!),
      ],
    );
  }

  Widget _buildActivityTimestamp(ActivityItem activity) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatRelativeTime(activity.timestamp),
          style: TextStyle(
            fontSize: 12.fSize,
            color: appTheme.gray500,
            fontWeight: FontWeight.w500,
          ),
        ),
        _buildActivityTypeChip(activity),
      ],
    );
  }

  Widget _buildActivityTypeChip(ActivityItem activity) {
    final color = _getActivityColor(activity);
    final label = _getActivityTypeLabel(activity.type);

    return Container(
      margin: EdgeInsets.only(top: 4.v),
      padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.v),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.fSize,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActivityMetadata(Map<String, dynamic> metadata) {
    return Padding(
      padding: EdgeInsets.only(top: 6.v),
      child: Wrap(
        spacing: 8.h,
        runSpacing: 4.v,
        children: metadata.entries
            .take(2)
            .map((entry) => _buildMetadataChip(entry.key, entry.value.toString()))
            .toList(),
      ),
    );
  }

  Widget _buildMetadataChip(String key, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.h, vertical: 2.v),
      decoration: BoxDecoration(
        color: appTheme.gray100,
        borderRadius: BorderRadius.circular(6.h),
      ),
      child: Text(
        '$key: $value',
        style: TextStyle(
          fontSize: 10.fSize,
          color: appTheme.gray600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      color: appTheme.red600,
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: 24.adaptSize,
          ),
          SizedBox(height: 4.v),
          Text(
            "Xóa",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: appTheme.gray200,
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40.h),
      decoration: AppDecoration.fillWhite.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder16,
      ),
      child: Column(
        children: [
          Icon(
            Icons.timeline_outlined,
            color: appTheme.gray400,
            size: 48.adaptSize,
          ),
          SizedBox(height: 16.v),
          Text(
            "Chưa có hoạt động nào",
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray600,
            ),
          ),
          SizedBox(height: 8.v),
          Text(
            "Các hoạt động của CLB sẽ được hiển thị tại đây",
            style: TextStyle(
              fontSize: 14.fSize,
              color: appTheme.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getActivityColor(ActivityItem activity) {
    if (activity.customColor != null) return activity.customColor!;

    switch (activity.type) {
      case ActivityType.memberJoined:
        return appTheme.green600;
      case ActivityType.memberLeft:
        return appTheme.red600;
      case ActivityType.tournamentCreated:
        return appTheme.orange600;
      case ActivityType.tournamentEnded:
        return appTheme.purple600;
      case ActivityType.matchCompleted:
        return appTheme.blue600;
      case ActivityType.paymentReceived:
        return appTheme.teal600;
      case ActivityType.profileUpdated:
        return appTheme.indigo600;
      case ActivityType.notificationSent:
        return appTheme.pink600;
    }
  }

  IconData _getActivityIcon(ActivityItem activity) {
    if (activity.customIcon != null) return activity.customIcon!;

    switch (activity.type) {
      case ActivityType.memberJoined:
        return Icons.person_add_outlined;
      case ActivityType.memberLeft:
        return Icons.person_remove_outlined;
      case ActivityType.tournamentCreated:
        return Icons.emoji_events_outlined;
      case ActivityType.tournamentEnded:
        return Icons.military_tech_outlined;
      case ActivityType.matchCompleted:
        return Icons.sports_esports_outlined;
      case ActivityType.paymentReceived:
        return Icons.payment_outlined;
      case ActivityType.profileUpdated:
        return Icons.edit_outlined;
      case ActivityType.notificationSent:
        return Icons.notifications_outlined;
    }
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.memberJoined:
        return 'Thành viên';
      case ActivityType.memberLeft:
        return 'Rời khỏi';
      case ActivityType.tournamentCreated:
        return 'Giải đấu';
      case ActivityType.tournamentEnded:
        return 'Kết thúc';
      case ActivityType.matchCompleted:
        return 'Trận đấu';
      case ActivityType.paymentReceived:
        return 'Thanh toán';
      case ActivityType.profileUpdated:
        return 'Cập nhật';
      case ActivityType.notificationSent:
        return 'Thông báo';
    }
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${(difference.inDays / 7).floor()} tuần trước';
    }
  }
}
