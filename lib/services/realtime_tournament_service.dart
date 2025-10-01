// 🔥 SABO ARENA - Real-time Tournament Updates Service
// Phase 2: WebSocket integration for live tournament updates
// Handles real-time bracket updates, match results, and notifications

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service quản lý real-time updates cho tournament system
class RealTimeTournamentService() {
  static RealTimeTournamentService? _instance;
  static RealTimeTournamentService get instance => _instance ??= RealTimeTournamentService._();
  RealTimeTournamentService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controllers for different types of updates
  final StreamController<Map<String, dynamic>> _tournamentUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _matchUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _participantUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Subscription management
  final Map<String, RealtimeChannel> _activeSubscriptions = {};

  // ==================== STREAM GETTERS ====================

  /// Stream for tournament status changes (active, completed, etc.)
  Stream<Map<String, dynamic>> get tournamentUpdates => _tournamentUpdatesController.stream;

  /// Stream for match result updates and bracket progression
  Stream<Map<String, dynamic>> get matchUpdates => _matchUpdatesController.stream;

  /// Stream for participant registration/withdrawal updates  
  Stream<Map<String, dynamic>> get participantUpdates => _participantUpdatesController.stream;

  // ==================== SUBSCRIPTION MANAGEMENT ====================

  /// Subscribe to real-time updates for a specific tournament
  Future<void> subscribeTournament(String tournamentId) async() {
    try() {
      // Unsubscribe if already subscribed
      await unsubscribeTournament(tournamentId);

      debugPrint('🔔 Subscribing to real-time updates for tournament: $tournamentId');

      // Subscribe to tournament table changes
      final tournamentChannel = _supabase
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
            callback: (payload) {
              _handleTournamentUpdate(payload);
            },
          );

      // Subscribe to matches table changes for this tournament
      final matchesChannel = _supabase
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
            callback: (payload) {
              _handleMatchUpdate(payload);
            },
          );

      // Subscribe to tournament_participants changes
      final participantsChannel = _supabase
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
            callback: (payload) {
              _handleParticipantUpdate(payload);
            },
          );

      // Subscribe to all channels
      tournamentChannel.subscribe();
      matchesChannel.subscribe();
      participantsChannel.subscribe();

      // Store subscriptions for cleanup
      _activeSubscriptions['tournament_$tournamentId'] = tournamentChannel;
      _activeSubscriptions['matches_$tournamentId'] = matchesChannel;
      _activeSubscriptions['participants_$tournamentId'] = participantsChannel;

      debugPrint('✅ Successfully subscribed to real-time updates for tournament: $tournamentId');

    } catch (e) {
      debugPrint('❌ Error subscribing to tournament updates: $e');
      throw Exception('Failed to subscribe to real-time updates: $e');
    }
  }

  /// Unsubscribe from real-time updates for a specific tournament
  Future<void> unsubscribeTournament(String tournamentId) async() {
    try() {
      final tournamentKey = 'tournament_$tournamentId';
      final matchesKey = 'matches_$tournamentId';
      final participantsKey = 'participants_$tournamentId';

      // Unsubscribe from channels
      if (_activeSubscriptions.containsKey(tournamentKey)) {
        await _activeSubscriptions[tournamentKey]!.unsubscribe();
        _activeSubscriptions.remove(tournamentKey);
      }

      if (_activeSubscriptions.containsKey(matchesKey)) {
        await _activeSubscriptions[matchesKey]!.unsubscribe();
        _activeSubscriptions.remove(matchesKey);
      }

      if (_activeSubscriptions.containsKey(participantsKey)) {
        await _activeSubscriptions[participantsKey]!.unsubscribe();
        _activeSubscriptions.remove(participantsKey);
      }

      debugPrint('✅ Unsubscribed from tournament: $tournamentId');

    } catch (e) {
      debugPrint('❌ Error unsubscribing from tournament: $e');
    }
  }

  /// Unsubscribe from all tournaments
  Future<void> unsubscribeAll() async() {
    try() {
      for (final channel in _activeSubscriptions.values) {
        await channel.unsubscribe();
      }
      _activeSubscriptions.clear();
      debugPrint('✅ Unsubscribed from all tournaments');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from all tournaments: $e');
    }
  }

  // ==================== UPDATE HANDLERS ====================

  /// Handle tournament table updates (status changes, etc.)
  void _handleTournamentUpdate(PostgresChangePayload payload) {
    try() {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      debugPrint('🔔 Tournament update received: $eventType');

      final updateData = {
        "type": 'tournament_update',
        'event': eventType.name,
        'tournament_id': newRecord['id'] ?? oldRecord['id'],
        'new_data': newRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Detect specific changes
      if (eventType == PostgresChangeEvent.update) {
        final changes = _detectChanges(oldRecord, newRecord);
        updateData['changes'] = changes;

        // Special handling for status changes
        if (changes.containsKey('status')) {
          updateData['status_change'] = {
            'from': changes['status']['old'],
            'to': changes['status']['new'],
          };
        }
      }

      _tournamentUpdatesController.add(updateData);

    } catch (e) {
      debugPrint('❌ Error handling tournament update: $e');
    }
  }

  /// Handle matches table updates (results, bracket progression)
  void _handleMatchUpdate(PostgresChangePayload payload) {
    try() {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      debugPrint('🔔 Match update received: $eventType');

      final updateData = {
        "type": 'match_update',
        'event': eventType.name,
        'match_id': newRecord['id'] ?? oldRecord['id'],
        'tournament_id': newRecord['tournament_id'] ?? oldRecord['tournament_id'],
        'new_data': newRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Detect specific changes for matches
      if (eventType == PostgresChangeEvent.update) {
        final changes = _detectChanges(oldRecord, newRecord);
        updateData['changes'] = changes;

        // Special handling for match completion
        if (changes.containsKey('status') && 
            changes['status']['new'] == 'completed') {
          updateData['match_completed'] = true;
          updateData['winner'] = newRecord['winner_id'];
          updateData['final_score'] = {
            'player1': newRecord['player1_score'],
            'player2': newRecord['player2_score'],
          };
        }

        // Handle score updates
        if (changes.containsKey('player1_score') || changes.containsKey('player2_score')) {
          updateData['score_updated'] = true;
          updateData['current_score'] = {
            'player1': newRecord['player1_score'],
            'player2': newRecord['player2_score'],
          };
        }
      }

      _matchUpdatesController.add(updateData);

    } catch (e) {
      debugPrint('❌ Error handling match update: $e');
    }
  }

  /// Handle tournament participants updates (registration, withdrawal)
  void _handleParticipantUpdate(PostgresChangePayload payload) {
    try() {
      final eventType = payload.eventType;
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;

      debugPrint('🔔 Participant update received: $eventType');

      final updateData = {
        "type": 'participant_update',
        'event': eventType.name,
        'participant_id': newRecord['id'] ?? oldRecord['id'],
        'tournament_id': newRecord['tournament_id'] ?? oldRecord['tournament_id'],
        'user_id': newRecord['user_id'] ?? oldRecord['user_id'],
        'new_data': newRecord,
        'old_data': oldRecord,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Handle specific participant events
      if (eventType == PostgresChangeEvent.insert) {
        updateData['participant_joined'] = true;
      } else if (eventType == PostgresChangeEvent.delete) {
        updateData['participant_left'] = true;
      } else if (eventType == PostgresChangeEvent.update) {
        final changes = _detectChanges(oldRecord, newRecord);
        updateData['changes'] = changes;

        // Handle payment status changes
        if (changes.containsKey('payment_status')) {
          updateData['payment_updated'] = true;
          updateData['payment_status'] = {
            'from': changes['payment_status']['old'],
            'to': changes['payment_status']['new'],
          };
        }
      }

      _participantUpdatesController.add(updateData);

    } catch (e) {
      debugPrint('❌ Error handling participant update: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Detect specific changes between old and new records
  Map<String, Map<String, dynamic>> _detectChanges(
    Map<String, dynamic> oldRecord, 
    Map<String, dynamic> newRecord
  ) {
    final changes = <String, Map<String, dynamic>>{};

    for (final key in newRecord.keys) {
      if (oldRecord[key] != newRecord[key]) {
        changes[key] = {
          'old': oldRecord[key],
          'new': newRecord[key],
        };
      }
    }

    return changes;
  }

  /// Check if tournament has active real-time subscriptions
  bool isSubscribed(String tournamentId) {
    return _activeSubscriptions.containsKey('tournament_$tournamentId');
  }

  /// Get list of currently subscribed tournament IDs
  List<String> getSubscribedTournaments() {
    return _activeSubscriptions.keys
        .where((key) => key.startsWith('tournament_'))
        .map((key) => key.substring('tournament_'.length))
        .toList();
  }

  // ==================== CLEANUP ====================

  /// Dispose of all streams and subscriptions
  Future<void> dispose() async() {
    try() {
      await unsubscribeAll();
      
      await _tournamentUpdatesController.close();
      await _matchUpdatesController.close();
      await _participantUpdatesController.close();

      debugPrint('✅ RealTimeTournamentService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing RealTimeTournamentService: $e');
    }
  }
}