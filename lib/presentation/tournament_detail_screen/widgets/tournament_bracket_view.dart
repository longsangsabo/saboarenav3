import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import '../../../core/utils/rank_migration_helper.dart';

class TournamentBracketView extends StatefulWidget() {
  final String tournamentId;
  final String format; // 'single_elimination', 'double_elimination', 'round_robin'
  final int totalParticipants;
  final bool isEditable;

  const TournamentBracketView({
    super.key,
    required this.tournamentId,
    required this.format,
    required this.totalParticipants,
    this.isEditable = false,
  });

  @override
  _TournamentBracketViewState createState() => _TournamentBracketViewState();
}

class _TournamentBracketViewState extends State<TournamentBracketView>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  double _scaleFactor = 1.0;
  
  List<BracketRound> _rounds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _loadBracketData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBracketData() async() {
    // Simulate data loading
    await Future.delayed(Duration(milliseconds: 1000));
    
    setState(() {
      _rounds = _generateMockBracket();
      _isLoading = false;
    });
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildBracketContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.dividerLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bảng đấu",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  _getFormatDescription(),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),

          // Zoom controls
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _updateScale(false),
                  icon: Icon(Icons.zoom_out, size: 18.sp),
                  padding: EdgeInsets.all(8.sp),
                  constraints: BoxConstraints(minWidth: 32.sp, minHeight: 32.sp),
                ),
                Container(width: 1, height: 20.sp, color: AppTheme.dividerLight),
                IconButton(
                  onPressed: () => _updateScale(true),
                  icon: Icon(Icons.zoom_in, size: 18.sp),
                  padding: EdgeInsets.all(8.sp),
                  constraints: BoxConstraints(minWidth: 32.sp, minHeight: 32.sp),
                ),
              ],
            ),
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
          CircularProgressIndicator(color: AppTheme.primaryLight),
          SizedBox(height: 16.sp),
          Text(
            "Đang tải bảng đấu...",
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleFactor,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Container(
                  padding: EdgeInsets.all(16.sp),
                  child: _buildBracketLayout(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBracketLayout() {
    if (widget.format == 'round_robin') {
      return _buildRoundRobinTable();
    } else() {
      return _buildEliminationBracket();
    }
  }

  Widget _buildEliminationBracket() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _rounds.asMap().entries.map((entry) {
        final index = entry.key;
        final round = entry.value;

        return Row(
          children: [
            _buildRoundColumn(round, index),
            if (index < _rounds.length - 1)
              SizedBox(width: 40.sp), // Spacing between rounds
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRoundColumn(BracketRound round, int roundIndex) {
    return Column(
      children: [
        // Round header
        Container(
          margin: EdgeInsets.only(bottom: 16.sp),
          padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12.sp),
          ),
          child: Text(
            round.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Matches in this round
        ...round.matches.asMap().entries.map((entry) {
          final matchIndex = entry.key;
          final match = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: _getMatchSpacing(roundIndex, matchIndex)),
            child: _buildMatchCard(match),
          );
        }),
      ],
    );
  }

  Widget _buildMatchCard(BracketMatch match) {
    return Container(
      width: 180.sp,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: match.status == 'completed'
              ? AppTheme.successLight.withOpacity(0.3)
              : AppTheme.dividerLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPlayerRow(match.player1, match.score1, match.winner == 1),
          Container(height: 1, color: AppTheme.dividerLight),
          _buildPlayerRow(match.player2, match.score2, match.winner == 2),
          if (match.status != 'pending' && match.scheduledTime != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.sp)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    match.status == 'completed'
                        ? Icons.check_circle_outline
                        : Icons.schedule,
                    size: 12.sp,
                    color: match.status == 'completed'
                        ? AppTheme.successLight
                        : AppTheme.accentLight,
                  ),
                  SizedBox(width: 4.sp),
                  Text(
                    match.status == 'completed'
                        ? 'Hoàn thành'
                        : match.scheduledTime!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: match.status == 'completed'
                          ? AppTheme.successLight
                          : AppTheme.accentLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(String? playerName, int? score, bool isWinner) {
    final isEmpty = playerName == null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: isWinner ? AppTheme.successLight.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(isWinner ? 8.sp : 0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEmpty ? 'TBD' : playerName,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isWinner ? FontWeight.w600 : FontWeight.normal,
                color: isEmpty
                    ? AppTheme.textDisabledLight
                    : (isWinner ? AppTheme.successLight : AppTheme.textPrimaryLight),
              ),
            ),
          ),
          if (!isEmpty && score != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
              decoration: BoxDecoration(
                color: isWinner ? AppTheme.successLight : AppTheme.textDisabledLight,
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoundRobinTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.sp)),
            ),
            child: Text(
              "Bảng xếp hạng Round Robin",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Hạng')),
                DataColumn(label: Text('Người chơi')),
                DataColumn(label: Text('Thắng')),
                DataColumn(label: Text('Thua')),
                DataColumn(label: Text('Điểm')),
              ],
              rows: _getRealRoundRobinData().map((player) {
                return DataRow(
                  cells: [
                    DataCell(Text(RankMigrationHelper.getNewDisplayName(player['rank']))),
                    DataCell(Text(player['name'])),
                    DataCell(Text(player['wins'].toString())),
                    DataCell(Text(player['losses'].toString())),
                    DataCell(Text(player['points'].toString())),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  double _getMatchSpacing(int roundIndex, int matchIndex) {
    // Increase spacing in later rounds to align with bracket structure
    return 16.sp * (1 << roundIndex);
  }

  void _updateScale(bool zoomIn) {
    setState(() {
      if (zoomIn && _scaleFactor < 2.0) {
        _scaleFactor += 0.2;
      } else if (!zoomIn && _scaleFactor > 0.5) {
        _scaleFactor -= 0.2;
      }
    });
  }

  String _getFormatDescription() {
    switch (widget.format) {
      case 'single_elimination':
        return 'Loại trực tiếp đơn - ${widget.totalParticipants} người chơi';
      case 'double_elimination':
        return 'Loại trực tiếp kép - ${widget.totalParticipants} người chơi';
      case 'round_robin':
        return 'Đấu vòng tròn - ${widget.totalParticipants} người chơi';
      default:
        return '${widget.totalParticipants} người chơi';
    }
  }

  List<BracketRound> _generateMockBracket() {
    if (widget.format == 'round_robin') {
      return []; // Round robin doesn't use bracket structure
    }
    
    // Generate single elimination bracket for demo
    final rounds = <BracketRound>[];
    int participantsInRound = widget.totalParticipants;
    int roundNumber = 1;
    
    while (participantsInRound > 1) {
      final matches = <BracketMatch>[];
      final matchesInRound = participantsInRound ~/ 2;
      
      for (int i = 0; i < matchesInRound; i++) {
        String? player1, player2;
        int? score1, score2;
        int? winner;
        String status = 'pending';
        
        // Mock some completed matches in early rounds
        if (roundNumber == 1) {
          player1 = 'Người chơi ${i * 2 + 1}';
          player2 = 'Người chơi ${i * 2 + 2}';
          
          if (i < 2) { // First 2 matches completed
            score1 = 3;
            score2 = 1;
            winner = 1;
            status = 'completed';
          }
        } else if (roundNumber == 2 && i == 0) {
          player1 = 'Người chơi 1';
          player2 = 'Người chơi 3';
          score1 = 3;
          score2 = 2;
          winner = 1;
          status = 'completed';
        }
        
        matches.add(BracketMatch(
          id: 'r${roundNumber}_m${i + 1}',
          player1: player1,
          player2: player2,
          score1: score1,
          score2: score2,
          winner: winner,
          status: status,
          scheduledTime: status != 'pending' ? null : '14:${30 + i * 15}',
        ));
      }
      
      rounds.add(BracketRound(
        name: _getRoundName(roundNumber, participantsInRound),
        matches: matches,
      ));
      
      participantsInRound = matchesInRound;
      roundNumber++;
    }
    
    return rounds;
  }

  String _getRoundName(int roundNumber, int participantsInRound) {
    if (participantsInRound <= 2) return 'Chung kết';
    if (participantsInRound <= 4) return 'Bán kết';
    if (participantsInRound <= 8) return 'Tứ kết';
    return 'Vòng $roundNumber';
  }

  List<Map<String, dynamic>> _getRealRoundRobinData() {
    // Get real tournament standings from database
    // This would be populated by real tournament data
    return [];
  }
}

class BracketRound() {
  final String name;
  final List<BracketMatch> matches;

  BracketRound({
    required this.name,
    required this.matches,
  });
}

class BracketMatch() {
  final String id;
  final String? player1;
  final String? player2;
  final int? score1;
  final int? score2;
  final int? winner; // 1 for player1, 2 for player2, null for no winner yet
  final String status; // 'pending', 'ongoing', 'completed'
  final String? scheduledTime;

  BracketMatch({
    required this.id,
    this.player1,
    this.player2,
    this.score1,
    this.score2,
    this.winner,
    required this.status,
    this.scheduledTime,
  });
}