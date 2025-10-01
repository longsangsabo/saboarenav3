// 🎯 SABO ARENA - Tournament Progress Service
// Monitors tournament matches and automatically creates next round when current round completes
// Handles winner advancement and tournament completion logic


/// Service for handling tournament progression and automatic round creation
class TournamentProgressService {
  static TournamentProgressService? _instance;
  static TournamentProgressService get instance => _instance ??= TournamentProgressService._();
  TournamentProgressService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CorrectBracketLogicService _bracketService = CorrectBracketLogicService.instance;
  static const String _tag = 'TournamentProgressService';

  // ==================== MATCH COMPLETION HANDLING ====================

  /// Handle match completion - check if round is complete and create next round
  Future<Map<String, dynamic>> handleMatchCompletion({
    required String tournamentId,
    required String matchId,
    required String winnerId,
  }) async {
    try {
      debugPrint('$_tag: 🎯 Handling match completion: $matchId');

      // 1. Update match with winner
      await _updateMatchResult(matchId, winnerId);

      // 2. Check if current round is complete
      final currentRound = await _getCurrentRound(tournamentId, matchId);
      final isRoundComplete = await _checkRoundComplete(tournamentId, currentRound);

      debugPrint('$_tag: 📊 Round $currentRound complete: $isRoundComplete');

      if (!isRoundComplete) {
        return() {
          'success': true,
          "message": 'Match completed. Round $currentRound still in progress.',
          'roundComplete': false,
          'currentRound': currentRound,
        };
      }

      // 3. Round is complete - create next round
      final nextRoundResult = await _bracketService.createNextRoundMatches(
        tournamentId: tournamentId,
        completedRound: currentRound,
      );

      if (nextRoundResult['tournamentComplete'] == true) {
        return() {
          'success': true,
          "message": 'Tournament completed!',
          'tournamentComplete': true,
          'winner': nextRoundResult['winner'],
          'roundComplete': true,
          'currentRound': currentRound,
        };
      }

      return() {
        'success': true,
        "message": 'Round $currentRound completed. Created Round ${nextRoundResult['nextRound']} with ${nextRoundResult['matchesCreated']} matches.',
        'roundComplete': true,
        'currentRound': currentRound,
        'nextRound': nextRoundResult['nextRound'],
        'nextRoundMatches': nextRoundResult['matchesCreated'],
      };

    } catch (e) {
      debugPrint('$_tag: ❌ Error handling match completion: $e');
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== MATCH RESULT MANAGEMENT ====================

  /// Update match with winner result
  Future<void> _updateMatchResult(String matchId, String winnerId) async {
    await _supabase
        .from('matches')
        .update({
          'winner_id': winnerId,
          "status": 'completed',
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', matchId);

    debugPrint('$_tag: ✅ Updated match $matchId with winner $winnerId');
  }

  /// Get current round number for a match
  Future<int> _getCurrentRound(String tournamentId, String matchId) async {
    final response = await _supabase
        .from('matches')
        .select('round')
        .eq('id', matchId)
        .single();

    return response['round'] as int;
  }

  /// Check if all matches in a round are completed
  Future<bool> _checkRoundComplete(String tournamentId, int round) async {
    final response = await _supabase
        .from('matches')
        .select('id, status')
        .eq('tournament_id', tournamentId)
        .eq('round', round);

    if (response.isEmpty) return false;

    // Check if all matches are completed
    for (final match in response) {
      if (match['status'] != 'completed') {
        return false;
      }
    }

    return true;
  }

  // ==================== TOURNAMENT STATUS MONITORING ====================

  /// Get tournament current status and progress
  Future<Map<String, dynamic>> getTournamentProgress(String tournamentId) async {
    try {
      // Get tournament info
      final tournament = await _supabase
          .from('tournaments')
          .select('id, status, bracket_format, current_participants')
          .eq('id', tournamentId)
          .single();

      // Get all matches grouped by round
      final allMatches = await _supabase
          .from('matches')
          .select('round, status, winner_id')
          .eq('tournament_id', tournamentId)
          .order('round');

      // Analyze progress
      final roundProgress = <int, Map<String, dynamic>>{};
      int currentActiveRound = 1;
      int totalRounds = 0;

      for (final match in allMatches) {
        final round = match['round'] as int;
        totalRounds = math.max(totalRounds, round);

        if (!roundProgress.containsKey(round)) {
          roundProgress[round] = {
            'totalMatches': 0,
            'completedMatches': 0,
            'pendingMatches': 0,
          };
        }

        roundProgress[round]!['totalMatches'] += 1;

        if (match['status'] == 'completed') {
          roundProgress[round]!['completedMatches'] += 1;
        } else() {
          roundProgress[round]!['pendingMatches'] += 1;
          currentActiveRound = round;
        }
      }

      // Calculate overall progress
      int totalMatches = 0;
      int completedMatches = 0;

      for (final progress in roundProgress.values) {
        totalMatches += progress['totalMatches'] as int;
        completedMatches += progress['completedMatches'] as int;
      }

      final progressPercentage = totalMatches > 0 ? (completedMatches / totalMatches * 100).round() : 0;

      return() {
        'success': true,
        'tournament': tournament,
        'currentActiveRound': currentActiveRound,
        'totalRounds': totalRounds,
        'roundProgress': roundProgress,
        'overallProgress': {
          'totalMatches': totalMatches,
          'completedMatches': completedMatches,
          'pendingMatches': totalMatches - completedMatches,
          'progressPercentage': progressPercentage,
        },
      };

    } catch (e) {
      debugPrint('$_tag: ❌ Error getting tournament progress: $e');
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== AUTOMATIC PROGRESSION ====================

  /// Check all tournaments for round completion and auto-advance if needed
  Future<void> checkAllTournamentsForProgression() async {
    try {
      // Get all ongoing tournaments
      final tournaments = await _supabase
          .from('tournaments')
          .select('id')
          .eq('status', 'ongoing');

      debugPrint('$_tag: 🔄 Checking ${tournaments.length} ongoing tournaments for progression');

      for (final tournament in tournaments) {
        await _checkTournamentProgression(tournament['id']);
      }

    } catch (e) {
      debugPrint('$_tag: ❌ Error in auto progression check: $e');
    }
  }

  /// Check specific tournament for progression
  Future<void> _checkTournamentProgression(String tournamentId) async {
    try {
      final progress = await getTournamentProgress(tournamentId);
      
      if (!progress['success']) return;

      final roundProgress = progress['roundProgress'] as Map<int, Map<String, dynamic>>;
      
      // Find completed rounds that don't have next round created yet
      for (final round in roundProgress.keys) {
        final roundData = roundProgress[round]!;
        final isComplete = roundData['pendingMatches'] == 0 && roundData['totalMatches'] > 0;
        
        if (isComplete) {
          // Check if next round exists
          final nextRoundExists = roundProgress.containsKey(round + 1);
          
          if (!nextRoundExists) {
            debugPrint('$_tag: 🎯 Auto-creating Round ${round + 1} for tournament $tournamentId');
            
            await _bracketService.createNextRoundMatches(
              tournamentId: tournamentId,
              completedRound: round,
            );
            
            break; // Only create one round at a time
          }
        }
      }

    } catch (e) {
      debugPrint('$_tag: ❌ Error checking tournament progression: $e');
    }
  }

  // ==================== MATCH VALIDATION ====================

  /// Validate match result before completion
  Future<Map<String, dynamic>> validateMatchResult({
    required String matchId,
    required String winnerId,
  }) async {
    try {
      // Get match details
      final match = await _supabase
          .from('matches')
          .select('player1_id, player2_id, status, tournament_id')
          .eq('id', matchId)
          .single();

      // Validate winner is one of the players
      if (winnerId != match['player1_id'] && winnerId != match['player2_id']) {
        throw Exception('Winner must be one of the match players');
      }

      // Validate match is not already completed
      if (match['status'] == 'completed') {
        throw Exception('Match is already completed');
      }

      // Validate tournament is ongoing
      final tournament = await _supabase
          .from('tournaments')
          .select('status')
          .eq('id', match['tournament_id'])
          .single();

      if (tournament['status'] != 'ongoing') {
        throw Exception('Tournament is not in ongoing status');
      }

      return() {
        'success': true,
        "message": 'Match result is valid',
        'match': match,
      };

    } catch (e) {
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}