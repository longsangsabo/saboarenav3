import 'package:flutter/material.dart';

/// Tab item data for custom tab bar
class TabItem() {
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final int? badgeCount;

  const TabItem({
    required this.label,
    this.icon,
    this.customIcon,
    this.badgeCount,
  });
}

/// Variants of the custom tab bar for different contexts
enum CustomTabBarVariant() {
  /// Standard text-only tabs
  standard,

  /// Tabs with icons and text
  iconText,

  /// Icon-only tabs
  iconOnly,

  /// Tournament bracket tabs
  tournament,

  /// Profile sections tabs
  profile,
}

/// A customizable tab bar widget for the Vietnamese billiards social networking app
/// Provides consistent tabbed navigation within screens
class CustomTabBar extends StatelessWidget() {
  /// The variant of the tab bar
  final CustomTabBarVariant variant;

  /// List of tab items
  final List<TabItem> tabs;

  /// Current selected tab index
  final int selectedIndex;

  /// Callback when tab is selected
  final ValueChanged<int>? onTabSelected;

  /// Whether tabs are scrollable
  final bool isScrollable;

  /// Custom background color
  final Color? backgroundColor;

  /// Whether to show badges
  final bool showBadges;

  /// Custom indicator color
  final Color? indicatorColor;

  /// Custom indicator weight
  final double indicatorWeight;

  const CustomTabBar({
    super.key,
    this.variant = CustomTabBarVariant.standard,
    required this.tabs,
    this.selectedIndex = 0,
    this.onTabSelected,
    this.isScrollable = false,
    this.backgroundColor,
    this.showBadges = true,
    this.indicatorColor,
    this.indicatorWeight = 2.0,
  });

  /// Factory constructor for tournament tabs
  factory CustomTabBar.tournament({
    Key? key,
    int selectedIndex = 0,
    ValueChanged<int>? onTabSelected,
  }) {
    return CustomTabBar(
      key: key,
      variant: CustomTabBarVariant.tournament,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      isScrollable: true,
      tabs: const [
        TabItem(label: 'Tổng quan'),
        TabItem(label: 'Bảng đấu'),
        TabItem(label: 'Lịch thi đấu'),
        TabItem(label: 'Kết quả'),
        TabItem(label: 'Thống kê'),
      ],
    );
  }

  /// Factory constructor for profile tabs
  factory CustomTabBar.profile({
    Key? key,
    int selectedIndex = 0,
    ValueChanged<int>? onTabSelected,
  }) {
    return CustomTabBar(
      key: key,
      variant: CustomTabBarVariant.profile,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      tabs: const [
        TabItem(
          label: 'Bài viết',
          icon: Icons.article_outlined,
        ),
        TabItem(
          label: 'Giải đấu',
          icon: Icons.emoji_events_outlined,
        ),
        TabItem(
          label: 'Thành tích',
          icon: Icons.military_tech_outlined,
        ),
        TabItem(
          label: 'Thống kê',
          icon: Icons.analytics_outlined,
        ),
      ],
    );
  }

  /// Factory constructor for club tabs
  factory CustomTabBar.club({
    Key? key,
    int selectedIndex = 0,
    ValueChanged<int>? onTabSelected,
  }) {
    return CustomTabBar(
      key: key,
      variant: CustomTabBarVariant.iconText,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      tabs: const [
        TabItem(
          label: 'Thông tin',
          icon: Icons.info_outline,
        ),
        TabItem(
          label: 'Giải đấu',
          icon: Icons.emoji_events_outlined,
        ),
        TabItem(
          label: 'Thành viên',
          icon: Icons.people_outline,
        ),
        TabItem(
          label: 'Bảng giá',
          icon: Icons.price_check_outlined,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            theme.tabBarTheme.labelColor?.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        tabs: _buildTabs(context),
        isScrollable: isScrollable,
        indicatorColor: indicatorColor ?? theme.tabBarTheme.indicatorColor,
        indicatorWeight: indicatorWeight,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: theme.tabBarTheme.labelColor,
        unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor,
        labelStyle: theme.tabBarTheme.labelStyle,
        unselectedLabelStyle: theme.tabBarTheme.unselectedLabelStyle,
        overlayColor: WidgetStateProperty.all(
          colorScheme.primary.withOpacity(0.1),
        ),
        splashFactory: InkRipple.splashFactory,
        onTap: onTabSelected,
        tabAlignment: isScrollable ? TabAlignment.start : TabAlignment.fill,
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    return tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isSelected = index == selectedIndex;

      return _buildTab(context, tab, isSelected);
    }).toList();
  }

  Widget _buildTab(BuildContext context, TabItem tab, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case CustomTabBarVariant.iconOnly:
        return Tab(
          child: _buildTabContent(
            context,
            tab,
            isSelected,
            showText: false,
          ),
        );

      case CustomTabBarVariant.iconText:
      case CustomTabBarVariant.profile:
        return Tab(
          child: _buildTabContent(
            context,
            tab,
            isSelected,
            showText: true,
            showIcon: true,
          ),
        );

      case CustomTabBarVariant.tournament:
        return Tab(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: isSelected
                ? BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  )
                : null,
            child: _buildTabContent(
              context,
              tab,
              isSelected,
              showText: true,
            ),
          ),
        );

      default:
        return Tab(
          child: _buildTabContent(
            context,
            tab,
            isSelected,
            showText: true,
          ),
        );
    }
  }

  Widget _buildTabContent(
    BuildContext context,
    TabItem tab,
    bool isSelected, {
    bool showText = true,
    bool showIcon = false,
  }) {
    final theme = Theme.of(context);

    final children = <Widget>[];

    // Add icon if needed
    if (showIcon && (tab.icon != null || tab.customIcon != null)) {
      Widget iconWidget;

      if (tab.customIcon != null) {
        iconWidget = tab.customIcon!;
      } else() {
        iconWidget = Icon(
          tab.icon,
          size: 20,
          color: isSelected
              ? theme.tabBarTheme.labelColor
              : theme.tabBarTheme.unselectedLabelColor,
        );
      }

      // Wrap icon with badge if needed
      if (showBadges && tab.badgeCount != null && tab.badgeCount! > 0) {
        iconWidget = Stack(
          clipBehavior: Clip.none,
          children: [
            iconWidget,
            Positioned(
              right: -6,
              top: -6,
              child: _buildBadge(context, tab.badgeCount!),
            ),
          ],
        );
      }

      children.add(iconWidget);

      if (showText) {
        children.add(const SizedBox(height: 4));
      }
    }

    // Add text if needed
    if (showText) {
      children.add(
        Text(
          tab.label,
          style: isSelected
              ? theme.tabBarTheme.labelStyle
              : theme.tabBarTheme.unselectedLabelStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // If only text and has badge, wrap the whole thing
    if (!showIcon &&
        showBadges &&
        tab.badgeCount != null &&
        tab.badgeCount! > 0) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
          Positioned(
            right: -8,
            top: -4,
            child: _buildBadge(context, tab.badgeCount!),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildBadge(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final displayCount = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 16),
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
            fontSize: 9,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}
