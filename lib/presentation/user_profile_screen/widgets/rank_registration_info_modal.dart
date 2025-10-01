import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';

class RankRegistrationInfoModal extends StatelessWidget() {
  final VoidCallback onStartRegistration;

  const RankRegistrationInfoModal({
    super.key,
    required this.onStartRegistration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 12.w,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: 3.h),

          // Title
          Text(
            'Hệ Thống Xếp Hạng Sabo',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Đăng ký hạng để mở khóa toàn bộ tiềm năng của bạn trên Sabo Arena!',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          SizedBox(height: 3.h),

          // Features
          _buildFeatureItem(
            context,
            icon: Icons.bar_chart,
            title: 'Xác định trình độ',
            subtitle: 'Biết rõ kỹ năng của bạn đang ở đâu so với cộng đồng.',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.people_alt_outlined,
            title: 'Tìm đối thủ xứng tầm',
            subtitle: 'Hệ thống sẽ gợi ý những người chơi có cùng đẳng cấp.',
          ),
          _buildFeatureItem(
            context,
            icon: Icons.emoji_events,
            title: 'Tham gia giải đấu độc quyền',
            subtitle: 'Nhiều giải đấu chỉ dành cho các thành viên đã có hạng.',
          ),
          SizedBox(height: 4.h),

          // Call to Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStartRegistration,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Bắt đầu đăng ký',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Để sau',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 28,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  subtitle,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
