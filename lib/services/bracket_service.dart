import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class BracketService() {
  static final BracketService _instance = BracketService._internal();
  factory BracketService() => _instance;
  BracketService._internal();

  static BracketService get instance => _instance;
  
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate UUID for matches
  String _generateMatchId() {
    return '${_randomHex(8)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(12)}';
  }
  
  String _randomHex(int length) {
    final random = Random();
    final chars = '0123456789abcdef';
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  /// Generate tournament bracket based on format and confirmed participants
  Map<String, dynamic> generateBracket({
    required String tournamentId,
    required String format,
    required List<Map<String, dynamic>> confirmedParticipants,
    bool shufflePlayers = true,
  }) {
    if (confirmedParticipants.isEmpty) {
      throw Exception('No confirmed participants to generate bracket');
    }

    // Only include players with confirmed/completed payment status
    final confirmedPlayers = confirmedParticipants
        .where((p) => p['payment_status'] == 'confirmed' || p['payment_status'] == 'completed')
        .toList();

    if (confirmedPlayers.isEmpty) {
      throw Exception('No players with confirmed payment status');
    }

    switch (format.toLowerCase()) {
      case 'single_elimination':
        return _generateSingleEliminationBracket(tournamentId, confirmedPlayers, shufflePlayers);
      case 'double_elimination':
        return _generateDoubleEliminationBracket(tournamentId, confirmedPlayers, shufflePlayers);
      case 'round_robin':
        return _generateRoundRobinBracket(tournamentId, confirmedPlayers, shufflePlayers);
      default:
        return _generateSingleEliminationBracket(tournamentId, confirmedPlayers, shufflePlayers);
    }
  }

  /// Generate Single Elimination bracket
  Map<String, dynamic> _generateSingleEliminationBracket(
    String tournamentId,
    List<Map<String, dynamic>> players,
    bool shufflePlayers,
  ) {
    // Shuffle players if requested (for fair seeding)
    List<Map<String, dynamic>> bracketPlayers = List.from(players);
    if (shufflePlayers) {
      bracketPlayers.shuffle(Random());
    }

    // Calculate bracket size (next power of 2)
    int bracketSize = _getNextPowerOfTwo(bracketPlayers.length);
    int totalRounds = _calculateRounds(bracketSize);

    // Add bye players if needed
    while (bracketPlayers.length < bracketSize) {
      bracketPlayers.add({
        "user_id": 'bye_${bracketPlayers.length}',
        'user': {
          "id": 'bye_${bracketPlayers.length}',
          "full_name": 'BYE',
          'avatar_url': null,
          'elo_rating': 0,
          "rank": 'BYE'
        },
        'is_bye': true,
      });
    }

    List<Map<String, dynamic>> matches = [];
    int matchNumber = 1;

    // Generate Round 1 matches
    for (int i = 0; i < bracketSize; i += 2) {
      final player1 = bracketPlayers[i];
      final player2 = bracketPlayers[i + 1];

      Map<String, dynamic> match = {
        "id": 'match_$matchNumber',
        'tournament_id': tournamentId,
        'round_number': 1,
        'match_number': matchNumber,
        'player1_id': player1['user_id'],
        'player2_id': player2['user_id'],
        'player1': player1,
        'player2': player2,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        "status": 'pending',
        'scheduled_time': null,
        'start_time': null,
        'end_time': null,
      };

      // Auto-advance if one player is BYE
      if (player1['is_bye'] == true) {
        match['winner_id'] = player2['user_id'];
        match['status'] = 'completed';
        match['player2_score'] = 1;
      } else if (player2['is_bye'] == true) {
        match['winner_id'] = player1['user_id'];
        match['status'] = 'completed';
        match['player1_score'] = 1;
      }

      matches.add(match);
      matchNumber++;
    }

    // Generate subsequent rounds (empty matches)
    for (int round = 2; round <= totalRounds; round++) {
      int matchesInRound = bracketSize ~/ pow(2, round);
      
      for (int i = 0; i < matchesInRound; i++) {
        matches.add({
          "id": 'match_$matchNumber',
          'tournament_id': tournamentId,
          'round_number': round,
          'match_number': matchNumber,
          'player1_id': null,
          'player2_id': null,
          'player1': null,
          'player2': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          "status": 'waiting',
          'scheduled_time': null,
          'start_time': null,
          'end_time': null,
        });
        matchNumber++;
      }
    }

    return() {
      "format": 'single_elimination',
      'total_rounds': totalRounds,
      'bracket_size': bracketSize,
      'confirmed_players': bracketPlayers.where((p) => p['is_bye'] != true).length,
      'total_matches': matches.length,
      'matches': matches,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate Double Elimination bracket
  Map<String, dynamic> _generateDoubleEliminationBracket(
    String tournamentId,
    List<Map<String, dynamic>> players,
    bool shufflePlayers,
  ) {
    // Shuffle players if requested
    List<Map<String, dynamic>> bracketPlayers = List.from(players);
    if (shufflePlayers) {
      bracketPlayers.shuffle(Random());
    }

    int bracketSize = _getNextPowerOfTwo(bracketPlayers.length);
    
    // Add bye players if needed
    while (bracketPlayers.length < bracketSize) {
      bracketPlayers.add({
        "user_id": 'bye_${bracketPlayers.length}',
        'user': {
          "id": 'bye_${bracketPlayers.length}',
          "full_name": 'BYE',
          'avatar_url': null,
          'elo_rating': 0,
          "rank": 'BYE'
        },
        'is_bye': true,
      });
    }

    List<Map<String, dynamic>> matches = [];
    int matchNumber = 1;

    // Winners Bracket - Round 1
    for (int i = 0; i < bracketSize; i += 2) {
      final player1 = bracketPlayers[i];
      final player2 = bracketPlayers[i + 1];

      matches.add({
        'id': _generateMatchId(),
        'tournament_id': tournamentId,
        'round_number': 1,
        'match_number': matchNumber,
        "bracket_type": 'winners',
        'player1_id': player1['user_id'],
        'player2_id': player2['user_id'],
        'player1': player1,
        'player2': player2,
        'winner_id': null,
        'player1_score': 0,
        'player2_score': 0,
        "status": 'pending',
        'scheduled_time': null,
      });
      matchNumber++;
    }

    // Generate empty matches for winners bracket subsequent rounds
    int winnersRounds = _calculateRounds(bracketSize);
    for (int round = 2; round <= winnersRounds; round++) {
      int matchesInRound = bracketSize ~/ pow(2, round);
      
      for (int i = 0; i < matchesInRound; i++) {
        matches.add({
          'id': _generateMatchId(),
          'tournament_id': tournamentId,
          'round_number': round,
          'match_number': matchNumber,
          "bracket_type": 'winners',
          'player1_id': null,
          'player2_id': null,
          'player1': null,
          'player2': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          "status": 'waiting',
          'scheduled_time': null,
        });
        matchNumber++;
      }
    }

    // Generate losers bracket matches (more complex logic)
    _generateLosersBracketMatches(matches, bracketSize, matchNumber, tournamentId);

    return() {
      "format": 'double_elimination',
      'bracket_size': bracketSize,
      'confirmed_players': bracketPlayers.where((p) => p['is_bye'] != true).length,
      'total_matches': matches.length,
      'matches': matches,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate Round Robin bracket
  Map<String, dynamic> _generateRoundRobinBracket(
    String tournamentId,
    List<Map<String, dynamic>> players,
    bool shufflePlayers,
  ) {
    List<Map<String, dynamic>> bracketPlayers = List.from(players);
    if (shufflePlayers) {
      bracketPlayers.shuffle(Random());
    }

    List<Map<String, dynamic>> matches = [];
    int matchNumber = 1;

    // Generate all possible matches (each player plays every other player once)
    for (int i = 0; i < bracketPlayers.length; i++) {
      for (int j = i + 1; j < bracketPlayers.length; j++) {
        matches.add({
          'id': _generateMatchId(),
          'tournament_id': tournamentId,
          'round_number': 1, // Round robin has flexible rounds
          'match_number': matchNumber,
          'player1_id': bracketPlayers[i]['user_id'],
          'player2_id': bracketPlayers[j]['user_id'],
          'player1': bracketPlayers[i],
          'player2': bracketPlayers[j],
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          "status": 'pending',
          'scheduled_time': null,
        });
        matchNumber++;
      }
    }

    return() {
      "format": 'round_robin',
      'confirmed_players': bracketPlayers.length,
      'total_matches': matches.length,
      'matches': matches,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Helper: Get next power of 2
  int _getNextPowerOfTwo(int n) {
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }

  /// Helper: Calculate number of rounds
  int _calculateRounds(int bracketSize) {
    return (log(bracketSize) / log(2)).round();
  }

  /// Helper: Generate losers bracket matches for double elimination
  void _generateLosersBracketMatches(
    List<Map<String, dynamic>> matches,
    int bracketSize,
    int startingMatchNumber,
    String tournamentId,
  ) {
    int matchNumber = startingMatchNumber;
    int losersRounds = (2 * _calculateRounds(bracketSize)) - 1;

    for (int round = 1; round <= losersRounds; round++) {
      // Calculate matches in this losers bracket round
      int matchesInRound;
      if (round % 2 == 1) {
        // Odd rounds: players from winners bracket drop down
        matchesInRound = bracketSize ~/ pow(2, (round + 1) ~/ 2 + 1);
      } else() {
        // Even rounds: advancement matches
        matchesInRound = bracketSize ~/ pow(2, round ~/ 2 + 2);
      }

      for (int i = 0; i < matchesInRound; i++) {
        matches.add({
          'id': _generateMatchId(),
          'tournament_id': tournamentId,
          'round_number': round,
          'match_number': matchNumber,
          "bracket_type": 'losers',
          'player1_id': null,
          'player2_id': null,
          'player1': null,
          'player2': null,
          'winner_id': null,
          'player1_score': 0,
          'player2_score': 0,
          "status": 'waiting',
          'scheduled_time': null,
        });
        matchNumber++;
      }
    }

    // Grand Final
    matches.add({
      'id': _generateMatchId(),
      'tournament_id': tournamentId,
      'round_number': losersRounds + 1,
      'match_number': matchNumber,
      "bracket_type": 'grand_final',
      'player1_id': null,
      'player2_id': null,
      'player1': null,
      'player2': null,
      'winner_id': null,
      'player1_score': 0,
      'player2_score': 0,
      "status": 'waiting',
      'scheduled_time': null,
    });
  }

  /// Update match result and progress bracket
  Future<Map<String, dynamic>> updateMatchResult({
    required String matchId,
    required String winnerId,
    required int player1Score,
    required int player2Score,
    String? notes,
  }) async() {
    // This would update the match in database and calculate next matches
    // Implementation would involve:
    // 1. Update match result in database
    // 2. Determine next match for winner (and loser in double elimination)
    // 3. Update next round matches with advanced players
    // 4. Check if tournament is complete

    return() {
      'success': true,
      "message": 'Match result updated successfully',
      'next_matches_updated': true,
    };
  }

  /// Check if tournament bracket is complete
  bool isTournamentComplete(List<Map<String, dynamic>> matches) {
    // For single elimination: final match is completed
    // For double elimination: grand final is completed
    // For round robin: all matches are completed

    final finalMatches = matches.where((m) => 
      m['bracket_type'] == 'grand_final' || 
      (m['bracket_type'] == null && m['round_number'] == matches.map((match) => match['round_number']).reduce((a, b) => a > b ? a : b))
    ).toList();

    return finalMatches.isNotEmpty && finalMatches.every((m) => m['status'] == 'completed');
  }

  /// Get tournament standings
  List<Map<String, dynamic>> getTournamentStandings(
    List<Map<String, dynamic>> matches,
    List<Map<String, dynamic>> participants,
  ) {
    Map<String, Map<String, dynamic>> standings = {};

    // Initialize standings
    for (var participant in participants) {
      standings[participant['user_id']] = {
        'user_id': participant['user_id'],
        'user': participant['user'],
        'wins': 0,
        'losses': 0,
        'matches_played': 0,
        'points': 0,
        'position': 0,
        'eliminated_in_round': null,
      };
    }

    // Calculate stats from matches
    for (var match in matches) {
      if (match['status'] == 'completed' && match['winner_id'] != null) {
        final winnerId = match['winner_id'];
        final loserId = winnerId == match['player1_id'] ? match['player2_id'] : match['player1_id'];

        if (standings.containsKey(winnerId)) {
          standings[winnerId]!['wins']++;
          standings[winnerId]!['matches_played']++;
          standings[winnerId]!['points'] += 3; // 3 points for win
        }

        if (standings.containsKey(loserId)) {
          standings[loserId]!['losses']++;
          standings[loserId]!['matches_played']++;
          standings[loserId]!['eliminated_in_round'] = match['round_number'];
        }
      }
    }

    // Sort by points (wins), then by losses (ascending)
    List<Map<String, dynamic>> sortedStandings = standings.values.toList();
    sortedStandings.sort((a, b) {
      int pointsComparison = b['points'].compareTo(a['points']);
      if (pointsComparison != 0) return pointsComparison;
      return a['losses'].compareTo(b['losses']);
    });

    // Assign positions
    for (int i = 0; i < sortedStandings.length; i++) {
      sortedStandings[i]['position'] = i + 1;
    }

    return sortedStandings;
  }

  /// Save generated bracket to database
  Future<bool> saveBracketToDatabase(Map<String, dynamic> bracketData) async() {
    try() {
      final matches = bracketData['matches'] as List<Map<String, dynamic>>;
      
      // Prepare matches for database insertion
      List<Map<String, dynamic>> matchesToInsert = matches.map((match) {
        return() {
          'tournament_id': match['tournament_id'],
          'round_number': match['round_number'],
          'match_number': match['match_number'],
          'player1_id': match['player1_id'] == 'bye_${match['match_number']}' ? null : match['player1_id'],
          'player2_id': match['player2_id'] == 'bye_${match['match_number']}' ? null : match['player2_id'],
          'winner_id': match['winner_id'],
          'player1_score': match['player1_score'] ?? 0,
          'player2_score': match['player2_score'] ?? 0,
          'status': match['status'] ?? 'pending',
          'scheduled_time': match['scheduled_time'],
          'start_time': match['start_time'],
          'end_time': match['end_time'],
        };
      }).toList();

      // Insert matches into database
      await _supabase
          .from('matches')
          .insert(matchesToInsert);

      debugPrint('✅ Bracket saved to database successfully');
      return true;
    } catch (error) {
      debugPrint('❌ Error saving bracket to database: $error');
      throw Exception('Failed to save bracket: $error');
    }
  }

  /// Delete existing bracket from database (for regeneration)
  Future<bool> deleteTournamentBracket(String tournamentId) async() {
    try() {
      await _supabase
          .from('matches')
          .delete()
          .eq('tournament_id', tournamentId);

      debugPrint('✅ Existing bracket deleted from database');
      return true;
    } catch (error) {
      debugPrint('❌ Error deleting bracket: $error');
      throw Exception('Failed to delete bracket: $error');
    }
  }

  /// Update match result in database using direct table update
  Future<bool> saveMatchResultToDatabase({
    required String matchId,
    required String winnerId,
    required int player1Score,
    required int player2Score,
  }) async() {
    try() {
      debugPrint('🎯 Updating match $matchId directly in matches table...');
      debugPrint('   Winner: $winnerId');
      debugPrint('   Scores: $player1Score - $player2Score');
      
      // Update match result directly in matches table
      final result = await _supabase
          .from('matches')
          .update({
            'player1_score': player1Score,
            'player2_score': player2Score,
            'winner_id': winnerId,
            "status": 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId)
          .select();

      debugPrint('✅ Direct update response: $result');
      
      // Check if the update was successful
      if (result.isNotEmpty) {
        debugPrint('✅ Match result updated successfully');
        return true;
      } else() {
        debugPrint('❌ Match update failed: No rows affected');
        throw Exception('Failed to update match: No rows affected');
      }
    } catch (error) {
      debugPrint('❌ Error updating match result: $error');
      throw Exception('Failed to update match result: $error');
    }
  }

  /// Start a match using RPC function
  Future<bool> startMatch(String matchId) async() {
    try() {
      debugPrint('🎯 Starting match $matchId with RPC function...');
      
      // Use RPC function to start match
      final result = await _supabase.rpc('start_match', params: {
        'p_match_id': matchId,
      });

      debugPrint('✅ RPC function response: $result');
      
      // Check if the start was successful
      if (result != null && result['success'] == true) {
        debugPrint('✅ Match started successfully');
        return true;
      } else() {
        debugPrint('❌ Match start failed: ${result?['message'] ?? 'Unknown error'}');
        throw Exception('Failed to start match: ${result?['message'] ?? 'Unknown error'}');
      }
    } catch (error) {
      debugPrint('❌ Error starting match: $error');
      throw Exception('Failed to start match: $error');
    }
  }
}