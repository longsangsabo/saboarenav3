import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../member_management_screen/member_management_screen.dart';

class MemberTournamentsTab extends StatefulWidget() {
  final MemberData memberData;

  const MemberTournamentsTab({
    super.key,
    required this.memberData,
  });

  @override
  _MemberTournamentsTabState createState() => _MemberTournamentsTabState();
}

class _MemberTournamentsTabState extends State<MemberTournamentsTab>
    with AutomaticKeepAliveClientMixin() {
  @override
  bool get wantKeepAlive => true;

  List<TournamentParticipation> _tournaments = [];
  String _selectedFilter = 'all'; // all, ongoing, completed, upcoming

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() {
    _tournaments = _generateMockTournaments();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTournamentStats(),
          SizedBox(height: 24),
          _buildTournamentRankings(),
          SizedBox(height: 24),
          _buildTournamentFilters(),
          SizedBox(height: 16),
          _buildTournamentList(),
        ],
      ),
    );
  }

  Widget _buildTournamentStats() {
    final totalTournaments = widget.memberData.activityStats.tournamentsJoined;
    final wins = (_tournaments.where((t) => t.placement == 1).length);
    final podiumFinishes = (_tournaments.where((t) => t.placement != null && t.placement! <= 3).length);
    
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
                Icon(Icons.military_tech, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Thống kê giải đấu',
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
                    'Tham gia',
                    '$totalTournaments',
                    Icons.emoji_events,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Vô địch',
                    '$wins',
                    Icons.emoji_events,
                    Colors.gold,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Top 3',
                    '$podiumFinishes',
                    Icons.workspace_premium,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Tỷ lệ thành công',
                    '${totalTournaments > 0 ? (podiumFinishes * 100 / totalTournaments).toInt() : 0}%',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentRankings() {
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
                Icon(Icons.leaderboard, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Thành tích nổi bật',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Best achievements
            _buildAchievementItem(
              'Vị trí cao nhất',
              '1st',
              'Giải đấu Mùa Hè 2024',
              Icons.military_tech,
              Colors.gold,
            ),
            
            SizedBox(height: 12),
            
            _buildAchievementItem(
              'Chuỗi thắng dài nhất',
              '7 trận',
              'Từ 15/08 - 22/08/2024',
              Icons.whatshot,
              Colors.orange,
            ),
            
            SizedBox(height: 12),
            
            _buildAchievementItem(
              'Điểm ELO cao nhất',
              '1520',
              'Đạt được ngày 10/09/2024',
              Icons.trending_up,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentFilters() {
    final filters = [
      {"key": 'all', "label": 'Tất cả', 'count': _tournaments.length},
      {"key": 'ongoing', "label": 'Đang diễn ra', 'count': _tournaments.where((t) => t.status == TournamentStatus.ongoing).length},
      {"key": 'completed', "label": 'Đã kết thúc', 'count': _tournaments.where((t) => t.status == TournamentStatus.completed).length},
      {"key": 'upcoming', "label": 'Sắp tới', 'count': _tournaments.where((t) => t.status == TournamentStatus.upcoming).length},
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

  Widget _buildTournamentList() {
    final filteredTournaments = _getFilteredTournaments();
    
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
                Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  'Danh sách giải đấu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _exportTournamentHistory,
                  child: Text('Xuất dữ liệu'),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            if (filteredTournaments.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có giải đấu nào',
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
                itemCount: filteredTournaments.length,
                separatorBuilder: (context, index) => Divider(height: 24),
                itemBuilder: (context, index) {
                  return _buildTournamentItem(filteredTournaments[index]);
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

  Widget _buildAchievementItem(String title, String value, String description, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          
          SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Spacer(),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentItem(TournamentParticipation tournament) {
    Color statusColor;
    IconData statusIcon;
    
    switch (tournament.status) {
      case TournamentStatus.ongoing:
        statusColor = Colors.blue;
        statusIcon = Icons.play_circle;
        break;
      case TournamentStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TournamentStatus.upcoming:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
    }

    return InkWell(
      onTap: () => _viewTournamentDetail(tournament),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            // Tournament image/icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.emoji_events, color: statusColor, size: 24),
            ),
            
            SizedBox(width: 12),
            
            // Tournament info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 10, color: statusColor),
                            SizedBox(width: 2),
                            Text(
                              _getStatusText(tournament.status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 6),
                  
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(tournament.startDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.people, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${tournament.participants} người tham gia',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  
                  if (tournament.placement != null) ...[
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.military_tech,
                          size: 12,
                          color: _getPlacementColor(tournament.placement!),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Vị trí: ${_getPlacementText(tournament.placement!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getPlacementColor(tournament.placement!),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (tournament.prize != null) ...[
                          SizedBox(width: 16),
                          Icon(Icons.card_giftcard, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            tournament.prize!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  List<TournamentParticipation> _getFilteredTournaments() {
    switch (_selectedFilter) {
      case 'ongoing':
        return _tournaments.where((t) => t.status == TournamentStatus.ongoing).toList();
      case 'completed':
        return _tournaments.where((t) => t.status == TournamentStatus.completed).toList();
      case 'upcoming':
        return _tournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
      default:
        return _tournaments;
    }
  }

  String _getStatusText(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.ongoing:
        return 'ĐANG DIỄN RA';
      case TournamentStatus.completed:
        return 'ĐÃ KẾT THÚC';
      case TournamentStatus.upcoming:
        return 'SẮP TỚI';
    }
  }

  String _getPlacementText(int placement) {
    if (placement == 1) return '🥇 Nhất';
    if (placement == 2) return '🥈 Nhì';
    if (placement == 3) return '🥉 Ba';
    return '#$placement';
  }

  Color _getPlacementColor(int placement) {
    if (placement == 1) return Colors.gold;
    if (placement == 2) return Colors.grey;
    if (placement == 3) return Colors.brown;
    if (placement <= 10) return Colors.green;
    return Colors.blue;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _exportTournamentHistory() {
    // Implementation for exporting tournament history
  }

  void _viewTournamentDetail(TournamentParticipation tournament) {
    // Implementation for viewing tournament details
  }

  List<TournamentParticipation> _generateMockTournaments() {
    final now = DateTime.now();
    return [
      TournamentParticipation(
        id: 'tournament_1',
        name: 'Giải đấu Mùa Thu 2024',
        startDate: now.subtract(Duration(days: 30)),
        endDate: now.subtract(Duration(days: 25)),
        status: TournamentStatus.completed,
        participants: 64,
        placement: 1,
        prize: '2.000.000 VNĐ',
      ),
      TournamentParticipation(
        id: 'tournament_2',
        name: 'Championship Series #12',
        startDate: now.subtract(Duration(days: 15)),
        endDate: now.subtract(Duration(days: 10)),
        status: TournamentStatus.completed,
        participants: 32,
        placement: 3,
        prize: '500.000 VNĐ',
      ),
      TournamentParticipation(
        id: 'tournament_3',
        name: 'Weekly Tournament #45',
        startDate: now.subtract(Duration(days: 5)),
        endDate: now.add(Duration(days: 2)),
        status: TournamentStatus.ongoing,
        participants: 16,
      ),
      TournamentParticipation(
        id: 'tournament_4',
        name: 'Giải đấu Tết 2025',
        startDate: now.add(Duration(days: 60)),
        endDate: now.add(Duration(days: 67)),
        status: TournamentStatus.upcoming,
        participants: 128,
      ),
      TournamentParticipation(
        id: 'tournament_5',
        name: 'Master Cup 2024',
        startDate: now.subtract(Duration(days: 90)),
        endDate: now.subtract(Duration(days: 83)),
        status: TournamentStatus.completed,
        participants: 256,
        placement: 8,
      ),
    ];
  }
}

enum TournamentStatus { ongoing, completed, upcoming }

class TournamentParticipation() {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentStatus status;
  final int participants;
  final int? placement;
  final String? prize;

  TournamentParticipation({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.participants,
    this.placement,
    this.prize,
  });
}