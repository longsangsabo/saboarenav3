import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Custom app bar variants for different screens
enum CustomAppBarVariant {
  /// Standard app bar with title and back button
  standard,

  /// Home feed app bar with search and notifications
  homeFeed,

  /// Tournament app bar with actions
  tournament,

  /// Profile app bar with edit action
  profile,

  /// Search app bar with search field
  search,
}

/// A customizable app bar widget that provides consistent navigation
/// and branding across the Vietnamese billiards social networking app
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  /// The variant of the app bar to display
  final CustomAppBarVariant variant;

  /// The title to display in the app bar
  final String? title;

  /// Whether to show the back button (auto-detected if null)
  final bool? showBackButton;

  /// Custom leading widget (overrides back button)
  final Widget? leading;

  /// List of action widgets to display
  final List<Widget>? actions;

  /// Callback for search text changes (search variant only)
  final ValueChanged<String>? onSearchChanged;

  /// Search hint text (search variant only)
  final String? searchHint;

  /// Whether the app bar is elevated
  final bool elevated;

  /// Custom background color (overrides theme)
  final Color? backgroundColor;

  /// Whether to center the title
  final bool centerTitle;

  const CustomAppBar({
    
    super.key,
    this.variant = CustomAppBarVariant.standard,
    this.title,
    this.showBackButton,
    this.leading,
    this.actions,
    this.onSearchChanged,
    this.searchHint,
    this.elevated = true,
    this.backgroundColor,
    this.centerTitle = true,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  /// Factory constructor for home feed app bar
  factory CustomAppBar.homeFeed({
    Key? key,
    VoidCallback? onNotificationTap,
    VoidCallback? onSearchTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.homeFeed,
      title: 'SABO ARENA',
      showBackButton: false,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
          tooltip: 'Tìm kiếm',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onNotificationTap,
          tooltip: 'Thông báo',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Factory constructor for tournament app bar
  factory CustomAppBar.tournament({
    Key? key,
    required String title,
    VoidCallback? onShareTap,
    VoidCallback? onFavoriteTap,
    bool isFavorite = false,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.tournament,
      title: title,
      actions: [
        IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: onFavoriteTap,
          tooltip: isFavorite ? "Bỏ yêu thích" : 'Yêu thích',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: onShareTap,
          tooltip: 'Chia sẻ',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Factory constructor for profile app bar
  factory CustomAppBar.profile({
    Key? key,
    required String title,
    VoidCallback? onEditTap,
    VoidCallback? onSettingsTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.profile,
      title: title,
      actions: [
        if (onEditTap != null)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEditTap,
            tooltip: 'Chỉnh sửa',
          ),
        if (onSettingsTap != null)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onSettingsTap,
            tooltip: 'Cài đặt',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Factory constructor for search app bar
  factory CustomAppBar.search({
    Key? key,
    required ValueChanged<String> onSearchChanged,
    String searchHint = 'Tìm kiếm...',
    VoidCallback? onFilterTap,
  }) {
    return CustomAppBar(
      key: key,
      variant: CustomAppBarVariant.search,
      onSearchChanged: onSearchChanged,
      searchHint: searchHint,
      actions: onFilterTap != null
          ? [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: onFilterTap,
                tooltip: 'Bộ lọc',
              ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine if we should show back button
    final shouldShowBack = showBackButton ??
        (leading == null && ModalRoute.of(context)?.canPop == true);

    return AppBar(
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: elevated ? (theme.appBarTheme.elevation ?? 1.0) : 0,
      shadowColor: theme.appBarTheme.shadowColor,
      surfaceTintColor: theme.appBarTheme.surfaceTintColor,
      centerTitle: centerTitle,
      systemOverlayStyle: theme.brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,

      // Leading widget
      leading: leading ?? (shouldShowBack ? _buildBackButton(context) : null),
      automaticallyImplyLeading: false,

      // Title based on variant
      title: _buildTitle(context),

      // Actions
      actions: actions,

      // Title spacing
      titleSpacing: leading != null || shouldShowBack ? 0 : 16,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.search:
        return _buildSearchField(context);

      case CustomAppBarVariant.homeFeed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sports_bar,
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title ?? 'SABO ARENA',
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        );

      default:
        return title != null
            ? Text(
                title!,
                style: theme.appBarTheme.titleTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null;
    }
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: searchHint ?? 'Tìm kiếm...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
      tooltip: 'Quay lại',
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
