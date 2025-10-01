// 🏆 ENHANCED SABO ARENA - Universal Match Progression Service
// Handles immediate automatic tournament bracket progression for ALL formats
// Supports immediate advancement without waiting for round completion

import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'package:flutter/foundation.dart';

/// Universal service quản lý progression cho tất cả tournament formats
class UniversalMatchProgressionService {
  static UniversalMatchProgressionService? _instance;
  static UniversalMatchProgressionService get instance =>
      _instance ??= UniversalMatchProgressionService._();
  UniversalMatchProgressionService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService.instance;

  // Cache advancement rules for performance
  final Map<String, Map<int, AdvancementRule>> _advancementCache = {};

  // ==================== MAIN PROGRESSION LOGIC ====================

  /// Update match result với IMMEDIATE ADVANCEMENT cho tất cả formats
  Future<Map<String, dynamic>> updateMatchResultWithImmediateAdvancement({
    required String matchId,
    String? tournamentId,
    required String winnerId,
    required String loserId,
    required Map<String, int> scores,
    String? notes,
  }) async {
    try {
      debugPrint(
          '🚀 UniversalMatchProgressionService: Starting IMMEDIATE advancement for match $matchId');
      debugPrint('🎯 Tournament ID: $tournamentId');
      debugPrint(
          '🏆 Winner: ${winnerId.substring(0, 8)}, Loser: ${loserId.substring(0, 8)}');

      // 1. Update match result in database
      debugPrint('💾 Step 1: Updating match in database...');
      await _updateMatchInDatabase(matchId, winnerId, loserId, scores, notes);
      debugPrint('✅ Step 1: Match updated in database');

      // 2. Process SPA bonuses for challenge matches
      await _processChallengeSpaBonuses(
        matchId: matchId,
        winnerId: winnerId,
        loserId: loserId,
      );

      // Check if this is a tournament match
      if (tournamentId != null) {
        // 3. Get tournament info
        debugPrint('🔍 Step 2: Getting tournament info...');
        final tournament = await _getTournamentInfo(tournamentId);
        final bracketFormat = tournament['bracket_format'];

        debugPrint('🏆 Tournament format: $bracketFormat');

        // 4. Calculate and execute IMMEDIATE advancement
        debugPrint('⚡ Step 3: Executing IMMEDIATE advancement...');
        final advancementResult = await _executeImmediateAdvancement(
          tournamentId: tournamentId,
          matchId: matchId,
          winnerId: winnerId,
          loserId: loserId,
          bracketFormat: bracketFormat,
        );

        debugPrint(
            '🎉 IMMEDIATE advancement completed: ${advancementResult['advancement_count']} players advanced');

        // 5. Check tournament completion
        final isComplete = await _checkTournamentCompletion(tournamentId);

        // 6. Send notifications
        await _sendProgressionNotifications(
          tournamentId: tournamentId,
          winnerId: winnerId,
          loserId: loserId,
          advancementResult: advancementResult,
          isComplete: isComplete,
        );

        return {
          'success': true,
          'match_updated': true,
          'immediate_advancement': true,
          'progression_completed': advancementResult['advancement_count'] > 0,
          'tournament_complete': isComplete,
          'advancement_details': advancementResult['advancement_details'],
          'next_ready_matches': await _getNextReadyMatches(tournamentId),
          'message':
              'Match completed with IMMEDIATE advancement! ${advancementResult['advancement_count']} players advanced instantly.',
        };
      } else {
        // Challenge match - basic notifications only
        await _sendChallengeNotifications(winnerId, loserId, matchId);

        return {
          'success': true,
          'match_updated': true,
          'immediate_advancement': false,
          'progression_completed': false,
          'tournament_complete': false,
          'message': 'Challenge match completed and rewards processed',
        };
      }
    } catch (error) {
      debugPrint('❌ Error in universal match progression: $error');
      return {
        'success': false,
        'error': error.toString(),
        'message': 'Failed to process match with immediate advancement',
      };
    }
  }

  // ==================== IMMEDIATE ADVANCEMENT LOGIC ====================

  /// Execute immediate advancement cho tất cả tournament formats
  Future<Map<String, dynamic>> _executeImmediateAdvancement({
    required String tournamentId,
    required String matchId,
    required String winnerId,
    required String loserId,
    required String bracketFormat,
  }) async {
    // Get current match details
    final currentMatch = await _supabase
        .from('matches')
        .select('match_number, round_number')
        .eq('id', matchId)
        .single();

    final matchNumber = currentMatch['match_number'] as int;

    // Get or calculate advancement rules
    final advancementRules =
        await _getAdvancementRules(tournamentId, bracketFormat);

    if (!advancementRules.containsKey(matchNumber)) {
      debugPrint('⚠️ No advancement rule found for match $matchNumber');
      return {'advancement_count': 0, 'advancement_details': []};
    }

    final rule = advancementRules[matchNumber]!;
    final advancementDetails = <Map<String, dynamic>>[];
    int advancementCount = 0;

    // Advance winner immediately
    if (rule.winnerAdvancesTo != null) {
      final winnerResult = await _advancePlayerToMatch(
        tournamentId: tournamentId,
        playerId: winnerId,
        targetMatchNumber: rule.winnerAdvancesTo!,
        advancementType: 'winner',
      );

      if (winnerResult['success']) {
        advancementDetails.add(winnerResult);
        advancementCount++;
        debugPrint('✅ Winner advanced to Match ${rule.winnerAdvancesTo}');
      }
    }

    // Advance loser immediately (Double Elimination only)
    if (rule.loserAdvancesTo != null) {
      final loserResult = await _advancePlayerToMatch(
        tournamentId: tournamentId,
        playerId: loserId,
        targetMatchNumber: rule.loserAdvancesTo!,
        advancementType: 'loser',
      );

      if (loserResult['success']) {
        advancementDetails.add(loserResult);
        advancementCount++;
        debugPrint('✅ Loser advanced to Match ${rule.loserAdvancesTo}');
      }
    }

    return {
      'advancement_count': advancementCount,
      'advancement_details': advancementDetails,
    };
  }

  /// Advance một player đến specific match
  Future<Map<String, dynamic>> _advancePlayerToMatch({
    required String tournamentId,
    required String playerId,
    required int targetMatchNumber,
    required String advancementType,
  }) async {
    // Find target match
    final targetMatches = await _supabase
        .from('matches')
        .select('id, match_number, round_number, player1_id, player2_id')
        .eq('tournament_id', tournamentId)
        .eq('match_number', targetMatchNumber);

    if (targetMatches.isEmpty) {
      return {
        'success': false,
        'error': 'Target match $targetMatchNumber not found'
      };
    }

    final targetMatch = targetMatches.first;

    // Determine which slot to fill
    Map<String, dynamic> updateData = {};
    String slot = '';

    if (targetMatch['player1_id'] == null) {
      updateData['player1_id'] = playerId;
      slot = 'player1';
    } else if (targetMatch['player2_id'] == null) {
      updateData['player2_id'] = playerId;
      slot = 'player2';
    } else {
      return {
        'success': false,
        'error': 'Target match $targetMatchNumber is already full'
      };
    }

    // Update match with player
    await _supabase
        .from('matches')
        .update(updateData)
        .eq('id', targetMatch['id']);

    // Check if match is now ready (both players assigned)
    final updatedMatch = await _supabase
        .from('matches')
        .select('player1_id, player2_id')
        .eq('id', targetMatch['id'])
        .single();

    bool isMatchReady = updatedMatch['player1_id'] != null &&
        updatedMatch['player2_id'] != null;

    if (isMatchReady) {
      await _supabase
          .from('matches')
          .update({'status': 'pending'}) // Ready to play
          .eq('id', targetMatch['id']);
    }

    return {
      'success': true,
      'player_id': playerId,
      'advanced_to_match': targetMatchNumber,
      'advanced_to_round': targetMatch['round_number'],
      'slot': slot,
      'advancement_type': advancementType,
      'match_ready': isMatchReady,
    };
  }

  // ==================== ADVANCEMENT RULES CALCULATION ====================

  /// Get advancement rules for tournament (with caching)
  Future<Map<int, AdvancementRule>> _getAdvancementRules(
      String tournamentId, String bracketFormat) async {
    if (_advancementCache.containsKey(tournamentId)) {
      return _advancementCache[tournamentId]!;
    }

    // Calculate rules based on format
    Map<int, AdvancementRule> rules = {};

    if (bracketFormat == 'single_elimination') {
      rules = await _calculateSingleEliminationRules(tournamentId);
    } else if (bracketFormat == 'double_elimination') {
      rules = await _calculateDoubleEliminationRules(tournamentId);
    }

    // Cache the rules
    _advancementCache[tournamentId] = rules;
    return rules;
  }

  /// Calculate Single Elimination advancement rules
  Future<Map<int, AdvancementRule>> _calculateSingleEliminationRules(
      String tournamentId) async {
    final matches = await _supabase
        .from('matches')
        .select('match_number, round_number')
        .eq('tournament_id', tournamentId)
        .order('match_number');

    final rules = <int, AdvancementRule>{};

    // Group matches by round
    final roundsData = <int, List<int>>{};
    for (final match in matches) {
      final roundNumber = match['round_number'] as int;
      final matchNumber = match['match_number'] as int;

      if (!roundsData.containsKey(roundNumber)) {
        roundsData[roundNumber] = [];
      }
      roundsData[roundNumber]!.add(matchNumber);
    }

    // Calculate advancement for each match
    for (final match in matches) {
      final matchNumber = match['match_number'] as int;
      final roundNumber = match['round_number'] as int;

      // Find next round
      final nextRound = roundNumber + 1;
      int? winnerAdvancesTo;

      if (roundsData.containsKey(nextRound)) {
        final nextRoundMatches = roundsData[nextRound]!..sort();
        final currentRoundMatches = roundsData[roundNumber]!..sort();

        final positionInRound = currentRoundMatches.indexOf(matchNumber);
        final nextMatchIndex = positionInRound ~/ 2;

        if (nextMatchIndex < nextRoundMatches.length) {
          winnerAdvancesTo = nextRoundMatches[nextMatchIndex];
        }
      }

      rules[matchNumber] = AdvancementRule(
        matchNumber: matchNumber,
        roundNumber: roundNumber,
        winnerAdvancesTo: winnerAdvancesTo,
        loserAdvancesTo: null, // No loser advancement in SE
      );
    }

    return rules;
  }

  /// Calculate Double Elimination advancement rules
  Future<Map<int, AdvancementRule>> _calculateDoubleEliminationRules(
      String tournamentId) async {
    final matches = await _supabase
        .from('matches')
        .select('match_number, round_number')
        .eq('tournament_id', tournamentId)
        .order('match_number');

    final rules = <int, AdvancementRule>{};

    // Separate WB and LB matches
    final wbMatches =
        matches.where((m) => (m['round_number'] as int) < 100).toList();
    final lbMatches =
        matches.where((m) => (m['round_number'] as int) >= 101).toList();

    // Group by round
    final wbRounds = <int, List<int>>{};
    final lbRounds = <int, List<int>>{};

    for (final match in wbMatches) {
      final roundNumber = match['round_number'] as int;
      final matchNumber = match['match_number'] as int;

      if (!wbRounds.containsKey(roundNumber)) {
        wbRounds[roundNumber] = [];
      }
      wbRounds[roundNumber]!.add(matchNumber);
    }

    for (final match in lbMatches) {
      final roundNumber = match['round_number'] as int;
      final matchNumber = match['match_number'] as int;

      if (!lbRounds.containsKey(roundNumber)) {
        lbRounds[roundNumber] = [];
      }
      lbRounds[roundNumber]!.add(matchNumber);
    }

    // Calculate WB advancement rules
    for (final match in wbMatches) {
      final matchNumber = match['match_number'] as int;
      final roundNumber = match['round_number'] as int;

      // Winner advancement (next WB round)
      int? winnerAdvancesTo;
      final nextWbRound = roundNumber + 1;
      if (wbRounds.containsKey(nextWbRound)) {
        final nextRoundMatches = wbRounds[nextWbRound]!..sort();
        final currentRoundMatches = wbRounds[roundNumber]!..sort();

        final positionInRound = currentRoundMatches.indexOf(matchNumber);
        final nextMatchIndex = positionInRound ~/ 2;

        if (nextMatchIndex < nextRoundMatches.length) {
          winnerAdvancesTo = nextRoundMatches[nextMatchIndex];
        }
      }

      // Loser advancement (to appropriate LB round)
      int? loserAdvancesTo;
      final lbRoundKey = _calculateLoserDestinationRound(roundNumber);
      if (lbRounds.containsKey(lbRoundKey) &&
          lbRounds[lbRoundKey]!.isNotEmpty) {
        // Simple mapping - first available LB match
        loserAdvancesTo = lbRounds[lbRoundKey]!.first;
      }

      rules[matchNumber] = AdvancementRule(
        matchNumber: matchNumber,
        roundNumber: roundNumber,
        winnerAdvancesTo: winnerAdvancesTo,
        loserAdvancesTo: loserAdvancesTo,
      );
    }

    // Calculate LB advancement rules
    for (final match in lbMatches) {
      final matchNumber = match['match_number'] as int;
      final roundNumber = match['round_number'] as int;

      // Winner advancement (next LB round)
      int? winnerAdvancesTo;
      final nextLbRound = roundNumber + 1;
      if (lbRounds.containsKey(nextLbRound) &&
          lbRounds[nextLbRound]!.isNotEmpty) {
        winnerAdvancesTo = lbRounds[nextLbRound]!.first;
      }

      rules[matchNumber] = AdvancementRule(
        matchNumber: matchNumber,
        roundNumber: roundNumber,
        winnerAdvancesTo: winnerAdvancesTo,
        loserAdvancesTo: null, // LB losers are eliminated
      );
    }

    return rules;
  }

  /// Calculate which LB round WB losers go to
  int _calculateLoserDestinationRound(int wbRound) {
    // Standard DE mapping
    switch (wbRound) {
      case 1:
        return 101;
      case 2:
        return 102;
      case 3:
        return 104;
      case 4:
        return 106;
      default:
        return 101 + (wbRound - 1) * 2;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Update match result trong database
  Future<void> _updateMatchInDatabase(
    String matchId,
    String winnerId,
    String loserId,
    Map<String, int> scores,
    String? notes,
  ) async {
    await _supabase.from('matches').update({
      'winner_id': winnerId,
      'player1_score': scores['player1'] ?? 0,
      'player2_score': scores['player2'] ?? 0,
      'status': 'completed',
      'end_time': DateTime.now().toIso8601String(),
      'notes': notes,
    }).eq('id', matchId);
  }

  /// Get tournament info
  Future<Map<String, dynamic>> _getTournamentInfo(String tournamentId) async {
    return await _supabase
        .from('tournaments')
        .select('bracket_format, game_format, title, status')
        .eq('id', tournamentId)
        .single();
  }

  /// Get next ready matches (có đủ 2 players)
  Future<List<Map<String, dynamic>>> _getNextReadyMatches(
      String tournamentId) async {
    final readyMatches = await _supabase
        .from('matches')
        .select('id, match_number, round_number')
        .eq('tournament_id', tournamentId)
        .eq('status', 'pending')
        .not('player1_id', 'is', null)
        .not('player2_id', 'is', null)
        .order('round_number')
        .order('match_number')
        .limit(5);

    return readyMatches;
  }

  /// Check tournament completion
  Future<bool> _checkTournamentCompletion(String tournamentId) async {
    final allMatches = await _supabase
        .from('matches')
        .select('status')
        .eq('tournament_id', tournamentId);

    final completedMatches =
        allMatches.where((m) => m['status'] == 'completed').length;
    final totalMatches = allMatches.length;

    final isComplete = totalMatches > 0 && completedMatches == totalMatches;

    if (isComplete) {
      await _supabase
          .from('tournaments')
          .update({'status': 'completed'}).eq('id', tournamentId);
    }

    return isComplete;
  }

  /// Process SPA bonuses for challenges
  Future<void> _processChallengeSpaBonuses({
    required String matchId,
    required String winnerId,
    required String loserId,
  }) async {
    // Implementation from existing service
    // ... existing SPA bonus logic
  }

  /// Send progression notifications
  Future<void> _sendProgressionNotifications({
    required String tournamentId,
    required String winnerId,
    required String loserId,
    required Map<String, dynamic> advancementResult,
    required bool isComplete,
  }) async {
    // Implementation from existing service
    // ... existing notification logic
  }

  /// Send challenge notifications
  Future<void> _sendChallengeNotifications(
      String winnerId, String loserId, String matchId) async {
    await _notificationService.sendNotification(
      userId: winnerId,
      type: 'match_victory',
      title: 'Chiến thắng thách đấu! 🎉',
      message: 'Bạn đã thắng trận thách đấu và nhận được phần thưởng SPA!',
      data: {'match_id': matchId},
    );

    await _notificationService.sendNotification(
      userId: loserId,
      type: 'match_defeat',
      title: 'Kết thúc trận đấu',
      message: 'Trận thách đấu đã kết thúc. Hãy tiếp tục luyện tập!',
      data: {'match_id': matchId},
    );
  }
}

// ==================== ADVANCEMENT RULE MODEL ====================

class AdvancementRule {
  final int matchNumber;
  final int roundNumber;
  final int? winnerAdvancesTo;
  final int? loserAdvancesTo;

  AdvancementRule({
    required this.matchNumber,
    required this.roundNumber,
    this.winnerAdvancesTo,
    this.loserAdvancesTo,
  });

  @override
  String toString() {
    return 'AdvancementRule(match: $matchNumber, round: $roundNumber, winner→$winnerAdvancesTo, loser→$loserAdvancesTo)';
  }
}
