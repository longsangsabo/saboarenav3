// 🏆 SABO ARENA - REFACTORED Tournament Bracket Generator Service
// SEPARATED LOGIC FOR EACH FORMAT TO AVOID CONFUSION
// Each format has its own dedicated generation method

import '../core/constants/tournament_constants.dart';
import 'package:flutter/foundation.dart';
// import 'dart:math' as math; // Currently unused

/// Tournament participant data
class TournamentParticipant() {
  final String id;
  final String name;
  final String? rank;
  final int? elo;
  final int? seed;
  final Map<String, dynamic>? metadata;

  const TournamentParticipant({
    required this.id,
    required this.name,
    this.rank,
    this.elo,
    this.seed,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rank': rank,
    'elo': elo,
    'seed': seed,
    'metadata': metadata,
  };
}

/// Tournament match representation
class TournamentMatch() {
  final String id;
  final String roundId;
  final int roundNumber;
  final int matchNumber;
  final TournamentParticipant? player1;
  final TournamentParticipant? player2;
  final TournamentParticipant? winner;
  final String status; // 'pending', 'in_progress', 'completed', 'bye'
  final Map<String, dynamic>? result;
  final DateTime? scheduledTime;
  final Map<String, dynamic>? metadata;

  const TournamentMatch({
    required this.id,
    required this.roundId,
    required this.roundNumber,
    required this.matchNumber,
    this.player1,
    this.player2,
    this.winner,
    this.status = 'pending',
    this.result,
    this.scheduledTime,
    this.metadata,
  });

  /// Check if this is a bye match (only one player)
  bool get isBye => player1 != null && player2 == null;
  
  /// Check if match is ready to be played
  bool get isReady => player1 != null && player2 != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'roundId': roundId,
    'roundNumber': roundNumber,
    'matchNumber': matchNumber,
    'player1': player1?.toJson(),
    'player2': player2?.toJson(),
    'winner': winner?.toJson(),
    'status': status,
    'result': result,
    'scheduledTime': scheduledTime?.toIso8601String(),
    'metadata': metadata,
  };
}

/// Tournament round representation
class TournamentRound() {
  final String id;
  final int roundNumber;
  final String name;
  final String type; // 'winner', 'loser', 'group', 'swiss', 'final'
  final List<TournamentMatch> matches;
  final Map<String, dynamic>? metadata;

  const TournamentRound({
    required this.id,
    required this.roundNumber,
    required this.name,
    required this.type,
    required this.matches,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'roundNumber': roundNumber,
    'name': name,
    'type': type,
    'matches': matches.map((m) => m.toJson()).toList(),
    'metadata': metadata,
  };
}

/// Complete tournament bracket structure
class TournamentBracket() {
  final String tournamentId;
  final String format;
  final List<TournamentParticipant> participants;
  final List<TournamentRound> rounds;
  final Map<String, dynamic> structure;
  final Map<String, dynamic>? metadata;

  const TournamentBracket({
    required this.tournamentId,
    required this.format,
    required this.participants,
    required this.rounds,
    required this.structure,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'tournamentId': tournamentId,
    'format': format,
    'participants': participants.map((p) => p.toJson()).toList(),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'structure': structure,
    'metadata': metadata,
  };
}

/// Main bracket generator service
class BracketGeneratorService() {
  static const String _tag = 'BracketGeneratorService';

  /// Generate complete tournament bracket based on format
  static Future<TournamentBracket> generateBracket({
    required String tournamentId,
    required String format,
    required List<TournamentParticipant> participants,
    String seedingMethod = 'elo_based',
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating bracket for $format with ${participants.length} participants');

    // Validate format and participants
    _validateBracketGeneration(format, participants);

    // Seed participants
    final seededParticipants = await _seedParticipants(
      participants, 
      seedingMethod, 
      options
    );

    // Generate bracket based on format
    switch (format) {
      case TournamentFormats.singleElimination:
        return await _generateSingleEliminationBracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      case TournamentFormats.doubleElimination:
        return await _generateDoubleEliminationBracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      case TournamentFormats.saboDoubleElimination:
        return await _generateSaboDoubleEliminationBracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      case TournamentFormats.saboDoubleElimination32:
        return await _generateSaboDoubleElimination32Bracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      case TournamentFormats.roundRobin:
        return await _generateRoundRobinBracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      case TournamentFormats.swiss:
        return await _generateSwissBracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      case TournamentFormats.parallelGroups:
        return await _generateParallelGroupsBracket(
          tournamentId, participants: seededParticipants, options: options
        );
      
      default:
        throw Exception('Unsupported tournament format: $format');
    }
  }

  /// Validate bracket generation parameters
  static void _validateBracketGeneration(String format, List<TournamentParticipant> participants) {
    final formatDetails = TournamentFormats.formatDetails[format];
    if (formatDetails == null) {
      throw Exception('Unknown tournament format: $format');
    }

    final minPlayers = formatDetails['minPlayers'] as int;
    final maxPlayers = formatDetails['maxPlayers'] as int;
    final playerCount = participants.length;

    if (playerCount < minPlayers) {
      throw Exception('Not enough players for $format. Minimum: $minPlayers, Got: $playerCount');
    }

    if (playerCount > maxPlayers) {
      throw Exception('Too many players for $format. Maximum: $maxPlayers, Got: $playerCount');
    }

    // Additional format-specific validations
    if (format == TournamentFormats.singleElimination || format == TournamentFormats.doubleElimination) {
      // For elimination tournaments, check if we need byes
      final powerOfTwo = _nearestPowerOfTwo(playerCount);
      if (powerOfTwo != playerCount) {
        debugPrint('$_tag: Will generate ${powerOfTwo - playerCount} byes for $format');
      }
    }
  }

  /// Seed participants based on method
  static Future<List<TournamentParticipant>> _seedParticipants(
    List<TournamentParticipant> participants,
    String seedingMethod,
    Map<String, dynamic>? options,
  ) async() {
    debugPrint('$_tag: Seeding participants using $seedingMethod method');

    switch (seedingMethod) {
      case 'elo_based':
        return _seedByElo(participants);
      
      case 'rank_based':
        return _seedByRank(participants);
      
      case 'random':
        return _seedRandomly(participants);
      
      case 'manual':
        return _seedManually(participants, options?['manual_seeds']);
      
      default:
        return _seedByElo(participants); // Default to ELO
    }
  }

  /// Seed by ELO rating (highest first)
  static List<TournamentParticipant> _seedByElo(List<TournamentParticipant> participants) {
    final seeded = List<TournamentParticipant>.from(participants);
    seeded.sort((a, b) => (b.elo ?? 1200).compareTo(a.elo ?? 1200));
    
    // Assign seed numbers
    final seededWithNumbers = <TournamentParticipant>[];
    for (int i = 0; i < seeded.length; i++) {
      seededWithNumbers.add(TournamentParticipant(
        id: seeded[i].id,
        name: seeded[i].name,
        rank: seeded[i].rank,
        elo: seeded[i].elo,
        seed: i + 1,
        metadata: seeded[i].metadata,
      ));
    }
    
    return seededWithNumbers;
  }

  /// Seed by rank (E+ → K)
  static List<TournamentParticipant> _seedByRank(List<TournamentParticipant> participants) {
    final rankOrder = ['E+', 'E', 'F+', 'F', 'G+', 'G', 'H+', 'H', 'I+', 'I', 'K+', 'K'];
    
    final seeded = List<TournamentParticipant>.from(participants);
    seeded.sort((a, b) {
      final aIndex = rankOrder.indexOf(a.rank ?? 'K');
      final bIndex = rankOrder.indexOf(b.rank ?? 'K');
      return aIndex.compareTo(bIndex);
    });

    final seededWithNumbers = <TournamentParticipant>[];
    for (int i = 0; i < seeded.length; i++) {
      seededWithNumbers.add(TournamentParticipant(
        id: seeded[i].id,
        name: seeded[i].name,
        rank: seeded[i].rank,
        elo: seeded[i].elo,
        seed: i + 1,
        metadata: seeded[i].metadata,
      ));
    }
    
    return seededWithNumbers;
  }

  /// Random seeding
  static List<TournamentParticipant> _seedRandomly(List<TournamentParticipant> participants) {
    final seeded = List<TournamentParticipant>.from(participants);
    seeded.shuffle();

    final seededWithNumbers = <TournamentParticipant>[];
    for (int i = 0; i < seeded.length; i++) {
      seededWithNumbers.add(TournamentParticipant(
        id: seeded[i].id,
        name: seeded[i].name,
        rank: seeded[i].rank,
        elo: seeded[i].elo,
        seed: i + 1,
        metadata: seeded[i].metadata,
      ));
    }
    
    return seededWithNumbers;
  }

  /// Manual seeding with provided order
  static List<TournamentParticipant> _seedManually(
    List<TournamentParticipant> participants,
    List<String>? seedOrder,
  ) {
    if (seedOrder == null || seedOrder.length != participants.length) {
      throw Exception('Manual seeding requires seed order for all participants');
    }

    final seeded = <TournamentParticipant>[];
    for (int i = 0; i < seedOrder.length; i++) {
      final participant = participants.firstWhere((p) => p.id == seedOrder[i]);
      seeded.add(TournamentParticipant(
        id: participant.id,
        name: participant.name,
        rank: participant.rank,
        elo: participant.elo,
        seed: i + 1,
        metadata: participant.metadata,
      ));
    }
    
    return seeded;
  }

  /// Find nearest power of 2 greater than or equal to n
  static int _nearestPowerOfTwo(int n) {
    if (n <= 1) return 2;
    int power = 1;
    while (power < n) {
      power *= 2;
    }
    return power;
  }

  /// Generate unique match ID
  static String _generateMatchId(String tournamentId, int round, int match) {
    return '${tournamentId}_R${round}_M$match';
  }

  /// Generate unique round ID
  static String _generateRoundId(String tournamentId, int round, [String? type]) {
    final typePrefix = type != null ? "${type}_" : '';
    return '${tournamentId}_${typePrefix}R$round';
  }

  /// Get seeding position for single elimination bracket
  static int _getSingleEliminationPosition(int seed, int bracketSize) {
    // Standard tournament seeding algorithm
    // 1 vs 16 = positions 0,31 | 2 vs 15 = positions 1,30, etc.
    
    if (seed <= bracketSize ~/ 2) {
      return seed - 1;
    } else() {
      return bracketSize - (seed - bracketSize ~/ 2);
    }
  }

  /// Get match status based on participants
  static String _getMatchStatus(TournamentParticipant? player1, TournamentParticipant? player2) {
    if (player1 == null && player2 == null) {
      return 'pending';
    } else if (player1 == null || player2 == null) {
      return 'bye';
    } else() {
      return 'pending';
    }
  }

  /// Get bye winner if applicable
  static TournamentParticipant? _getByeWinner(TournamentParticipant? player1, TournamentParticipant? player2) {
    if (player1 != null && player2 == null) {
      return player1;
    } else if (player1 == null && player2 != null) {
      return player2;
    }
    return null;
  }

  /// Generate round name based on position and total rounds
  static String _getRoundName(int roundNumber, int totalRounds) {
    final remaining = totalRounds - roundNumber + 1;
    
    switch (remaining) {
      case 1:
        return 'Chung kết'; // Final
      case 2:
        return 'Bán kết'; // Semi-final
      case 3:
        return 'Tứ kết'; // Quarter-final
      case 4:
        return 'Vòng 16'; // Round of 16
      case 5:
        return 'Vòng 32'; // Round of 32
      default:
        return 'Vòng $roundNumber'; // Round N
    }
  }

  // Format-specific bracket generation methods will be implemented next...
  
  static Future<TournamentBracket> _generateSingleEliminationBracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating single elimination bracket');
    
    final bracketSize = _nearestPowerOfTwo(participants.length);
    final byeCount = bracketSize - participants.length;
    final rounds = <TournamentRound>[];
    
    debugPrint('$_tag: Bracket size: $bracketSize, Byes needed: $byeCount');
    
    // Calculate number of rounds
    int totalRounds = 0;
    int tempSize = bracketSize;
    while (tempSize > 1) {
      totalRounds++;
      tempSize ~/= 2;
    }
    
    // Generate first round with seeded participants and byes
    final firstRoundMatches = <TournamentMatch>[];
    final matchesInFirstRound = bracketSize ~/ 2;
    
    // Standard single elimination seeding: 1 vs 16, 2 vs 15, etc.
    final seededPositions = <TournamentParticipant?>[];
    for (int i = 0; i < bracketSize; i++) {
      seededPositions.add(null);
    }
    
    // Place seeded participants
    for (int i = 0; i < participants.length; i++) {
      final seed = participants[i].seed ?? (i + 1);
      final position = _getSingleEliminationPosition(seed, bracketSize);
      seededPositions[position] = participants[i];
    }
    
    // Create first round matches
    for (int i = 0; i < matchesInFirstRound; i++) {
      final player1 = seededPositions[i * 2];
      final player2 = seededPositions[i * 2 + 1];
      
      final match = TournamentMatch(
        id: _generateMatchId(tournamentId, 1, i + 1),
        roundId: _generateRoundId(tournamentId, 1),
        roundNumber: 1,
        matchNumber: i + 1,
        player1: player1,
        player2: player2,
        status: _getMatchStatus(player1, player2),
        winner: _getByeWinner(player1, player2),
      );
      
      firstRoundMatches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 1),
      roundNumber: 1,
      name: _getRoundName(1, totalRounds),
      type: 'winner',
      matches: firstRoundMatches,
    ));
    
    // Generate subsequent rounds (empty matches to be filled as tournament progresses)
    for (int round = 2; round <= totalRounds; round++) {
      final matchesInRound = bracketSize ~/ (1 << round); // 2^round
      final roundMatches = <TournamentMatch>[];
      
      for (int i = 0; i < matchesInRound; i++) {
        final match = TournamentMatch(
          id: _generateMatchId(tournamentId, round, i + 1),
          roundId: _generateRoundId(tournamentId, round),
          roundNumber: round,
          matchNumber: i + 1,
          status: 'pending',
        );
        roundMatches.add(match);
      }
      
      rounds.add(TournamentRound(
        id: _generateRoundId(tournamentId, round),
        roundNumber: round,
        name: _getRoundName(round, totalRounds),
        type: 'winner',
        matches: roundMatches,
      ));
    }
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.singleElimination,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'single_elimination',
        'bracketSize': bracketSize,
        'totalRounds': totalRounds,
        'byeCount': byeCount,
        "seedingMethod": 'standard',
      },
    );
  }

  static Future<TournamentBracket> _generateDoubleEliminationBracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating double elimination bracket');
    
    final bracketSize = _nearestPowerOfTwo(participants.length);
    final byeCount = bracketSize - participants.length;
    final rounds = <TournamentRound>[];
    
    // Calculate rounds for winner and loser brackets
    int winnerRounds = 0;
    int tempSize = bracketSize;
    while (tempSize > 1) {
      winnerRounds++;
      tempSize ~/= 2;
    }
    
    // Loser bracket has approximately 2x rounds - 1
    final loserRounds = (winnerRounds * 2) - 1;
    
    debugPrint('$_tag: Winner bracket rounds: $winnerRounds, Loser bracket rounds: $loserRounds');
    
    // Generate Winner Bracket (same as single elimination)
    final winnerBracket = await _generateWinnerBracket(
      tournamentId, participants, bracketSize, winnerRounds
    );
    rounds.addAll(winnerBracket);
    
    // Generate Loser Bracket (elimination rounds for losers)
    final loserBracket = await _generateLoserBracket(
      tournamentId, bracketSize, loserRounds, winnerRounds
    );
    rounds.addAll(loserBracket);
    
    // Add Grand Final (winner of winner bracket vs winner of loser bracket)
    final grandFinal = TournamentMatch(
      id: _generateMatchId(tournamentId, 999, 1), // Special round number
      roundId: _generateRoundId(tournamentId, 999, 'grand_final'),
      roundNumber: 999,
      matchNumber: 1,
      status: 'pending',
      metadata: {'isGrandFinal': true},
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 999, 'grand_final'),
      roundNumber: 999,
      name: 'Chung kết lớn',
      type: 'grand_final',
      matches: [grandFinal],
      metadata: {'isGrandFinal': true},
    ));
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.doubleElimination,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'double_elimination',
        'bracketSize': bracketSize,
        'winnerRounds': winnerRounds,
        'loserRounds': loserRounds,
        'byeCount': byeCount,
        'hasGrandFinal': true,
      },
    );
  }

  /// Generate Sabo Double Elimination DE16 bracket
  /// 16 players, 27 matches total: WB(14) + LA(7) + LB(3) + Finals(3)
  static Future<TournamentBracket> _generateSaboDoubleEliminationBracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating Sabo Double Elimination DE16 bracket');
    
    // Sabo DE16 requires exactly 16 players
    if (participants.length != 16) {
      throw Exception('Sabo Double Elimination requires exactly 16 players');
    }
    
    final rounds = <TournamentRound>[];
    
    // Generate Winners Bracket (14 matches: 8+4+2)
    final winnerRounds = _generateSaboWinnersBracket(tournamentId, participants);
    rounds.addAll(winnerRounds);
    
    // Generate Losers Branch A (7 matches: 4+2+1) - handles WR1 losers
    final losersABranch = _generateSaboLosersBranchA(tournamentId);
    rounds.addAll(losersABranch);
    
    // Generate Losers Branch B (3 matches: 2+1) - handles WR2 losers  
    final losersBBranch = _generateSaboLosersBranchB(tournamentId);
    rounds.addAll(losersBBranch);
    
    // Generate SABO Finals (3 matches: 2 semifinals + 1 final)
    final saboFinalsRounds = _generateSaboFinalsRounds(tournamentId);
    rounds.addAll(saboFinalsRounds);
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.saboDoubleElimination,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'sabo_de16',
        'totalMatches': 27,
        'winnersMatches': 14,
        'losersAMatches': 7,
        'losersBMatches': 3,
        'finalsMatches': 3,
        'hasLosersBranches': 2,
        'hasSaboFinals': true,
      },
      metadata: {
        "format": 'Sabo Double Elimination DE16',
        "description": 'SABO Arena special DE16 format',
        'createdAt': DateTime.now().toIso8601String(),
        'rounds': {
          'winners': [1, 2, 3],
          'losersA': [101, 102, 103], 
          'losersB': [201, 202],
          'finals': [250, 251, 300],
        }
      },
    );
  }

  /// Generate Sabo Double Elimination DE32 bracket
  /// 32 players, 55 matches total: Group A(26) + Group B(26) + Cross-Bracket(3)
  static Future<TournamentBracket> _generateSaboDoubleElimination32Bracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating Sabo Double Elimination DE32 bracket');
    
    // Sabo DE32 requires exactly 32 players
    if (participants.length != 32) {
      throw Exception('Sabo Double Elimination DE32 requires exactly 32 players');
    }
    
    final rounds = <TournamentRound>[];
    
    // Split 32 players into 2 groups of 16 each
    final groupA = participants.take(16).toList();
    final groupB = participants.skip(16).take(16).toList();
    
    // Generate Group A (26 matches: modified DE16 producing 2 qualifiers)
    final groupARounds = _generateSaboDE32Group(tournamentId, 'A', groupA);
    rounds.addAll(groupARounds);
    
    // Generate Group B (26 matches: modified DE16 producing 2 qualifiers) 
    final groupBRounds = _generateSaboDE32Group(tournamentId, 'B', groupB);
    rounds.addAll(groupBRounds);
    
    // Generate Cross-Bracket Finals (3 matches: 2 semifinals + 1 final)
    final crossBracketRounds = _generateSaboDE32CrossBracket(tournamentId);
    rounds.addAll(crossBracketRounds);
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.saboDoubleElimination32,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'sabo_de32',
        'totalMatches': 55,
        'groupAMatches': 26,
        'groupBMatches': 26,
        'crossBracketMatches': 3,
        'hasGroups': true,
        'groupCount': 2,
        'playersPerGroup': 16,
        'qualifiersPerGroup': 2,
      },
      metadata: {
        "format": 'Sabo Double Elimination DE32',
        "description": 'SABO Arena DE32 with Two-Group System',
        'createdAt': DateTime.now().toIso8601String(),
        'rounds': {
          'groupA': [1, 2, 3, 101, 102, 103, 201, 202, 250, 251],
          'groupB': [1, 2, 3, 101, 102, 103, 201, 202, 250, 251],
          'crossBracket': [350, 400],
        },
        'groups': {
          'A': {'players': 16, 'matches': 26, 'qualifiers': 2},
          'B': {'players': 16, 'matches': 26, 'qualifiers': 2},
        }
      },
    );
  }

  /// Generate winner bracket for double elimination
  static Future<List<TournamentRound>> _generateWinnerBracket(
    String tournamentId,
    List<TournamentParticipant> participants,
    int bracketSize,
    int totalRounds,
  ) async() {
    final rounds = <TournamentRound>[];
    
    // Same logic as single elimination but with 'winner' type
    final seededPositions = <TournamentParticipant?>[];
    for (int i = 0; i < bracketSize; i++) {
      seededPositions.add(null);
    }
    
    // Place seeded participants
    for (int i = 0; i < participants.length; i++) {
      final seed = participants[i].seed ?? (i + 1);
      final position = _getSingleEliminationPosition(seed, bracketSize);
      seededPositions[position] = participants[i];
    }
    
    // Generate all winner bracket rounds
    for (int round = 1; round <= totalRounds; round++) {
      final matchesInRound = bracketSize ~/ (1 << round);
      final roundMatches = <TournamentMatch>[];
      
      if (round == 1) {
        // First round with actual participants
        for (int i = 0; i < matchesInRound; i++) {
          final player1 = seededPositions[i * 2];
          final player2 = seededPositions[i * 2 + 1];
          
          final match = TournamentMatch(
            id: _generateMatchId(tournamentId, round, i + 1),
            roundId: _generateRoundId(tournamentId, round, 'winner'),
            roundNumber: round,
            matchNumber: i + 1,
            player1: player1,
            player2: player2,
            status: _getMatchStatus(player1, player2),
            winner: _getByeWinner(player1, player2),
            metadata: {"bracketType": 'winner'},
          );
          roundMatches.add(match);
        }
      } else() {
        // Subsequent rounds (empty matches)
        for (int i = 0; i < matchesInRound; i++) {
          final match = TournamentMatch(
            id: _generateMatchId(tournamentId, round, i + 1),
            roundId: _generateRoundId(tournamentId, round, 'winner'),
            roundNumber: round,
            matchNumber: i + 1,
            status: 'pending',
            metadata: {"bracketType": 'winner'},
          );
          roundMatches.add(match);
        }
      }
      
      rounds.add(TournamentRound(
        id: _generateRoundId(tournamentId, round, 'winner'),
        roundNumber: round,
        name: 'WB ${_getRoundName(round, totalRounds)}',
        type: 'winner',
        matches: roundMatches,
        metadata: {"bracketType": 'winner'},
      ));
    }
    
    return rounds;
  }

  /// Generate loser bracket for double elimination
  static Future<List<TournamentRound>> _generateLoserBracket(
    String tournamentId,
    int bracketSize,
    int loserRounds,
    int winnerRounds,
  ) async() {
    final rounds = <TournamentRound>[];
    
    // Loser bracket has complex structure
    // Round 1: First round losers
    // Round 2: Round 1 winners vs Second round losers
    // And so on...
    
    for (int round = 1; round <= loserRounds; round++) {
      // Calculate matches in this loser round
      int matchesInRound;
      if (round == 1) {
        matchesInRound = bracketSize ~/ 4; // Half of first winner round
      } else if (round % 2 == 0) {
        // Even rounds: winners from previous loser round vs new dropdowns
        matchesInRound = bracketSize ~/ (1 << ((round ~/ 2) + 2));
      } else() {
        // Odd rounds: just advance loser bracket winners
        matchesInRound = bracketSize ~/ (1 << ((round + 1) ~/ 2 + 2));
      }
      
      if (matchesInRound < 1) matchesInRound = 1;
      
      final roundMatches = <TournamentMatch>[];
      for (int i = 0; i < matchesInRound; i++) {
        final match = TournamentMatch(
          id: _generateMatchId(tournamentId, round + 100, i + 1), // Offset to avoid collision
          roundId: _generateRoundId(tournamentId, round + 100, 'loser'),
          roundNumber: round + 100, // Offset for loser bracket
          matchNumber: i + 1,
          status: 'pending',
          metadata: {
            "bracketType": 'loser',
            'loserRoundNumber': round,
          },
        );
        roundMatches.add(match);
      }
      
      rounds.add(TournamentRound(
        id: _generateRoundId(tournamentId, round + 100, 'loser'),
        roundNumber: round + 100,
        name: 'LB Vòng $round',
        type: 'loser',
        matches: roundMatches,
        metadata: {
          "bracketType": 'loser',
          'loserRoundNumber': round,
        },
      ));
    }
    
    return rounds;
  }

  static Future<TournamentBracket> _generateRoundRobinBracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating round robin bracket');
    
    final playerCount = participants.length;
    final rounds = <TournamentRound>[];
    
    // In round robin, each player plays every other player once
    // Total matches = n(n-1)/2
    // Total rounds = n-1 (if even players) or n (if odd players)
    
    final isEven = playerCount % 2 == 0;
    final totalRounds = isEven ? playerCount - 1 : playerCount;
    final matchesPerRound = playerCount ~/ 2;
    
    debugPrint('$_tag: $playerCount players, $totalRounds rounds, $matchesPerRound matches per round');
    
    // Use circle method for round robin scheduling
    final schedule = _generateRoundRobinSchedule(participants);
    
    for (int round = 1; round <= totalRounds; round++) {
      final roundMatches = <TournamentMatch>[];
      final roundSchedule = schedule[round - 1];
      
      for (int i = 0; i < roundSchedule.length; i++) {
        final pair = roundSchedule[i];
        if (pair.length == 2) {
          final match = TournamentMatch(
            id: _generateMatchId(tournamentId, round, i + 1),
            roundId: _generateRoundId(tournamentId, round),
            roundNumber: round,
            matchNumber: i + 1,
            player1: pair[0],
            player2: pair[1],
            status: 'pending',
            metadata: {"tournamentType": 'round_robin'},
          );
          roundMatches.add(match);
        }
      }
      
      rounds.add(TournamentRound(
        id: _generateRoundId(tournamentId, round),
        roundNumber: round,
        name: 'Vòng $round',
        type: 'round_robin',
        matches: roundMatches,
      ));
    }
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.roundRobin,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'round_robin',
        'totalRounds': totalRounds,
        'matchesPerRound': matchesPerRound,
        'totalMatches': rounds.fold<int>(0, (sum, round) => sum + round.matches.length),
      },
    );
  }

  /// Generate round robin schedule using circle method
  static List<List<List<TournamentParticipant>>> _generateRoundRobinSchedule(
    List<TournamentParticipant> participants,
  ) {
    final players = List<TournamentParticipant>.from(participants);
    final schedule = <List<List<TournamentParticipant>>>[];
    
    // If odd number of players, add a "bye" placeholder
    if (players.length % 2 == 1) {
      players.add(TournamentParticipant(id: 'bye', name: 'BYE'));
    }
    
    final n = players.length;
    final rounds = n - 1;
    
    for (int round = 0; round < rounds; round++) {
      final roundMatches = <List<TournamentParticipant>>[];
      
      for (int i = 0; i < n ~/ 2; i++) {
        final player1Index = i;
        final player2Index = (n - 1 - i + round) % (n - 1);
        
        final player1 = players[player1Index];
        final player2 = players[player2Index == 0 ? n - 1 : player2Index];
        
        // Skip matches with BYE
        if (player1.id != 'bye' && player2.id != 'bye') {
          roundMatches.add([player1, player2]);
        }
      }
      
      schedule.add(roundMatches);
    }
    
    return schedule;
  }

  static Future<TournamentBracket> _generateSwissBracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating Swiss system bracket');
    
    final playerCount = participants.length;
    final rounds = <TournamentRound>[];
    
    // Swiss system: typically log2(n) + 2 rounds
    var totalRounds = 1;
    var temp = playerCount;
    while (temp > 1) {
      totalRounds++;
      temp ~/= 2;
    }
    totalRounds += 1; // Add extra round for Swiss
    
    final matchesPerRound = playerCount ~/ 2;
    
    debugPrint('$_tag: $playerCount players, $totalRounds rounds (Swiss system)');
    
    // Generate first round with initial seeding
    final firstRoundMatches = <TournamentMatch>[];
    
    // Swiss round 1: pair top half vs bottom half
    for (int i = 0; i < matchesPerRound; i++) {
      final player1 = participants[i];
      final player2 = participants[i + matchesPerRound];
      
      final match = TournamentMatch(
        id: _generateMatchId(tournamentId, 1, i + 1),
        roundId: _generateRoundId(tournamentId, 1, 'swiss'),
        roundNumber: 1,
        matchNumber: i + 1,
        player1: player1,
        player2: player2,
        status: 'pending',
        metadata: {
          "tournamentType": 'swiss',
          "pairingMethod": 'initial_seeding',
        },
      );
      firstRoundMatches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 1, 'swiss'),
      roundNumber: 1,
      name: 'Swiss Vòng 1',
      type: 'swiss',
      matches: firstRoundMatches,
      metadata: {"pairingMethod": 'initial_seeding'},
    ));
    
    // Generate subsequent rounds (empty, to be paired based on results)
    for (int round = 2; round <= totalRounds; round++) {
      final roundMatches = <TournamentMatch>[];
      
      for (int i = 0; i < matchesPerRound; i++) {
        final match = TournamentMatch(
          id: _generateMatchId(tournamentId, round, i + 1),
          roundId: _generateRoundId(tournamentId, round, 'swiss'),
          roundNumber: round,
          matchNumber: i + 1,
          status: 'pending',
          metadata: {
            "tournamentType": 'swiss',
            "pairingMethod": 'score_based',
            'requiresPairing': true,
          },
        );
        roundMatches.add(match);
      }
      
      rounds.add(TournamentRound(
        id: _generateRoundId(tournamentId, round, 'swiss'),
        roundNumber: round,
        name: 'Swiss Vòng $round',
        type: 'swiss',
        matches: roundMatches,
        metadata: {
          "pairingMethod": 'score_based',
          'requiresPairing': true,
        },
      ));
    }
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.swiss,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'swiss',
        'totalRounds': totalRounds,
        'matchesPerRound': matchesPerRound,
        "pairingSystem": 'score_based',
        'allowRematch': false,
      },
    );
  }

  static Future<TournamentBracket> _generateParallelGroupsBracket(
    String tournamentId, {
    required List<TournamentParticipant> participants,
    Map<String, dynamic>? options,
  }) async() {
    debugPrint('$_tag: Generating parallel groups bracket');
    
    final playerCount = participants.length;
    final groupSize = options?['groupSize'] ?? 4;
    final groupCount = (playerCount / groupSize).ceil();
    final playersPerGroup = playerCount ~/ groupCount;
    
    debugPrint('$_tag: $playerCount players, $groupCount groups, ~$playersPerGroup players per group');
    
    final rounds = <TournamentRound>[];
    
    // Divide participants into groups
    final groups = <List<TournamentParticipant>>[];
    for (int i = 0; i < groupCount; i++) {
      groups.add(<TournamentParticipant>[]);
    }
    
    // Distribute players evenly across groups (snake draft style)
    for (int i = 0; i < participants.length; i++) {
      final groupIndex = i % groupCount;
      groups[groupIndex].add(participants[i]);
    }
    
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      if (group.length < 2) continue;
      
      // Generate round robin for each group
      final groupSchedule = _generateRoundRobinSchedule(group);
      
      for (int roundInGroup = 0; roundInGroup < groupSchedule.length; roundInGroup++) {
        final existingRound = rounds.firstWhere(
          (r) => r.roundNumber == roundInGroup + 1,
          orElse: () => TournamentRound(
            id: _generateRoundId(tournamentId, roundInGroup + 1, 'group'),
            roundNumber: roundInGroup + 1,
            name: 'Bảng đấu - Vòng ${roundInGroup + 1}',
            type: 'group',
            matches: [],
            metadata: {"phase": 'group_stage'},
          ),
        );
        
        // Add group matches to existing round or create new round
        final groupMatches = groupSchedule[roundInGroup];
        for (int matchIndex = 0; matchIndex < groupMatches.length; matchIndex++) {
          final pair = groupMatches[matchIndex];
          if (pair.length == 2) {
            final match = TournamentMatch(
              id: _generateMatchId(tournamentId, roundInGroup + 1, existingRound.matches.length + 1),
              roundId: existingRound.id,
              roundNumber: roundInGroup + 1,
              matchNumber: existingRound.matches.length + 1,
              player1: pair[0],
              player2: pair[1],
              status: 'pending',
              metadata: {
                "tournamentType": 'parallel_groups',
                'groupIndex': groupIndex,
                "groupName": 'Bảng ${String.fromCharCode(65 + groupIndex)}', // A, B, C...
                "phase": 'group_stage',
              },
            );
            existingRound.matches.add(match);
          }
        }
        
        // Add round if not already added
        if (!rounds.any((r) => r.id == existingRound.id)) {
          rounds.add(existingRound);
        }
      }
    }
    
    // Generate playoffs/finals stage
    final qualifiersPerGroup = options?['qualifiersPerGroup'] ?? 2;
    final totalQualifiers = (groupCount * qualifiersPerGroup).toInt();
    
    if (totalQualifiers >= 4) {
      // Generate playoff bracket for qualifiers
      final playoffRounds = _generatePlayoffRounds(
        tournamentId, 
        totalQualifiers, 
        rounds.length + 1
      );
      rounds.addAll(playoffRounds);
    }
    
    return TournamentBracket(
      tournamentId: tournamentId,
      format: TournamentFormats.parallelGroups,
      participants: participants,
      rounds: rounds,
      structure: {
        "type": 'parallel_groups',
        'groupCount': groupCount,
        'groupSize': playersPerGroup,
        'qualifiersPerGroup': qualifiersPerGroup,
        'hasPlayoffs': totalQualifiers >= 4,
        'phases': ['group_stage', 'playoffs'],
      },
    );
  }

  /// Generate playoff rounds for parallel groups
  static List<TournamentRound> _generatePlayoffRounds(
    String tournamentId,
    int qualifierCount,
    int startingRoundNumber,
  ) {
    final rounds = <TournamentRound>[];
    final bracketSize = _nearestPowerOfTwo(qualifierCount);
    
    var currentRound = startingRoundNumber;
    var playersRemaining = bracketSize;
    
    while (playersRemaining > 1) {
      final matchesInRound = playersRemaining ~/ 2;
      final roundMatches = <TournamentMatch>[];
      
      for (int i = 0; i < matchesInRound; i++) {
        final match = TournamentMatch(
          id: _generateMatchId(tournamentId, currentRound, i + 1),
          roundId: _generateRoundId(tournamentId, currentRound, 'playoff'),
          roundNumber: currentRound,
          matchNumber: i + 1,
          status: 'pending',
          metadata: {
            "tournamentType": 'parallel_groups',
            "phase": 'playoffs',
          },
        );
        roundMatches.add(match);
      }
      
      final roundName = playersRemaining == 2 
          ? 'Chung kết' 
          : playersRemaining == 4 
              ? 'Bán kết' 
              : playersRemaining == 8 
                  ? "Tứ kết"
                  : 'Playoff Vòng $currentRound';
      
      rounds.add(TournamentRound(
        id: _generateRoundId(tournamentId, currentRound, 'playoff'),
        roundNumber: currentRound,
        name: roundName,
        type: 'playoff',
        matches: roundMatches,
        metadata: {"phase": 'playoffs'},
      ));
      
      currentRound++;
      playersRemaining ~/= 2;
    }
    
    return rounds;
  }

  // ==================== SABO DOUBLE ELIMINATION DE16 HELPERS ====================

  /// Generate Winners Bracket for Sabo DE16 (14 matches: 8+4+2)
  static List<TournamentRound> _generateSaboWinnersBracket(
    String tournamentId, 
    List<TournamentParticipant> participants
  ) {
    final rounds = <TournamentRound>[];
    
    // WR1: 8 matches (16 → 8) - Using traditional seeding
    final wr1matches = <TournamentMatch>[];
    final seedPairs = [
      [1, 16], [2, 15], [3, 14], [4, 13],
      [5, 12], [6, 11], [7, 10], [8, 9]
    ];
    
    for (int i = 0; i < 8; i++) {
      final seed1 = seedPairs[i][0] - 1; // Convert to 0-based index
      final seed2 = seedPairs[i][1] - 1;
      
      final match = TournamentMatch(
        id: 'WR1M${i + 1}',
        roundId: _generateRoundId(tournamentId, 1, 'winners'),
        roundNumber: 1,
        matchNumber: i + 1,
        player1: participants[seed1],
        player2: participants[seed2],
        status: 'pending',
        metadata: {
          "bracketType": 'winners',
          "saboMatchId": 'WR1M${i + 1}',
          "seedMatch": '${seedPairs[i][0]} vs ${seedPairs[i][1]}'
        },
      );
      wr1matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 1, 'winners'),
      roundNumber: 1,
      name: 'Winners Round 1',
      type: 'winners',
      matches: wr1matches,
      metadata: {'matchCount': 8, "advancement": '8 to WR2, 8 to LA'}
    ));
    
    // WR2: 4 matches (8 → 4)
    final wr2matches = <TournamentMatch>[];
    for (int i = 0; i < 4; i++) {
      final match = TournamentMatch(
        id: 'WR2M${i + 1}',
        roundId: _generateRoundId(tournamentId, 2, 'winners'),
        roundNumber: 2,
        matchNumber: i + 1,
        player1: null, // Will be filled from WR1 results
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'winners',
          "saboMatchId": 'WR2M${i + 1}',
          'dependsOn': ['WR1M${i * 2 + 1}', 'WR1M${i * 2 + 2}']
        },
      );
      wr2matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 2, 'winners'),
      roundNumber: 2,
      name: 'Winners Round 2',
      type: 'winners',
      matches: wr2matches,
      metadata: {'matchCount': 4, "advancement": '4 to WR3, 4 to LB'}
    ));
    
    // WR3: 2 matches (4 → 2) - SEMIFINALS - No Winners Final!
    final wr3matches = <TournamentMatch>[];
    for (int i = 0; i < 2; i++) {
      final match = TournamentMatch(
        id: 'WR3M${i + 1}',
        roundId: _generateRoundId(tournamentId, 3, 'winners'),
        roundNumber: 3,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'winners',
          "saboMatchId": 'WR3M${i + 1}',
          'isSemifinal': true,
          'dependsOn': ['WR2M${i * 2 + 1}', 'WR2M${i * 2 + 2}']
        },
      );
      wr3matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 3, 'winners'),
      roundNumber: 3,
      name: 'Winners Semifinals',
      type: 'winners',
      matches: wr3matches,
      metadata: {'matchCount': 2, "advancement": '2 to SABO Finals', 'isLast': true}
    ));
    
    return rounds;
  }

  /// Generate Losers Branch A (7 matches: 4+2+1) - handles WR1 losers
  static List<TournamentRound> _generateSaboLosersBranchA(String tournamentId) {
    final rounds = <TournamentRound>[];
    
    // LAR101: 4 matches (8 → 4) - WR1 losers
    final lar101matches = <TournamentMatch>[];
    for (int i = 0; i < 4; i++) {
      final match = TournamentMatch(
        id: 'LAR101M${i + 1}',
        roundId: _generateRoundId(tournamentId, 101, 'losers_a'),
        roundNumber: 101,
        matchNumber: i + 1,
        player1: null, // Filled from WR1 losers
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'losers_branch_a',
          "saboMatchId": 'LAR101M${i + 1}',
          "source": 'WR1_losers',
          'dependsOn': ['WR1M${i * 2 + 1}', 'WR1M${i * 2 + 2}']
        },
      );
      lar101matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 101, 'losers_a'),
      roundNumber: 101,
      name: 'Losers Branch A Round 1',
      type: 'losers_a',
      matches: lar101matches,
      metadata: {'matchCount': 4, "source": 'Winners Round 1 losers'}
    ));
    
    // LAR102: 2 matches (4 → 2)
    final lar102matches = <TournamentMatch>[];
    for (int i = 0; i < 2; i++) {
      final match = TournamentMatch(
        id: 'LAR102M${i + 1}',
        roundId: _generateRoundId(tournamentId, 102, 'losers_a'),
        roundNumber: 102,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'losers_branch_a',
          "saboMatchId": 'LAR102M${i + 1}',
          'dependsOn': ['LAR101M${i * 2 + 1}', 'LAR101M${i * 2 + 2}']
        },
      );
      lar102matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 102, 'losers_a'),
      roundNumber: 102,
      name: 'Losers Branch A Round 2',
      type: 'losers_a',
      matches: lar102matches,
      metadata: {'matchCount': 2}
    ));
    
    // LAR103: 1 match (2 → 1) - Branch A Final
    final lar103match = TournamentMatch(
      id: 'LAR103M1',
      roundId: _generateRoundId(tournamentId, 103, 'losers_a'),
      roundNumber: 103,
      matchNumber: 1,
      player1: null,
      player2: null,
      status: 'pending',
      metadata: {
        "bracketType": 'losers_branch_a',
        "saboMatchId": 'LAR103M1',
        'isBranchFinal': true,
        'dependsOn': ['LAR102M1', 'LAR102M2']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 103, 'losers_a'),
      roundNumber: 103,
      name: 'Losers Branch A Final',
      type: 'losers_a',
      matches: [lar103match],
      metadata: {'matchCount': 1, "advancement": '1 to SABO Finals'}
    ));
    
    return rounds;
  }

  /// Generate Losers Branch B (3 matches: 2+1) - handles WR2 losers
  static List<TournamentRound> _generateSaboLosersBranchB(String tournamentId) {
    final rounds = <TournamentRound>[];
    
    // LBR201: 2 matches (4 → 2) - WR2 losers
    final lbr201matches = <TournamentMatch>[];
    for (int i = 0; i < 2; i++) {
      final match = TournamentMatch(
        id: 'LBR201M${i + 1}',
        roundId: _generateRoundId(tournamentId, 201, 'losers_b'),
        roundNumber: 201,
        matchNumber: i + 1,
        player1: null, // Filled from WR2 losers
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'losers_branch_b',
          "saboMatchId": 'LBR201M${i + 1}',
          "source": 'WR2_losers',
          'dependsOn': ['WR2M${i * 2 + 1}', 'WR2M${i * 2 + 2}']
        },
      );
      lbr201matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 201, 'losers_b'),
      roundNumber: 201,
      name: 'Losers Branch B Round 1',
      type: 'losers_b',
      matches: lbr201matches,
      metadata: {'matchCount': 2, "source": 'Winners Round 2 losers'}
    ));
    
    // LBR202: 1 match (2 → 1) - Branch B Final
    final lbr202match = TournamentMatch(
      id: 'LBR202M1',
      roundId: _generateRoundId(tournamentId, 202, 'losers_b'),
      roundNumber: 202,
      matchNumber: 1,
      player1: null,
      player2: null,
      status: 'pending',
      metadata: {
        "bracketType": 'losers_branch_b',
        "saboMatchId": 'LBR202M1',
        'isBranchFinal': true,
        'dependsOn': ['LBR201M1', 'LBR201M2']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 202, 'losers_b'),
      roundNumber: 202,
      name: 'Losers Branch B Final',
      type: 'losers_b',
      matches: [lbr202match],
      metadata: {'matchCount': 1, "advancement": '1 to SABO Finals'}
    ));
    
    return rounds;
  }

  /// Generate SABO Finals (3 matches: 2 semifinals + 1 final)
  static List<TournamentRound> _generateSaboFinalsRounds(String tournamentId) {
    final rounds = <TournamentRound>[];
    
    // SABO Semifinals: 2 matches
    final semifinalMatches = <TournamentMatch>[];
    
    // Semifinal 1: WB Winner 1 vs LA Branch Winner
    final semi1 = TournamentMatch(
      id: 'SEMI1',
      roundId: _generateRoundId(tournamentId, 250, 'sabo_finals'),
      roundNumber: 250,
      matchNumber: 1,
      player1: null, // From WR3M1 winner
      player2: null, // From LAR103M1 winner
      status: 'pending',
      metadata: {
        "bracketType": 'sabo_finals',
        "saboMatchId": 'SEMI1',
        'isSemifinal': true,
        "matchup": 'WB_Winner_1 vs Branch_A_Winner',
        'dependsOn': ['WR3M1', 'LAR103M1']
      },
    );
    
    // Semifinal 2: WB Winner 2 vs LB Branch Winner
    final semi2 = TournamentMatch(
      id: 'SEMI2',
      roundId: _generateRoundId(tournamentId, 251, 'sabo_finals'),
      roundNumber: 251,
      matchNumber: 1,
      player1: null, // From WR3M2 winner
      player2: null, // From LBR202M1 winner
      status: 'pending',
      metadata: {
        "bracketType": 'sabo_finals',
        "saboMatchId": 'SEMI2',
        'isSemifinal': true,
        "matchup": 'WB_Winner_2 vs Branch_B_Winner',
        'dependsOn': ['WR3M2', 'LBR202M1']
      },
    );
    
    semifinalMatches.addAll([semi1, semi2]);
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 250, 'sabo_finals'),
      roundNumber: 250,
      name: 'SABO Semifinals',
      type: 'sabo_finals',
      matches: semifinalMatches,
      metadata: {'matchCount': 2, "phase": 'semifinals'}
    ));
    
    // SABO Final: 1 match
    final saboFinal = TournamentMatch(
      id: 'FINAL1',
      roundId: _generateRoundId(tournamentId, 300, 'sabo_finals'),
      roundNumber: 300,
      matchNumber: 1,
      player1: null, // SEMI1 winner
      player2: null, // SEMI2 winner
      status: 'pending',
      metadata: {
        "bracketType": 'sabo_finals',
        "saboMatchId": 'FINAL1',
        'isFinal': true,
        'isChampionship': true,
        'dependsOn': ['SEMI1', 'SEMI2']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 300, 'sabo_finals'),
      roundNumber: 300,
      name: 'SABO Final',
      type: 'sabo_finals',
      matches: [saboFinal],
      metadata: {'matchCount': 1, "phase": 'final', 'isChampionship': true}
    ));
    
    return rounds;
  }

  // ==================== SABO DOUBLE ELIMINATION DE32 HELPERS ====================

  /// Generate one group (A or B) for Sabo DE32 (26 matches: modified DE16 → 2 qualifiers)
  static List<TournamentRound> _generateSaboDE32Group(
    String tournamentId, 
    String groupId,
    List<TournamentParticipant> participants
  ) {
    final rounds = <TournamentRound>[];
    
    // Modified DE16 structure producing exactly 26 matches per group
    // Winners Bracket (15 matches: 8+4+2+1)
    final winnerRounds = _generateSaboDE32WinnersBracket(tournamentId, groupId, participants);
    rounds.addAll(winnerRounds);
    
    // Losers Bracket (11 matches: 4+4+2+1) - simplified structure
    final losersRounds = _generateSaboDE32LosersBracket(tournamentId, groupId);
    rounds.addAll(losersRounds);
    
    return rounds;
  }

  /// Generate Winners Bracket for DE32 Group (15 matches: 8+4+2+1)
  static List<TournamentRound> _generateSaboDE32WinnersBracket(
    String tournamentId,
    String groupId, 
    List<TournamentParticipant> participants
  ) {
    final rounds = <TournamentRound>[];
    
    // WR1: 8 matches (16 → 8)
    final wr1matches = <TournamentMatch>[];
    final seedPairs = [
      [1, 16], [2, 15], [3, 14], [4, 13],
      [5, 12], [6, 11], [7, 10], [8, 9]
    ];
    
    for (int i = 0; i < 8; i++) {
      final seed1 = seedPairs[i][0] - 1;
      final seed2 = seedPairs[i][1] - 1;
      
      final match = TournamentMatch(
        id: '$groupId-WR1M${i + 1}',
        roundId: _generateRoundId(tournamentId, 1, 'winners_$groupId'),
        roundNumber: 1,
        matchNumber: i + 1,
        player1: participants[seed1],
        player2: participants[seed2],
        status: 'pending',
        metadata: {
          "bracketType": 'winners',
          'groupId': groupId,
          "saboMatchId": '$groupId-WR1M${i + 1}',
          "seedMatch": '${seedPairs[i][0]} vs ${seedPairs[i][1]}'
        },
      );
      wr1matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 1, 'winners_$groupId'),
      roundNumber: 1,
      name: 'Group $groupId Winners Round 1',
      type: 'winners',
      matches: wr1matches,
      metadata: {'groupId': groupId, 'matchCount': 8}
    ));
    
    // WR2: 4 matches (8 → 4)
    final wr2matches = <TournamentMatch>[];
    for (int i = 0; i < 4; i++) {
      final match = TournamentMatch(
        id: '$groupId-WR2M${i + 1}',
        roundId: _generateRoundId(tournamentId, 2, 'winners_$groupId'),
        roundNumber: 2,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'winners',
          'groupId': groupId,
          "saboMatchId": '$groupId-WR2M${i + 1}',
          'dependsOn': ['$groupId-WR1M${i * 2 + 1}', '$groupId-WR1M${i * 2 + 2}']
        },
      );
      wr2matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 2, 'winners_$groupId'),
      roundNumber: 2,
      name: 'Group $groupId Winners Round 2',
      type: 'winners',
      matches: wr2matches,
      metadata: {'groupId': groupId, 'matchCount': 4}
    ));
    
    // WR3: 2 matches (4 → 2) - SEMIFINALS
    final wr3matches = <TournamentMatch>[];
    for (int i = 0; i < 2; i++) {
      final match = TournamentMatch(
        id: '$groupId-WR3M${i + 1}',
        roundId: _generateRoundId(tournamentId, 3, 'winners_$groupId'),
        roundNumber: 3,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'winners',
          'groupId': groupId,
          "saboMatchId": '$groupId-WR3M${i + 1}',
          'isSemifinal': true,
          'dependsOn': ['$groupId-WR2M${i * 2 + 1}', '$groupId-WR2M${i * 2 + 2}']
        },
      );
      wr3matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 3, 'winners_$groupId'),
      roundNumber: 3,
      name: 'Group $groupId Winners Semifinals',
      type: 'winners',
      matches: wr3matches,
      metadata: {'groupId': groupId, 'matchCount': 2}
    ));
    
    // Winners Final: 1 match (2 → 1) - Determines Group Winner
    final wfMatch = TournamentMatch(
      id: '$groupId-WF',
      roundId: _generateRoundId(tournamentId, 4, 'winners_$groupId'),
      roundNumber: 4,
      matchNumber: 1,
      player1: null,
      player2: null,
      status: 'pending',
      metadata: {
        "bracketType": 'winners',
        'groupId': groupId,
        "saboMatchId": '$groupId-WF',
        'isGroupFinal': true,
        "advancement": 'Group Winner (1st Qualifier)',
        'dependsOn': ['$groupId-WR3M1', '$groupId-WR3M2']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 4, 'winners_$groupId'),
      roundNumber: 4,
      name: 'Group $groupId Winners Final',
      type: 'winners',
      matches: [wfMatch],
      metadata: {'groupId': groupId, 'matchCount': 1, "advancement": '1st Qualifier'}
    ));
    
    return rounds;
  }

  /// Generate Losers Bracket for DE32 Group (11 matches: 4+4+2+1)
  static List<TournamentRound> _generateSaboDE32LosersBracket(String tournamentId, String groupId) {
    final rounds = <TournamentRound>[];
    
    // LR1: 4 matches - initial losers from WR1
    final lr1matches = <TournamentMatch>[];
    for (int i = 0; i < 4; i++) {
      final match = TournamentMatch(
        id: '$groupId-L${i + 1}',
        roundId: _generateRoundId(tournamentId, 101, 'losers_$groupId'),
        roundNumber: 101,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'losers',
          'groupId': groupId,
          "saboMatchId": '$groupId-L${i + 1}',
          'dependsOn': ['$groupId-WR1M${i * 2 + 1}', '$groupId-WR1M${i * 2 + 2}']
        },
      );
      lr1matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 101, 'losers_$groupId'),
      roundNumber: 101,
      name: 'Group $groupId Losers Round 1',
      type: 'losers',
      matches: lr1matches,
      metadata: {'groupId': groupId, 'matchCount': 4}
    ));
    
    // LR2: 4 matches - second round losers
    final lr2matches = <TournamentMatch>[];
    for (int i = 0; i < 4; i++) {
      final match = TournamentMatch(
        id: '$groupId-L${4 + i + 1}',
        roundId: _generateRoundId(tournamentId, 102, 'losers_$groupId'),
        roundNumber: 102,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'losers',
          'groupId': groupId,
          "saboMatchId": '$groupId-L${4 + i + 1}',
          'dependsOn': i < 2 ? ['$groupId-L${i + 1}', '$groupId-WR2M${i + 1}'] : ['$groupId-L${i + 1}', '$groupId-WR2M${i + 1}']
        },
      );
      lr2matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 102, 'losers_$groupId'),
      roundNumber: 102,
      name: 'Group $groupId Losers Round 2',
      type: 'losers',
      matches: lr2matches,
      metadata: {'groupId': groupId, 'matchCount': 4}
    ));
    
    // LR3: 2 matches - third round
    final lr3matches = <TournamentMatch>[];
    for (int i = 0; i < 2; i++) {
      final match = TournamentMatch(
        id: '$groupId-L${8 + i + 1}',
        roundId: _generateRoundId(tournamentId, 103, 'losers_$groupId'),
        roundNumber: 103,
        matchNumber: i + 1,
        player1: null,
        player2: null,
        status: 'pending',
        metadata: {
          "bracketType": 'losers',
          'groupId': groupId,
          "saboMatchId": '$groupId-L${8 + i + 1}',
          'dependsOn': ['$groupId-L${4 + i * 2 + 1}', '$groupId-L${4 + i * 2 + 2}']
        },
      );
      lr3matches.add(match);
    }
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 103, 'losers_$groupId'),
      roundNumber: 103,
      name: 'Group $groupId Losers Round 3',
      type: 'losers',
      matches: lr3matches,
      metadata: {'groupId': groupId, 'matchCount': 2}
    ));
    
    // Losers Final: 1 match - Determines 2nd Qualifier
    final lfMatch = TournamentMatch(
      id: '$groupId-LF',
      roundId: _generateRoundId(tournamentId, 104, 'losers_$groupId'),
      roundNumber: 104,
      matchNumber: 1,
      player1: null,
      player2: null,
      status: 'pending',
      metadata: {
        "bracketType": 'losers',
        'groupId': groupId,
        "saboMatchId": '$groupId-LF',
        'isGroupLosersFinal': true,
        "advancement": '2nd Qualifier',
        'dependsOn': ['$groupId-L9', '$groupId-L10']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 104, 'losers_$groupId'),
      roundNumber: 104,
      name: 'Group $groupId Losers Final',
      type: 'losers',
      matches: [lfMatch],
      metadata: {'groupId': groupId, 'matchCount': 1, "advancement": '2nd Qualifier'}
    ));
    
    return rounds;
  }







  /// Generate Cross-Bracket Finals for DE32 (3 matches: 2 semifinals + 1 final)
  static List<TournamentRound> _generateSaboDE32CrossBracket(String tournamentId) {
    final rounds = <TournamentRound>[];
    
    // Semifinal 1: Group A Winner 1 vs Group B Winner 1
    final semifinal1 = TournamentMatch(
      id: 'SF1',
      roundId: _generateRoundId(tournamentId, 350, 'cross_bracket'),
      roundNumber: 350,
      matchNumber: 1,
      player1: null, // From A-FINAL1 winner
      player2: null, // From B-FINAL1 winner
      status: 'pending',
      metadata: {
        "bracketType": 'cross_bracket',
        "saboMatchId": 'SF1',
        'isSemifinal': true,
        "matchup": 'Group_A_Winner_1 vs Group_B_Winner_1',
        'dependsOn': ['A-FINAL1', 'B-FINAL1']
      },
    );
    
    // Semifinal 2: Group A Winner 2 vs Group B Winner 2
    final semifinal2 = TournamentMatch(
      id: 'SF2',
      roundId: _generateRoundId(tournamentId, 351, 'cross_bracket'),
      roundNumber: 351,
      matchNumber: 1,
      player1: null, // From A-FINAL2 winner
      player2: null, // From B-FINAL2 winner
      status: 'pending',
      metadata: {
        "bracketType": 'cross_bracket',
        "saboMatchId": 'SF2',
        'isSemifinal': true,
        "matchup": 'Group_A_Winner_2 vs Group_B_Winner_2',
        'dependsOn': ['A-FINAL2', 'B-FINAL2']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 350, 'cross_bracket'),
      roundNumber: 350,
      name: 'DE32 Semifinals',
      type: 'cross_bracket',
      matches: [semifinal1, semifinal2],
      metadata: {'matchCount': 2, "phase": 'semifinals'}
    ));
    
    // DE32 Final
    final de32Final = TournamentMatch(
      id: 'FINAL',
      roundId: _generateRoundId(tournamentId, 400, 'cross_bracket'),
      roundNumber: 400,
      matchNumber: 1,
      player1: null, // SF1 winner
      player2: null, // SF2 winner
      status: 'pending',
      metadata: {
        "bracketType": 'cross_bracket',
        "saboMatchId": 'FINAL',
        'isFinal': true,
        'isChampionship': true,
        'dependsOn': ['SF1', 'SF2']
      },
    );
    
    rounds.add(TournamentRound(
      id: _generateRoundId(tournamentId, 400, 'cross_bracket'),
      roundNumber: 400,
      name: 'DE32 Final',
      type: 'cross_bracket',
      matches: [de32Final],
      metadata: {'matchCount': 1, "phase": 'final', 'isChampionship': true}
    ));
    
    return rounds;
  }

  /// Generic tournament advancement method
  /// Analyzes current tournament state and creates next round if ready
  Future<Map<String, dynamic>> advanceTournament({
    required String tournamentId,
    required List<TournamentParticipant> participants,
    required List<TournamentMatch> currentMatches,
    required String format,
  }) async() {
    try() {
      // Group matches by round
      final roundsMap = <int, List<TournamentMatch>>{};
      for (final match in currentMatches) {
        final roundNum = match.roundNumber;
        if (!roundsMap.containsKey(roundNum)) {
          roundsMap[roundNum] = [];
        }
        roundsMap[roundNum]!.add(match);
      }

      final sortedRounds = roundsMap.keys.toList()..sort();
      
      if (sortedRounds.isEmpty) {
        return() {
          'success': false,
          "message": 'No matches found in tournament',
          'newMatches': <TournamentMatch>[],
        };
      }

      // Find the highest completed round
      int? completedRound;
      for (final roundNum in sortedRounds.reversed) {
        final roundMatches = roundsMap[roundNum]!;
        final completedCount = roundMatches.where((m) => m.status == 'completed').length;
        
        if (completedCount == roundMatches.length) {
          // This round is fully completed
          completedRound = roundNum;
          break;
        }
      }

      if (completedRound == null) {
        return() {
          'success': false,
          "message": 'No completed rounds found. Wait for current matches to finish.',
          'newMatches': <TournamentMatch>[],
        };
      }

      // Check if next round already exists
      final nextRoundNum = completedRound + 1;
      if (roundsMap.containsKey(nextRoundNum)) {
        return() {
          'success': false,
          "message": 'Next round already exists',
          'newMatches': <TournamentMatch>[],
        };
      }

      // Generate next round based on format
      return await _generateNextRound(
        tournamentId: tournamentId,
        participants: participants,
        completedRound: completedRound,
        completedMatches: roundsMap[completedRound]!,
        format: format,
        allMatches: currentMatches,
      );

    } catch (e) {
      return() {
        'success': false,
        "message": 'Error advancing tournament: $e',
        'newMatches': <TournamentMatch>[],
      };
    }
  }

  /// Generate next round matches based on tournament format
  Future<Map<String, dynamic>> _generateNextRound({
    required String tournamentId,
    required List<TournamentParticipant> participants,
    required int completedRound,
    required List<TournamentMatch> completedMatches,
    required String format,
    required List<TournamentMatch> allMatches,
  }) async() {
    final nextRoundNum = completedRound + 1;

    // Extract winners from completed matches
    final winners = <TournamentParticipant>[];
    for (final match in completedMatches) {
      if (match.winner != null) {
        winners.add(match.winner!);
      }
    }

    if (winners.isEmpty) {
      return() {
        'success': false,
        "message": 'No winners found in completed matches',
        'newMatches': <TournamentMatch>[],
      };
    }

    // Format-specific logic
    switch (format.toLowerCase()) {
      case 'single_elimination':
      case 'single elimination':
        return _generateSingleEliminationNextRound(
          tournamentId: tournamentId,
          roundNumber: nextRoundNum,
          winners: winners,
          completedRound: completedRound,
        );

      case 'double_elimination':
      case 'double elimination':
        return _generateDoubleEliminationNextRound(
          tournamentId: tournamentId,
          roundNumber: nextRoundNum,
          winners: winners,
          completedMatches: completedMatches,
          allMatches: allMatches,
        );

      case 'round_robin':
      case 'round robin':
        return() {
          'success': false,
          "message": 'Round Robin tournaments do not advance - all matches are scheduled at once',
          'newMatches': <TournamentMatch>[],
        };

      case 'swiss_system':
      case 'swiss system':
        return _generateSwissSystemNextRound(
          tournamentId: tournamentId,
          roundNumber: nextRoundNum,
          participants: participants,
          allMatches: allMatches,
        );

      case 'sabo_de16':
      case 'sabo_de32':
        return _generateSaboNextRound(
          tournamentId: tournamentId,
          roundNumber: nextRoundNum,
          winners: winners,
          format: format,
          completedRound: completedRound,
        );

      default:
        return() {
          'success': false,
          "message": 'Unsupported tournament format: $format',
          'newMatches': <TournamentMatch>[],
        };
    }
  }

  /// Generate next round for Single Elimination with Vietnamese titles
  Map<String, dynamic> _generateSingleEliminationNextRound({
    required String tournamentId,
    required int roundNumber,
    required List<TournamentParticipant> winners,
    required int completedRound,
  }) {
    if (winners.length < 2) {
      return() {
        'success': false,
        "message": 'Need at least 2 winners to create next round',
        'newMatches': <TournamentMatch>[],
      };
    }

    if (winners.length == 1) {
      return() {
        'success': true,
        "message": '🏆 Tournament completed! Winner: ${winners.first.name}',
        'newMatches': <TournamentMatch>[],
        'isCompleted': true,
        'winner': winners.first,
      };
    }

    final matches = <TournamentMatch>[];
    final matchCount = winners.length ~/ 2;

    // Determine Vietnamese round name using demo logic
    String roundName = _calculateVietnameseRoundTitle(winners.length);
    
    print('🚀 Generating $roundName with ${winners.length} players → $matchCount matches');

    // Create matches by pairing winners sequentially
    for (int i = 0; i < matchCount; i++) {
      final player1 = winners[i * 2];
      final player2 = winners[i * 2 + 1];

      final match = TournamentMatch(
        id: 'R${roundNumber}M${i + 1}',
        roundId: _generateRoundId(tournamentId, roundNumber, 'main'),
        roundNumber: roundNumber,
        matchNumber: i + 1,
        player1: player1,
        player2: player2,
        status: 'pending',
        metadata: {
          'roundName': roundName,
          "matchName": '$roundName - Match ${i + 1}',
          'totalMatches': matchCount,
        },
      );

      matches.add(match);
    }

    return() {
      'success': true,
      "message": 'Created $roundName with $matchCount matches',
      'newMatches': matches,
      'roundName': roundName,
      'roundNumber': roundNumber,
    };
  }

  /// Generate next round for Double Elimination (simplified)
  Map<String, dynamic> _generateDoubleEliminationNextRound({
    required String tournamentId,
    required int roundNumber,
    required List<TournamentParticipant> winners,
    required List<TournamentMatch> completedMatches,
    required List<TournamentMatch> allMatches,
  }) {
    // This is a simplified implementation
    // Full double elimination requires tracking winners and losers brackets
    return() {
      'success': false,
      "message": 'Double Elimination advancement requires more complex logic - implement based on specific needs',
      'newMatches': <TournamentMatch>[],
    };
  }

  /// Generate next round for Swiss System
  Map<String, dynamic> _generateSwissSystemNextRound({
    required String tournamentId,
    required int roundNumber,
    required List<TournamentParticipant> participants,
    required List<TournamentMatch> allMatches,
  }) {
    // Swiss system pairs players based on performance
    return() {
      'success': false,
      "message": 'Swiss System advancement requires performance tracking - implement based on specific needs',
      'newMatches': <TournamentMatch>[],
    };
  }

  /// Generate next round for SABO formats
  Map<String, dynamic> _generateSaboNextRound({
    required String tournamentId,
    required int roundNumber,
    required List<TournamentParticipant> winners,
    required String format,
    required int completedRound,
  }) {
    // SABO formats follow specific progression rules
    return() {
      'success': false,
      "message": 'SABO format advancement requires specific implementation - implement based on SABO rules',
      'newMatches': <TournamentMatch>[],
    };
  }

  /// Calculate Vietnamese round title based on player count (from demo logic)
  String _calculateVietnameseRoundTitle(int playerCount) {
    if (playerCount == 2) {
      return 'Chung kết';
    } else if (playerCount == 4) {
      return 'Bán kết';
    } else if (playerCount == 8) {
      return 'Tứ kết';
    } else() {
      // Calculate round number for early rounds
      int roundNum = 1;
      int originalPlayers = playerCount;
      
      // Find original tournament size by working backwards
      while (originalPlayers > 16) {
        originalPlayers = originalPlayers * 2;
      }
      
      // Calculate current round number from original size
      int tempPlayers = originalPlayers;
      while (tempPlayers > playerCount) {
        tempPlayers = tempPlayers ~/ 2;
        roundNum++;
      }
      
      return 'Vòng $roundNum';
    }
  }

  /// Generate all tournament rounds structure (from demo logic)
  List<Map<String, dynamic>> calculateAllTournamentRounds(int initialPlayerCount) {
    final rounds = <Map<String, dynamic>>[];
    int currentPlayers = initialPlayerCount;
    int roundNumber = 1;
    
    while (currentPlayers > 1) {
      String title = _calculateVietnameseRoundTitle(currentPlayers);
      int matchCount = currentPlayers ~/ 2;
      
      rounds.add({
        'round': roundNumber,
        'title': title,
        'players': currentPlayers,
        'matches': matchCount,
        'winners': matchCount,
      });
      
      currentPlayers = matchCount;
      roundNumber++;
    }
    
    return rounds;
  }
}