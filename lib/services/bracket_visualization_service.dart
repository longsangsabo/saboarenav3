// 🎯 SABO ARENA - Bracket Visualization Service  
// Renders real tournament brackets with live participant data and match results
// Converts bracket data into UI-ready components with real-time updates

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/tournament_detail_screen/widgets/demo_bracket/components/bracket_components.dart';
import 'dart:math' as math;

/// Service for rendering tournament brackets with real participant data
class BracketVisualizationService() {
  static BracketVisualizationService? _instance;
  static BracketVisualizationService get instance => _instance ??= BracketVisualizationService._();
  BracketVisualizationService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== MAIN VISUALIZATION METHODS ====================

  /// Build complete bracket widget from tournament data
  Future<Widget> buildTournamentBracket({
    required String tournamentId,
    required Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates = true,
  }) async() {
    try() {
      final format = bracketData['format'] ?? 'single_elimination';
      
      debugPrint('🎨 Building bracket visualization for format: $format');

      switch (format.toLowerCase()) {
        case 'single_elimination':
          return await _buildSingleEliminationBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        case 'double_elimination':
          return await _buildDoubleEliminationBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        case 'sabo_de16':
        case 'sabo_double_elimination':
          return await _buildSaboDE16Bracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        case 'round_robin':
          return await _buildRoundRobinBracket(
            tournamentId,
            bracketData,
            onMatchTap,
            showLiveUpdates,
          );
        default:
          return _buildUnsupportedFormatWidget(format);
      }
    } catch (e) {
      debugPrint('❌ Error building bracket visualization: $e');
      return _buildErrorWidget(e.toString());
    }
  }

  // ==================== SINGLE ELIMINATION BRACKET ====================

  Future<Widget> _buildSingleEliminationBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async() {
    final matches = bracketData['matches'] as List<dynamic>? ?? [];
    
    if (matches.isEmpty) {
      return _buildNoMatchesWidget();
    }
    
    // Convert matches to rounds format like demo bracket
    final rounds = _convertMatchesToRounds(matches);
    
    if (rounds.isEmpty) {
      return _buildNoMatchesWidget();
    }

    return Container(
      padding: const EdgeInsets.all(4), // Giảm padding tối đa
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bỏ luôn Compact Bracket Header để tiết kiệm không gian
          // _buildCompactBracketHeader(bracketData),
          // const SizedBox(height: 4), 
          
          // Maximized Tournament Bracket Tree (Fill toàn bộ không gian)
          Expanded(
            child: Container(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Container(
                  // Ensure minimum dimensions for proper bracket display
                  constraints: BoxConstraints(
                    minHeight: 300, // Minimum height for bracket visibility
                    minWidth: 320, // Minimum width for bracket display
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: _buildRoundsWithConnectors(rounds),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BRACKET HEADER ====================

  /// Compact header for maximum bracket space (1 line only)
  /*
  // TEMPORARILY COMMENTED OUT - Unused method
  Widget _buildCompactBracketHeader(Map<String, dynamic> bracketData) {
    // Safely parse participant count
    final participantCountData = bracketData['participantCount'];
    int participantCount = 0;
    
    if (participantCountData is int) {
      participantCount = participantCountData;
    } else if (participantCountData is String) {
      participantCount = int.tryParse(participantCountData) ?? 0;
    } else if (participantCountData != null) {
      participantCount = int.tryParse(participantCountData.toString()) ?? 0;
    }
    
    final format = bracketData['format'] ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Compact padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF1B5E7D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8), // Smaller radius
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree,
            color: Colors.white,
            size: 20, // Smaller icon
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_formatTournamentType(format)} • $participantCount players',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Smaller font
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  */

  Widget _buildBracketHeader(Map<String, dynamic> bracketData) {
    // Safely parse participant count (could be String or int from database)
    final participantCountData = bracketData['participantCount'];
    int participantCount = 0;
    
    if (participantCountData is int) {
      participantCount = participantCountData;
    } else if (participantCountData is String) {
      participantCount = int.tryParse(participantCountData) ?? 0;
    } else if (participantCountData != null) {
      participantCount = int.tryParse(participantCountData.toString()) ?? 0;
    }
    
    final format = bracketData['format'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF1B5E7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTournamentType(format),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$participantCount người tham gia',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DOUBLE ELIMINATION BRACKET ====================

  Future<Widget> _buildDoubleEliminationBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBracketHeader(bracketData),
          const SizedBox(height: 20),
          const Text(
            'Double Elimination Bracket - Coming Soon',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==================== SABO DE16 BRACKET ====================

  Future<Widget> _buildSaboDE16Bracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async {
    try {
      // Get actual matches from database
      final matches = await _getSaboDE16Matches(tournamentId);
      
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSaboDE16Header(bracketData, matches),
            const SizedBox(height: 20),
            Expanded(
              child: _buildSaboDE16BracketLayout(matches, onMatchTap),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building SABO DE16 bracket: $e');
      return _buildErrorWidget(e.toString());
    }
  }

  // ==================== ROUND ROBIN BRACKET ====================

  Future<Widget> _buildRoundRobinBracket(
    String tournamentId,
    Map<String, dynamic> bracketData,
    VoidCallback? onMatchTap,
    bool showLiveUpdates,
  ) async() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBracketHeader(bracketData),
          const SizedBox(height: 20),
          const Text(
            'Round Robin Bracket - Coming Soon',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  String _formatTournamentType(String format) {
    switch (format.toLowerCase()) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'sabo_de16':
        return 'SABO DE16';
      case 'sabo_de32':
        return 'SABO DE32';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss_system':
        return 'Swiss System';
      default:
        return format.toUpperCase();
    }
  }

  Widget _buildNoMatchesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports,
            color: Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có trận đấu nào',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedFormatWidget(String format) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Format "$format" chưa được hỗ trợ',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải bracket: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ==================== REAL-TIME UPDATES ====================

  /// Stream for real-time bracket updates
  Stream<Map<String, dynamic>> getBracketUpdateStream(String tournamentId) {
    return _supabase
        .from('tournaments')
        .stream(primaryKey: ['id'])
        .eq('id', tournamentId)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  /// Stream for real-time match updates
  Stream<List<Map<String, dynamic>>> getMatchUpdateStream(String tournamentId) {
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .order('round')
        .order('created_at');
  }

  // ==================== BRACKET TREE METHODS ====================

  /// Convert database matches to rounds format (like demo bracket)
  List<Map<String, dynamic>> _convertMatchesToRounds(List<dynamic> matches) {
    // Group matches by round
    Map<int, List<dynamic>> roundMatches = {};
    int maxRound = 0;
    
    for (final match in matches) {
      final roundData = match['round_number']; // Use round_number instead of round
      int round = 1;
      
      if (roundData is int) {
        round = roundData;
      } else if (roundData is String) {
        round = int.tryParse(roundData) ?? 1;
      } else if (roundData != null) {
        round = int.tryParse(roundData.toString()) ?? 1;
      }
      
      maxRound = math.max(maxRound, round);
      roundMatches[round] ??= [];
      roundMatches[round]!.add(match);
    }

      // Convert to rounds format with match cards
      final List<Map<String, dynamic>> rounds = [];
      final sortedRounds = roundMatches.keys.toList()..sort();
      
      // Calculate expected total rounds based on first round matches
      int totalExpectedRounds = 1;
      if (roundMatches.containsKey(1)) {
        final firstRoundMatches = roundMatches[1]!.length;
        totalExpectedRounds = _calculateTotalRounds(firstRoundMatches);
      }
      
      debugPrint('🔍 Bracket Analysis: ${matches.length} matches in ${sortedRounds.length} rounds, expected $totalExpectedRounds total rounds');
      
      for (int round in sortedRounds) {
        final roundData = roundMatches[round]!;
        
        // Create match cards for this round  
        final List<Map<String, String>> matchCards = [];
        for (final match in roundData) {
          final player1Data = match['player1'] as Map<String, dynamic>?;
          final player2Data = match['player2'] as Map<String, dynamic>?;
          
          // Handle progressive creation - show TBD for future matches
          String player1Name = 'TBD';
          String player2Name = 'TBD';
          
          if (player1Data != null) {
            player1Name = player1Data['full_name'] ?? player1Data['username'] ?? 'TBD';
          }
          if (player2Data != null) {
            player2Name = player2Data['full_name'] ?? player2Data['username'] ?? 'TBD';
          }
          
          // For Round 1 matches without players (shouldn't happen in new system)
          if (round == 1 && (player1Data == null || player2Data == null)) {
            debugPrint('⚠️ Warning: Round 1 match missing player data - this indicates bracket generation issue');
          }
          
          matchCards.add({
            'player1': player1Name,
            'player2': player2Name,
            'player1_avatar': player1Data?['avatar_url']?.toString() ?? '',
            'player2_avatar': player2Data?['avatar_url']?.toString() ?? '',
            'score': match['status'] == 'completed' ? 
                    '${match['player1_score'] ?? 0}-${match['player2_score"] ?? 0}" : 
                    '0-0',
            'status': match['status']?.toString() ?? 'scheduled',
            'winner_id': match['winner_id']?.toString() ?? '',
            'player1_id': match['player1_id']?.toString() ?? '',
            'player2_id': match['player2_id']?.toString() ?? '',
          });
        }      // Generate round title based on total expected rounds
      String title = _generateRoundTitle(round, totalExpectedRounds);
      
      rounds.add({
        'title': title,
        'matches': matchCards,
      });
    }
    
    return rounds;
  }

  /// Build rounds with connectors (like demo bracket)
  List<Widget> _buildRoundsWithConnectors(List<Map<String, dynamic>> rounds) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final isLastRound = i == rounds.length - 1;
      
      // Add round column
      widgets.add(
        RoundColumn(
          title: round['title'],
          matches: round['matches'].cast<Map<String, String>>(),
          roundIndex: i,
          totalRounds: rounds.length,
        ),
      );
      
      // Add connector if not the last round
      if (!isLastRound) {
        final nextRound = rounds[i + 1];
        widgets.add(
          BracketConnector(
            fromMatchCount: (round['matches'] as List).length,
            toMatchCount: (nextRound['matches'] as List).length,
            isLastRound: isLastRound,
          ),
        );
      }
    }
    
    return widgets;
  }

  // ==================== HELPER METHODS ====================

  /// Calculate total rounds needed based on first round match count
  int _calculateTotalRounds(int firstRoundMatches) {
    if (firstRoundMatches <= 0) return 1;
    
    // Each round reduces matches by half, so total rounds = log2(firstRoundMatches) + 1
    return (math.log(firstRoundMatches) / math.log(2)).round() + 1;
  }

  /// Generate round title based on round number and total expected rounds
  String _generateRoundTitle(int round, int totalRounds) {
    // Calculate matches in this round (working backwards from final)
    final matchesInRound = math.pow(2, totalRounds - round).toInt();
    
    if (matchesInRound == 1) {
      return 'Chung kết';
    } else if (matchesInRound == 2) {
      return 'Bán kết';
    } else if (matchesInRound == 4) {
      return 'Tứ kết';
    } else if (matchesInRound == 8) {
      return 'Vòng 1/8';
    } else if (matchesInRound == 16) {
      return 'Vòng 1/16';
    } else if (matchesInRound == 32) {
      return 'Vòng 1/32';
    } else() {
      return 'Vòng $round';
    }
  }

  // ==================== SABO DE16 HELPER METHODS ====================

  /// Get SABO DE16 matches from database
  Future<List<Map<String, dynamic>>> _getSaboDE16Matches(String tournamentId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('*, player1:player1_id(*), player2:player2_id(*), winner:winner_id(*)')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching SABO DE16 matches: $e');
      return [];
    }
  }

  /// Build SABO DE16 header with proper round counts
  Widget _buildSaboDE16Header(Map<String, dynamic> bracketData, List<Map<String, dynamic>> matches) {
    // Count matches by SABO DE16 structure
    final wbMatches = matches.where((m) => m['round_number'] <= 3).length;  // WR1,2,3
    final lbAMatches = matches.where((m) => m['round_number'] >= 101 && m['round_number'] <= 103).length; // LAR101,102,103
    final lbBMatches = matches.where((m) => m['round_number'] >= 201 && m['round_number'] <= 202).length; // LBR201,202
    final saboFinalsMatches = matches.where((m) => m['round_number'] >= 250 && m['round_number'] <= 300).length; // R250,251,300
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat('Tổng cộng', '${matches.length}', Colors.green),
          _buildHeaderStat('WB', '$wbMatches', Colors.blue),
          _buildHeaderStat('LB-A', '$lbAMatches', Colors.orange),
          _buildHeaderStat('LB-B', '$lbBMatches', Colors.purple),
          _buildHeaderStat('Finals', '$saboFinalsMatches', Colors.red),
        ],
      ),
    );
  }

  /// Build SABO DE16 bracket layout with proper structure
  Widget _buildSaboDE16BracketLayout(List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winners Bracket Section
          _buildSaboWinnerBracketSection(matches, onMatchTap),
          const SizedBox(height: 20),
          
          // Losers Bracket Section
          _buildSaboLoserBracketSection(matches, onMatchTap),
          const SizedBox(height: 20),
          
          // SABO Finals Section
          _buildSaboFinalsSection(matches, onMatchTap),
        ],
      ),
    );
  }

  /// Build SABO Winner Bracket section (R1→R2→R3) - Demo Style
  Widget _buildSaboWinnerBracketSection(List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    final r1Matches = matches.where((m) => m['round_number'] == 1).toList();
    final r2Matches = matches.where((m) => m['round_number'] == 2).toList();
    final r3Matches = matches.where((m) => m['round_number'] == 3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header like demo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏆 Winners Bracket',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Info box like demo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Winners Bracket Logic',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Single elimination format\n• Losers drop to Losers Bracket (second chance)\n• Winner advances to SABO Finals',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Bracket display
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoundColumn('WB R1\n(8 matches)', r1Matches, onMatchTap),
                const SizedBox(width: 16),
                _buildRoundColumn('WB R2\n(4 matches)', r2Matches, onMatchTap),
                const SizedBox(width: 16),
                _buildRoundColumn('WB R3\n(2 matches)', r3Matches, onMatchTap),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build SABO Losers Bracket section (Combined A + B) - Demo Style
  Widget _buildSaboLoserBracketSection(List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    final lbAMatches = matches.where((m) => m['round_number'] >= 101 && m['round_number'] <= 103).toList();
    final lbBMatches = matches.where((m) => m['round_number'] >= 201 && m['round_number'] <= 202).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header like demo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🔥 Losers Bracket',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Info box like demo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Losers Bracket Complex Logic',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Branch A: WB R1 losers compete (R101→R102→R103)\n• Branch B: WB R2 losers vs Branch A survivor (R201→R202)\n• Final survivor faces WB Champion in SABO Finals',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Combined bracket display
        SizedBox(
          height: 220,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Branch A
                _buildSaboLoserBranchA(lbAMatches, onMatchTap),
                const SizedBox(width: 20),
                // Branch B  
                _buildSaboLoserBranchB(lbBMatches, onMatchTap),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build SABO Loser Branch A section (R101→R102→R103) - Compact Style  
  Widget _buildSaboLoserBranchA(List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    final r101Matches = matches.where((m) => m['round_number'] == 101).toList();
    final r102Matches = matches.where((m) => m['round_number'] == 102).toList();
    final r103Matches = matches.where((m) => m['round_number'] == 103).toList();
    
    return Column(
      children: [
        // Branch A header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),  
          decoration: BoxDecoration(
            color: Colors.red.shade500,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Branch A (WB R1 Losers)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRoundColumn('LB-A R1', r101Matches, onMatchTap),
            const SizedBox(width: 10),
            _buildRoundColumn('LB-A R2', r102Matches, onMatchTap),
            const SizedBox(width: 10),
            _buildRoundColumn('LB-A R3', r103Matches, onMatchTap),
          ],
        ),
      ],
    );
  }

  /// Build SABO Loser Branch B section (R201→R202) - Compact Style
  Widget _buildSaboLoserBranchB(List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    final r201Matches = matches.where((m) => m['round_number'] == 201).toList();
    final r202Matches = matches.where((m) => m['round_number'] == 202).toList();
    
    return Column(
      children: [
        // Branch B header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade500,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Branch B (WB R2 Losers)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRoundColumn('LB-B R1', r201Matches, onMatchTap),
            const SizedBox(width: 10),
            _buildRoundColumn('LB-B R2', r202Matches, onMatchTap),
          ],
        ),
      ],
    );
  }

  /// Build SABO Finals section (R250, R251, R300) - Demo Style
  Widget _buildSaboFinalsSection(List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    final r250Matches = matches.where((m) => m['round_number'] == 250).toList();
    final r251Matches = matches.where((m) => m['round_number'] == 251).toList();
    final r300Matches = matches.where((m) => m['round_number'] == 300).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header like demo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏅 SABO Finals',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Info box like demo
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.purple.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'SABO Finals Rules',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Semi 1 (R250): WB Champion vs LB Branch B survivor\n• Semi 2 (R251): Loser match if Semi 1 loser survives\n• Final (R300): Ultimate championship match',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Finals display
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoundColumn('Semi 1\n(R250)', r250Matches, onMatchTap),
                const SizedBox(width: 16),
                _buildRoundColumn('Semi 2\n(R251)', r251Matches, onMatchTap),
                const SizedBox(width: 16),
                _buildRoundColumn('Final\n(R300)', r300Matches, onMatchTap),
              ],
            ),
          ),
        ),
      ],
    );
  }



  /// Build a round column with matches - Compact for SABO DE16
  Widget _buildRoundColumn(String title, List<Map<String, dynamic>> matches, VoidCallback? onMatchTap) {
    return Container(
      width: 100, // Fixed width to prevent overflow
      constraints: const BoxConstraints(maxHeight: 120), // Max height constraint
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          // Compact header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2E86AB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          
          // Match count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${matches.length} matches',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          
          // Match details (if any)
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                'Status: ${matches.first['status'] ?? 'pending'}',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build header stat widget
  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}