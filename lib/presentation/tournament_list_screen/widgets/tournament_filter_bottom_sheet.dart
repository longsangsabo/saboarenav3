import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TournamentFilterBottomSheet extends StatefulWidget {
  const TournamentFilterBottomSheet({super.key});

} 
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const TournamentFilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
  });

  @override
  State<TournamentFilterBottomSheet> createState() =>
      _TournamentFilterBottomSheetState();
}

class _TournamentFilterBottomSheetState
    extends State<TournamentFilterBottomSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: Gaps.sm),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(Gaps.xl),
            child: Row(
              children: [
                Text(
                  'Bộ lọc giải đấu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Đặt lại',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withAlpha(51)),

          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gaps.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location radius
                  _buildLocationRadiusSection(context, theme, colorScheme),

                  const SizedBox(height: Gaps.xl),

                  // Entry fee range
                  _buildEntryFeeSection(context, theme, colorScheme),

                  const SizedBox(height: Gaps.xl),

                  // Tournament format
                  _buildFormatSection(context, theme, colorScheme),

                  const SizedBox(height: Gaps.xl),

                  // Skill level
                  _buildSkillLevelSection(context, theme, colorScheme),

                  const SizedBox(height: Gaps.xl),

                  // Additional filters
                  _buildAdditionalFiltersSection(context, theme),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(Gaps.xl),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withAlpha(51),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: Gaps.md),
                  ),
                  child: Text(
                    'Áp dụng bộ lọc',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRadiusSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              'Khoảng cách',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
  const SizedBox(height: Gaps.md),
        Text(
          'Trong vòng ${(_filters['locationRadius'] as double).toInt()} km',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Slider(
          value: _filters['locationRadius'] as double,
          min: 1,
          max: 50,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _filters['locationRadius'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEntryFeeSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'payments',
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              'Phí tham gia',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
  const SizedBox(height: Gaps.md),
        Wrap(
          spacing: Gaps.md,
          runSpacing: Gaps.sm,
          children: [
            _buildFeeChip(context, theme, colorScheme, 'Miễn phí', 'free'),
            _buildFeeChip(
                context, theme, colorScheme, 'Dưới 100k', 'under_100k'),
            _buildFeeChip(
                context, theme, colorScheme, '100k - 500k', '100k_500k'),
            _buildFeeChip(context, theme, colorScheme, '500k - 1M', '500k_1m'),
            _buildFeeChip(context, theme, colorScheme, 'Trên 1M', 'over_1m'),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'sports_bar',
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              'Thể thức',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
  const SizedBox(height: Gaps.md),
        Wrap(
          spacing: Gaps.md,
          runSpacing: Gaps.sm,
          children: [
            _buildFormatChip(context, theme, colorScheme, '8-Ball', '8-ball'),
            _buildFormatChip(context, theme, colorScheme, '9-Ball', '9-ball'),
            _buildFormatChip(
                context, theme, colorScheme, '10-Ball', '10-ball'),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillLevelSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'military_tech',
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              'Trình độ',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
  const SizedBox(height: Gaps.md),
        Wrap(
          spacing: Gaps.md,
          runSpacing: Gaps.sm,
          children: [
            _buildSkillChip(
                context, theme, colorScheme, 'Mới bắt đầu', 'beginner'),
            _buildSkillChip(
                context, theme, colorScheme, 'Trung bình', 'intermediate'),
            _buildSkillChip(
                context, theme, colorScheme, 'Cao cấp', 'advanced'),
            _buildSkillChip(
                context, theme, colorScheme, 'Chuyên nghiệp', 'professional'),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditionalFiltersSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tùy chọn khác',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
  const SizedBox(height: Gaps.md),
        CheckboxListTile(
          title: Text(
            'Chỉ giải đấu có live stream',
            style: theme.textTheme.bodyMedium,
          ),
          value: _filters['hasLiveStream'] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _filters['hasLiveStream'] = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: Text(
            'Chỉ giải đấu còn chỗ',
            style: theme.textTheme.bodyMedium,
          ),
          value: _filters['hasAvailableSlots'] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _filters['hasAvailableSlots'] = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: Text(
            'Chỉ giải đấu có giải thưởng',
            style: theme.textTheme.bodyMedium,
          ),
          value: _filters['hasPrizePool'] as bool? ?? false,
          onChanged: (value) {
            setState(() {
              _filters['hasPrizePool'] = value ?? false;
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildFeeChip(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, String label, String value) {
    final isSelected =
        (_filters['entryFeeRange'] as List<String>? ?? []).contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final feeRanges =
              (_filters['entryFeeRange'] as List<String>? ?? <String>[])
                  .toList();
          if (selected) {
            feeRanges.add(value);
          } else {
            () {
            feeRanges.remove(value);
          }
          
          }_filters['entryFeeRange'] = feeRanges;
        });
      },
      selectedColor: colorScheme.primary.withAlpha(51),
      checkmarkColor: colorScheme.primary,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildFormatChip(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, String label, String value) {
    final isSelected =
        (_filters['formats'] as List<String>? ?? []).contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final formats =
              (_filters['formats'] as List<String>? ?? <String>[]).toList();
          if (selected) {
            formats.add(value);
          } else {
            () {
            formats.remove(value);
          }
          
          }_filters['formats'] = formats;
        });
      },
      selectedColor: colorScheme.primary.withAlpha(51),
      checkmarkColor: colorScheme.primary,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildSkillChip(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, String label, String value) {
    final isSelected =
        (_filters['skillLevels'] as List<String>? ?? []).contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          final skillLevels =
              (_filters['skillLevels'] as List<String>? ?? <String>[]).toList();
          if (selected) {
            skillLevels.add(value);
          } else {
            () {
            skillLevels.remove(value);
          }
          
          }_filters['skillLevels'] = skillLevels;
        });
      },
      selectedColor: colorScheme.primary.withAlpha(51),
      checkmarkColor: colorScheme.primary,
      labelStyle: theme.textTheme.labelMedium?.copyWith(
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'locationRadius': 10.0,
        'entryFeeRange': <String>[],
        'formats': <String>[],
        'skillLevels': <String>[],
        'hasLiveStream': false,
        'hasAvailableSlots': false,
        'hasPrizePool': false,
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_filters);
    Navigator.pop(context);
  }
}
