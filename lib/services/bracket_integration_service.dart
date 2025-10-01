// 🚀 SABO ARENA - Bracket Integration Service
// Tích hợp BracketGeneratorService với database hiện tại


class BracketIntegrationService {
  static const String _tag = '🎯 BracketIntegration';
  static final _supabase = Supabase.instance.client;

  /// Calculate rank from ELO rating
  static String _calculateRankFromElo(int elo) {
    if (elo < 800) return 'Beginner';
    if (elo < 1000) return 'Amateur'; 
    if (elo < 1200) return 'Intermediate';
    if (elo < 1500) return 'Advanced';
    if (elo < 1800) return 'Expert';
    return 'Master';
  }

  /// Tạo và lưu bracket vào database
  static Future<Map<String, dynamic>> createTournamentBracket({
    required String tournamentId,
    required String format,
    required String seedingMethod,
    Map<String, dynamic>? options,
  }) async {
    try {
      debugPrint('$_tag: Creating bracket for tournament $tournamentId');

      // 1. Load tournament participants
      final participants = await _loadTournamentParticipants(tournamentId);
      debugPrint('$_tag: Loaded ${participants.length} participants');

      // 2. Generate bracket using existing service
      final bracket = await BracketGeneratorService.generateBracket(
        tournamentId: tournamentId,
        format: format,
        participants: participants,
        seedingMethod: seedingMethod,
        options: options,
      );

      // 3. Save bracket metadata to tournament
      await _saveBracketMetadata(tournamentId, bracket);

      // 4. Update participant seeding
      await _updateParticipantSeeding(tournamentId, bracket.participants);

      // 5. Create matches in database
      await _createBracketMatches(tournamentId, bracket);

      debugPrint('$_tag: ✅ Bracket created and saved successfully');

      return() {
        'success': true,
        'tournamentId': tournamentId,
        'format': format,
        'totalMatches': bracket.rounds.fold<int>(
          0, (sum, round) => sum + round.matches.length
        ),
        'totalRounds': bracket.rounds.length,
        'participants': bracket.participants.length,
      };

    } catch (e) {
      debugPrint('$_tag: ❌ Error creating bracket: $e');
      rethrow;
    }
  }

  /// Load participants from database and convert to TournamentParticipant
  static Future<List<TournamentParticipant>> _loadTournamentParticipants(
    String tournamentId
  ) async {
    // Get participants with user profile data
    final response = await _supabase
        .from('tournament_participants')
        .select('''
          *,
          users:user_id (
            id,
            email,
            full_name,
            elo_rating
          )
        ''')
        .eq('tournament_id', tournamentId)
        .eq('status', 'registered');

    if (response.isEmpty) {
      throw Exception('No registered participants found');
    }

    final participants = <TournamentParticipant>[];
    
    for (final participant in response) {
      final user = participant['users'];
      if (user != null) {
        participants.add(TournamentParticipant(
          id: user['id'],
          name: user['full_name'] ?? user['email'],
          rank: _calculateRankFromElo(user['elo_rating'] ?? 1000),
          elo: user['elo_rating'] ?? 1000,
          metadata: {
            'participantId': participant['id'],
            'paymentStatus': participant['payment_status'],
            'registeredAt': participant['registered_at'],
          },
        ));
      }
    }

    return participants;
  }

  /// Save bracket metadata to tournaments table
  static Future<void> _saveBracketMetadata(
    String tournamentId,
    TournamentBracket bracket,
  ) async {
    final bracketData = {
      'format': bracket.format,
      'structure': bracket.structure,
      'totalRounds': bracket.rounds.length,
      'totalMatches': bracket.rounds.fold<int>(
        0, (sum, round) => sum + round.matches.length
      ),
      'participantCount': bracket.participants.length,
      'generatedAt': DateTime.now().toIso8601String(),
      "generatedBy": 'BracketGeneratorService',
      'rounds': bracket.rounds.map((round) => {
        'id': round.id,
        'roundNumber': round.roundNumber,
        'name': round.name,
        'type': round.type,
        'matchCount': round.matches.length,
      }).toList(),
    };

    await _supabase
        .from('tournaments')
        .update({'bracket_data': bracketData})
        .eq('id', tournamentId);

    debugPrint('$_tag: ✅ Bracket metadata saved');
  }

  /// Update participant seeding information
  static Future<void> _updateParticipantSeeding(
    String tournamentId,
    List<TournamentParticipant> participants,
  ) async {
    final updates = participants.map((participant) {
      final participantId = participant.metadata?['participantId'];
      return() {
        'id': participantId,
        'bracket_seed': participant.seed,
        'bracket_metadata': {
          'eloAtSeeding': participant.elo,
          'rankAtSeeding': participant.rank,
          'bracketPosition': participant.seed,
          'seededAt': DateTime.now().toIso8601String(),
        },
      };
    }).toList();

    // Batch update participants
    for (final update in updates) {
      await _supabase
          .from('tournament_participants')
          .update({
            'bracket_seed': update['bracket_seed'],
            'bracket_metadata': update['bracket_metadata'],
          })
          .eq('id', update['id']);
    }

    debugPrint('$_tag: ✅ Participant seeding updated');
  }

  /// Create matches in database from bracket
  static Future<void> _createBracketMatches(
    String tournamentId,
    TournamentBracket bracket,
  ) async {
    final matches = <Map<String, dynamic>>[];

    for (final round in bracket.rounds) {
      for (final match in round.matches) {
        final matchData = {
          'id': match.id,
          'tournament_id': tournamentId,
          'round_number': match.roundNumber,
          'match_number': match.matchNumber,
          'player1_id': match.player1?.id,
          'player2_id': match.player2?.id,
          'winner_id': match.winner?.id,
          'status': match.status,
          'scheduled_time': match.scheduledTime?.toIso8601String(),
          'bracket_type': match.metadata?['bracketType'] ?? 'winner',
          'bracket_position': match.matchNumber,
          "match_type": 'tournament',
          'player1_score': 0,
          'player2_score': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        matches.add(matchData);
      }
    }

    // Insert matches in batches
    const batchSize = 50;
    for (int i = 0; i < matches.length; i += batchSize) {
      final batch = matches.skip(i).take(batchSize).toList();
      await _supabase.from('matches').insert(batch);
    }

    debugPrint('$_tag: ✅ Created ${matches.length} matches');
  }

  /// Load existing bracket from database
  static Future<Map<String, dynamic>?> loadTournamentBracket(
    String tournamentId
  ) async {
    try {
      // Get tournament bracket data
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('bracket_data, format')
          .eq('id', tournamentId)
          .single();

      if (tournamentResponse['bracket_data'] == null) {
        return null; // No bracket generated yet
      }

      // Get matches with participant data
      final matchesResponse = await _supabase
          .from('matches')
          .select('''
            *,
            player1:player1_id (id, full_name, elo_rating),
            player2:player2_id (id, full_name, elo_rating),
            winner:winner_id (id, full_name, elo_rating)
          ''')
          .eq('tournament_id', tournamentId)
          .eq('match_type', 'tournament')
          .order('round_number')
          .order('match_number');

      return() {
        'bracketData': tournamentResponse['bracket_data'],
        'format': tournamentResponse['format'],
        'matches': matchesResponse,
      };

    } catch (e) {
      debugPrint('$_tag: ❌ Error loading bracket: $e');
      return null;
    }
  }

  /// Update match result and progress bracket
  static Future<bool> updateMatchResult({
    required String matchId,
    required String winnerId,
    required int player1Score,
    required int player2Score,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('$_tag: Updating match $matchId with winner $winnerId');

      // Update match result
      await _supabase
          .from('matches')
          .update({
            'winner_id': winnerId,
            'player1_score': player1Score,
            'player2_score': player2Score,
            "status": 'completed',
            'end_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId);

      // TODO: Auto-progress to next round (future enhancement)
      await _progressBracket(matchId, winnerId);

      debugPrint('$_tag: ✅ Match result updated successfully');
      return true;

    } catch (e) {
      debugPrint('$_tag: ❌ Error updating match result: $e');
      return false;
    }
  }

  /// Progress bracket after match completion (placeholder for future)
  static Future<void> _progressBracket(String matchId, String winnerId) async {
    // TODO: Implement automatic bracket progression
    // - Find next round matches that need this winner
    // - Update player1_id or player2_id in next match
    // - Handle loser bracket progression for double elimination
    debugPrint('$_tag: TODO - Auto bracket progression for match $matchId');
  }

  /// Get bracket visualization data
  static Future<Map<String, dynamic>?> getBracketVisualizationData(
    String tournamentId
  ) async {
    final bracketData = await loadTournamentBracket(tournamentId);
    
    if (bracketData == null) return null;

    // Organize matches by rounds for visualization
    final matches = bracketData['matches'] as List;
    final roundsMap = <int, List<Map<String, dynamic>>>{};

    for (final match in matches) {
      final roundNumber = match['round_number'] as int;
      roundsMap.putIfAbsent(roundNumber, () => []);
      roundsMap[roundNumber]!.add(match);
    }

    return() {
      'format': bracketData['format'],
      'bracketData': bracketData['bracketData'],
      'rounds': roundsMap,
      'totalRounds': roundsMap.keys.length,
      'totalMatches': matches.length,
    };
  }
}