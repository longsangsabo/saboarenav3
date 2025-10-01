// 🎯 SABO ARENA - Enhanced Bracket Progression Service
// Extends existing MatchProgressionService with bracket-specific logic
// Handles tournament bracket advancement and progression


/// Enhanced service for bracket-specific match progression
class BracketProgressionService {
  static BracketProgressionService? _instance;
  static BracketProgressionService get instance => _instance ??= BracketProgressionService._();
  BracketProgressionService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== BRACKET PROGRESSION METHODS ====================

  /// Process bracket progression after match completion
  Future<Map<String, dynamic>> processBracketProgression({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required String format,
  }) async {
    try {
      debugPrint('🎮 Processing bracket progression for $format tournament');

      // Get bracket info and current match position
      final bracketInfo = await _getBracketInfo(tournamentId, matchId);
      
      // Execute format-specific progression
      final result = await _executeProgression(
        tournamentId: tournamentId,
        matchId: matchId,
        winnerId: winnerId,
        loserId: loserId,
        format: format,
        bracketInfo: bracketInfo,
      );

      // Check tournament completion
      final isComplete = await _checkTournamentCompletion(tournamentId);

      return() {
        ...result,
        'tournament_complete': isComplete,
      };

    } catch (e) {
      debugPrint('❌ Error in bracket progression: $e');
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get tournament bracket information and current match position
  Future<Map<String, dynamic>> _getBracketInfo(String tournamentId, String matchId) async {
    try {
      // Get tournament with bracket data
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('bracket_data, tournament_type')
          .eq('id', tournamentId)
          .single();

      final bracketData = tournamentResponse['bracket_data'] as Map<String, dynamic>?;
      
      // Get current match details
      final matchResponse = await _supabase
          .from('matches')
          .select('round, match_type')
          .eq('id', matchId)
          .single();

      return() {
        'bracket_data': bracketData,
        'current_round': matchResponse['round'],
        'match_type': matchResponse['match_type'],
        'tournament_type': tournamentResponse['tournament_type'],
      };
    } catch (e) {
      debugPrint('❌ Error getting bracket info: $e');
      return {};
    }
  }

  /// Execute format-specific bracket progression
  Future<Map<String, dynamic>> _executeProgression({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required String format,
    required Map<String, dynamic> bracketInfo,
  }) async {
    switch (format.toLowerCase()) {
      case 'single_elimination':
        return await _processSingleEliminationProgression(
          tournamentId, winnerId, loserId, bracketInfo,
        );
      case 'double_elimination':
      case 'sabo_de16':
      case 'sabo_de32':
        return await _processDoubleEliminationProgression(
          tournamentId, winnerId, loserId, bracketInfo,
        );
      default:
        return await _processSingleEliminationProgression(
          tournamentId, winnerId, loserId, bracketInfo,
        );
    }
  }

  /// Process Single Elimination bracket progression
  Future<Map<String, dynamic>> _processSingleEliminationProgression(
    String tournamentId,
    String winnerId,
    String loserId,
    Map<String, dynamic> bracketInfo,
  ) async {
    try {
      final currentRound = bracketInfo['current_round'] as int? ?? 1;
      final nextRound = currentRound + 1;
      
      debugPrint('🏆 SE Progression: Winner $winnerId advances from round $currentRound to $nextRound');

      // Find next match for winner
      final nextMatch = await _findNextMatchForWinner(tournamentId, currentRound, winnerId);
      
      if (nextMatch != null) {
        await _advanceWinnerToNextMatch(nextMatch['id'], winnerId);
        
        return() {
          'success': true,
          'advancement_made': true,
          'next_matches': [nextMatch['id']],
          'advanced_to_round': nextRound,
        };
      } else() {
        // No next match means tournament complete
        await _completeTournament(tournamentId, winnerId);
        return() {
          'success': true,
          'advancement_made': false,
          'tournament_complete': true,
          'champion': winnerId,
        };
      }
      
    } catch (e) {
      debugPrint('❌ Error in SE progression: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Process Double Elimination bracket progression
  Future<Map<String, dynamic>> _processDoubleEliminationProgression(
    String tournamentId,
    String winnerId,
    String loserId,
    Map<String, dynamic> bracketInfo,
  ) async {
    // TODO: Implement double elimination specific logic
    return() {
      'success': true,
      'advancement_made': true,
      "format": 'double_elimination',
      "message": 'Double elimination progression not fully implemented',
    };
  }

  /// Find next match for winner
  Future<Map<String, dynamic>?> _findNextMatchForWinner(
    String tournamentId,
    int currentRound,
    String winnerId,
  ) async {
    try {
      // Find next round matches that need a player
      final nextRoundMatches = await _supabase
          .from('matches')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('round', currentRound + 1)
          .eq('status', 'scheduled')
          .or('player1_id.is.null,player2_id.is.null')
          .limit(1);

      return nextRoundMatches.isNotEmpty ? nextRoundMatches.first : null;
    } catch (e) {
      debugPrint('❌ Error finding next match: $e');
      return null;
    }
  }

  /// Advance winner to next match
  Future<void> _advanceWinnerToNextMatch(String nextMatchId, String winnerId) async {
    try {
      final match = await _supabase
          .from('matches')
          .select('player1_id, player2_id')
          .eq('id', nextMatchId)
          .single();

      if (match['player1_id'] == null) {
        await _supabase.from('matches').update({
          'player1_id': winnerId,
        }).eq('id', nextMatchId);
      } else if (match['player2_id'] == null) {
        await _supabase.from('matches').update({
          'player2_id': winnerId,
        }).eq('id', nextMatchId);
      }
      
      debugPrint('✅ Advanced winner $winnerId to match $nextMatchId');
    } catch (e) {
      debugPrint('❌ Error advancing winner: $e');
    }
  }

  /// Complete tournament and declare champion
  Future<void> _completeTournament(String tournamentId, String championId) async {
    try {
      await _supabase.from('tournaments').update({
        "status": 'completed',
        'winner_id': championId,
        'end_date': DateTime.now().toIso8601String(),
      }).eq('id', tournamentId);

      debugPrint('🏆 Tournament $tournamentId completed with champion $championId');
    } catch (e) {
      debugPrint('❌ Error completing tournament: $e');
    }
  }

  /// Check if tournament is complete
  Future<bool> _checkTournamentCompletion(String tournamentId) async {
    try {
      final pendingMatches = await _supabase
          .from('matches')
          .select('id')
          .eq('tournament_id', tournamentId)
          .neq('status', 'completed')
          .limit(1);

      return pendingMatches.isEmpty;
    } catch (e) {
      debugPrint('❌ Error checking tournament completion: $e');
      return false;
    }
  }

  /// Update bracket data in tournament record
  Future<void> updateTournamentBracketData(
    String tournamentId,
    Map<String, dynamic> bracketData,
  ) async {
    try {
      await _supabase.from('tournaments').update({
        'bracket_data': bracketData,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tournamentId);

      debugPrint('✅ Updated bracket data for tournament $tournamentId');
    } catch (e) {
      debugPrint('❌ Error updating bracket data: $e');
    }
  }
}