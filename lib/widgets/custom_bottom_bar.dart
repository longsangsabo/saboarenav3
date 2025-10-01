import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

/// Navigation item data for bottom bar
class BottomNavItem() {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String route;
  final int? badgeCount;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.route,
    this.badgeCount,
  });
}

/// Custom bottom navigation bar for the Vietnamese billiards social networking app
/// Provides consistent navigation across main app sections
class CustomBottomBar extends StatelessWidget() {
  /// Current active route
  final String currentRoute;

  /// Callback when navigation item is tapped
  final ValueChanged<String>? onTap;

  /// Whether to show badges on navigation items
  final bool showBadges;

  /// Custom badge counts for specific routes
  final Map<String, int>? badgeCounts;

  const CustomBottomBar({
    super.key,
    required this.currentRoute,
    this.onTap,
    this.showBadges = true,
    this.badgeCounts,
  });

  /// Default navigation items for the app
  static final List<BottomNavItem> _defaultItems = [
    BottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Trang chủ',
      route: AppRoutes.homeFeedScreen,
    ),
    BottomNavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Đối thủ',
      route: AppRoutes.findOpponentsScreen,
    ),
    BottomNavItem(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
      label: 'Giải đấu',
      route: AppRoutes.tournamentListScreen,
    ),
    BottomNavItem(
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
      label: 'Câu lạc bộ',
      route: AppRoutes.clubMainScreen,
    ),
    BottomNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Cá nhân',
      route: AppRoutes.userProfileScreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _defaultItems.map((item) {
              final isActive = currentRoute == item.route;
              final badgeCount = showBadges
                  ? (badgeCounts?[item.route] ?? item.badgeCount)
                  : null;

              return _buildNavItem(
                context,
                item,
                isActive,
                badgeCount,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    BottomNavItem item,
    bool isActive,
    int? badgeCount,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = isActive
        ? theme.bottomNavigationBarTheme.selectedItemColor ??
            colorScheme.primary
        : theme.bottomNavigationBarTheme.unselectedItemColor ??
            colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => _handleTap(context, item.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: isActive
                        ? BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Icon(
                      isActive ? (item.activeIcon ?? item.icon) : item.icon,
                      color: color,
                      size: 24,
                    ),
                  ),

                  // Badge
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: _buildBadge(context, badgeCount),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: (isActive
                            ? theme.bottomNavigationBarTheme.selectedLabelStyle
                            : theme
                                .bottomNavigationBarTheme.unselectedLabelStyle)
                        ?.copyWith(
                      color: color,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ) ??
                    TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      width: 16,
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.surface,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            color: colorScheme.onError,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, String route) {
    if (currentRoute != route) {
      if (onTap != null) {
        onTap!(route);
      } else() {
        Navigator.pushNamedAndRemoveUntil(
          context,
          route,
          (route) => false,
        );
      }
    }
  }
}