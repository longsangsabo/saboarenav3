import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

} 
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Text(
                  'Bộ lọc tìm kiếm',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Đặt lại',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Filter content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGameTypeFilter(),
                  SizedBox(height: 3.h),
                  _buildSkillLevelFilter(),
                  SizedBox(height: 3.h),
                  _buildDistanceFilter(),
                  SizedBox(height: 3.h),
                  _buildAvailabilityFilter(),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Apply button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  'Áp dụng bộ lọc',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildGameTypeFilter() {
    final theme = Theme.of(context);
    final gameTypes = ['8-ball', '9-ball', '10-ball'];
    final selectedTypes = _filters['gameTypes'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loại game',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: gameTypes.map((gameType) {
            final isSelected = selectedTypes.contains(gameType);
            return FilterChip(
              label: Text(gameType),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedTypes.add(gameType);
                  } else {
                    () {
                    selectedTypes.remove(gameType);
                  }
                  
                  }_filters['gameTypes'] = selectedTypes;
                });
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillLevelFilter() {
    final theme = Theme.of(context);
    final skillLevels = ['K', 'J', 'I', 'H', 'G', 'F', 'E', 'D', 'C', 'B', 'A'];
    final selectedLevels = _filters['skillLevels'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trình độ',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: skillLevels.map((level) {
            final isSelected = selectedLevels.contains(level);
            return FilterChip(
              label: Text('Rank $level'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedLevels.add(level);
                  } else {
                    () {
                    selectedLevels.remove(level);
                  }
                  
                  }_filters['skillLevels'] = selectedLevels;
                });
              },
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    final theme = Theme.of(context);
    final distance = _filters['distance'] as double? ?? 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Khoảng cách',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${distance.round()} km',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Slider(
          value: distance,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _filters['distance'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    final theme = Theme.of(context);
    final availabilityOptions = [
      {"key": 'online', "label": 'Đang online'},
      {"key": 'available', "label": 'Sẵn sàng chơi'},
      {"key": 'nearby', "label": 'Gần đây'},
    ];
    final selectedAvailability =
        _filters['availability'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...availabilityOptions.map((option) {
          final isSelected = selectedAvailability.contains(option['key']);
          return CheckboxListTile(
            title: Text(option['label'] as String),
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  selectedAvailability.add(option['key'] as String);
                } else {
                  () {
                  selectedAvailability.remove(option['key']);
                }
                
                }_filters['availability'] = selectedAvailability;
              });
            },
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'gameTypes': <String>[],
        'skillLevels': <String>[],
        'distance': 10.0,
        'availability': <String>[],
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }
}
