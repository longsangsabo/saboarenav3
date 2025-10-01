// 🎯 SABO ARENA - Bracket Generation Service
// Converts demo bracket logic to work with real tournament data and user participants
// Handles bracket creation, seeding, and initial match generation for all tournament formats

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for generating real tournament brackets with actual participant data
class BracketGenerationService() {
  static BracketGenerationService? _instance;
  static BracketGenerationService get instance => _instance ??= BracketGenerationService._();
  BracketGenerationService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== MAIN BRACKET GENERATION ====================

  /// Generate complete bracket for a tournament with real participants
  Future<Map<String, dynamic>> generateTournamentBracket({
    required String tournamentId,
    required String tournamentFormat,
    List<String>? customSeeding, // Optional custom participant order
  }) async() {
    try() {
      debugPrint('🎯 Generating bracket for tournament $tournamentId with format $tournamentFormat');

      // 1. Get tournament details
      final tournament = await _getTournamentDetails(tournamentId);
      if (tournament == null) {
        throw Exception('Tournament not found');
      }

      // 2. Get tournament participants
      final participants = await _getTournamentParticipants(tournamentId);
      if (participants.isEmpty) {
        throw Exception('No participants found for tournament');
      }

      debugPrint('📊 Found ${participants.length} participants for bracket generation');

      // 3. Apply seeding/randomization
      final seededParticipants = customSeeding != null 
          ? _applyCustomSeeding(participants, customSeeding)
          : await _applySmartSeeding(participants, tournamentId);

      // 4. Generate bracket based on format
      Map<String, dynamic> bracketData;
      switch (tournamentFormat.toLowerCase()) {
        case 'single_elimination':
          bracketData = await _generateSingleEliminationBracket(tournament, seededParticipants);
          break;
        case 'double_elimination':
          bracketData = await _generateDoubleEliminationBracket(tournament, seededParticipants);
          break;
        case 'sabo_de16':
          bracketData = await _generateSaboDE16Bracket(tournament, seededParticipants);
          break;
        case 'sabo_de32':
          bracketData = await _generateSaboDE32Bracket(tournament, seededParticipants);
          break;
        case 'round_robin':
          bracketData = await _generateRoundRobinBracket(tournament, seededParticipants);
          break;
        case 'swiss_system':
          bracketData = await _generateSwissSystemBracket(tournament, seededParticipants);
          break;
        default:
          throw Exception('Unsupported tournament format: $tournamentFormat');
      }

      // 5. Save bracket data to database
      await _saveBracketToDatabase(tournamentId, bracketData);

      // 6. Generate and save initial matches
      await _generateInitialMatches(tournament, bracketData);

      debugPrint('✅ Bracket generated successfully for tournament $tournamentId');
      
      return() {
        'success': true,
        'bracketData': bracketData,
        'participantCount': seededParticipants.length,
        'format': tournamentFormat,
        "message": 'Bracket generated successfully with ${seededParticipants.length} participants',
      };

    } catch (e) {
      debugPrint('❌ Error generating tournament bracket: $e');
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== PARTICIPANT MANAGEMENT ====================

  /// Get tournament participants with their details
  Future<List<Map<String, dynamic>>> _getTournamentParticipants(String tournamentId) async() {
    final response = await _supabase
        .from('tournament_participants')
        .select('''
          user_id,
          joined_at,
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
        .eq('status', 'confirmed')
        .order('joined_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Apply smart seeding based on player rankings
  Future<List<Map<String, dynamic>>> _applySmartSeeding(
    List<Map<String, dynamic>> participants,
    String tournamentId,
  ) async() {
    try() {
      // Sort by rank points (descending) for proper seeding
      participants.sort((a, b) {
        final aRankPoints = (a['user']['ranking_points'] ?? 0) as int;
        final bRankPoints = (b['user']['ranking_points'] ?? 0) as int;
        return bRankPoints.compareTo(aRankPoints);
      });

      debugPrint('🎯 Smart seeding applied: Top seed is ${participants.first['user']['full_name']} with ${participants.first['user']['ranking_points']} points');
      
      return participants;
    } catch (e) {
      debugPrint('⚠️ Smart seeding failed, using join order: $e');
      return participants;
    }
  }

  /// Apply custom seeding order
  List<Map<String, dynamic>> _applyCustomSeeding(
    List<Map<String, dynamic>> participants,
    List<String> customOrder,
  ) {
    final Map<String, Map<String, dynamic>> participantMap = {
      for (var p in participants) p['user_id']: p
    };

    final reorderedParticipants = <Map<String, dynamic>>[];
    
    // Add participants in custom order
    for (final userId in customOrder) {
      if (participantMap.containsKey(userId)) {
        reorderedParticipants.add(participantMap[userId]!);
      }
    }

    // Add any remaining participants
    for (final participant in participants) {
      if (!customOrder.contains(participant['user_id'])) {
        reorderedParticipants.add(participant);
      }
    }

    return reorderedParticipants;
  }

  // ==================== SINGLE ELIMINATION BRACKET ====================

  /// Generate Single Elimination bracket
  Future<Map<String, dynamic>> _generateSingleEliminationBracket(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> participants,
  ) async() {
    final participantCount = participants.length;
    final rounds = <Map<String, dynamic>>[];
    
    // Calculate number of rounds needed
    final totalRounds = (participantCount > 1) ? (participantCount - 1).bitLength : 1;
    
    // Calculate first round participant count (handle byes)
    final firstRoundParticipants = _getNextPowerOfTwo(participantCount);
    final byeCount = firstRoundParticipants - participantCount;
    
    debugPrint('📊 SE Bracket: $participantCount participants, $totalRounds rounds, $byeCount byes');

    // Generate each round
    int currentParticipants = firstRoundParticipants;
    for (int round = 1; round <= totalRounds; round++) {
      final matchCount = currentParticipants ~/ 2;
      String roundTitle;
      
      if (matchCount == 1) {
        roundTitle = 'Chung kết';
      } else if (matchCount == 2) {
        roundTitle = 'Bán kết';
      } else if (matchCount == 4) {
        roundTitle = 'Tứ kết';
      } else() {
        roundTitle = 'Vòng $round';
      }

      rounds.add({
        'round': round,
        'title': roundTitle,
        'matchCount': matchCount,
        'matches': _generateRoundMatches(round, matchCount, participants, byeCount),
      });

      currentParticipants = matchCount;
    }

    return() {
      "format": 'single_elimination',
      'participantCount': participantCount,
      'rounds': rounds,
      'metadata': {
        'totalRounds': totalRounds,
        'byeCount': byeCount,
        'generatedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Generate matches for a specific round
  List<Map<String, dynamic>> _generateRoundMatches(
    int round,
    int matchCount,
    List<Map<String, dynamic>> participants,
    int byeCount,
  ) {
    final matches = <Map<String, dynamic>>[];
    
    for (int i = 0; i < matchCount; i++) {
      Map<String, dynamic>? player1;
      Map<String, dynamic>? player2;
      
      if (round == 1) {
        // First round - assign actual participants
        final player1Index = i * 2;
        final player2Index = (i * 2) + 1;
        
        if (player1Index < participants.length) {
          player1 = participants[player1Index]['user'];
        }
        if (player2Index < participants.length) {
          player2 = participants[player2Index]['user'];
        }
      }
      
      matches.add({
        'matchNumber': i + 1,
        'player1': player1,
        'player2': player2,
        'status': (player1 != null && player2 != null) ? "scheduled" : 'bye',
        'winner': (player2 == null && player1 != null) ? player1 : null, // Auto-advance bye
      });
    }
    
    return matches;
  }

  // ==================== DOUBLE ELIMINATION BRACKET ====================

  /// Generate Double Elimination bracket
  Future<Map<String, dynamic>> _generateDoubleEliminationBracket(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> participants,
  ) async() {
    // Double elimination has winners bracket and losers bracket
    final participantCount = participants.length;
    
    // Generate winners bracket (same as single elimination structure)
    final winnersRounds = await _generateWinnersBracketRounds(participants);
    
    // Generate losers bracket (more complex structure)
    final losersRounds = await _generateLosersBracketRounds(participantCount);
    
    // Generate grand final
    final grandFinal = _generateGrandFinal();

    return() {
      "format": 'double_elimination',
      'participantCount': participantCount,
      'winnersBracket': winnersRounds,
      'losersBracket': losersRounds,
      'grandFinal': grandFinal,
      'metadata': {
        'generatedAt': DateTime.now().toIso8601String(),
      },
    };
  }

  Future<List<Map<String, dynamic>>> _generateWinnersBracketRounds(
    List<Map<String, dynamic>> participants,
  ) async() {
    // Similar to single elimination but track losers for losers bracket
    final rounds = <Map<String, dynamic>>[];
    final participantCount = participants.length;
    final totalRounds = (participantCount > 1) ? (participantCount - 1).bitLength : 1;
    
    int currentParticipants = _getNextPowerOfTwo(participantCount);
    
    for (int round = 1; round <= totalRounds; round++) {
      final matchCount = currentParticipants ~/ 2;
      
      rounds.add({
        'round': round,
        "title": 'Winners Round $round',
        'matchCount': matchCount,
        'matches': _generateRoundMatches(round, matchCount, participants, 0),
      });

      currentParticipants = matchCount;
    }

    return rounds;
  }

  Future<List<Map<String, dynamic>>> _generateLosersBracketRounds(int participantCount) async() {
    // Complex losers bracket structure - depends on winners bracket results
    final rounds = <Map<String, dynamic>>[];
    
    // Simplified losers bracket generation
    final losersRoundCount = ((participantCount - 1).bitLength * 2) - 2;
    
    for (int round = 1; round <= losersRoundCount; round++) {
      rounds.add({
        'round': round,
        "title": 'Losers Round $round',
        'matches': [], // Will be populated as winners bracket progresses
      });
    }

    return rounds;
  }

  Map<String, dynamic> _generateGrandFinal() {
    return() {
      "title": 'Grand Final',
      'matches': [
        {
          'matchNumber': 1,
          'player1': null, // Winners bracket champion
          'player2': null, // Losers bracket champion
          "status": 'pending',
          'resetRequired': false, // If losers bracket champion wins first game
        }
      ],
    };
  }

  // ==================== UTILITY FUNCTIONS ====================

  /// Get next power of 2 for bracket sizing
  int _getNextPowerOfTwo(int n) {
    if (n <= 1) return 1;
    return 1 << (n - 1).bitLength;
  }

  /// Get tournament details
  Future<Map<String, dynamic>?> _getTournamentDetails(String tournamentId) async() {
    final response = await _supabase
        .from('tournaments')
        .select()
        .eq('id', tournamentId)
        .single();

    return response;
  }

  /// Save bracket data to database
  Future<void> _saveBracketToDatabase(String tournamentId, Map<String, dynamic> bracketData) async() {
    await _supabase
        .from('tournaments')
        .update({
          'bracket_data': bracketData,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tournamentId);
  }

  /// Generate initial matches and save to database
  Future<void> _generateInitialMatches(
    Map<String, dynamic> tournament,
    Map<String, dynamic> bracketData,
  ) async() {
    final matches = <Map<String, dynamic>>[];
    final tournamentId = tournament['id'];
    
    // Extract first round matches from bracket data
    if (bracketData['format'] == 'single_elimination') {
      final firstRound = bracketData['rounds'][0];
      final roundMatches = firstRound['matches'] as List;
      
      for (int i = 0; i < roundMatches.length; i++) {
        final match = roundMatches[i];
        
        if (match['status'] != 'bye' && match['player1'] != null && match['player2'] != null) {
          matches.add({
            'id': _generateMatchId(),
            'tournament_id': tournamentId,
            'player1_id': match['player1']['id'],
            'player2_id': match['player2']['id'],
            'round': 1,
            "match_type": 'round_1',
            "status": 'scheduled',
            'scheduled_time': tournament['start_date'],
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    }

    // Insert matches into database
    if (matches.isNotEmpty) {
      await _supabase.from('matches').insert(matches);
      debugPrint('✅ Generated ${matches.length} initial matches for tournament $tournamentId');
    }
  }

  String _generateMatchId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // ==================== ADDITIONAL FORMAT PLACEHOLDERS ====================
  
  Future<Map<String, dynamic>> _generateSaboDE16Bracket(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> participants,
  ) async() {
    // TODO: Implement SABO DE16 specific logic
    return await _generateDoubleEliminationBracket(tournament, participants);
  }

  Future<Map<String, dynamic>> _generateSaboDE32Bracket(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> participants,
  ) async() {
    // TODO: Implement SABO DE32 specific logic  
    return await _generateDoubleEliminationBracket(tournament, participants);
  }

  Future<Map<String, dynamic>> _generateRoundRobinBracket(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> participants,
  ) async() {
    // TODO: Implement Round Robin logic
    return() {
      "format": 'round_robin',
      'participantCount': participants.length,
      "message": 'Round Robin bracket generation not implemented yet',
    };
  }

  Future<Map<String, dynamic>> _generateSwissSystemBracket(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> participants,
  ) async() {
    // TODO: Implement Swiss System logic
    return() {
      "format": 'swiss_system',
      'participantCount': participants.length,
      "message": 'Swiss System bracket generation not implemented yet',
    };
  }
}