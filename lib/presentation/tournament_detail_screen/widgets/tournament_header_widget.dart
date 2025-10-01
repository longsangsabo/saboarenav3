import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';

class TournamentHeaderWidget extends StatelessWidget() {
  final Map<String, dynamic> tournament;
  final VoidCallback? onShareTap;
  final ScrollController scrollController;
  final Function(String)? onMenuAction;

  const TournamentHeaderWidget({
    super.key,
    required this.tournament,
    this.onShareTap,
    required this.scrollController,
    this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
  expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      leading: IconButton(
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: AppTheme.lightTheme.colorScheme.onSurface,
          size: 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'participants',
              child: Row(
                children: [
                  Icon(Icons.people, size: 16),
                  SizedBox(width: 8),
                  Text('Người chơi'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'bracket',
              child: Row(
                children: [
                  Icon(Icons.account_tree, size: 16),
                  SizedBox(width: 8),
                  Text('Bảng đấu'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'matches',
              child: Row(
                children: [
                  Icon(Icons.sports_tennis, size: 16),
                  SizedBox(width: 8),
                  Text('Trận đấu'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.analytics, size: 16),
                  SizedBox(width: 8),
                  Text('Thống kê'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'manage',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 16),
                  SizedBox(width: 8),
                  Text('Quản lý'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 16),
                  SizedBox(width: 8),
                  Text('Chia sẻ'),
                ],
              ),
            ),
          ],
          onSelected: onMenuAction,
        ),
        const SizedBox(width: Gaps.md),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CustomImageWidget(
              imageUrl: tournament["coverImage"] as String,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: Gaps.xl,
              left: Gaps.xl,
              right: Gaps.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Gaps.lg,
                      vertical: Gaps.sm,
                    ),
                    decoration: BoxDecoration(
                      color: _getEliminationTypeColor(tournament["eliminationType"] as String),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tournament["eliminationType"] as String, // Show elimination type instead of game type
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: Gaps.sm),
                  Text(
                    tournament["title"] as String,
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      const SizedBox(width: Gaps.sm),
                      Expanded(
                        child: Text(
                          tournament["location"] as String,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEliminationTypeColor(String eliminationType) {
    switch (eliminationType.toLowerCase()) {
      case 'single elimination':
        return Colors.red;
      case 'double elimination':
        return Colors.purple;
      case 'round robin':
        return Colors.green;
      case 'swiss system':
        return Colors.blue;
      case 'sabo de16':
        return Colors.orange;
      case 'sabo de32':
        return Colors.deepOrange;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }

  // Keep for game type colors if needed elsewhere
  Color _getFormatColor(String format) {
    switch (format.toLowerCase()) {
      case '8-ball':
        return AppTheme.lightTheme.colorScheme.primary;
      case '9-ball':
        return AppTheme.lightTheme.colorScheme.secondary;
      case '10-ball':
        return AppTheme.lightTheme.colorScheme.tertiary;
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
