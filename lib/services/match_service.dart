class Match {
  final String id;
  final String tournamentId;
  final String? player1Id;
  final String? player2Id;
  final String? winnerId;
  final int player1Score;
  final int player2Score;
  final int roundNumber;
  final int matchNumber;
  final String status;
  final DateTime? scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields from joins
  final String? player1Name;
  final String? player2Name;
  final String? winnerName;
  final String? tournamentTitle;

  const Match({
    required this.id,
    required this.tournamentId,
    this.player1Id,
    this.player2Id,
    this.winnerId,
    required this.player1Score,
    required this.player2Score,
    required this.roundNumber,
    required this.matchNumber,
    required this.status,
    this.scheduledTime,
    this.startTime,
    this.endTime,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.player1Name,
    this.player2Name,
    this.winnerName,
    this.tournamentTitle,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      tournamentId: json['tournament_id'] ?? '',
      player1Id: json['player1_id'],
      player2Id: json['player2_id'],
      winnerId: json['winner_id'],
      player1Score: json['player1_score'] ?? 0,
      player2Score: json['player2_score'] ?? 0,
      roundNumber: json['round_number'] ?? 1,
      matchNumber: json['match_number'] ?? 1,
      status: json['status'] ?? 'pending',
      scheduledTime:
          json['scheduled_at'] != null // Fixed: scheduled_time -> scheduled_at
              ? DateTime.parse(json['scheduled_at'])
              : null,
      startTime: json['started_at'] != null // Fixed: start_time -> started_at
          ? DateTime.parse(json['started_at'])
          : null,
      endTime: json['completed_at'] != null // Fixed: end_time -> completed_at
          ? DateTime.parse(json['completed_at'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      player1Name: json['player1']?['full_name'],
      player2Name: json['player2']?['full_name'],
      winnerName: json['winner']?['full_name'],
      tournamentTitle: json['tournament']?['title'],
    );
  }
}

class MatchService {
  static MatchService? _instance;
  static MatchService get instance => _instance ??= MatchService._();
  MatchService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Match>> getTournamentMatches(String tournamentId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (full_name),
            player2:users!matches_player2_id_fkey (full_name),
            winner:users!matches_winner_id_fkey (full_name),
            tournament:tournaments (title)
          ''')
          .eq('tournament_id', tournamentId)
          .order('round_number')
          .order('match_number');

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get tournament matches: $error');
    }
  }

  Future<List<Match>> getUserMatches(String userId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (full_name),
            player2:users!matches_player2_id_fkey (full_name),
            winner:users!matches_winner_id_fkey (full_name),
            tournament:tournaments (title)
          ''')
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get user matches: $error');
    }
  }

  Future<List<Match>> getLiveMatches({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (full_name),
            player2:users!matches_player2_id_fkey (full_name),
            winner:users!matches_winner_id_fkey (full_name),
            tournament:tournaments (title)
          ''')
          .eq('status', 'in_progress')
          .order('start_time', ascending: false)
          .limit(limit);

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get live matches: $error');
    }
  }

  Future<List<Match>> getUpcomingMatches({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            player1:users!matches_player1_id_fkey (full_name),
            player2:users!matches_player2_id_fkey (full_name),
            winner:users!matches_winner_id_fkey (full_name),
            tournament:tournaments (title)
          ''')
          .eq('status',
              'pending') // REVERT: scheduled -> pending (correct enum)
          .gte(
              'scheduled_time',
              DateTime.now()
                  .toIso8601String()) // REVERT: scheduled_at -> scheduled_time
          .order('scheduled_time') // REVERT: scheduled_at -> scheduled_time
          .limit(limit);

      return response.map<Match>((json) => Match.fromJson(json)).toList();
    } catch (error) {
      throw Exception('Failed to get upcoming matches: $error');
    }
  }

  Future<Match> updateMatchScore({
    required String matchId,
    required int player1Score,
    required int player2Score,
    String? winnerId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = {
        'player1_score': player1Score,
        'player2_score': player2Score,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (winnerId != null) {
        updateData['winner_id'] = winnerId;
        updateData['status'] = 'completed';
        updateData['end_time'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('matches')
          .update(updateData)
          .eq('id', matchId)
          .select('''
            *,
            player1:users!matches_player1_id_fkey (full_name),
            player2:users!matches_player2_id_fkey (full_name),
            winner:users!matches_winner_id_fkey (full_name),
            tournament:tournaments (title)
          ''').single();

      return Match.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update match score: $error');
    }
  }

  Future<Match> startMatch(String matchId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('matches')
          .update({
            "status": 'in_progress',
            'start_time': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId)
          .select('''
            *,
            player1:users!matches_player1_id_fkey (full_name),
            player2:users!matches_player2_id_fkey (full_name),
            winner:users!matches_winner_id_fkey (full_name),
            tournament:tournaments (title)
          ''')
          .single();

      return Match.fromJson(response);
    } catch (error) {
      throw Exception('Failed to start match: $error');
    }
  }
}
