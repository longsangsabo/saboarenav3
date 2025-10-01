
import 'dart:convert';

class Match {
  final String id;
  final String? tournamentId;
  final String player1Id;
  final String player2Id;
  final String? player1Name;
  final String? player2Name;
  final int? player1Score;
  final int? player2Score;
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled', 'no_show'
  final String? winnerId;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int round;
  final String matchType; // 'group_stage', 'quarter_final', 'semi_final', 'final', 'third_place'
  final String? venue;
  final String? table;
  final int? durationMinutes;
  final String? notes;
  final List<String>? videoUrls;
  final Map<String, dynamic>? gameStats;
  final String? referee;
  final bool isLive;
  final int viewerCount;
  final Map<String, dynamic>? liveData;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Match({
    required this.id,
    this.tournamentId,
    required this.player1Id,
    required this.player2Id,
    this.player1Name,
    this.player2Name,
    this.player1Score,
    this.player2Score,
    required this.status,
    this.winnerId,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.round,
    required this.matchType,
    this.venue,
    this.table,
    this.durationMinutes,
    this.notes,
    this.videoUrls,
    this.gameStats,
    this.referee,
    required this.isLive,
    required this.viewerCount,
    this.liveData,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      tournamentId: json['tournament_id'],
      player1Id: json['player1_id'] ?? '',
      player2Id: json['player2_id'] ?? '',
      player1Name: json['player1_name'],
      player2Name: json['player2_name'],
      player1Score: json['player1_score'],
      player2Score: json['player2_score'],
      status: json['status'] ?? 'scheduled',
      winnerId: json['winner_id'],
      scheduledAt: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      round: json['round'] ?? 1,
      matchType: json['match_type'] ?? 'group_stage',
      venue: json['venue'],
      table: json['table'],
      durationMinutes: json['duration_minutes'],
      notes: json['notes'],
      videoUrls: json['video_urls'] != null ? List<String>.from(json['video_urls']) : null,
      gameStats: _parseGameStats(json['game_stats']),
      referee: json['referee'],
      isLive: json['is_live'] ?? false,
      viewerCount: json['viewer_count'] ?? 0,
      liveData: _parseLiveData(json['live_data']),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  static Map<String, dynamic>? _parseGameStats(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _parseLiveData(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        return jsonDecode(value) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'tournament_id': tournamentId,
      'player1_id': player1Id,
      'player2_id': player2Id,
      'player1_name': player1Name,
      'player2_name': player2Name,
      'player1_score': player1Score,
      'player2_score': player2Score,
      'status': status,
      'winner_id': winnerId,
      'scheduled_time': scheduledAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'round': round,
      'match_type': matchType,
      'venue': venue,
      'table': table,
      'duration_minutes': durationMinutes,
      'notes': notes,
      'video_urls': videoUrls,
      'game_stats': gameStats != null ? jsonEncode(gameStats) : null,
      'referee': referee,
      'is_live': isLive,
      'viewer_count': viewerCount,
      'live_data': liveData != null ? jsonEncode(liveData) : null,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Match copyWith({
    String? id,
    String? tournamentId,
    String? player1Id,
    String? player2Id,
    String? player1Name,
    String? player2Name,
    int? player1Score,
    int? player2Score,
    String? status,
    String? winnerId,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? round,
    String? matchType,
    String? venue,
    String? table,
    int? durationMinutes,
    String? notes,
    List<String>? videoUrls,
    Map<String, dynamic>? gameStats,
    String? referee,
    bool? isLive,
    int? viewerCount,
    Map<String, dynamic>? liveData,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Match(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      player1Name: player1Name ?? this.player1Name,
      player2Name: player2Name ?? this.player2Name,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      round: round ?? this.round,
      matchType: matchType ?? this.matchType,
      venue: venue ?? this.venue,
      table: table ?? this.table,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      videoUrls: videoUrls ?? this.videoUrls,
      gameStats: gameStats ?? this.gameStats,
      referee: referee ?? this.referee,
      isLive: isLive ?? this.isLive,
      viewerCount: viewerCount ?? this.viewerCount,
      liveData: liveData ?? this.liveData,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Match && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Match(id: $id, ${player1Name ?? player1Id} vs ${player2Name ?? player2Id}, status: $status)';
  }

  // Computed properties for UI
  bool get isScheduled => status == 'scheduled';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  String get statusDisplay() {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return 'Unknown';
    }
  }

  String get matchTypeDisplay() {
    switch (matchType) {
      case 'group_stage':
        return 'Group Stage';
      case 'quarter_final':
        return 'Quarter Final';
      case 'semi_final':
        return 'Semi Final';
      case 'final':
        return 'Final';
      case 'third_place':
        return 'Third Place';
      default:
        return 'Match';
    }
  }

  String get roundDisplay => 'Round $round';

  String get scoreDisplay() {
    if (player1Score == null || player2Score == null) {
      return 'vs';
    }
    return '$player1Score - $player2Score';
  }

  String get matchupDisplay() {
    final p1 = player1Name ?? 'Player 1';
    final p2 = player2Name ?? 'Player 2';
    return '$p1 vs $p2';
  }

  bool get hasWinner => winnerId != null && winnerId!.isNotEmpty;

  String? get winnerName() {
    if (!hasWinner) return null;
    if (winnerId == player1Id) return player1Name ?? 'Player 1';
    if (winnerId == player2Id) return player2Name ?? 'Player 2';
    return null;
  }

  String? get loserName() {
    if (!hasWinner) return null;
    if (winnerId == player1Id) return player2Name ?? 'Player 2';
    if (winnerId == player2Id) return player1Name ?? 'Player 1';
    return null;
  }

  bool get player1Won => winnerId == player1Id;
  bool get player2Won => winnerId == player2Id;

  bool get hasScheduledTime => scheduledAt != null;
  bool get hasActualStartTime => startedAt != null;
  bool get hasCompletionTime => completedAt != null;

  Duration? get actualDuration() {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  String get durationDisplay() {
    if (durationMinutes != null) {
      final hours = durationMinutes! ~/ 60;
      final minutes = durationMinutes! % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }
    
    final duration = actualDuration;
    if (duration != null) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${minutes}m';
    }
    
    return 'Unknown';
  }

  bool get hasVenue => venue != null && venue!.isNotEmpty;
  bool get hasTable => table != null && table!.isNotEmpty;
  bool get hasReferee => referee != null && referee!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get hasVideos => videoUrls != null && videoUrls!.isNotEmpty;

  String get venueDisplay() {
    final parts = <String>[];
    if (hasVenue) parts.add(venue!);
    if (hasTable) parts.add('Table $table');
    return parts.join(' - ');
  }

  List<String> get matchVideos => videoUrls ?? [];
  Map<String, dynamic> get statistics => gameStats ?? {};
  Map<String, dynamic> get currentLiveData => liveData ?? {};

  bool get canStart => isScheduled && !isLive;
  bool get canComplete => isInProgress;
  bool get canCancel => isScheduled || isInProgress;

  String get timeUntilMatch() {
    if (scheduledAt == null) return 'No scheduled time';
    
    final now = DateTime.now();
    if (scheduledAt!.isBefore(now)) return 'Match time passed';
    
    final difference = scheduledAt!.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours';
    } else() {
      return '${difference.inDays} days';
    }
  }

  int get totalScore => (player1Score ?? 0) + (player2Score ?? 0);

  bool get isHighScoringMatch => totalScore > 20; // Assuming ping pong scoring

  String get competitiveLevel() {
    if (matchType == 'final') return 'Championship';
    if (matchType == 'semi_final') return 'Semi-Final';
    if (matchType == 'quarter_final') return 'Quarter-Final';
    return 'Regular';
  }
}
