import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';

class TournamentSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> tournaments;
  final Function(Map<String, dynamic>) onTournamentSelected;

  TournamentSearchDelegate({
    required this.tournaments,
    required this.onTournamentSelected,
  });

  @override
  String get searchFieldLabel => 'Tìm kiếm giải đấu...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: CustomIconWidget(
          iconName: 'clear',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 24,
        ),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: CustomIconWidget(
        iconName: 'arrow_back',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 24,
      ),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final filteredTournaments = _getFilteredTournaments();

    if (filteredTournaments.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      itemCount: filteredTournaments.length,
      itemBuilder: (context, index) {
        final tournament = filteredTournaments[index];
        return _buildSearchResultItem(context, tournament);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches(context);
    }

    final suggestions = _getFilteredTournaments();

    return ListView.builder(
      itemCount: suggestions.length > 5 ? 5 : suggestions.length,
      itemBuilder: (context, index) {
        final tournament = suggestions[index];
        return _buildSuggestionItem(context, tournament);
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredTournaments() {
    if (query.isEmpty) return tournaments;

    return tournaments.where((tournament) {
      final title = (tournament['title'] as String).toLowerCase();
      final clubName = (tournament['clubName'] as String).toLowerCase();
      final format = (tournament['format'] as String).toLowerCase();
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) ||
          clubName.contains(searchQuery) ||
          format.contains(searchQuery);
    }).toList();
  }

  Widget _buildSearchResultItem(
      BuildContext context, Map<String, dynamic> tournament) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: Gaps.xl, vertical: Gaps.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.all(Gaps.lg),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomImageWidget(
            imageUrl: tournament['coverImage'] as String,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          tournament['title'] as String,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Gaps.xs),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'business',
                  color: colorScheme.onSurfaceVariant,
                  size: 14,
                ),
                const SizedBox(width: Gaps.xs),
                Expanded(
                  child: Text(
                    tournament['clubName'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gaps.xs),
            Row(
              children: [
                _buildFormatBadge(context, tournament['format'] as String),
                const Spacer(),
                Text(
                  tournament['entryFee'] as String,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          onTournamentSelected(tournament);
          close(context, tournament['title'] as String);
        },
      ),
    );
  }

  Widget _buildSuggestionItem(
      BuildContext context, Map<String, dynamic> tournament) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CustomIconWidget(
        iconName: 'search',
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: _buildHighlightedText(
            tournament['title'] as String,
            query,
            theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ) ??
                TextStyle(color: colorScheme.primary),
          ),
        ),
      ),
      subtitle: Text(
        tournament['clubName'] as String,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: CustomIconWidget(
        iconName: 'north_west',
        color: colorScheme.onSurfaceVariant,
        size: 16,
      ),
      onTap: () {
        query = tournament['title'] as String;
        showResults(context);
      },
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock recent searches
    final recentSearches = [
      'Giải 8-ball',
      'Giải 9-ball',
      'Giải cuối tuần',
      'Giải miễn phí',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(Gaps.xl),
          child: Text(
            'Tìm kiếm gần đây',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...recentSearches.map((search) => ListTile(
              leading: CustomIconWidget(
                iconName: 'history',
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              title: Text(
                search,
                style: theme.textTheme.bodyMedium,
              ),
              trailing: CustomIconWidget(
                iconName: 'north_west',
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              onTap: () {
                query = search;
                showResults(context);
              },
            )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            color: colorScheme.onSurfaceVariant,
            size: 64,
          ),
          const SizedBox(height: Gaps.lg),
          Text(
            'Không tìm thấy giải đấu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            'Thử tìm kiếm với từ khóa khác',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatBadge(BuildContext context, String format) {
    final theme = Theme.of(context);
    Color badgeColor;

    switch (format.toLowerCase()) {
      case '8-ball':
        badgeColor = Colors.blue;
        break;
      case '9-ball':
        badgeColor = Colors.orange;
        break;
      case '10-ball':
        badgeColor = Colors.purple;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gaps.md, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        format,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(
      String text, String query, TextStyle highlightStyle) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle,
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }
}
