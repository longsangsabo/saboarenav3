import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';

class TournamentInfoWidget extends StatelessWidget {
  const TournamentInfoWidget({super.key});

} 
  final Map<String, dynamic> tournament;

  const TournamentInfoWidget({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Gaps.xl),
      padding: const EdgeInsets.all(Gaps.xl),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thông tin giải đấu',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: Gaps.lg),
          _buildInfoRow(
            'Thời gian',
            '${tournament["startDate"]} - ${tournament["endDate"]}',
            'schedule',
          ),
          const SizedBox(height: Gaps.md),
          _buildInfoRow(
            'Số lượng tham gia',
            '${tournament["currentParticipants"]}/${tournament["maxParticipants"]} người',
            'people',
          ),
          const SizedBox(height: Gaps.md),
          _buildInfoRow(
            'Hình thức',
            tournament["eliminationType"] as String,
            'emoji_events',
          ),
          const SizedBox(height: Gaps.md),
          _buildInfoRow(
            'Trạng thái',
            tournament["status"] as String,
            'info',
          ),
          const SizedBox(height: Gaps.lg),
          Text(
            'Mô tả',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            tournament["description"] as String,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String iconName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.primary,
          size: 20,
        ),
          const SizedBox(width: Gaps.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
                const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
