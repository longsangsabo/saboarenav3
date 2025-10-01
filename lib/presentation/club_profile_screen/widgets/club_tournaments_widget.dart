import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ClubTournamentsWidget extends StatelessWidget {
  const ClubTournamentsWidget({super.key});

} 
  final List<Map<String, dynamic>> tournaments;
  final bool isOwner;
  final VoidCallback onCreateTournament;
  final VoidCallback onViewAll;
  final Function(Map<String, dynamic>) onTournamentTap;

  const ClubTournamentsWidget({
    super.key,
    required this.tournaments,
    required this.isOwner,
    required this.onCreateTournament,
    required this.onViewAll,
    required this.onTournamentTap,
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
                'Giải đấu (${tournaments.length})',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  if (isOwner)
                    IconButton(
                      onPressed: onCreateTournament,
                      icon: Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                        foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                      ),
                    ),
                  if (tournaments.isNotEmpty)
                    TextButton(
                      onPressed: onViewAll,
                      child: Text('Xem tất cả'),
                    ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 2.h),
          
          if (tournaments.isEmpty)
            _buildEmptyState()
          else
            _buildTournamentList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 12.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            'Chưa có giải đấu nào',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            isOwner 
                ? "Tạo giải đấu đầu tiên cho câu lạc bộ của bạn"
                : 'Câu lạc bộ chưa tổ chức giải đấu nào',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (isOwner) ...[
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: onCreateTournament,
              child: Text('Tạo giải đấu'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTournamentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: tournaments.length > 3 ? 3 : tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return Container(
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: InkWell(
            onTap: () => onTournamentTap(tournament),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(tournament["status"]).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(tournament["status"]),
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: _getStatusColor(tournament["status"]),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 4.w,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 2.h),
                  
                  Text(
                    tournament["name"] ?? "Unknown Tournament",
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 1.h),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        size: 4.w,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '${tournament["participants"] ?? 0}/${tournament["maxParticipants"] ?? 0} người tham gia',
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 0.5.h),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 4.w,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _formatDate(tournament["startDate"]),
                        style: AppTheme.lightTheme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  
                  if (tournament["prizePool"] != null) ...[
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 4.w,
                          color: AppTheme.lightTheme.colorScheme.primary,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Giải thưởng: ${_formatPrize(tournament["prizePool"])}',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Chưa xác định';
    
    try {
      final DateTime dateTime = date is DateTime ? date : DateTime.parse(date.toString());
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Chưa xác định';
    }
  }

  String _formatPrize(dynamic prize) {
    if (prize == null) return '';
    
    try {
      final num prizeValue = num.parse(prize.toString());
      if (prizeValue >= 1000000) {
        return '${(prizeValue / 1000000).toStringAsFixed(1)}M VND';
      } else if (prizeValue >= 1000) {
        return '${(prizeValue / 1000).toStringAsFixed(0)}K VND';
      } else {
        return '$prizeValue VND';
      }
    } catch (e) {
      return prize.toString();
    }
  }
}
