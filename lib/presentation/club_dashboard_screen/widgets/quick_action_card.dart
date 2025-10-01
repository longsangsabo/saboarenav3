import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:sabo_arena/theme/app_colors_styles.dart';

class QuickActionCard extends StatefulWidget() {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int? badge;
  final VoidCallback onPress;
  final bool isLoading;
  final Duration animationDuration;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    required this.onPress,
    this.isLoading = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  _QuickActionCardState createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard>
    with TickerProviderStateMixin() {
  late AnimationController _controller;
  late AnimationController _badgeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _badgeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _badgeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _shadowAnimation = Tween<double>(
      begin: 1.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _badgeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));

    // Start badge animation if badge exists
    if (widget.badge != null && widget.badge! > 0) {
      _badgeController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(QuickActionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle badge animation changes
    if (widget.badge != oldWidget.badge) {
      if (widget.badge != null && widget.badge! > 0) {
        _badgeController.repeat(reverse: true);
      } else() {
        _badgeController.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
    widget.onPress();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.isLoading ? null : _handleTapDown,
            onTapUp: widget.isLoading ? null : _handleTapUp,
            onTapCancel: widget.isLoading ? null : _handleTapCancel,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.h),
                border: Border(
                  left: BorderSide(
                    color: widget.color,
                    width: 4.h,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15 * _shadowAnimation.value),
                    blurRadius: 12 * _shadowAnimation.value,
                    offset: Offset(0, 4 * _shadowAnimation.value),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: AppTheme.onBackgroundLight.withOpacity(0.05 * _shadowAnimation.value),
                    blurRadius: 8 * _shadowAnimation.value,
                    offset: Offset(0, 2 * _shadowAnimation.value),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16.h),
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onPress,
                  borderRadius: BorderRadius.circular(16.h),
                  splashColor: widget.color.withOpacity(0.1),
                  highlightColor: widget.color.withOpacity(0.05),
                  child: Padding(
                    padding: EdgeInsets.all(20.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 16.h),
                        _buildContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _buildIcon(),
        Spacer(),
        if (widget.badge != null && widget.badge! > 0)
          _buildBadge(),
      ],
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withOpacity(0.8),
            widget.color.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: widget.color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: widget.isLoading
          ? SizedBox(
              width: 20.sp,
              height: 20.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              widget.icon,
              color: Colors.white,
              size: 20.sp,
            ),
    );
  }

  Widget _buildBadge() {
    return AnimatedBuilder(
      animation: _badgeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _badgeAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  appTheme.red600,
                  AppTheme.errorLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.h),
              boxShadow: [
                BoxShadow(
                  color: appTheme.red600.withOpacity(0.4),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.badge! > 99 ? '99+' : widget.badge.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.onBackgroundLight,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          widget.subtitle,
          style: TextStyle(
            fontSize: 13.sp,
            color: AppTheme.onSurfaceLight,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

// Specialized Quick Action Cards
class CreateTournamentCard extends QuickActionCard() {
  const CreateTournamentCard({
    super.key,
    required super.onPress,
    super.isLoading,
  }) : super(
          title: "Tạo giải đấu",
          subtitle: "Tổ chức giải đấu mới cho thành viên",
          icon: Icons.add_circle_outline_rounded,
          color: AppColors.primaryColor,
        );
}

class ManageMembersCard extends QuickActionCard() {
  const ManageMembersCard({
    super.key,
    required super.onPress,
    int? pendingRequests,
    super.isLoading,
  }) : super(
          title: "Quản lý thành viên",
          subtitle: "Xem và quản lý danh sách thành viên",
          icon: Icons.people_outline_rounded,
          color: AppColors.blue,
          badge: pendingRequests,
        );
}

class EditProfileCard extends QuickActionCard() {
  const EditProfileCard({
    super.key,
    required super.onPress,
    super.isLoading,
  }) : super(
          title: "Cập nhật thông tin",
          subtitle: "Chỉnh sửa thông tin và cài đặt CLB",
          icon: Icons.edit_outlined,
          color: AppColors.orange,
        );
}

class SendNotificationCard extends QuickActionCard() {
  const SendNotificationCard({
    super.key,
    required super.onPress,
    super.isLoading,
  }) : super(
          title: "Thông báo",
          subtitle: "Gửi thông báo đến tất cả thành viên",
          icon: Icons.notifications_outlined,
          color: AppColors.blue,
        );
}

// Quick Actions Grid Layout
class QuickActionsGrid extends StatelessWidget() {
  final VoidCallback onCreateTournament;
  final VoidCallback onManageMembers;
  final VoidCallback onEditProfile;
  final VoidCallback onSendNotification;
  final int? pendingMemberRequests;
  final bool isLoading;

  const QuickActionsGrid({
    super.key,
    required this.onCreateTournament,
    required this.onManageMembers,
    required this.onEditProfile,
    required this.onSendNotification,
    this.pendingMemberRequests,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thao tác nhanh",
          style: CustomTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: CreateTournamentCard(
                onPress: onCreateTournament,
                isLoading: isLoading,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: ManageMembersCard(
                onPress: onManageMembers,
                pendingRequests: pendingMemberRequests,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: EditProfileCard(
                onPress: onEditProfile,
                isLoading: isLoading,
              ),
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: SendNotificationCard(
                onPress: onSendNotification,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
