import 'package:flutter/material.dart';

import '../../../models/club.dart';

class HorizontalClubList extends StatelessWidget {
  const HorizontalClubList({super.key});

} 
  final List<Club> clubs;
  final Club? selectedClub;
  final Function(Club) onClubSelected;

  const HorizontalClubList({
    super.key,
    required this.clubs,
    required this.selectedClub,
    required this.onClubSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (clubs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 48,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có câu lạc bộ nào',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy tham gia hoặc tạo câu lạc bộ đầu tiên của bạn',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.4),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with search and filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu lạc bộ của tôi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      // Filter button
                      Semantics(
                        label: 'Filter clubs',
                        child: IconButton(
                          onPressed: () => _showFilterDialog(context, colorScheme),
                          icon: Icon(
                            Icons.filter_list,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Lọc câu lạc bộ',
                        ),
                      ),
                      // Search button
                      Semantics(
                        label: 'Search clubs',
                        child: IconButton(
                          onPressed: () => _showSearchDialog(context, colorScheme),
                          icon: Icon(
                            Icons.search,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Tìm kiếm câu lạc bộ',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to all clubs screen
                        },
                        child: Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal club list
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              final isSelected = selectedClub?.id == club.id;

              return Semantics(
                label: 'Club ${club.name}, rating ${club.rating.toStringAsFixed(1)} stars, ${club.totalTables} tables',
                button: true,
                child: GestureDetector(
                  onTap: () => onClubSelected(club),
                  child: Container(
                    width: _getCardWidth(context),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildClubCard(club, isSelected, colorScheme),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClubCard(Club club, bool isSelected, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? colorScheme.primary 
              : colorScheme.outline.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Club cover image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                image: club.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(club.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: club.coverImageUrl == null
                    ? colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: club.coverImageUrl == null
                  ? Icon(
                      Icons.business,
                      size: 32,
                      color: colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
          ),

          // Club info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Club name
                    Text(
                      club.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // Add some space
                    // Club stats
                    Semantics(
                      label:
                          'Rating ${club.rating.toStringAsFixed(1)} stars, ${club.totalTables} tables available',
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            club.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.sports_bar,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${club.totalTables} bàn',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Better responsive breakpoints
    if (screenWidth > 1200) {
      return 350; // Desktop
    } else if (screenWidth > 600) {
      return 300; // Tablet
    } else {
      return screenWidth * 0.7; // Mobile
    }
  }

  void _showSearchDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Tìm kiếm câu lạc bộ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Nhập tên câu lạc bộ...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search logic
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ...',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement location search
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Apply search
              Navigator.of(context).pop();
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Lọc câu lạc bộ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating filter
              const Text(
                'Đánh giá tối thiểu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      // TODO: Set rating filter
                    },
                    child: Icon(
                      Icons.star,
                      size: 24,
                      color: index < 4 ? Colors.amber : Colors.grey,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 24),
              
              // Distance filter
              const Text(
                'Khoảng cách',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: '10km',
                items: const [
                  DropdownMenuItem(value: '5km', child: Text('Trong 5km')),
                  DropdownMenuItem(value: '10km', child: Text('Trong 10km')),
                  DropdownMenuItem(value: '20km', child: Text('Trong 20km')),
                  DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                ],
                onChanged: (value) {
                  // TODO: Set distance filter
                },
              ),
              
              const SizedBox(height: 24),
              
              // Facilities filter
              const Text(
                'Tiện ích',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'WiFi',
                  'Bãi đỗ xe',
                  'Quầy bar',
                  'Phòng VIP',
                  'Điều hòa',
                ].map((facility) => FilterChip(
                  label: Text(facility),
                  selected: false,
                  onSelected: (selected) {
                    // TODO: Toggle facility filter
                  },
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Reset filters
            },
            child: const Text('Đặt lại'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Apply filters
              Navigator.of(context).pop();
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}
