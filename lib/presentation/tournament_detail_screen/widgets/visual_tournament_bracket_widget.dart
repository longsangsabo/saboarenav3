// 🎨 SABO ARENA - Visual Tournament Bracket Widget
// Phase 2: Interactive bracket visualization for all tournament formats
// Supports drag-drop, real-time updates, and responsive design

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/constants/tournament_constants.dart';
import '../../../services/tournament_service.dart';
import '../../../services/realtime_tournament_service.dart';

class VisualTournamentBracketWidget extends StatefulWidget {
  const VisualTournamentBracketWidget({super.key});

} 
  final String tournamentId;
  final String tournamentFormat;
  final bool isInteractive;
  final bool showRealTimeUpdates;
  final VoidCallback? onMatchTapped;

  const VisualTournamentBracketWidget({
    super.key,
    required this.tournamentId,
    required this.tournamentFormat,
    this.isInteractive = true,
    this.showRealTimeUpdates = true,
    this.onMatchTapped,
  });

  @override
  State<VisualTournamentBracketWidget> createState() => _VisualTournamentBracketWidgetState();
}

class _VisualTournamentBracketWidgetState extends State<VisualTournamentBracketWidget>
    with TickerProviderStateMixin {
  final TournamentService _tournamentService = TournamentService();
  final RealTimeTournamentService _realTimeService = RealTimeTournamentService.instance;
  
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _error;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBracketData();
    if (widget.showRealTimeUpdates) {
      _subscribeToRealTimeUpdates();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.showRealTimeUpdates) {
      _realTimeService.unsubscribeTournament(widget.tournamentId);
    }
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadBracketData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _tournamentService.getTournamentMatches(widget.tournamentId),
        _tournamentService.getTournamentParticipants(widget.tournamentId),
      ]);

      if (mounted) {
        setState(() {
          _matches = results[0];
          _participants = results[1];
          _isLoading = false;
        });
        _animationController.forward();
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

  void _subscribeToRealTimeUpdates() {
    _realTimeService.subscribeTournament(widget.tournamentId);
    
    // Listen for match updates
    _realTimeService.matchUpdates.listen((update) {
      if (update['tournament_id'] == widget.tournamentId) {
        _handleRealTimeMatchUpdate(update);
      }
    });
  }

  void _handleRealTimeMatchUpdate(Map<String, dynamic> update) {
    if (!mounted) return;
    
    final matchId = update['match_id'];
    final newData = update['new_data'];
    
    setState(() {
      final matchIndex = _matches.indexWhere((m) => m['id'] == matchId);
      if (matchIndex != -1) {
        _matches[matchIndex] = newData;
      }
    });

    // Animate changes
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.indigo[50]!,
          ],
        ),
      ),
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildBracketContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 16.sp),
          Text(
            'Đang tải bracket...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.sp),
          Text(
            'Lỗi khi tải bracket',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
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
            onPressed: _loadBracketData,
            icon: Icon(Icons.refresh),
            label: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: _buildBracketForFormat(),
          ),
        ),
      ),
    );
  }

  Widget _buildBracketForFormat() {
    switch (widget.tournamentFormat) {
      case TournamentFormats.singleElimination:
        return _buildSingleEliminationBracket();
      case TournamentFormats.doubleElimination:
        return _buildDoubleEliminationBracket();
      case TournamentFormats.saboDoubleElimination:
        return _buildSaboDE16Bracket();
      case TournamentFormats.saboDoubleElimination32:
        return _buildSaboDE32Bracket();
      case TournamentFormats.roundRobin:
        return _buildRoundRobinBracket();
      case TournamentFormats.swiss:
        return _buildSwissBracket();
      case TournamentFormats.parallelGroups:
        return _buildParallelGroupsBracket();
      case TournamentFormats.winnerTakesAll:
        return _buildWinnerTakesAllBracket();
      default:
        return _buildGenericBracket();
    }
  }

  // ==================== SINGLE ELIMINATION BRACKET ====================

  Widget _buildSingleEliminationBracket() {
    final rounds = _organizeMatchesByRounds();
    if (rounds.isEmpty) return _buildEmptyBracket();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rounds.entries.map((entry) {
        final roundNumber = entry.key;
        final roundMatches = entry.value;
        
        return _buildRoundColumn(
          roundNumber: roundNumber,
          matches: roundMatches,
          isElimination: true,
        );
      }).toList(),
    );
  }

  // ==================== DOUBLE ELIMINATION BRACKET ====================

  Widget _buildDoubleEliminationBracket() {
    final winnersBracket = _matches.where((m) => m['bracket_type'] == 'winners').toList();
    final losersBracket = _matches.where((m) => m['bracket_type'] == 'losers').toList();
    final finals = _matches.where((m) => m['bracket_type'] == 'finals').toList();

    return Column(
      children: [
        // Winners Bracket
        _buildBracketSection(
          title: 'Winners Bracket',
          matches: winnersBracket,
          color: Colors.green,
        ),
        SizedBox(height: 32.sp),
        // Losers Bracket
        _buildBracketSection(
          title: 'Losers Bracket',
          matches: losersBracket,
          color: Colors.orange,
        ),
        SizedBox(height: 32.sp),
        // Finals
        _buildBracketSection(
          title: 'Finals',
          matches: finals,
          color: Colors.purple,
        ),
      ],
    );
  }

  // ==================== SABO DE16 BRACKET ====================

  Widget _buildSaboDE16Bracket() {
    final winnersMatches = _matches.where((m) => m['bracket_type'] == 'winners').toList();
    final losersAMatches = _matches.where((m) => m['bracket_type'] == 'losers_a').toList();
    final losersBMatches = _matches.where((m) => m['bracket_type'] == 'losers_b').toList();
    final finalsMatches = _matches.where((m) => m['bracket_type'] == 'finals').toList();

    return Column(
      children: [
        // Winners Bracket (14 matches)
        _buildBracketSection(
          title: 'Winners Bracket (8+4+2)',
          matches: winnersMatches,
          color: Colors.blue,
        ),
        SizedBox(height: 24.sp),
        
        // Losers Brackets
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Losers A (7 matches)
            Expanded(
              child: _buildBracketSection(
                title: 'Losers A (4+2+1)',
                matches: losersAMatches,
                color: Colors.orange,
              ),
            ),
            SizedBox(width: 16.sp),
            // Losers B (3 matches)
            Expanded(
              child: _buildBracketSection(
                title: 'Losers B (2+1)',
                matches: losersBMatches,
                color: Colors.red,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24.sp),
        // Finals (3 matches)
        _buildBracketSection(
          title: 'Sabo Finals (2 SF + 1 Final)',
          matches: finalsMatches,
          color: Colors.purple,
        ),
      ],
    );
  }

  // ==================== SABO DE32 BRACKET ====================

  Widget _buildSaboDE32Bracket() {
    final groupAMatches = _matches.where((m) => m['group_id'] == 'A').toList();
    final groupBMatches = _matches.where((m) => m['group_id'] == 'B').toList();
    final crossBracketMatches = _matches.where((m) => m['bracket_type'] == 'cross_bracket').toList();

    return Column(
      children: [
        Text(
          'SABO DE32 - Two Group System',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.indigo[800],
          ),
        ),
        SizedBox(height: 16.sp),
        
        // Two Groups Side by Side
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group A (26 matches)
            Expanded(
              child: _buildBracketSection(
                title: 'Group A (16 players → 2 qualifiers)',
                matches: groupAMatches,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 16.sp),
            // Group B (26 matches)
            Expanded(
              child: _buildBracketSection(
                title: 'Group B (16 players → 2 qualifiers)',
                matches: groupBMatches,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 24.sp),
        // Cross Bracket Finals (3 matches)
        _buildBracketSection(
          title: 'Cross-Bracket Finals (4 qualifiers → Champion)',
          matches: crossBracketMatches,
          color: Colors.purple,
        ),
      ],
    );
  }

  // ==================== ROUND ROBIN BRACKET ====================

  Widget _buildRoundRobinBracket() {
    final rounds = _organizeMatchesByRounds();
    
    return Column(
      children: [
        Text(
          'Round Robin - Everyone vs Everyone',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 16.sp),
        
        // Grid of all matches organized by rounds
        ...rounds.entries.map((entry) {
          final roundNumber = entry.key;
          final roundMatches = entry.value;
          
          return Column(
            children: [
              Text(
                'Round $roundNumber',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.sp),
              Wrap(
                spacing: 8.sp,
                runSpacing: 8.sp,
                children: roundMatches.map((match) => _buildMatchCard(match)).toList(),
              ),
              SizedBox(height: 16.sp),
            ],
          );
        }),
      ],
    );
  }

  // ==================== SWISS BRACKET ====================

  Widget _buildSwissBracket() {
    final rounds = _organizeMatchesByRounds();
    
    return Column(
      children: [
        Text(
          'Swiss System - Pairing by Performance',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        SizedBox(height: 16.sp),
        
        // Swiss rounds with performance-based pairing
        ...rounds.entries.map((entry) {
          final roundNumber = entry.key;
          final roundMatches = entry.value;
          
          return _buildSwissRound(roundNumber, roundMatches);
        }),
      ],
    );
  }

  // ==================== PARALLEL GROUPS BRACKET ====================

  Widget _buildParallelGroupsBracket() {
    final groups = <String, List<Map<String, dynamic>>>{};
    final knockoutMatches = <Map<String, dynamic>>[];

    // Organize matches by groups
    for (final match in _matches) {
      if (match['group_id'] != null) {
        final groupId = match['group_id'];
        if (!groups.containsKey(groupId)) {
          groups[groupId] = [];
        }
        groups[groupId]!.add(match);
      } else {
        knockoutMatches.add(match);
      }
    }

    return Column(
      children: [
        // Group Stage
        Text(
          'Group Stage',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.purple[800],
          ),
        ),
        SizedBox(height: 16.sp),
        
        Wrap(
          spacing: 16.sp,
          runSpacing: 16.sp,
          children: groups.entries.map((entry) {
            final groupId = entry.key;
            final groupMatches = entry.value;
            
            return _buildGroupCard(groupId, groupMatches);
          }).toList(),
        ),
        
        if (knockoutMatches.isNotEmpty) ...[
          SizedBox(height: 24.sp),
          Text(
            'Knockout Stage',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red[800],
            ),
          ),
          SizedBox(height: 16.sp),
          _buildKnockoutStage(knockoutMatches),
        ],
      ],
    );
  }

  // ==================== WINNER TAKES ALL BRACKET ====================

  Widget _buildWinnerTakesAllBracket() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[400]!, Colors.amber[600]!],
            ),
            borderRadius: BorderRadius.circular(12.sp),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 24.sp),
              SizedBox(width: 8.sp),
              Text(
                'WINNER TAKES ALL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.sp),
        _buildSingleEliminationBracket(), // Same structure as single elimination
      ],
    );
  }

  // ==================== GENERIC BRACKET ====================

  Widget _buildGenericBracket() {
    final rounds = _organizeMatchesByRounds();
    
    return Column(
      children: rounds.entries.map((entry) {
        final roundNumber = entry.key;
        final roundMatches = entry.value;
        
        return Column(
          children: [
            Text(
              'Round $roundNumber',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.sp),
            Wrap(
              spacing: 8.sp,
              runSpacing: 8.sp,
              children: roundMatches.map((match) => _buildMatchCard(match)).toList(),
            ),
            SizedBox(height: 16.sp),
          ],
        );
      }).toList(),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildBracketSection({
    required String title,
    required List<Map<String, dynamic>> matches,
    required Color color,
  }) {
    final rounds = _organizeMatchesByRounds(matches);
    
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12.sp),
        color: color.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color.shade800,
            ),
          ),
          SizedBox(height: 12.sp),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: rounds.entries.map((entry) {
              final roundNumber = entry.key;
              final roundMatches = entry.value;
              
              return _buildRoundColumn(
                roundNumber: roundNumber,
                matches: roundMatches,
                color: color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundColumn({
    required int roundNumber,
    required List<Map<String, dynamic>> matches,
    bool isElimination = false,
    Color? color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.sp),
      child: Column(
        children: [
          Text(
            isElimination ? _getEliminationRoundName(roundNumber, matches.length) : 'R$roundNumber',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color?.shade700 ?? Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.sp),
          Column(
            children: matches.map((match) => Container(
              margin: EdgeInsets.only(bottom: 8.sp),
              child: _buildMatchCard(match, color: color),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, {Color? color}) {
    final isCompleted = match['status'] == 'completed';
    final player1Name = _getPlayerName(match['player1_id']) ?? match['player1'] ?? 'TBD';
    final player2Name = _getPlayerName(match['player2_id']) ?? match['player2'] ?? 'TBD';
    final winnerId = match['winner_id'];
    
    return GestureDetector(
      onTap: widget.isInteractive ? () => widget.onMatchTapped?.call() : null,
      child: Container(
        width: 180.sp,
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: isCompleted 
              ? (color?.withOpacity(0.2) ?? Colors.green[50])
              : Colors.white,
          border: Border.all(
            color: isCompleted 
                ? (color ?? Colors.green) 
                : Colors.grey[300]!,
            width: isCompleted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Player 1
            _buildPlayerRow(
              name: player1Name,
              score: match['player1_score'],
              isWinner: winnerId == match['player1_id'],
              isCompleted: isCompleted,
            ),
            SizedBox(height: 4.sp),
            Text(
              'VS',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.sp),
            // Player 2
            _buildPlayerRow(
              name: player2Name,
              score: match['player2_score'],
              isWinner: winnerId == match['player2_id'],
              isCompleted: isCompleted,
            ),
            
            // Match info
            if (match['scheduled_time'] != null) ...[
              SizedBox(height: 8.sp),
              Text(
                _formatMatchTime(match['scheduled_time']),
                style: TextStyle(
                  fontSize: 9.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow({
    required String name,
    int? score,
    required bool isWinner,
    required bool isCompleted,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: isCompleted && isWinner 
            ? Colors.green[100] 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4.sp),
        border: isCompleted && isWinner
            ? Border.all(color: Colors.green[400]!, width: 1)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.green[800] : Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (score != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
              decoration: BoxDecoration(
                color: isWinner ? Colors.green[200] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isWinner ? Colors.green[800] : Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwissRound(int roundNumber, List<Map<String, dynamic>> matches) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        border: Border.left(color: Colors.green, width: 3),
        color: Colors.green[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Swiss Round $roundNumber',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8.sp),
          Wrap(
            spacing: 8.sp,
            runSpacing: 8.sp,
            children: matches.map((match) => _buildMatchCard(match, color: Colors.green)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(String groupId, List<Map<String, dynamic>> matches) {
    return Container(
      width: 200.sp,
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.purple, width: 2),
        borderRadius: BorderRadius.circular(8.sp),
        color: Colors.purple[50],
      ),
      child: Column(
        children: [
          Text(
            'Group $groupId',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.purple[800],
            ),
          ),
          SizedBox(height: 8.sp),
          ...matches.map((match) => Container(
            margin: EdgeInsets.only(bottom: 4.sp),
            child: _buildMatchCard(match, color: Colors.purple),
          )),
        ],
      ),
    );
  }

  Widget _buildKnockoutStage(List<Map<String, dynamic>> matches) {
    final rounds = _organizeMatchesByRounds(matches);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: rounds.entries.map((entry) {
        final roundNumber = entry.key;
        final roundMatches = entry.value;
        
        return _buildRoundColumn(
          roundNumber: roundNumber,
          matches: roundMatches,
          isElimination: true,
          color: Colors.red,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyBracket() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree,
            size: 48.sp,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16.sp),
          Text(
            'Bracket chưa được tạo',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            'Bracket sẽ được tạo khi giải đấu bắt đầu',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  Map<int, List<Map<String, dynamic>>> _organizeMatchesByRounds([List<Map<String, dynamic>>? matchList]) {
    final matches = matchList ?? _matches;
    final rounds = <int, List<Map<String, dynamic>>>{};
    
    for (final match in matches) {
      final roundNumber = match['round_number'] ?? 1;
      if (!rounds.containsKey(roundNumber)) {
        rounds[roundNumber] = [];
      }
      rounds[roundNumber]!.add(match);
    }
    
    return Map.fromEntries(rounds.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  String? _getPlayerName(String? playerId) {
    if (playerId == null) return null;
    final participant = _participants.firstWhere(
      (p) => p['user_id'] == playerId,
      orElse: () => {},
    );
    return participant['users']?['username'];
  }

  String _getEliminationRoundName(int roundNumber, int matchCount) {
    if (matchCount == 1) return 'Final';
    if (matchCount == 2) return 'Semi';
    if (matchCount == 4) return 'Quarter';
    if (matchCount == 8) return 'R16';
    if (matchCount == 16) return 'R32';
    return 'R$roundNumber';
  }

  String _formatMatchTime(String? timeString) {
    if (timeString == null) return '';
    try {
      final time = DateTime.parse(timeString).toLocal();
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
