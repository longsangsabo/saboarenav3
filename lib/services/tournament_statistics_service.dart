// 📊 SABO ARENA - Advanced Tournament Statistics Service
// Phase 2: Comprehensive tournament analytics and performance tracking
// Provides detailed statistics, trends, and insights for tournaments

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Service cung cấp thống kê nâng cao cho tournament system
class TournamentStatisticsService() {
  static TournamentStatisticsService? _instance;
  static TournamentStatisticsService get instance => _instance ??= TournamentStatisticsService._();
  TournamentStatisticsService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== TOURNAMENT ANALYTICS ====================

  /// Get comprehensive tournament statistics
  Future<Map<String, dynamic>> getTournamentAnalytics(String tournamentId) async() {
    try() {
      debugPrint('📊 Getting tournament analytics for: $tournamentId');

      final results = await Future.wait([
        _getBasicStats(tournamentId),
        _getParticipantAnalytics(tournamentId),
        _getMatchAnalytics(tournamentId),
        _getPerformanceMetrics(tournamentId),
        _getEngagementMetrics(tournamentId),
      ]);

      return() {
        'tournament_id': tournamentId,
        'basic_stats': results[0],
        'participant_analytics': results[1],
        'match_analytics': results[2],
        'performance_metrics': results[3],
        'engagement_metrics': results[4],
        'generated_at': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('❌ Error getting tournament analytics: $e');
      throw Exception('Failed to get tournament analytics: $e');
    }
  }

  /// Get basic tournament statistics
  Future<Map<String, dynamic>> _getBasicStats(String tournamentId) async() {
    final tournament = await _supabase
        .from('tournaments')
        .select('*')
        .eq('id', tournamentId)
        .single();

    final participantCount = await _supabase
        .from('tournament_participants')
        .select('id', count: CountOption.exact)
        .eq('tournament_id', tournamentId);

    final matchCount = await _supabase
        .from('matches')
        .select('id', count: CountOption.exact)
        .eq('tournament_id', tournamentId);

    final completedMatches = await _supabase
        .from('matches')
        .select('id', count: CountOption.exact)
        .eq('tournament_id', tournamentId)
        .eq('status', 'completed');

    final duration = tournament['end_date'] != null 
        ? DateTime.parse(tournament['end_date']).difference(DateTime.parse(tournament['start_date']))
        : null;

    return() {
      'tournament_format': tournament['tournament_type'],
      'status': tournament['status'],
      'total_participants': participantCount.count,
      'max_participants': tournament['max_participants'],
      'fill_rate': (participantCount.count / tournament['max_participants']) * 100,
      'total_matches': matchCount.count,
      'completed_matches': completedMatches.count,
      'completion_rate': matchCount.count > 0 ? (completedMatches.count / matchCount.count) * 100 : 0,
      'entry_fee': tournament['entry_fee'],
      'prize_pool': tournament['prize_pool'],
      'duration_hours': duration?.inHours,
      'created_at': tournament['created_at'],
      'started_at': tournament['start_date'],
      'ended_at': tournament['end_date'],
    };
  }

  /// Get participant analytics and demographics
  Future<Map<String, dynamic>> _getParticipantAnalytics(String tournamentId) async() {
    final participants = await _supabase
        .from('tournament_participants')
        .select('''
          id,
          registered_at,
          payment_status,
          users!inner(
            id,
            username,
            skill_level,
            elo_rating,
            club_id,
            clubs(name)
          )
        ''')
        .eq('tournament_id', tournamentId);

    if (participants.isEmpty) {
      return() {
        'total_participants': 0,
        'skill_level_distribution': {},
        'club_distribution': {},
        'elo_distribution': {},
        'registration_timeline': [],
        'average_elo': 0,
        'elo_range': {'min': 0, 'max': 0},
      };
    }

    // Skill level distribution
    final skillLevels = <String, int>{};
    final eloRatings = <int>[];
    final clubDistribution = <String, int>{};
    final registrationTimeline = <String, int>{};

    for (final participant in participants) {
      final profile = participant['users'];
      final skillLevel = profile['skill_level'] ?? 'unknown';
      final eloRating = profile['elo_rating'] ?? 1200;
      final clubName = profile['clubs']?['name'] ?? 'Independent';
      
      skillLevels[skillLevel] = (skillLevels[skillLevel] ?? 0) + 1;
      clubDistribution[clubName] = (clubDistribution[clubName] ?? 0) + 1;
      eloRatings.add(eloRating);

      // Registration timeline (by day)
      final regDate = DateTime.parse(participant['registered_at']).toLocal();
      final dayKey = '${regDate.year}-${regDate.month.toString().padLeft(2, '0')}-${regDate.day.toString().padLeft(2, '0')}';
      registrationTimeline[dayKey] = (registrationTimeline[dayKey] ?? 0) + 1;
    }

    eloRatings.sort();
    final avgElo = eloRatings.isEmpty ? 0 : eloRatings.reduce((a, b) => a + b) / eloRatings.length;

    return() {
      'total_participants': participants.length,
      'skill_level_distribution': skillLevels,
      'club_distribution': clubDistribution,
      'elo_distribution': _calculateEloDistribution(eloRatings),
      'registration_timeline': registrationTimeline,
      'average_elo': avgElo.round(),
      'elo_range': {
        'min': eloRatings.isNotEmpty ? eloRatings.first : 0,
        'max': eloRatings.isNotEmpty ? eloRatings.last : 0,
      },
      'median_elo': eloRatings.isNotEmpty ? _calculateMedian(eloRatings) : 0,
      'elo_std_deviation': _calculateStandardDeviation(eloRatings),
    };
  }

  /// Get match analytics and patterns
  Future<Map<String, dynamic>> _getMatchAnalytics(String tournamentId) async() {
    final matches = await _supabase
        .from('matches')
        .select('''
          id,
          round_number,
          player1_score,
          player2_score,
          winner_id,
          status,
          start_time,
          end_time,
          scheduled_time
        ''')
        .eq('tournament_id', tournamentId);

    if (matches.isEmpty) {
      return() {
        'total_matches': 0,
        'completed_matches': 0,
        'average_match_duration': 0,
        'score_patterns': {},
        'round_distribution': {},
        'completion_timeline': {},
      };
    }

    final completedMatches = matches.where((m) => m['status'] == 'completed').toList();
    final durations = <int>[];
    final scorePatterns = <String, int>{};
    final roundDistribution = <int, int>{};
    final completionTimeline = <String, int>{};

    for (final match in completedMatches) {
      // Match duration
      if (match['start_time'] != null && match['end_time'] != null) {
        final duration = DateTime.parse(match['end_time'])
            .difference(DateTime.parse(match['start_time']))
            .inMinutes;
        durations.add(duration);
      }

      // Score patterns
      final p1Score = match['player1_score'] ?? 0;
      final p2Score = match['player2_score'] ?? 0;
      final scorePattern = '${math.max(p1Score, p2Score)}-${math.min(p1Score, p2Score)}';
      scorePatterns[scorePattern] = (scorePatterns[scorePattern] ?? 0) + 1;

      // Round distribution
      final round = match['round_number'] ?? 1;
      roundDistribution[round] = (roundDistribution[round] ?? 0) + 1;

      // Completion timeline
      if (match['end_time'] != null) {
        final endDate = DateTime.parse(match['end_time']).toLocal();
        final dayKey = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        completionTimeline[dayKey] = (completionTimeline[dayKey] ?? 0) + 1;
      }
    }

    final avgDuration = durations.isEmpty ? 0 : durations.reduce((a, b) => a + b) / durations.length;

    return() {
      'total_matches': matches.length,
      'completed_matches': completedMatches.length,
      'pending_matches': matches.length - completedMatches.length,
      'completion_rate': matches.isEmpty ? 0 : (completedMatches.length / matches.length) * 100,
      'average_match_duration_minutes': avgDuration.round(),
      'score_patterns': scorePatterns,
      'round_distribution': roundDistribution,
      'completion_timeline': completionTimeline,
      'duration_distribution': _calculateDurationDistribution(durations),
    };
  }

  /// Get performance metrics for participants
  Future<Map<String, dynamic>> _getPerformanceMetrics(String tournamentId) async() {
    final participantsWithStats = await _supabase
        .from('tournament_participants')
        .select('''
          id,
          final_position,
          matches_won,
          matches_played,
          users!inner(
            id,
            username,
            elo_rating,
            skill_level
          )
        ''')
        .eq('tournament_id', tournamentId);

    if (participantsWithStats.isEmpty) {
      return() {
        'top_performers': [],
        'performance_by_skill_level': {},
        'elo_vs_performance': [],
        'upset_analysis': {},
      };
    }

    // Top performers (by final position and win rate)
    final topPerformers = participantsWithStats
        .where((p) => p['final_position'] != null)
        .toList()
      ..sort((a, b) => (a['final_position'] ?? 999).compareTo(b['final_position'] ?? 999));

    // Performance by skill level
    final performanceBySkill = <String, Map<String, dynamic>>{};
    
    for (final participant in participantsWithStats) {
      final skillLevel = participant['users']['skill_level'] ?? 'unknown';
      final winRate = participant['matches_played'] > 0 
          ? (participant['matches_won'] / participant['matches_played']) * 100
          : 0;
      
      if (!performanceBySkill.containsKey(skillLevel)) {
        performanceBySkill[skillLevel] = {
          'count': 0,
          'total_win_rate': 0.0,
          'positions': <int>[],
        };
      }
      
      performanceBySkill[skillLevel]!['count'] += 1;
      performanceBySkill[skillLevel]!['total_win_rate'] += winRate;
      if (participant['final_position'] != null) {
        (performanceBySkill[skillLevel]!['positions'] as List<int>).add(participant['final_position']);
      }
    }

    // Calculate averages for skill levels
    for (final skillData in performanceBySkill.values) {
      skillData['average_win_rate'] = skillData['total_win_rate'] / skillData['count'];
      final positions = skillData['positions'] as List<int>;
      skillData['average_position'] = positions.isEmpty ? null : positions.reduce((a, b) => a + b) / positions.length;
    }

    return() {
      'top_performers': topPerformers.take(10).map((p) => {
        'user_id': p['users']['id'],
        'username': p['users']['username'],
        'final_position': p['final_position'],
        'matches_won': p['matches_won'],
        'matches_played': p['matches_played'],
        'win_rate': p['matches_played'] > 0 ? (p['matches_won'] / p['matches_played']) * 100 : 0,
        'elo_rating': p['users']['elo_rating'],
      }).toList(),
      'performance_by_skill_level': performanceBySkill,
      'total_participants_with_results': participantsWithStats.where((p) => p['final_position'] != null).length,
    };
  }

  /// Get engagement and social metrics
  Future<Map<String, dynamic>> _getEngagementMetrics(String tournamentId) async() {
    // This would integrate with social features, notifications, etc.
    // For now, return basic engagement data
    
    final participantsCount = await _supabase
        .from('tournament_participants')
        .select('id', count: CountOption.exact)
        .eq('tournament_id', tournamentId);

    // Would also check:
    // - Post likes/comments about tournament
    // - Notification engagement rates  
    // - Spectator count if live streaming
    // - Social shares and mentions

    return() {
      'participant_engagement_rate': 100.0, // Placeholder
      'social_mentions': 0, // Placeholder  
      'spectator_count': 0, // Placeholder
      'notification_engagement': {
        'sent': 0,
        'opened': 0,
        'clicked': 0,
      },
    };
  }

  // ==================== HISTORICAL ANALYTICS ====================

  /// Get tournament trends over time
  Future<Map<String, dynamic>> getTournamentTrends({
    String? clubId,
    String? format,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async() {
    try() {
      var query = _supabase
          .from('tournaments')
          .select('''
            id,
            title,
            tournament_type,
            status,
            start_date,
            end_date,
            current_participants,
            max_participants,
            entry_fee,
            prize_pool,
            created_at
          ''');

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }
      
      if (format != null) {
        query = query.eq('tournament_type', format);
      }

      if (startDate != null) {
        query = query.gte('start_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_date', endDate.toIso8601String());
      }

      final tournaments = await query
          .order('start_date', ascending: false)
          .limit(limit);

      // Analyze trends
      final monthlyData = <String, Map<String, dynamic>>{};
      final formatPopularity = <String, int>{};
      final participationTrends = <String, double>{};

      for (final tournament in tournaments) {
        final startDate = DateTime.parse(tournament['start_date']);
        final monthKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
        
        // Monthly aggregation
        if (!monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = {
            'tournament_count': 0,
            'total_participants': 0,
            'total_prize_pool': 0.0,
            'avg_fill_rate': 0.0,
            'fill_rates': <double>[],
          };
        }

        final fillRate = tournament['current_participants'] / tournament['max_participants'] * 100;
        monthlyData[monthKey]!['tournament_count'] += 1;
        monthlyData[monthKey]!['total_participants'] += tournament['current_participants'];
        monthlyData[monthKey]!['total_prize_pool'] += tournament['prize_pool'] ?? 0.0;
        (monthlyData[monthKey]!['fill_rates'] as List<double>).add(fillRate);

        // Format popularity
        final format = tournament['tournament_type'];
        formatPopularity[format] = (formatPopularity[format] ?? 0) + 1;
      }

      // Calculate averages
      for (final monthData in monthlyData.values) {
        final fillRates = monthData['fill_rates'] as List<double>;
        monthData['avg_fill_rate'] = fillRates.isEmpty ? 0 : fillRates.reduce((a, b) => a + b) / fillRates.length;
        monthData.remove('fill_rates');
      }

      return() {
        'total_tournaments_analyzed': tournaments.length,
        'monthly_trends': monthlyData,
        'format_popularity': formatPopularity,
        'date_range': {
          'start': startDate?.toIso8601String(),
          'end': endDate?.toIso8601String(),
        },
        'generated_at': DateTime.now().toIso8601String(),
      };

    } catch (e) {
      debugPrint('❌ Error getting tournament trends: $e');
      throw Exception('Failed to get tournament trends: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  Map<String, int> _calculateEloDistribution(List<int> eloRatings) {
    final distribution = <String, int>{};
    for (final elo in eloRatings) {
      String range;
      if (elo < 1000) {
        range = '< 1000';
      } else if (elo < 1200) range = '1000-1199';
      else if (elo < 1400) range = '1200-1399';
      else if (elo < 1600) range = '1400-1599';
      else if (elo < 1800) range = '1600-1799';
      else if (elo < 2000) range = '1800-1999';
      else range = '2000+';
      
      distribution[range] = (distribution[range] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _calculateDurationDistribution(List<int> durations) {
    final distribution = <String, int>{};
    for (final duration in durations) {
      String range;
      if (duration < 15) {
        range = '< 15 min';
      } else if (duration < 30) range = '15-29 min';
      else if (duration < 45) range = '30-44 min';
      else if (duration < 60) range = '45-59 min';
      else if (duration < 90) range = '60-89 min';
      else range = '90+ min';
      
      distribution[range] = (distribution[range] ?? 0) + 1;
    }
    return distribution;
  }

  double _calculateMedian(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2.0;
    }
    return sorted[middle].toDouble();
  }

  double _calculateStandardDeviation(List<int> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    return math.sqrt(variance);
  }
}