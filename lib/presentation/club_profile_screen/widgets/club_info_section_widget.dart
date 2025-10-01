import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubInfoSectionWidget extends StatelessWidget() {
  final Map<String, dynamic> clubData;

  const ClubInfoSectionWidget({
    super.key,
    required this.clubData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Thông tin câu lạc bộ',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 2.h),
          
          // Description
          if (clubData["description"] != null) ...[
            Text(
              clubData["description"],
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 2.h),
          ],
          
          // Contact Info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.phone,
                  title: 'Điện thoại',
                  value: clubData["phone"] ?? "Chưa có",
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.email,
                  title: 'Email',
                  value: clubData["email"] ?? "Chưa có",
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Rating and Members
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.star,
                  title: 'Đánh giá',
                  value: '${clubData["rating"] ?? 0.0} (${clubData["reviewCount"] ?? 0} đánh giá)',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.people,
                  title: 'Thành viên',
                  value: '${clubData["memberCount"] ?? 0} người',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          // Operating Hours
          if (clubData["operatingHours"] != null) ...[
            Text(
              'Giờ mở cửa',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: (clubData["operatingHours"] as Map<String, dynamic>)
                    .entries
                    .map((entry) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 0.5.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                entry.value,
                                style: AppTheme.lightTheme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 5.w,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}