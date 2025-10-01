import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';

class ParticipantsListWidget extends StatelessWidget {
  const ParticipantsListWidget({super.key});

} 
  final List<Map<String, dynamic>> participants;
  final VoidCallback? onViewAllTap;

  const ParticipantsListWidget({
    super.key,
    required this.participants,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayParticipants = participants.take(6).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Gaps.xl),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'people',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: Gaps.md),
                  Text(
                    'Danh sách tham gia',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (participants.length > 6)
                TextButton(
                  onPressed: onViewAllTap,
                  child: Text(
                    'Xem tất cả',
                    style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gaps.lg),
          ...displayParticipants
              .map((participant) => _buildParticipantItem(participant)),
          if (participants.length > 6)
            Container(
              margin: const EdgeInsets.only(top: Gaps.sm),
              padding: const EdgeInsets.all(Gaps.lg),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '+${participants.length - 6} người khác',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantItem(Map<String, dynamic> participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: Gaps.md),
      padding: const EdgeInsets.all(Gaps.lg),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              border: Border.all(
                color: _getRankColor(participant["rank"] as String),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: CustomImageWidget(
                imageUrl: participant["avatar"] as String,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant["name"] as String,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gaps.md, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRankColor(participant["rank"] as String),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Rank ${participant["rank"]}',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: Gaps.md),
                    Text(
                      '${participant["elo"]} ELO',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: 'chevron_right',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank.toUpperCase()) {
      case 'A':
        return const Color(0xFFFF6B6B);
      case 'B':
        return const Color(0xFFFF9F43);
      case 'C':
        return const Color(0xFFFFD93D);
      case 'D':
        return const Color(0xFF6BCF7F);
      case 'E':
        return const Color(0xFF4ECDC4);
      case 'F':
        return const Color(0xFF45B7D1);
      case 'G':
        return const Color(0xFF96CEB4);
      case 'H':
        return const Color(0xFFA8E6CF);
      case 'I':
        return const Color(0xFFDDA0DD);
      case 'J':
        return const Color(0xFFB19CD9);
      case 'K':
        return const Color(0xFF95A5A6);
      default:
        return AppTheme.lightTheme.colorScheme.primary;
    }
  }
}
