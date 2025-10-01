import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';

import '../../../core/app_export.dart';

class TournamentRulesWidget extends StatelessWidget() {
  final List<String> rules;

  const TournamentRulesWidget({
    super.key,
    required this.rules,
  });

  @override
  Widget build(BuildContext context) {
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
            children: [
              CustomIconWidget(
                iconName: 'rule',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                'Luật thi đấu',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.lg),
          ...rules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: Gaps.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style:
                            AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gaps.md),
                  Expanded(
                    child: Text(
                      rule,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
