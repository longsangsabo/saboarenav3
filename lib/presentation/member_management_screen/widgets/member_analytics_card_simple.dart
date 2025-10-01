import 'package:flutter/material.dart';
import '../../../models/member_analytics.dart';

class MemberAnalyticsCardSimple extends StatelessWidget() {
  final MemberAnalytics analytics;
  
  const MemberAnalyticsCardSimple({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê thành viên',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsItem(
                  context: context,
                  icon: Icons.people,
                  title: 'Tổng thành viên',
                  value: '${analytics.totalMembers}',
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: _buildAnalyticsItem(
                  context: context,
                  icon: Icons.people_alt,
                  title: 'Hoạt động',
                  value: '${analytics.activeMembers}',
                  color: Colors.green,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: _buildAnalyticsItem(
                  context: context,
                  icon: Icons.trending_up,
                  title: 'Mới tháng này',
                  value: '+${analytics.newThisMonth}',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}