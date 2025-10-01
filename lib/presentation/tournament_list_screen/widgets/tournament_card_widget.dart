import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../models/tournament.dart';
import '../../../routes/app_routes.dart';

class TournamentCardWidget extends StatelessWidget {
  const TournamentCardWidget({super.key});

} 
  final Tournament tournament;

  const TournamentCardWidget({
    super.key,
    required this.tournament,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.tournamentDetailScreen,
          arguments: tournament.id,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament Cover Image
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: tournament.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              tournament.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image, color: Colors.grey[400]),
                            ),
                          )
                        : Icon(Icons.emoji_events, color: Colors.grey[400]),
                  ),
                  const SizedBox(width: 12),

                  // Tournament Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournament.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tournament.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(tournament.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(tournament.status),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Tournament Details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      DateFormat('dd/MM/yyyy').format(tournament.startDate),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.people,
                      '${tournament.currentParticipants}/${tournament.maxParticipants}',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.star,
                      tournament.skillLevelRequired != null
                          ? _getSkillLevelText(tournament.skillLevelRequired!)
                          : 'Tất cả',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.monetization_on,
                      tournament.entryFee > 0
                          ? "${tournament.entryFee.toStringAsFixed(0)}đ"
                          : 'Miễn phí',
                    ),
                  ),
                ],
              ),

              if (tournament.prizePool > 0) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[100]!, Colors.amber[50]!],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🏆 Giải thưởng: ${tournament.prizePool.toStringAsFixed(0)}đ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
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
        return Colors.blue;
    }
  }

  String _getStatusText(String status) {
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
        return 'Sắp diễn ra';
    }
  }

  String _getSkillLevelText(String skillLevel) {
    switch (skillLevel) {
      case 'beginner':
        return 'Người mới';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return 'Tất cả';
    }
  }
}
