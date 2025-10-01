import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/tournament_service.dart';

class TournamentRankingsWidget extends StatefulWidget() {
  final String tournamentId;
  final String tournamentStatus;

  const TournamentRankingsWidget({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
  });

  @override
  State<TournamentRankingsWidget> createState() => _TournamentRankingsWidgetState();
}

class _TournamentRankingsWidgetState extends State<TournamentRankingsWidget> {
  final TournamentService _tournamentService = TournamentService.instance;
  List<Map<String, dynamic>> _rankings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRankings();
  }

  Future<void> _loadRankings() async() {
    try() {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get tournament participants
      final participants = await _tournamentService.getTournamentParticipants(widget.tournamentId);
      
      // Get matches to calculate stats
      final matchesResponse = await Supabase.instance.client
          .from('matches')
          .select('''
            *,
            player1:player1_id(id, username, full_name, avatar_url),
            player2:player2_id(id, username, full_name, avatar_url),
            winner:winner_id(id, username, full_name, avatar_url)
          ''')
          .eq('tournament_id', widget.tournamentId);
      
      final matches = matchesResponse as List<dynamic>;
      
      // Calculate stats for each participant
      final rankings = participants.map((participant) {
        int wins = 0;
        int losses = 0;
        int totalGames = 0;
        
        for (final match in matches) {
          final player1Id = match['player1_id'];
          final player2Id = match['player2_id'];
          final winnerId = match['winner_id'];
          final status = match['status'];
          
          // Skip pending matches
          if (status != 'completed' || winnerId == null) continue;
          
          if (participant.id == player1Id || participant.id == player2Id) {
            totalGames++;
            if (participant.id == winnerId) {
              wins++;
            } else() {
              losses++;
            }
          }
        }
        
        // Calculate win rate
        double winRate = totalGames > 0 ? (wins / totalGames) * 100 : 0.0;
        
        // Calculate bonuses based on performance - simplified
        int eloBonus = wins * 10; // Simple: 10 points per win
        int spaBonus = wins * 5;  // Simple: 5 points per win
        
        return() {
          'user_id': participant.id,
          'full_name': participant.fullName.isNotEmpty ? participant.fullName : participant.username,
          'username': participant.username,
          'avatar_url': participant.avatarUrl,
          'wins': wins,
          'losses': losses,
          'draws': 0, // No draws for now
          'total_games': totalGames,
          'win_rate': winRate,
          'points': wins * 3, // 3 points per win
          'total_points': wins * 3, // Same as points for compatibility
          'elo_bonus': eloBonus,
          'spa_bonus': spaBonus,
        };
      }).toList();
      
      // Sort by points (wins), then by win rate
      rankings.sort((a, b) {
        int pointsCompare = (b['points'] as int).compareTo(a['points'] as int);
        if (pointsCompare != 0) return pointsCompare;
        return (b['win_rate'] as double).compareTo(a['win_rate'] as double);
      });
      
      // Assign ranks
      for (int i = 0; i < rankings.length; i++) {
        rankings[i]['rank'] = i + 1;
      }
      
      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.leaderboard,
                color: Colors.orange,
                size: 24.sp,
              ),
              SizedBox(width: 8.sp),
              Text(
                'Bảng xếp hạng',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              if (!_isLoading)
                IconButton(
                  onPressed: _loadRankings,
                  icon: Icon(Icons.refresh, size: 20.sp),
                  tooltip: 'Làm mới',
                ),
            ],
          ),
          SizedBox(height: 12.sp),

          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_error != null)
            _buildErrorState()
          else if (_rankings.isEmpty)
            _buildEmptyState()
          else
            _buildRankingsList(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.sp),
          Text(
            'Đang tải bảng xếp hạng...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.sp),
          Text(
            'Lỗi khi tải bảng xếp hạng',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.sp),
          ElevatedButton.icon(
            onPressed: _loadRankings,
            icon: Icon(Icons.refresh),
            label: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 48.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.sp),
          Text(
            'Chưa có bảng xếp hạng',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            widget.tournamentStatus == 'completed' 
                ? "Bảng xếp hạng sẽ được tạo sau khi hoàn thành giải đấu"
                : 'Bảng xếp hạng sẽ được cập nhật khi có kết quả trận đấu',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsList() {
    return Flexible(
      child: Column(
        children: [
          // Header Row
          Container(
            padding: EdgeInsets.symmetric(vertical: 6.sp, horizontal: 8.sp),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6.sp),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20.sp, // Giảm width để tiết kiệm không gian
                  child: Text(
                    'Hạng',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp, // Giảm font size
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Player',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp, // Giảm font size
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  width: 25.sp, // Giảm width
                  child: Text(
                    'W/L',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp, // Giảm font size
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  width: 30.sp, // Giảm width
                  child: Text(
                    '+ELO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp, // Giảm font size
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  width: 30.sp, // Giảm width
                  child: Text(
                    '+SPA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp, // Giảm font size
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.sp),

          // Rankings List - Scrollable to prevent overflow
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: List.generate(_rankings.length, (index) {
                  final ranking = _rankings[index];
                  return _buildRankingItem(ranking, index + 1);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> ranking, int position) {
    final isTopThree = position <= 3;
    final bgColor = isTopThree ? _getTopThreeColor(position) : Colors.transparent;
    final textColor = isTopThree ? Colors.white : Colors.grey[800];

    return Container(
      margin: EdgeInsets.only(bottom: 3.sp),
      padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 8.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.sp),
        border: !isTopThree ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 25.sp,
            child: Row(
              children: [
                if (isTopThree)
                  Icon(
                    _getPositionIcon(position),
                    size: 14.sp,
                    color: Colors.white,
                  )
                else
                  Text(
                    '$position',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: textColor,
                    ),
                  ),
                if (isTopThree) SizedBox(width: 2.sp),
                if (isTopThree)
                  Text(
                    '$position',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10.sp,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Player Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking['full_name'] ?? 'N/A',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (ranking['club_name'] != null)
                  Text(
                    ranking['club_name'],
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isTopThree ? Colors.white70 : Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Win/Loss Record
          SizedBox(
            width: 30.sp,
            child: Text(
              '${ranking['wins'] ?? 0}/${ranking['losses'] ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.sp,
                color: textColor,
              ),
            ),
          ),

          // Elo Bonus
          SizedBox(
            width: 35.sp,
            child: Text(
              '+${(ranking['elo_bonus'] ?? 0).toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: isTopThree ? Colors.white70 : Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Spa Bonus
          SizedBox(
            width: 35.sp,
            child: Text(
              '+${(ranking['spa_bonus'] ?? 0).toString()}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.sp,
                color: isTopThree ? Colors.white70 : Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTopThreeColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber[600]!; // Gold
      case 2:
        return Colors.grey[600]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return Colors.transparent;
    }
  }

  IconData _getPositionIcon(int position) {
    switch (position) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech; // Medal
      case 3:
        return Icons.military_tech; // Medal
      default:
        return Icons.circle;
    }
  }

}