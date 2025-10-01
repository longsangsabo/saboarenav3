import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tournament.dart';
import '../models/match.dart';
import 'bracket_generator_service.dart';

/// Real-time Bracket Updates Service with WebSocket streaming
/// Phase 2 enhancement for live tournament updates
class RealtimeBracketService() {
  static final RealtimeBracketService _instance = RealtimeBracketService._internal();
  factory RealtimeBracketService() => _instance;
  RealtimeBracketService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, StreamController<List<Match>>> _matchControllers = {};
  final Map<String, StreamController<Tournament>> _tournamentControllers = {};
  final Map<String, StreamController<List<TournamentParticipant>>> _participantControllers = {};
  
  /// Subscribe to real-time match updates for a tournament
  Stream<List<Match>> getMatchUpdatesStream(String tournamentId) {
    if (!_matchControllers.containsKey(tournamentId)) {
      _matchControllers[tournamentId] = StreamController<List<Match>>.broadcast();
      _setupMatchSubscription(tournamentId);
    }
    return _matchControllers[tournamentId]!.stream;
  }

  /// Subscribe to real-time tournament updates
  Stream<Tournament> getTournamentUpdatesStream(String tournamentId) {
    if (!_tournamentControllers.containsKey(tournamentId)) {
      _tournamentControllers[tournamentId] = StreamController<Tournament>.broadcast();
      _setupTournamentSubscription(tournamentId);
    }
    return _tournamentControllers[tournamentId]!.stream;
  }

  /// Subscribe to real-time participant updates
  Stream<List<TournamentParticipant>> getParticipantUpdatesStream(String tournamentId) {
    if (!_participantControllers.containsKey(tournamentId)) {
      _participantControllers[tournamentId] = StreamController<List<TournamentParticipant>>.broadcast();
      _setupParticipantSubscription(tournamentId);
    }
    return _participantControllers[tournamentId]!.stream;
  }

  /// Setup WebSocket subscription for match updates
  void _setupMatchSubscription(String tournamentId) {
    _supabase
        .channel('matches_$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: tournamentId,
          ),
          callback: (payload) async() {
            debugPrint('🔄 Match update received for tournament $tournamentId');
            await _handleMatchUpdate(tournamentId, payload);
          },
        )
        .subscribe();
  }

  /// Setup WebSocket subscription for tournament updates
  void _setupTournamentSubscription(String tournamentId) {
    _supabase
        .channel('tournament_$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tournaments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: tournamentId,
          ),
          callback: (payload) async() {
            debugPrint('🔄 Tournament update received for $tournamentId');
            await _handleTournamentUpdate(tournamentId, payload);
          },
        )
        .subscribe();
  }

  /// Setup WebSocket subscription for participant updates
  void _setupParticipantSubscription(String tournamentId) {
    _supabase
        .channel('participants_$tournamentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tournament_participants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'tournament_id',
            value: tournamentId,
          ),
          callback: (payload) async() {
            debugPrint('🔄 Participant update received for tournament $tournamentId');
            await _handleParticipantUpdate(tournamentId, payload);
          },
        )
        .subscribe();
  }

  /// Handle match update from WebSocket
  Future<void> _handleMatchUpdate(String tournamentId, PostgresChangePayload payload) async() {
    try() {
      // Fetch updated matches
      final matchesResponse = await _supabase
          .from('matches')
          .select('*')
          .eq('tournament_id', tournamentId)
          .order('round')
          .order('match_number');

      final matches = (matchesResponse as List)
          .map((json) => Match.fromJson(json))
          .toList();

      // Emit updated matches
      if (_matchControllers.containsKey(tournamentId)) {
        _matchControllers[tournamentId]!.add(matches);
      }

      // Check if this update affects bracket progression
      await _checkBracketProgression(tournamentId, matches);
    } catch (e) {
      debugPrint('❌ Error handling match update: $e');
    }
  }

  /// Handle tournament update from WebSocket
  Future<void> _handleTournamentUpdate(String tournamentId, PostgresChangePayload payload) async() {
    try() {
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      final tournament = Tournament.fromJson(tournamentResponse);

      // Emit updated tournament
      if (_tournamentControllers.containsKey(tournamentId)) {
        _tournamentControllers[tournamentId]!.add(tournament);
      }
    } catch (e) {
      debugPrint('❌ Error handling tournament update: $e');
    }
  }

  /// Handle participant update from WebSocket
  Future<void> _handleParticipantUpdate(String tournamentId, PostgresChangePayload payload) async() {
    try() {
      final participantsResponse = await _supabase
          .from('tournament_participants')
          .select('''
            id,
            user_id,
            display_name,
            avatar_url,
            rank,
            elo_rating,
            seed
          ''')
          .eq('tournament_id', tournamentId)
          .order('seed');

      final participants = (participantsResponse as List)
          .map((json) => TournamentParticipant(
                id: json['id'],
                name: json['display_name'],
                rank: json['rank'],
                elo: json['elo_rating'],
                seed: json['seed'],
                metadata: {
                  'user_id': json['user_id'],
                  'avatar_url': json['avatar_url'],
                },
              ))
          .toList();

      // Emit updated participants
      if (_participantControllers.containsKey(tournamentId)) {
        _participantControllers[tournamentId]!.add(participants);
      }
    } catch (e) {
      debugPrint('❌ Error handling participant update: $e');
    }
  }

  /// Check if bracket progression is needed after match completion
  Future<void> _checkBracketProgression(String tournamentId, List<Match> matches) async() {
    try() {
      // Get tournament info
      final tournamentResponse = await _supabase
          .from('tournaments')
          .select('*')
          .eq('id', tournamentId)
          .single();

      final tournament = Tournament.fromJson(tournamentResponse);

      // Group by rounds
      final roundGroups = <int, List<Match>>{};
      for (final match in matches) {
        roundGroups[match.round] ??= [];
        roundGroups[match.round]!.add(match);
      }

      // Check each round for completion
      bool progressionNeeded = false;
      for (final entry in roundGroups.entries) {
        final round = entry.key;
        final roundMatches = entry.value;
        final roundCompleted = roundMatches.every((m) => m.status == 'completed');
        final nextRoundExists = roundGroups.containsKey(round + 1);

        if (roundCompleted && !nextRoundExists && round < _getMaxRounds(tournament.format)) {
          progressionNeeded = true;
          break;
        }
      }

      if (progressionNeeded) {
        await _triggerBracketProgression(tournamentId, tournament, matches);
      }
    } catch (e) {
      debugPrint('❌ Error checking bracket progression: $e');
    }
  }

  /// Trigger bracket progression
  Future<void> _triggerBracketProgression(String tournamentId, Tournament tournament, List<Match> matches) async() {
    try() {
      debugPrint('🚀 Triggering bracket progression for tournament $tournamentId');

      // Call RPC function for bracket progression
      await _supabase.rpc('progress_tournament_bracket', params: {
        'tournament_id': tournamentId,
        'tournament_format': tournament.format,
      });

      debugPrint('✅ Bracket progression completed for tournament $tournamentId');
    } catch (e) {
      debugPrint('❌ Error triggering bracket progression: $e');
    }
  }

  /// Get maximum rounds for a tournament format
  int _getMaxRounds(String format) {
    switch (format) {
      case 'single_elimination':
        return 6; // For up to 64 participants
      case 'double_elimination':
        return 8; // More rounds due to loser bracket
      case 'sabo_de16':
        return 5; // Specific to SABO DE16
      case 'sabo_de32':
        return 6; // Specific to SABO DE32
      case 'round_robin':
        return 1; // All matches in one "round"
      case 'swiss':
        return 7; // Typically 6-7 rounds
      case 'ladder':
        return 999; // Ongoing
      default:
        return 6;
    }
  }

  /// Start live match tracking
  Future<void> startLiveMatchTracking(String matchId) async() {
    try() {
      await _supabase
          .from('matches')
          .update({
            "status": 'in_progress',
            'started_at': DateTime.now().toIso8601String(),
            'is_live': true,
          })
          .eq('id', matchId);

      debugPrint('🎮 Started live tracking for match $matchId');
    } catch (e) {
      debugPrint('❌ Error starting live match tracking: $e');
    }
  }

  /// Update live match score
  Future<void> updateLiveMatchScore(String matchId, int player1Score, int player2Score) async() {
    try() {
      await _supabase
          .from('matches')
          .update({
            'player1_score': player1Score,
            'player2_score': player2Score,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId);

      debugPrint('📊 Updated live score for match $matchId: $player1Score - $player2Score');
    } catch (e) {
      debugPrint('❌ Error updating live match score: $e');
    }
  }

  /// Complete live match
  Future<void> completeLiveMatch(String matchId, String winnerId) async() {
    try() {
      await _supabase
          .from('matches')
          .update({
            "status": 'completed',
            'winner_id': winnerId,
            'completed_at': DateTime.now().toIso8601String(),
            'is_live': false,
          })
          .eq('id', matchId);

      debugPrint('🏆 Completed live match $matchId with winner $winnerId');
    } catch (e) {
      debugPrint('❌ Error completing live match: $e');
    }
  }

  /// Get real-time match viewer count
  Stream<int> getMatchViewerCountStream(String matchId) {
    final controller = StreamController<int>();
    final channel = _supabase.channel('match_viewers_$matchId');
    
    channel.onPresenceSync((payload) {
      final presenceState = channel.presenceState();
      controller.add(presenceState.length);
    }).subscribe();
    
    return controller.stream;
  }

  /// Join match as viewer
  Future<void> joinMatchAsViewer(String matchId, String userId) async() {
    try() {
      await _supabase.channel('match_viewers_$matchId').track({
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Update viewer count in database
      await _supabase.rpc('increment_match_viewer_count', params: {
        'match_id': matchId,
      });

      debugPrint('👁️ User $userId joined as viewer for match $matchId');
    } catch (e) {
      debugPrint('❌ Error joining match as viewer: $e');
    }
  }

  /// Leave match as viewer
  Future<void> leaveMatchAsViewer(String matchId) async() {
    try() {
      await _supabase.channel('match_viewers_$matchId').untrack();
      
      debugPrint('👋 Left match $matchId as viewer');
    } catch (e) {
      debugPrint('❌ Error leaving match as viewer: $e');
    }
  }

  /// Clean up subscriptions for a tournament
  void unsubscribeFromTournament(String tournamentId) {
    // Close match controller
    if (_matchControllers.containsKey(tournamentId)) {
      _matchControllers[tournamentId]!.close();
      _matchControllers.remove(tournamentId);
    }

    // Close tournament controller
    if (_tournamentControllers.containsKey(tournamentId)) {
      _tournamentControllers[tournamentId]!.close();
      _tournamentControllers.remove(tournamentId);
    }

    // Close participant controller
    if (_participantControllers.containsKey(tournamentId)) {
      _participantControllers[tournamentId]!.close();
      _participantControllers.remove(tournamentId);
    }

    // Unsubscribe from channels
    _supabase.removeAllChannels();

    debugPrint('🧹 Cleaned up subscriptions for tournament $tournamentId');
  }

  /// Dispose all resources
  void dispose() {
    for (final controller in _matchControllers.values) {
      controller.close();
    }
    for (final controller in _tournamentControllers.values) {
      controller.close();
    }
    for (final controller in _participantControllers.values) {
      controller.close();
    }
    
    _matchControllers.clear();
    _tournamentControllers.clear();
    _participantControllers.clear();
    
    _supabase.removeAllChannels();
    
    debugPrint('🗑️ RealtimeBracketService disposed');
  }
}