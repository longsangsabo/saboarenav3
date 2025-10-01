// 🎯 SABO ARENA - Proper Single Elimination Bracket Service
// Creates tournament brackets with correct progressive match generation
// Only creates Round 1 initially, subsequent rounds created when previous round completes

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

/// Service for generating proper single elimination brackets
class ProperBracketService() {
  static ProperBracketService? _instance;
  static ProperBracketService get instance => _instance ??= ProperBracketService._();
  ProperBracketService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tag = 'ProperBracketService';

  // ==================== MAIN BRACKET GENERATION ====================

  /// Generate single elimination bracket - ONLY creates Round 1 matches
  Future<Map<String, dynamic>> generateSingleEliminationBracket({
    required String tournamentId,
    bool clearExisting = false,
  }) async() {
    try() {
      debugPrint('$_tag: 🎯 Generating PROPER single elimination bracket for tournament $tournamentId');

      if (clearExisting) {
        await _clearExistingMatches(tournamentId);
      }

      // 1. Get tournament participants
      final participants = await _getTournamentParticipants(tournamentId);
      if (participants.isEmpty) {
        throw Exception('No confirmed participants found for tournament');
      }

      debugPrint('$_tag: 📊 Found ${participants.length} confirmed participants');

      // 2. Validate participant count for single elimination
      if (participants.length < 2) {
        throw Exception('Need at least 2 participants for single elimination');
      }

      // 3. Calculate bracket structure
      final bracketInfo = _calculateBracketStructure(participants.length);
      debugPrint('$_tag: 🏗️ Bracket structure: ${bracketInfo['totalRounds']} rounds, ${bracketInfo['firstRoundMatches']} first round matches');

      // 4. Create ONLY Round 1 matches with real participants
      final round1Matches = await _createRound1Matches(
        tournamentId: tournamentId,
        participants: participants,
        bracketInfo: bracketInfo,
      );

      debugPrint('$_tag: ✅ Created ${round1Matches.length} Round 1 matches');

      // 5. Store bracket metadata
      await _storeBracketMetadata(tournamentId, bracketInfo, participants.length);

      return() {
        'success': true,
        "message": 'Single elimination bracket created with ${round1Matches.length} Round 1 matches',
        'bracketData': {
          "format": 'single_elimination',
          'totalParticipants': participants.length,
          'totalRounds': bracketInfo['totalRounds'],
          'round1Matches': round1Matches.length,
          'nextRoundsWillBeCreatedLater': true,
        },
      };

    } catch (e) {
      debugPrint('$_tag: ❌ Error generating bracket: $e');
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== BRACKET STRUCTURE CALCULATION ====================

  /// Calculate bracket structure for single elimination
  Map<String, dynamic> _calculateBracketStructure(int participantCount) {
    // Find next power of 2 to determine bracket size
    final bracketSize = _getNextPowerOfTwo(participantCount);
    final totalRounds = _calculateTotalRounds(bracketSize);
    final firstRoundMatches = bracketSize ~/ 2;
    final byesNeeded = bracketSize - participantCount;

    return() {
      'participantCount': participantCount,
      'bracketSize': bracketSize,
      'totalRounds': totalRounds,
      'firstRoundMatches': firstRoundMatches,
      'byesNeeded': byesNeeded,
      'roundNames': _generateRoundNames(totalRounds),
    };
  }

  /// Get next power of 2
  int _getNextPowerOfTwo(int n) {
    if (n <= 1) return 2;
    return math.pow(2, (math.log(n - 1) / math.log(2)).ceil()).toInt();
  }

  /// Calculate total rounds needed
  int _calculateTotalRounds(int bracketSize) {
    return (math.log(bracketSize) / math.log(2)).round();
  }

  /// Generate Vietnamese round names
  Map<int, String> _generateRoundNames(int totalRounds) {
    final roundNames = <int, String>{};
    
    for (int i = 1; i <= totalRounds; i++) {
      final matchesInRound = math.pow(2, totalRounds - i).toInt();
      
      if (matchesInRound == 1) {
        roundNames[i] = 'Chung kết';
      } else if (matchesInRound == 2) {
        roundNames[i] = 'Bán kết';
      } else if (matchesInRound == 4) {
        roundNames[i] = 'Tứ kết';
      } else if (matchesInRound == 8) {
        roundNames[i] = 'Vòng 1/8';
      } else if (matchesInRound == 16) {
        roundNames[i] = 'Vòng 1/16';
      } else() {
        roundNames[i] = 'Vòng $i';
      }
    }
    
    return roundNames;
  }

  // ==================== PARTICIPANT MANAGEMENT ====================

  /// Get confirmed tournament participants
  Future<List<Map<String, dynamic>>> _getTournamentParticipants(String tournamentId) async() {
    final response = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          registered_at,
          user:users!inner (
            id,
            full_name,
            username,
            avatar_url,
            ranking_points,
            rank
          )
        ''')
        .eq('tournament_id', tournamentId)
        .eq('status', 'registered')
        .order('registered_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==================== ROUND 1 MATCH CREATION ====================

  /// Create Round 1 matches with proper seeding
  Future<List<Map<String, dynamic>>> _createRound1Matches({
    required String tournamentId,
    required List<Map<String, dynamic>> participants,
    required Map<String, dynamic> bracketInfo,
  }) async() {
    final matches = <Map<String, dynamic>>[];
    final bracketSize = bracketInfo['bracketSize'] as int;
    final firstRoundMatches = bracketInfo['firstRoundMatches'] as int;
    
    // Apply seeding (higher ranking gets better position)
    final seededParticipants = _applySeeding(participants, bracketSize);
    
    // Create matches for Round 1
    for (int i = 0; i < firstRoundMatches; i++) {
      final player1Index = i * 2;
      final player2Index = (i * 2) + 1;
      
      final player1 = player1Index < seededParticipants.length ? seededParticipants[player1Index] : null;
      final player2 = player2Index < seededParticipants.length ? seededParticipants[player2Index] : null;
      
      // Create match data với column names chính xác
      final matchData = {
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 1,  // Đúng column name
        'match_number': i + 1,  // Required column
        'bracket_position': i + 1,
        'player1_id': player1?['user_id'],
        'player2_id': player2?['user_id'],
        'winner_id': null,
        'status': _getMatchStatus(player1, player2),
        "match_type": 'tournament',  // Required
        "format": 'single_elimination',  // Required
        'scheduled_time': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Handle byes (auto-advance if only one player)
      if (player1 != null && player2 == null) {
        matchData['winner_id'] = player1['user_id'];
        matchData['status'] = 'completed';
      } else if (player1 == null && player2 != null) {
        matchData['winner_id'] = player2['user_id'];
        matchData['status'] = 'completed';
      }
      
      matches.add(matchData);
    }
    
    // Insert matches into database
    if (matches.isNotEmpty) {
      await _supabase.from('matches').insert(matches);
      debugPrint('$_tag: ✅ Inserted ${matches.length} Round 1 matches into database');
    }
    
    return matches;
  }

  /// Apply seeding to participants
  List<Map<String, dynamic>?> _applySeeding(List<Map<String, dynamic>> participants, int bracketSize) {
    // Sort participants by ranking (descending)
    participants.sort((a, b) {
      final aRanking = a['user']['ranking_points'] ?? 0;
      final bRanking = b['user']['ranking_points'] ?? 0;
      return bRanking.compareTo(aRanking);
    });
    
    // Create seeded bracket positions
    final seededPositions = <Map<String, dynamic>?>[];
    for (int i = 0; i < bracketSize; i++) {
      seededPositions.add(null);
    }
    
    // Place participants using standard tournament seeding
    for (int i = 0; i < participants.length; i++) {
      final position = _getSeededPosition(i + 1, bracketSize);
      seededPositions[position] = participants[i];
    }
    
    return seededPositions;
  }

  /// Get seeded position for a seed number (1 vs 16, 2 vs 15, etc.)
  int _getSeededPosition(int seed, int bracketSize) {
    if (seed <= bracketSize ~/ 2) {
      return seed - 1;
    } else() {
      return bracketSize - (seed - bracketSize ~/ 2);
    }
  }

  /// Get match status based on players
  String _getMatchStatus(Map<String, dynamic>? player1, Map<String, dynamic>? player2) {
    if (player1 == null || player2 == null) {
      return 'completed'; // Bye - auto complete
    }
    return 'pending'; // Normal match waiting to be played
  }

  // ==================== ROUND PROGRESSION ====================

  /// Create next round matches when current round completes
  Future<Map<String, dynamic>> createNextRoundMatches({
    required String tournamentId,
    required int completedRound,
  }) async() {
    try() {
      debugPrint('$_tag: 🎯 Creating Round ${completedRound + 1} matches after Round $completedRound completion');

      // Get winners from completed round
      final winners = await _getRoundWinners(tournamentId, completedRound);
      if (winners.isEmpty) {
        throw Exception('No winners found from Round $completedRound');
      }

      debugPrint('$_tag: 🏆 Found ${winners.length} winners from Round $completedRound');

      // Check if tournament is complete
      if (winners.length == 1) {
        await _completeTournament(tournamentId, winners.first);
        return() {
          'success': true,
          "message": 'Tournament completed! Winner: ${winners.first['full_name']}',
          'tournamentComplete': true,
          'winner': winners.first,
        };
      }

      // Create next round matches
      final nextRound = completedRound + 1;
      final nextRoundMatches = await _createNextRoundMatches(
        tournamentId: tournamentId,
        roundNumber: nextRound,
        winners: winners,
      );

      return() {
        'success': true,
        "message": 'Created ${nextRoundMatches.length} matches for Round $nextRound',
        'nextRound': nextRound,
        'matchesCreated': nextRoundMatches.length,
      };

    } catch (e) {
      debugPrint('$_tag: ❌ Error creating next round: $e');
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get winners from a completed round
  Future<List<Map<String, dynamic>>> _getRoundWinners(String tournamentId, int round) async() {
    final response = await _supabase
        .from('matches')
        .select('''
          winner_id,
          winner:users!winner_id (
            id,
            full_name,
            username,
            avatar_url,
            ranking_points,
            rank
          )
        ''')
        .eq('tournament_id', tournamentId)
        .eq('round_number', round)
        .eq('status', 'completed')
        .not('winner_id', 'is', null)
        .order('bracket_position');

    final winners = <Map<String, dynamic>>[];
    for (final match in response) {
      if (match['winner'] != null) {
        winners.add(match['winner']);
      }
    }

    return winners;
  }

  /// Create matches for next round
  Future<List<Map<String, dynamic>>> _createNextRoundMatches({
    required String tournamentId,
    required int roundNumber,
    required List<Map<String, dynamic>> winners,
  }) async() {
    final matchCount = winners.length ~/ 2;
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < matchCount; i++) {
      final player1 = winners[i * 2];
      final player2 = winners[i * 2 + 1];

      final matchData = {
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': roundNumber,  // Sửa column name
        'match_number': i + 1,  // Required
        'bracket_position': i + 1,
        'player1_id': player1['id'],
        'player2_id': player2['id'],
        'winner_id': null,
        "status": 'pending',
        "match_type": 'tournament',  // Required
        "format": 'single_elimination',  // Required
        'scheduled_time': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      matches.add(matchData);
    }

    if (matches.isNotEmpty) {
      await _supabase.from('matches').insert(matches);
      debugPrint('$_tag: ✅ Created ${matches.length} matches for Round $roundNumber');
    }

    return matches;
  }

  // ==================== UTILITY METHODS ====================

  /// Clear existing matches for tournament
  Future<void> _clearExistingMatches(String tournamentId) async() {
    await _supabase
        .from('matches')
        .delete()
        .eq('tournament_id', tournamentId);
    debugPrint('$_tag: 🧹 Cleared existing matches for tournament');
  }

  /// Store bracket metadata
  Future<void> _storeBracketMetadata(String tournamentId, Map<String, dynamic> bracketInfo, int participantCount) async() {
    // Convert bracketInfo to ensure JSON serialization compatibility
    final serializableBracketInfo = Map<String, dynamic>.from(bracketInfo);
    
    // Convert roundNames Map<int, String> to Map<String, String> for JSON compatibility
    if (serializableBracketInfo['roundNames'] is Map<int, String>) {
      final roundNames = serializableBracketInfo['roundNames'] as Map<int, String>;
      serializableBracketInfo['roundNames'] = roundNames.map((key, value) => MapEntry(key.toString(), value));
    }
    
    await _supabase
        .from('tournaments')
        .update({
          'bracket_data': {
            "format": 'single_elimination',
            'structure': serializableBracketInfo,
            'participantCount': participantCount,
            'createdAt': DateTime.now().toIso8601String(),
          },
          "status": 'ongoing',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tournamentId);
  }

  /// Complete tournament
  Future<void> _completeTournament(String tournamentId, Map<String, dynamic> winner) async() {
    await _supabase
        .from('tournaments')
        .update({
          "status": 'completed',
          'winner_id': winner['id'],
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tournamentId);

    debugPrint('$_tag: 🏆 Tournament completed with winner: ${winner['full_name']}');
  }

  /// Generate unique match ID
  String _generateMatchId() {
    const uuid = Uuid();
    return uuid.v4();
  }
}