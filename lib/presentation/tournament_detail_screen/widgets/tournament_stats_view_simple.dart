import 'package:flutter/material.dart';

class TournamentStatsView extends StatefulWidget {
  const TournamentStatsView({super.key});

} 
  final String tournamentId;
  final String tournamentStatus;

  const TournamentStatsView({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
  });

  @override
  _TournamentStatsViewState createState() => _TournamentStatsViewState();
}

class _TournamentStatsViewState extends State<TournamentStatsView> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      _stats = {
        'participants': 32,
        'completed_matches': 18,
        'pending_matches': 14,
        'prize_pool': 5000000,
        'avg_match_time': 25,
        'quick_wins': 5,
        'sports_tennis': 12,
        'sports_pool': 20,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildStatsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.analytics, color: Colors.blue[600], size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Thống kê giải đấu",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[600]),
          SizedBox(height: 16),
          Text(
            "Đang tải thống kê...",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOverviewStats(),
          SizedBox(height: 24),
          _buildMatchStats(),
          SizedBox(height: 24),
          _buildPerformanceStats(),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    final stats = [
      {"title": 'Người tham gia', "value": '${_stats['participants']}', 'icon': Icons.people, 'color': Colors.blue},
      {"title": 'Trận hoàn thành', "value": '${_stats['completed_matches']}', 'icon': Icons.check_circle, 'color': Colors.green},
      {"title": 'Trận đang chờ', "value": '${_stats['pending_matches']}', 'icon': Icons.schedule, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tổng quan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: stats.map((stat) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: stats.indexOf(stat) < 2 ? 8 : 0),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 32),
                  SizedBox(height: 8),
                  Text(
                    stat['value'] as String,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    stat['title'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_score, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                "Thống kê trận đấu",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Thời gian TB",
                  "${_stats['avg_match_time']} phút",
                  "Mỗi trận",
                  Icons.timer,
                  Colors.blue[600] ?? Colors.blue,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  "Thắng nhanh",
                  "${_stats['quick_wins']}",
                  "< 15 phút",
                  Icons.settings,
                  Colors.grey[600] ?? Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Giải thưởng",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[100]!, Colors.amber[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tổng giải thưởng",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      "${_stats['prize_pool']} VNĐ",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
