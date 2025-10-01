import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// 🏆 COMPLETE DOUBLE ELIMINATION 16 SERVICE
/// Auto-generating bracket with precise logic and triggers
/// Author: SABO Arena v1.0
/// Date: October 1, 2025

class CompleteDoubleEliminationService {
  static const String _tag = 'CompleteDE16';
  final _supabase = Supabase.instance.client;

  static CompleteDoubleEliminationService? _instance;
  static CompleteDoubleEliminationService get instance =>
      _instance ??= CompleteDoubleEliminationService._();
  CompleteDoubleEliminationService._();

  // Global lock to prevent concurrent advancement processing
  static final Map<String, bool> _processingLocks = <String, bool>{};

  // =========================== BRACKET GENERATION ===========================

  /// Generate complete DE16 bracket with all 31 matches
  Future<Map<String, dynamic>> generateDE16Bracket({
    required String tournamentId,
    required List<Map<String, dynamic>> participants,
  }) async {
    try {
      debugPrint('$_tag: 🏆 Generating DE16 bracket for $tournamentId');
      debugPrint('$_tag: Participants: ${participants.length}');

      if (participants.length != 16) {
        throw Exception(
            'DE16 requires exactly 16 participants, got ${participants.length}');
      }

      // Clear existing matches
      await _clearExistingMatches(tournamentId);

      // Generate all 31 matches
      final allMatches =
          await _generateAll31Matches(tournamentId, participants);

      debugPrint(
          '$_tag: ✅ Generated ${allMatches.length} matches for DE16 bracket');

      return {
        'success': true,
        'matches_count': allMatches.length,
        'message': 'DE16 bracket generated successfully with all 31 matches',
        'matches': allMatches,
      };
    } catch (e) {
      debugPrint('$_tag: ❌ Error generating DE16 bracket: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to generate DE16 bracket',
      };
    }
  }

  /// Generate all 31 matches for complete DE16 structure
  Future<List<Map<String, dynamic>>> _generateAll31Matches(
    String tournamentId,
    List<Map<String, dynamic>> participants,
  ) async {
    final allMatches = <Map<String, dynamic>>[];

    // WB Rounds 1-4 (15 matches)
    allMatches.addAll(
        await _generateWBRound1WithParticipants(tournamentId, participants));
    allMatches.addAll(await _generateWBRound2(tournamentId));
    allMatches.addAll(await _generateWBRound3(tournamentId));
    allMatches.addAll(await _generateWBRound4(tournamentId));

    // LB Rounds 101-106 (14 matches)
    allMatches.addAll(await _generateLBRound101(tournamentId));
    allMatches.addAll(await _generateLBRound102(tournamentId));
    allMatches.addAll(await _generateLBRound103(tournamentId));
    allMatches.addAll(await _generateLBRound104(tournamentId));
    allMatches.addAll(await _generateLBRound105(tournamentId));
    allMatches.addAll(await _generateLBRound106(tournamentId));

    // Grand Finals (2 matches)
    allMatches.addAll(await _generateGrandFinal(tournamentId));
    allMatches.addAll(await _generateGrandFinalReset(tournamentId));

    // Batch insert all matches
    await _supabase.from('matches').insert(allMatches);

    return allMatches;
  }

  // =========================== WB ROUNDS ===========================

  Future<List<Map<String, dynamic>>> _generateWBRound1WithParticipants(
    String tournamentId,
    List<Map<String, dynamic>> participants,
  ) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 8; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 1,
        'match_number': i + 1,
        'bracket_position': i + 1,
        'player1_id': participants[i * 2]['user_id'],
        'player2_id': participants[i * 2 + 1]['user_id'],
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint(
        '$_tag: 🏆 WB Round 1: ${matches.length} matches with real participants');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateWBRound2(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 4; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 2,
        'match_number': i + 9,
        'bracket_position': i + 1,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint('$_tag: 🏆 WB Round 2: ${matches.length} matches');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateWBRound3(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 3,
        'match_number': i + 13,
        'bracket_position': i + 1,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint('$_tag: 🏆 WB Round 3: ${matches.length} matches');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateWBRound4(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': 4,
      'match_number': 15,
      'bracket_position': 1,
      'player1_id': null,
      'player2_id': null,
      'winner_id': null,
      'status': 'pending',
      'match_type': 'tournament',
      'bracket_format': 'double_elimination',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint('$_tag: 🏆 WB Round 4 (WB Final): ${matches.length} match');
    return matches;
  }

  // =========================== LB ROUNDS ===========================

  Future<List<Map<String, dynamic>>> _generateLBRound101(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 4; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 101,
        'match_number': i + 16,
        'bracket_position': i + 1,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint('$_tag: 💀 LB Round 101: ${matches.length} matches');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateLBRound102(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 4; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 102,
        'match_number': i + 20,
        'bracket_position': i + 1,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint('$_tag: 💀 LB Round 102: ${matches.length} matches');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateLBRound103(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 103,
        'match_number': i + 24,
        'bracket_position': i + 1,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint('$_tag: 💀 LB Round 103: ${matches.length} matches');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateLBRound104(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < 2; i++) {
      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 104,
        'match_number': i + 26,
        'bracket_position': i + 1,
        'player1_id': null,
        'player2_id': null,
        'winner_id': null,
        'status': 'pending',
        'match_type': 'tournament',
        'bracket_format': 'double_elimination',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    debugPrint('$_tag: 💀 LB Round 104: ${matches.length} matches');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateLBRound105(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': 105,
      'match_number': 28,
      'bracket_position': 1,
      'player1_id': null,
      'player2_id': null,
      'winner_id': null,
      'status': 'pending',
      'match_type': 'tournament',
      'bracket_format': 'double_elimination',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint('$_tag: 💀 LB Round 105: ${matches.length} match');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateLBRound106(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': 106,
      'match_number': 29,
      'bracket_position': 1,
      'player1_id': null,
      'player2_id': null,
      'winner_id': null,
      'status': 'pending',
      'match_type': 'tournament',
      'bracket_format': 'double_elimination',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint(
        '$_tag: 💀 LB Round 106 (LB CHUNG KẾT - LB FINAL): ${matches.length} match');
    return matches;
  }

  // =========================== GRAND FINAL ===========================

  Future<List<Map<String, dynamic>>> _generateGrandFinal(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': 200,
      'match_number': 30,
      'bracket_position': 1,
      'player1_id': null,
      'player2_id': null,
      'winner_id': null,
      'status': 'pending',
      'match_type': 'tournament',
      'bracket_format': 'double_elimination',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint('$_tag: 🏆 Grand Final: ${matches.length} match');
    return matches;
  }

  Future<List<Map<String, dynamic>>> _generateGrandFinalReset(
      String tournamentId) async {
    final matches = <Map<String, dynamic>>[];

    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': 201,
      'match_number': 31,
      'bracket_position': 1,
      'player1_id': null,
      'player2_id': null,
      'winner_id': null,
      'status': 'pending',
      'match_type': 'tournament',
      'bracket_format': 'double_elimination',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    debugPrint(
        '$_tag: 🔄 Grand Final Reset: ${matches.length} match (NULL PLAYERS = INACTIVE)');
    return matches;
  }

  // =========================== AUTO-ADVANCE TRIGGERS ===========================

  /// 🚀 Auto-advance trigger with HARD-CODED mapping
  Future<Map<String, dynamic>> onMatchComplete({
    required String matchId,
    required String winnerId,
    required String loserId,
  }) async {
    try {
      debugPrint('$_tag: 🎯 Auto-advance with hard-coded mapping');
      debugPrint('$_tag: Match completed: Winner $winnerId, Loser $loserId');

      final matchResponse = await _supabase
          .from('matches')
          .select('round_number, match_number, tournament_id')
          .eq('id', matchId)
          .single();

      final round = matchResponse['round_number'] as int;
      final matchNumber = matchResponse['match_number'] as int;
      final tournamentId = matchResponse['tournament_id'] as String;

      bool winnerAdvanced = false;
      bool loserAdvanced = false;

      if (round == 200) {
        // 🏆 GRAND FINAL (R200) - Special handling for bracket reset logic
        debugPrint(
            '$_tag: 🏆 Grand Final completed - checking for bracket reset');
        await _handleGrandFinalWinner(tournamentId, winnerId);
        winnerAdvanced = true;
      } else if (round < 100) {
        // Winners Bracket - advance winner
        final winnerTarget = _getWBWinnerAdvancement(round, matchNumber);
        final winnerSlot = _getWBPlayerSlot(round, matchNumber);

        if (winnerTarget != null) {
          await _placePlayerInMatch(
              tournamentId, winnerTarget, winnerId, winnerSlot);
          debugPrint('$_tag: ✅ Winner $winnerId advanced to $winnerTarget');
          winnerAdvanced = true;
        }

        // Winners Bracket - drop loser to LB
        final loserTarget = _getWBLoserDropTarget(round, matchNumber);
        final loserSlot = _getWBLoserPlayerSlot(round, matchNumber);

        if (loserTarget != null) {
          await _placePlayerInMatch(
              tournamentId, loserTarget, loserId, loserSlot);
          debugPrint('$_tag: ⬇️ Loser $loserId dropped to $loserTarget');
          loserAdvanced = true;
        }
      } else {
        // Losers Bracket - advance winner only
        final winnerTarget = _getLBWinnerAdvancement(round, matchNumber);
        final winnerSlot = _getLBPlayerSlot(round, matchNumber);

        if (winnerTarget != null) {
          await _placePlayerInMatch(
              tournamentId, winnerTarget, winnerId, winnerSlot);
          debugPrint('$_tag: ✅ LB Winner $winnerId advanced to $winnerTarget');
          winnerAdvanced = true;
        }

        debugPrint('$_tag: 💀 LB Loser $loserId eliminated');
      }

      return {
        'success': true,
        'message': 'Players advanced using hard-coded mapping',
        'winnerAdvanced': winnerAdvanced,
        'loserAdvanced': loserAdvanced,
      };
    } catch (e) {
      debugPrint('$_tag: ❌ Auto-advance failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'winnerAdvanced': false,
        'loserAdvanced': false,
      };
    }
  }

  // =========================== HARD-CODED MAPPING ===========================

  Map<String, Map<String, dynamic>> _getWBWinnerAdvancementMap() {
    return {
      'M1': {
        'target': 'round_number = 2 AND match_number = 9',
        'slot': 'player1_id'
      },
      'M2': {
        'target': 'round_number = 2 AND match_number = 9',
        'slot': 'player2_id'
      },
      'M3': {
        'target': 'round_number = 2 AND match_number = 10',
        'slot': 'player1_id'
      },
      'M4': {
        'target': 'round_number = 2 AND match_number = 10',
        'slot': 'player2_id'
      },
      'M5': {
        'target': 'round_number = 2 AND match_number = 11',
        'slot': 'player1_id'
      },
      'M6': {
        'target': 'round_number = 2 AND match_number = 11',
        'slot': 'player2_id'
      },
      'M7': {
        'target': 'round_number = 2 AND match_number = 12',
        'slot': 'player1_id'
      },
      'M8': {
        'target': 'round_number = 2 AND match_number = 12',
        'slot': 'player2_id'
      },
      'M9': {
        'target': 'round_number = 3 AND match_number = 13',
        'slot': 'player1_id'
      },
      'M10': {
        'target': 'round_number = 3 AND match_number = 13',
        'slot': 'player2_id'
      },
      'M11': {
        'target': 'round_number = 3 AND match_number = 14',
        'slot': 'player1_id'
      },
      'M12': {
        'target': 'round_number = 3 AND match_number = 14',
        'slot': 'player2_id'
      },
      'M13': {
        'target': 'round_number = 4 AND match_number = 15',
        'slot': 'player1_id'
      },
      'M14': {
        'target': 'round_number = 4 AND match_number = 15',
        'slot': 'player2_id'
      },
      'M15': {
        'target': 'round_number = 200 AND match_number = 30',
        'slot': 'player1_id'
      },
    };
  }

  Map<String, Map<String, dynamic>> _getWBLoserDropMap() {
    return {
      'M1': {
        'target': 'round_number = 101 AND match_number = 16',
        'slot': 'player2_id'
      },
      'M2': {
        'target': 'round_number = 101 AND match_number = 17',
        'slot': 'player2_id'
      },
      'M3': {
        'target': 'round_number = 101 AND match_number = 18',
        'slot': 'player2_id'
      },
      'M4': {
        'target': 'round_number = 101 AND match_number = 19',
        'slot': 'player2_id'
      },
      'M5': {
        'target': 'round_number = 101 AND match_number = 19',
        'slot': 'player1_id'
      },
      'M6': {
        'target': 'round_number = 101 AND match_number = 18',
        'slot': 'player1_id'
      },
      'M7': {
        'target': 'round_number = 101 AND match_number = 17',
        'slot': 'player1_id'
      },
      'M8': {
        'target': 'round_number = 101 AND match_number = 16',
        'slot': 'player1_id'
      },
      'M9': {
        'target': 'round_number = 102 AND match_number = 20',
        'slot': 'player2_id'
      },
      'M10': {
        'target': 'round_number = 102 AND match_number = 21',
        'slot': 'player2_id'
      },
      'M11': {
        'target': 'round_number = 102 AND match_number = 22',
        'slot': 'player2_id'
      },
      'M12': {
        'target': 'round_number = 102 AND match_number = 23',
        'slot': 'player2_id'
      },
      'M13': {
        'target': 'round_number = 104 AND match_number = 26',
        'slot': 'player2_id'
      },
      'M14': {
        'target': 'round_number = 104 AND match_number = 27',
        'slot': 'player2_id'
      },
      'M15': {
        'target': 'round_number = 106 AND match_number = 29',
        'slot': 'player2_id'
      },
    };
  }

  Map<String, Map<String, dynamic>> _getLBWinnerAdvancementMap() {
    return {
      'M16': {
        'target': 'round_number = 102 AND match_number = 20',
        'slot': 'player1_id'
      },
      'M17': {
        'target': 'round_number = 102 AND match_number = 21',
        'slot': 'player1_id'
      },
      'M18': {
        'target': 'round_number = 102 AND match_number = 22',
        'slot': 'player1_id'
      },
      'M19': {
        'target': 'round_number = 102 AND match_number = 23',
        'slot': 'player1_id'
      },
      'M20': {
        'target': 'round_number = 103 AND match_number = 24',
        'slot': 'player1_id'
      },
      'M21': {
        'target': 'round_number = 103 AND match_number = 24',
        'slot': 'player2_id'
      },
      'M22': {
        'target': 'round_number = 103 AND match_number = 25',
        'slot': 'player1_id'
      },
      'M23': {
        'target': 'round_number = 103 AND match_number = 25',
        'slot': 'player2_id'
      },
      'M24': {
        'target': 'round_number = 104 AND match_number = 26',
        'slot': 'player1_id'
      },
      'M25': {
        'target': 'round_number = 104 AND match_number = 27',
        'slot': 'player1_id'
      },
      'M26': {
        'target': 'round_number = 105 AND match_number = 28',
        'slot': 'player1_id'
      },
      'M27': {
        'target': 'round_number = 105 AND match_number = 28',
        'slot': 'player2_id'
      },
      'M28': {
        'target': 'round_number = 106 AND match_number = 29',
        'slot': 'player1_id'
      },
      'M29': {
        'target': 'round_number = 200 AND match_number = 30',
        'slot': 'player2_id'
      },
    };
  }

  String? _getWBWinnerAdvancement(int round, int matchNumber) {
    final mapping = _getWBWinnerAdvancementMap();
    final matchKey = 'M$matchNumber';
    return mapping[matchKey]?['target'];
  }

  String? _getWBLoserDropTarget(int round, int matchNumber) {
    final mapping = _getWBLoserDropMap();
    final matchKey = 'M$matchNumber';
    return mapping[matchKey]?['target'];
  }

  String? _getLBWinnerAdvancement(int round, int matchNumber) {
    final mapping = _getLBWinnerAdvancementMap();
    final matchKey = 'M$matchNumber';
    return mapping[matchKey]?['target'];
  }

  String _getWBPlayerSlot(int round, int matchNumber) {
    final mapping = _getWBWinnerAdvancementMap();
    final matchKey = 'M$matchNumber';
    return mapping[matchKey]?['slot'] ?? 'player1_id';
  }

  String _getLBPlayerSlot(int round, int matchNumber) {
    final mapping = _getLBWinnerAdvancementMap();
    final matchKey = 'M$matchNumber';
    return mapping[matchKey]?['slot'] ?? 'player1_id';
  }

  String _getWBLoserPlayerSlot(int round, int matchNumber) {
    final mapping = _getWBLoserDropMap();
    final matchKey = 'M$matchNumber';
    return mapping[matchKey]?['slot'] ?? 'player2_id';
  }

  // =========================== UTILITY FUNCTIONS ===========================

  Future<void> _placePlayerInMatch(
    String tournamentId,
    String matchQuery,
    String playerId,
    String playerSlot,
  ) async {
    final parts = matchQuery.split(' AND ');
    final roundPart = parts[0].trim();
    final matchPart = parts[1].trim();

    final roundNumber = int.parse(roundPart.split(' = ')[1]);
    final matchNumber = int.parse(matchPart.split(' = ')[1]);

    final currentMatch = await _supabase
        .from('matches')
        .select('player1_id, player2_id')
        .eq('tournament_id', tournamentId)
        .eq('round_number', roundNumber)
        .eq('match_number', matchNumber)
        .single();

    String targetSlot = playerSlot;

    if (targetSlot == 'player1_id' && currentMatch['player1_id'] != null) {
      debugPrint('$_tag: ❌ REJECTED: player1_id slot already occupied');
      return;
    }

    if (targetSlot == 'player2_id' && currentMatch['player2_id'] != null) {
      debugPrint('$_tag: ❌ REJECTED: player2_id slot already occupied');
      return;
    }

    await _supabase
        .from('matches')
        .update({targetSlot: playerId})
        .eq('tournament_id', tournamentId)
        .eq('round_number', roundNumber)
        .eq('match_number', matchNumber);

    debugPrint(
        '$_tag: 📍 Placed player $playerId in round $roundNumber match $matchNumber slot $targetSlot');
  }

  Future<void> _handleGrandFinalWinner(
      String tournamentId, String winnerId) async {
    final wbChampion = await _getWBChampion(tournamentId);

    if (winnerId == wbChampion) {
      await _completeTournament(tournamentId, winnerId);
    } else {
      await _unlockBracketReset(tournamentId, winnerId, wbChampion!);
    }
  }

  Future<String?> _getWBChampion(String tournamentId) async {
    final wbFinal = await _supabase
        .from('matches')
        .select('winner_id')
        .eq('tournament_id', tournamentId)
        .eq('round_number', 4)
        .eq('match_number', 15)
        .single();

    return wbFinal['winner_id'];
  }

  Future<void> _completeTournament(String tournamentId, String winnerId) async {
    await _supabase.from('tournaments').update({
      'status': 'completed',
      'winner_id': winnerId,
      'end_date': DateTime.now().toIso8601String(),
    }).eq('id', tournamentId);

    debugPrint('$_tag: 🏆 Tournament completed! Winner: $winnerId');
  }

  Future<void> _unlockBracketReset(
    String tournamentId,
    String lbChampion,
    String wbChampion,
  ) async {
    try {
      debugPrint('$_tag: 🔓 UNLOCKING BRACKET RESET...');
      debugPrint('$_tag: Tournament: $tournamentId');
      debugPrint('$_tag: WB Champion: $wbChampion');
      debugPrint('$_tag: LB Champion: $lbChampion');

      final resetMatch = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .eq('round_number', 201)
          .eq('match_number', 31)
          .single();

      debugPrint('$_tag: ✅ Found R201 match: ${resetMatch['id']}');

      final updateResult = await _supabase.from('matches').update({
        'player1_id': wbChampion,
        'player2_id': lbChampion,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', resetMatch['id']);

      debugPrint(
          '$_tag: 🔥 BRACKET RESET UNLOCKED - WB vs LB Champion rematch!');
    } catch (e) {
      debugPrint('$_tag: ❌ FAILED to unlock bracket reset: $e');
      rethrow;
    }
  }

  Future<void> _clearExistingMatches(String tournamentId) async {
    await _supabase.from('matches').delete().eq('tournament_id', tournamentId);

    debugPrint('$_tag: 🗑️ Cleared existing matches');
  }

  String _generateMatchId() {
    const uuid = Uuid();
    return uuid.v4();
  }
}
