import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';

class PrizePoolWidget extends StatelessWidget() {
  final Map<String, dynamic> tournament;

  const PrizePoolWidget({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    final prizePool = tournament["prizePool"] as Map<String, dynamic>;
    final entryFee = tournament["entryFee"] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Gaps.xl),
      padding: const EdgeInsets.all(Gaps.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
            AppTheme.lightTheme.colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'monetization_on',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                'Giải thưởng & Lệ phí',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.lg),
          Container(
            padding: const EdgeInsets.all(Gaps.lg),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lệ phí tham gia',
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  entryFee,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Gaps.lg),
          Text(
            'Cơ cấu giải thưởng',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          ..._buildPrizeList(prizePool),
        ],
      ),
    );
  }

  List<Widget> _buildPrizeList(Map<String, dynamic> prizePool) {
    final prizes = [
      {
        "position": 'Nhất',
        'amount': prizePool["first"],
        "icon": 'emoji_events',
        'color': const Color(0xFFFFD700)
      },
      {
        "position": 'Nhì',
        'amount': prizePool["second"],
        "icon": 'emoji_events',
        'color': const Color(0xFFC0C0C0)
      },
      {
        "position": 'Ba',
        'amount': prizePool["third"],
        "icon": 'emoji_events',
        'color': const Color(0xFFCD7F32)
      },
    ];

    return prizes
    .map((prize) => Container(
      margin: const EdgeInsets.only(bottom: Gaps.sm),
      padding: const EdgeInsets.all(Gaps.lg),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (prize['color'] as Color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Gaps.md),
                    decoration: BoxDecoration(
                      color: (prize['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomIconWidget(
                      iconName: prize['icon'] as String,
                      color: prize['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: Gaps.md),
                  Expanded(
                    child: Text(
                      'Giải ${prize['position']}',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    prize['amount'] as String,
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: prize['color'] as Color,
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}
