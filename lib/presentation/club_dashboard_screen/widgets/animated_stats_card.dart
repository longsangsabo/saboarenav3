import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';

class AnimatedStatsCard extends StatefulWidget() {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final String? trendValue;
  final String? subtitle;
  final VoidCallback? onPress;
  final Duration animationDuration;

  const AnimatedStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendValue,
    this.subtitle,
    this.onPress,
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  _AnimatedStatsCardState createState() => _AnimatedStatsCardState();
}

class _AnimatedStatsCardState extends State<AnimatedStatsCard>
    with TickerProviderStateMixin() {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _countAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    // Pulse animation controller for icon
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scale animation for card entrance
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Fade animation for content
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    // Slide animation for trend indicator
    _slideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.5, 1.0, curve: Curves.bounceOut),
    ));

    // Count animation for numbers
    _countAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    // Pulse animation for icon
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _controller.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPress,
                borderRadius: BorderRadius.circular(16.h),
                child: Container(
                  padding: EdgeInsets.all(20.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withOpacity(0.15),
                        widget.color.withOpacity(0.05),
                        Colors.white.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(16.h),
                    border: Border.all(
                      color: widget.color.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 20,
                        offset: Offset(-8, -8),
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 16.h),
                      _buildValue(),
                      SizedBox(height: 8.h),
                      _buildTitle(),
                    ],
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
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
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
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            );
          },
        ),
        Spacer(),
        if (widget.trend != null)
          Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: _buildTrendIndicator(),
          ),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    final isUp = widget.trend == "up";
    final trendColor = isUp ? appTheme.green600 : appTheme.red600;
    final backgroundColor = isUp ? appTheme.green50 : appTheme.red50;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.h),
        border: Border.all(
          color: trendColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: trendColor,
            size: 16.sp,
          ),
          SizedBox(width: 4.h),
          Text(
            widget.trendValue ?? "",
            style: TextStyle(
              color: trendColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValue() {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        // Extract numeric value for animation
        final numericValue = _extractNumericValue(widget.value);
        final animatedValue = numericValue * _countAnimation.value;
        final displayValue = _formatAnimatedValue(animatedValue, widget.value);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: appTheme.onBackgroundLight,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.subtitle != null) ...[
              SizedBox(width: 4.h),
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: appTheme.onSurfaceLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.title,
      style: TextStyle(
        fontSize: 14.sp,
        color: appTheme.onBackgroundLight,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  double _extractNumericValue(String value) {
    // Extract numeric part from strings like "156", "45.2M", "#12"
    final cleanValue = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  String _formatAnimatedValue(double animatedValue, String originalValue) {
    if (originalValue.contains('M')) {
      return '${animatedValue.toStringAsFixed(1)}M';
    } else if (originalValue.contains('#')) {
      return '#${animatedValue.round()}';
    } else if (originalValue.contains('.')) {
      return animatedValue.toStringAsFixed(1);
    } else() {
      return animatedValue.round().toString();
    }
  }
}

// Specialized Stats Cards for different types
class MemberStatsCard extends AnimatedStatsCard() {
  MemberStatsCard({
    super.key,
    required int memberCount,
    required int newMembers,
    super.onPress,
  }) : super(
          title: "Thành viên",
          value: memberCount.toString(),
          icon: Icons.people_outline_rounded,
          color: AppColors.primary,
          trend: newMembers > 0 ? "up" : (newMembers < 0 ? "down" : null),
          trendValue: newMembers > 0 ? "+$newMembers" : "$newMembers",
        );
}

class TournamentStatsCard extends AnimatedStatsCard() {
  TournamentStatsCard({
    super.key,
    required int activeTournaments,
    super.onPress,
  }) : super(
          title: "Giải đấu hoạt động",
          value: activeTournaments.toString(),
          icon: Icons.emoji_events_outlined,
          color: AppColors.orange,
        );
}

class RevenueStatsCard extends AnimatedStatsCard() {
  RevenueStatsCard({
    super.key,
    required double revenue,
    required double revenueChange,
    super.onPress,
  }) : super(
          title: "Doanh thu tháng",
          value: "${revenue.toStringAsFixed(1)}M",
          subtitle: "VND",
          icon: Icons.attach_money_outlined,
          color: AppColors.blue,
          trend: revenueChange > 0 ? "up" : (revenueChange < 0 ? "down" : null),
          trendValue: "${revenueChange > 0 ? "+" : ''}${revenueChange.toStringAsFixed(1)}%",
        );
}

class RankingStatsCard extends AnimatedStatsCard() {
  const RankingStatsCard({
    super.key,
    required int ranking,
    super.onPress,
  }) : super(
          title: "Xếp hạng CLB",
          value: "#$ranking",
          subtitle: "Khu vực",
          icon: Icons.military_tech_outlined,
          color: AppColors.purple,
        );
}

// Color definitions if not already in theme
class AppColors() {
  static const Color primary = Color(0xFF4CAF50);
  static const Color orange = Color(0xFFFF9800);
  static const Color blue = Color(0xFF2196F3);
  static const Color purple = Color(0xFF9C27B0);
}
