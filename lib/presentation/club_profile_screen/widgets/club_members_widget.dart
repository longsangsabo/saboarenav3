import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubMembersWidget extends StatelessWidget {
  const ClubMembersWidget({super.key});

} 
  final List<Map<String, dynamic>> members;
  final bool isOwner;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onMemberTap;

  const ClubMembersWidget({
    super.key,
    required this.members,
    required this.isOwner,
    required this.onViewAll,
    required this.onMemberTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thành viên (${members.length})',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text('Xem tất cả'),
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: members.length > 5 ? 5 : members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 6.w,
                      backgroundImage: member["avatar"] != null
                          ? NetworkImage(member["avatar"])
                          : null,
                      child: member["avatar"] == null
                          ? Icon(Icons.person, size: 6.w)
                          : null,
                    ),
                    
                    SizedBox(width: 3.w),
                    
                    // Member Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member["name"] ?? "Unknown",
                                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (member["isOnline"] == true)
                                Container(
                                  width: 2.w,
                                  height: 2.w,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            member["rank"] ?? "Unranked",
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getRoleText(member["role"]),
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'owner':
        return 'Chủ sở hữu';
      case 'admin':
        return 'Quản trị viên';
      case 'member':
        return 'Thành viên';
      default:
        return 'Thành viên';
    }
  }
}
