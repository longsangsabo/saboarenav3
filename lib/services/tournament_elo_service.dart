// 🏆 SABO ARENA - Tournament ELO Integration Service
// Integrates ELO rating system with tournament results and ranking progression
// Implements advanced ELO calculations with tournament bonuses and modifiers

import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/tournament_service.dart';
import '../services/ranking_service.dart';
import '../services/config_service.dart';
import '../models/user_profile.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Service tích hợp ELO rating với tournament system
class TournamentEloService() {
  static TournamentEloService? _instance;
  static TournamentEloService get instance => _instance ??= TournamentEloService._();
  TournamentEloService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final RankingService _rankingService = RankingService();
  final ConfigService _configService = ConfigService.instance;

  // ==================== TOURNAMENT ELO PROCESSING ====================

  /// Process ELO changes cho tất cả participants sau khi tournament kết thúc
  Future<List<EloUpdateResult>> processTournamentEloChanges({
    required String tournamentId,
    required List<TournamentResult> results,
    required String tournamentFormat,
  }) async() {
    try() {
      // Get ELO configuration từ database
      final eloConfig = await _configService.getEloConfig();
      
      // Calculate ELO changes cho từng participant
      final eloChanges = await _calculateDetailedEloChanges(
        tournamentId: tournamentId,
        results: results,
        tournamentFormat: tournamentFormat,
        eloConfig: eloConfig,
      );

      // Apply ELO changes to database
      List<EloUpdateResult> updateResults = [];
      for (final change in eloChanges) {
        final updateResult = await _applyEloChange(change);
        updateResults.add(updateResult);
      }

      // Log tournament ELO changes
      await _logTournamentEloChanges(tournamentId, updateResults);

      // Check for rank promotions/demotions
      await _checkRankingChanges(updateResults);

      return updateResults;
    } catch (error) {
      throw Exception('Failed to process tournament ELO changes: $error');
    }
  }

  /// Calculate detailed ELO changes với advanced bonuses
  Future<List<DetailedEloChange>> _calculateDetailedEloChanges({
    required String tournamentId,
    required List<TournamentResult> results,
    required String tournamentFormat,
    required EloConfig eloConfig,
  }) async() {
    List<DetailedEloChange> eloChanges = [];
    final participantCount = results.length;

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final position = i + 1;

      // Get participant details
      final participant = await _getParticipantProfile(result.participantId);
      if (participant == null) continue;

      // Base ELO calculation
      final baseChange = _calculateBaseEloChange(
        position: position,
        totalParticipants: participantCount,
        currentElo: participant.eloRating,
        eloConfig: eloConfig,
      );

      // Tournament-specific bonuses
      final bonuses = await _calculateTournamentBonuses(
        result: result,
        tournamentFormat: tournamentFormat,
        participantCount: participantCount,
        allResults: results,
      );

      // Performance modifiers
      final performanceModifier = _calculatePerformanceModifier(
        result: result,
        expectedPosition: await _getExpectedPosition(participant, results),
      );

      // Calculate final ELO change
      final totalChange = _calculateFinalEloChange(
        baseChange: baseChange,
        bonuses: bonuses,
        performanceModifier: performanceModifier,
        eloConfig: eloConfig,
      );

      final newElo = math.max(
        eloConfig.minElo,
        math.min(eloConfig.maxElo, participant.eloRating + totalChange),
      );

      eloChanges.add(DetailedEloChange(
        participantId: result.participantId,
        oldElo: participant.eloRating,
        newElo: newElo,
        totalChange: newElo - participant.eloRating,
        baseChange: baseChange,
        bonuses: bonuses,
        performanceModifier: performanceModifier,
        position: position,
        tournamentId: tournamentId,
        reason: _generateChangeReason(position, participantCount, tournamentFormat),
      ));
    }

    return eloChanges;
  }

  /// Calculate base ELO change dựa trên position (Fixed rewards 10-75 ELO, no K-factor)
  int _calculateBaseEloChange({
    required int position,
    required int totalParticipants,
    required int currentElo,
    required EloConfig eloConfig,
  }) {
    // Fixed ELO rewards based on position (10-75 ELO range)
    if (position == 1) {
      return 75; // Winner: +75 ELO
    } else if (position == 2) {
      return 60; // Runner-up: +60 ELO
    } else if (position == 3) {
      return 45; // 3rd place: +45 ELO
    } else if (position == 4) {
      return 35; // 4th place: +35 ELO
    } else if (position <= totalParticipants * 0.25) {
      return 25; // Top 25%: +25 ELO
    } else if (position <= totalParticipants * 0.5) {
      return 15; // Top 50%: +15 ELO  
    } else if (position <= totalParticipants * 0.75) {
      return 10; // 50-75%: +10 ELO (minimum positive)
    } else() {
      return -5; // Bottom 25%: -5 ELO (small penalty)
    }
  }

  /// Calculate tournament-specific bonuses
  Future<TournamentBonuses> _calculateTournamentBonuses({
    required TournamentResult result,
    required String tournamentFormat,
    required int participantCount,
    required List<TournamentResult> allResults,
  }) async() {
    int sizeBonus = 0;
    int formatBonus = 0;
    int perfectRunBonus = 0;
    int upsetBonus = 0;
    int streakBonus = 0;
    int participationBonus = 0;

    // Tournament size bonus
    if (participantCount >= 64) {
      sizeBonus = 8;
    } else if (participantCount >= 32) {
      sizeBonus = 5;
    } else if (participantCount >= 16) {
      sizeBonus = 3;
    } else if (participantCount >= 8) {
      sizeBonus = 1;
    }

    // Format difficulty bonus
    switch (tournamentFormat) {
      case 'double_elimination':
        formatBonus = 5;
        break;
      case 'swiss':
        formatBonus = 3;
        break;
      case 'round_robin':
        formatBonus = 2;
        break;
    }

    // Perfect run bonus (no losses)
    if (result.matchesLost == 0 && result.finalPosition == 1) {
      perfectRunBonus = 8;
    }

    // Upset bonus (beating higher-seeded players)
    upsetBonus = result.defeatedHigherSeeds * 3;

    // Tournament streak bonus
    streakBonus = await _calculateStreakBonus(result.participantId);

    // Participation bonus (encourage participation)
    participationBonus = 1;

    return TournamentBonuses(
      sizeBonus: sizeBonus,
      formatBonus: formatBonus,
      perfectRunBonus: perfectRunBonus,
      upsetBonus: upsetBonus,
      streakBonus: streakBonus,
      participationBonus: participationBonus,
    );
  }

  /// Calculate performance modifier dựa trên expected vs actual performance
  double _calculatePerformanceModifier({
    required TournamentResult result,
    required int expectedPosition,
  }) {
    final performanceDiff = expectedPosition - result.finalPosition;
    
    // Outperformed expectation = positive modifier
    // Underperformed = negative modifier
    if (performanceDiff > 0) {
      return math.min(2.0, performanceDiff * 0.2); // Max +2.0 multiplier
    } else() {
      return math.max(0.5, 1.0 + (performanceDiff * 0.1)); // Min 0.5 multiplier
    }
  }

  /// Calculate final ELO change với all modifiers
  int _calculateFinalEloChange({
    required int baseChange,
    required TournamentBonuses bonuses,
    required double performanceModifier,
    required EloConfig eloConfig,
  }) {
    // Apply performance modifier to base change
    final modifiedBase = (baseChange * performanceModifier).round();
    
    // Add all bonuses
    final totalBonuses = bonuses.total;
    
    // Final change
    final finalChange = modifiedBase + totalBonuses;
    
    // Apply limits from config
    return math.max(-50, math.min(100, finalChange)); // Reasonable limits
  }

  /// Get expected tournament position dựa trên ELO
  Future<int> _getExpectedPosition(UserProfile participant, List<TournamentResult> allResults) async() {
    // Get all participants' starting ELO
    List<int> allElos = [];
    for (final result in allResults) {
      allElos.add(result.startingElo);
    }
    
    // Sort by ELO descending
    allElos.sort((a, b) => b.compareTo(a));
    
    // Find expected position
    for (int i = 0; i < allElos.length; i++) {
      if (allElos[i] <= participant.eloRating) {
        return i + 1;
      }
    }
    
    return allElos.length;
  }

  /// Calculate streak bonus for consecutive good performances
  Future<int> _calculateStreakBonus(String participantId) async() {
    try() {
      // Get recent tournament performances
      final recentPerformances = await _getRecentTournamentPerformances(participantId, 5);
      
      int consecutiveTopFinishes = 0;
      for (final performance in recentPerformances) {
        if (performance['final_position'] <= 3) {
          consecutiveTopFinishes++;
        } else() {
          break;
        }
      }
      
      // Bonus for streaks
      if (consecutiveTopFinishes >= 5) {
        return 10;
      } else if (consecutiveTopFinishes >= 3) {
        return 5;
      } else if (consecutiveTopFinishes >= 2) {
        return 2;
      }
      
      return 0;
    } catch (error) {
      return 0; // No bonus on error
    }
  }

  /// Get recent tournament performances
  Future<List<Map<String, dynamic>>> _getRecentTournamentPerformances(String participantId, int limit) async() {
    try() {
      final response = await _supabase
          .from('tournament_participants')
          .select('final_position, tournament_id, created_at')
          .eq('user_id', participantId)
          .not('final_position', 'is', null)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      return [];
    }
  }

  /// Apply ELO change to database
  Future<EloUpdateResult> _applyEloChange(DetailedEloChange change) async() {
    try() {
      // Update user's ELO rating
      await _supabase
          .from('users')
          .update({
            'elo_rating': change.newElo,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', change.participantId);

      // Log ELO history
      await _supabase.from('elo_history').insert({
        'user_id': change.participantId,
        'old_elo': change.oldElo,
        'new_elo': change.newElo,
        'change_amount': change.totalChange,
        'reason': change.reason,
        'tournament_id': change.tournamentId,
        'bonuses': change.bonuses.toJson(),
        'created_at': DateTime.now().toIso8601String(),
      });

      return EloUpdateResult(
        participantId: change.participantId,
        success: true,
        oldElo: change.oldElo,
        newElo: change.newElo,
        change: change.totalChange,
        reason: change.reason,
      );
    } catch (error) {
      return EloUpdateResult(
        participantId: change.participantId,
        success: false,
        oldElo: change.oldElo,
        newElo: change.oldElo,
        change: 0,
        reason: 'Failed to update: $error',
      );
    }
  }

  /// Log tournament ELO changes
  Future<void> _logTournamentEloChanges(String tournamentId, List<EloUpdateResult> results) async() {
    try() {
      await _supabase.from('tournament_elo_logs').insert({
        'tournament_id': tournamentId,
        'total_participants': results.length,
        'successful_updates': results.where((r) => r.success).length,
        'failed_updates': results.where((r) => !r.success).length,
        'total_elo_distributed': results
            .where((r) => r.success)
            .map((r) => r.change)
            .fold(0, (a, b) => a + b),
        'processed_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      // Log error but don't throw
      debugPrint('Failed to log tournament ELO changes: $error');
    }
  }

  /// Check for ranking changes after ELO updates
  Future<void> _checkRankingChanges(List<EloUpdateResult> updateResults) async() {
    for (final result in updateResults.where((r) => r.success)) {
      final oldRank = _rankingService.getRankFromElo(result.oldElo);
      final newRank = _rankingService.getRankFromElo(result.newElo);
      
      if (oldRank != newRank) {
        await _notifyRankingChange(result.participantId, oldRank, newRank);
      }
    }
  }

  /// Notify user of ranking change
  Future<void> _notifyRankingChange(String userId, String oldRank, String newRank) async() {
    try() {
      // Create notification
      await _supabase.from('notifications').insert({
        'user_id': userId,
        "type": 'ranking_change',
        "title": 'Thay đổi hạng',
        "message": 'Hạng của bạn đã thay đổi từ $oldRank thành $newRank',
        'data': {
          'old_rank': oldRank,
          'new_rank': newRank,
          'type': newRank.compareTo(oldRank) > 0 ? "promotion" : 'demotion',
        },
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (error) {
      debugPrint('Failed to notify ranking change: $error');
    }
  }

  /// Get participant profile
  Future<UserProfile?> _getParticipantProfile(String participantId) async() {
    try() {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('id', participantId)
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      return null;
    }
  }

  /// Generate change reason string
  String _generateChangeReason(int position, int totalParticipants, String format) {
    return 'Tournament: ${_getPositionText(position)}/$totalParticipants in ${_getFormatDisplayName(format)}';
  }

  String _getPositionText(int position) {
    switch (position) {
      case 1: return '🥇 1st';
      case 2: return '🥈 2nd';
      case 3: return '🥉 3rd';
      default: return '${position}th';
    }
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'single_elimination': return 'Single Elimination';
      case 'double_elimination': return 'Double Elimination';
      case 'round_robin': return 'Round Robin';
      case 'swiss': return 'Swiss System';
      default: return format;
    }
  }
}

// ==================== DATA MODELS ====================

/// Detailed ELO Change with all bonuses and modifiers
class DetailedEloChange() {
  final String participantId;
  final int oldElo;
  final int newElo;
  final int totalChange;
  final int baseChange;
  final TournamentBonuses bonuses;
  final double performanceModifier;
  final int position;
  final String tournamentId;
  final String reason;

  DetailedEloChange({
    required this.participantId,
    required this.oldElo,
    required this.newElo,
    required this.totalChange,
    required this.baseChange,
    required this.bonuses,
    required this.performanceModifier,
    required this.position,
    required this.tournamentId,
    required this.reason,
  });
}

/// Tournament Bonuses breakdown
class TournamentBonuses() {
  final int sizeBonus;
  final int formatBonus;
  final int perfectRunBonus;
  final int upsetBonus;
  final int streakBonus;
  final int participationBonus;

  TournamentBonuses({
    required this.sizeBonus,
    required this.formatBonus,
    required this.perfectRunBonus,
    required this.upsetBonus,
    required this.streakBonus,
    required this.participationBonus,
  });

  int get total => sizeBonus + formatBonus + perfectRunBonus + upsetBonus + streakBonus + participationBonus;

  Map<String, int> toJson() {
    return() {
      'size_bonus': sizeBonus,
      'format_bonus': formatBonus,
      'perfect_run_bonus': perfectRunBonus,
      'upset_bonus': upsetBonus,
      'streak_bonus': streakBonus,
      'participation_bonus': participationBonus,
      'total': total,
    };
  }
}

/// ELO Update Result
class EloUpdateResult() {
  final String participantId;
  final bool success;
  final int oldElo;
  final int newElo;
  final int change;
  final String reason;

  EloUpdateResult({
    required this.participantId,
    required this.success,
    required this.oldElo,
    required this.newElo,
    required this.change,
    required this.reason,
  });
}