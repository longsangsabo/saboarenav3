// 🎯 SABO ARENA - Bracket Visualization Service  
// Renders real tournament brackets with live participant data and match results
// Converts bracket data into UI-ready components with real-time updates

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  // Ensure minimum height for proper bracket display
                  constraints: BoxConstraints(
                    minHeight: 300, // Minimum height for bracket visibility
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
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
}