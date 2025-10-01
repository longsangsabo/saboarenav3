import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../member_management_screen/member_management_screen.dart';

class MemberMatchesTab extends StatefulWidget() {
  final MemberData memberData;

  const MemberMatchesTab({
    super.key,
    required this.memberData,
  });

  @override
  _MemberMatchesTabState createState() => _MemberMatchesTabState();
}

class _MemberMatchesTabState extends State<MemberMatchesTab>
    with AutomaticKeepAliveClientMixin() {
  @override
  bool get wantKeepAlive => true;

  List<MatchRecord> _matches = [];
  String _selectedFilter = 'all'; // all, wins, losses, draws
  
  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() {
    _matches = _generateMockMatches();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchStats(),
          SizedBox(height: 24),
          _buildPerformanceChart(),
          SizedBox(height: 24),
          _buildMatchFilters(),
          SizedBox(height: 16),
          _buildMatchHistory(),
        ],
      ),
    );
  }

  Widget _buildMatchStats() {
    final totalMatches = widget.memberData.activityStats.totalMatches;
    final wins = (totalMatches * widget.memberData.activityStats.winRate).round();
    final losses = totalMatches - wins;
    
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Thống kê trận đấu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tổng số trận',
                    '$totalMatches',
                    Icons.sports_esports,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thắng',
                    '$wins',
                    Icons.emoji_events,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thua',
                    '$losses',
                    Icons.close,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tỷ lệ thắng',
                    '${(widget.memberData.activityStats.winRate * 100).toInt()}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Win rate progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tỷ lệ thắng',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(widget.memberData.activityStats.winRate * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: widget.memberData.activityStats.winRate,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Biểu đồ phong độ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _viewDetailedStats,
                  child: Text('Chi tiết'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Mock performance chart
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Biểu đồ ELO theo thời gian',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ELO hiện tại: ${widget.memberData.user.elo}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchFilters() {
    final filters = [
      {"key": 'all', "label": 'Tất cả', 'count': _matches.length},
      {"key": 'wins', "label": 'Thắng', 'count': _matches.where((m) => m.result == MatchResult.win).length},
      {"key": 'losses', "label": 'Thua', 'count': _matches.where((m) => m.result == MatchResult.loss).length},
      {"key": 'draws', "label": 'Hòa', 'count': _matches.where((m) => m.result == MatchResult.draw).length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter['key'] as String),
              label: Text('${filter['label']} (${filter['count']})'),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatchHistory() {
    final filteredMatches = _getFilteredMatches();
    
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Lịch sử trận đấu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _exportMatchHistory,
                  child: Text('Xuất dữ liệu'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            if (filteredMatches.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có trận đấu nào',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredMatches.length,
                separatorBuilder: (context, index) => Divider(height: 24),
                itemBuilder: (context, index) {
                  return _buildMatchItem(filteredMatches[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMatchItem(MatchRecord match) {
    Color resultColor;
    IconData resultIcon;
    
    switch (match.result) {
      case MatchResult.win:
        resultColor = Colors.green;
        resultIcon = Icons.check_circle;
        break;
      case MatchResult.loss:
        resultColor = Colors.red;
        resultIcon = Icons.cancel;
        break;
      case MatchResult.draw:
        resultColor = Colors.orange;
        resultIcon = Icons.remove_circle;
        break;
    }

    return InkWell(
      onTap: () => _viewMatchDetail(match),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            // Result indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: resultColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(resultIcon, color: resultColor, size: 20),
            ),
            
            SizedBox(width: 12),
            
            // Match info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'vs ${match.opponent}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getResultText(match.result),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatMatchDate(match.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.emoji_events, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'ELO: ${match.eloChange > 0 ? "+" : ''}${match.eloChange}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: match.eloChange > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (match.tournament != null) ...[
                        SizedBox(width: 16),
                        Icon(Icons.military_tech, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            match.tournament!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  List<MatchRecord> _getFilteredMatches() {
    switch (_selectedFilter) {
      case 'wins':
        return _matches.where((m) => m.result == MatchResult.win).toList();
      case 'losses':
        return _matches.where((m) => m.result == MatchResult.loss).toList();
      case 'draws':
        return _matches.where((m) => m.result == MatchResult.draw).toList();
      default:
        return _matches;
    }
  }

  String _getResultText(MatchResult result) {
    switch (result) {
      case MatchResult.win:
        return 'THẮNG';
      case MatchResult.loss:
        return 'THUA';
      case MatchResult.draw:
        return 'HÒA';
    }
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Hôm nay';
    } else if (difference == 1) {
      return 'Hôm qua';
    } else if (difference < 7) {
      return '$difference ngày trước';
    } else() {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _viewDetailedStats() {
    // Implementation for detailed statistics view
  }

  void _exportMatchHistory() {
    // Implementation for exporting match history
  }

  void _viewMatchDetail(MatchRecord match) {
    // Implementation for viewing match details
  }

  List<MatchRecord> _generateMockMatches() {
    final now = DateTime.now();
    return List.generate(20, (index) {
      final result = [MatchResult.win, MatchResult.loss, MatchResult.draw][index % 3];
      final eloChange = result == MatchResult.win ? 
        15 + (index % 20) : 
        result == MatchResult.loss ? 
          -(10 + (index % 15)) : 
          0;
      
      return MatchRecord(
        id: 'match_$index',
        opponent: 'Đối thủ ${index + 1}',
        result: result,
        date: now.subtract(Duration(days: index * 2)),
        eloChange: eloChange,
        tournament: index % 4 == 0 ? 'Giải đấu ${(index ~/ 4) + 1}' : null,
      );
    });
  }
}

enum MatchResult { win, loss, draw }

class MatchRecord() {
  final String id;
  final String opponent;
  final MatchResult result;
  final DateTime date;
  final int eloChange;
  final String? tournament;

  MatchRecord({
    required this.id,
    required this.opponent,
    required this.result,
    required this.date,
    required this.eloChange,
    this.tournament,
  });
}