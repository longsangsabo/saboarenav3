import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/user_profile.dart';
import './challenge_modal_widget.dart';

class PlayerCardWidget extends StatelessWidget {
  const PlayerCardWidget({super.key});

} 
  final UserProfile player;

  const PlayerCardWidget({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Row(
              children: [
                // Player Avatar
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  child:
                      player.avatarUrl != null
                          ? ClipOval(
                            child: Image.network(
                              player.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.person,
                                    color: Colors.grey[400],
                                  ),
                            ),
                          )
                          : Icon(Icons.person, color: Colors.grey[400]),
                ),
                SizedBox(width: 12.w),

                // Player Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.fullName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (player.username != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '@${player.username}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      SizedBox(height: 4.h),

                      // Skill Level Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getSkillLevelColor(player.skillLevel),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          player.skillLevelDisplay,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Challenge Button
                ElevatedButton(
                  onPressed: () => _showChallengeModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Thách đấu',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Player Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Thắng',
                    '${player.totalWins}',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thua',
                    '${player.totalLosses}',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tỷ lệ',
                    '${player.winRate.toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Điểm',
                    '${player.rankingPoints}',
                    Colors.purple,
                  ),
                ),
              ],
            ),

            if (player.location != null) ...[
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14.sp, color: Colors.grey[500]),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      player.location!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey[600])),
      ],
    );
  }

  Color _getSkillLevelColor(String skillLevel) {
    switch (skillLevel) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.blue;
      case 'advanced':
        return Colors.orange;
      case 'professional':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showChallengeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => ChallengeModalWidget(
            player: {
              'name': player.fullName,
              'username': player.username,
              'skillLevel': player.skillLevel,
            },
            challengeType: 'thach_dau',
          ),
    );
  }
}
