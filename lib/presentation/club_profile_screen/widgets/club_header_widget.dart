import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubHeaderWidget extends StatelessWidget {
  const ClubHeaderWidget({super.key});

} 
  final Map<String, dynamic> clubData;
  final bool isOwner;
  final VoidCallback onEditPressed;
  final VoidCallback onJoinTogglePressed;

  const ClubHeaderWidget({
    super.key,
    required this.clubData,
    required this.isOwner,
    required this.onEditPressed,
    required this.onJoinTogglePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 25.h,
      pinned: true,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover Image
            clubData["coverImage"] != null
                ? Image.network(
                    clubData["coverImage"],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.sports_bar,
                          size: 15.w,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: Icon(
                      Icons.sports_bar,
                      size: 15.w,
                      color: Colors.grey.shade600,
                    ),
                  ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // Club Info
            Positioned(
              bottom: 2.h,
              left: 4.w,
              right: 4.w,
              child: Row(
                children: [
                  // Club Logo
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: clubData["logo"] != null
                          ? Image.network(
                              clubData["logo"],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade300,
                                  child: Icon(
                                    Icons.sports_bar,
                                    color: Colors.grey.shade600,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.sports_bar,
                                color: Colors.grey.shade600,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(width: 3.w),
                  
                  // Club Name and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clubData["name"] ?? "Unknown Club",
                          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 4.w,
                            ),
                            SizedBox(width: 1.w),
                            Expanded(
                              child: Text(
                                clubData["location"] ?? "Unknown Location",
                                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Button
                  ElevatedButton(
                    onPressed: isOwner ? onEditPressed : onJoinTogglePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOwner ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      isOwner ? 'Chỉnh sửa' : (clubData["isMember"] ? "Rời khỏi" : 'Tham gia'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
