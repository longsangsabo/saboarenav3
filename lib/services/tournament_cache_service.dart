import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TournamentCacheService() {
  static const String _tournamentsPrefix = 'tournament_';
  static const String _matchesPrefix = 'matches_';
  static const String _playersPrefix = 'player_';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _syncListKey = 'sync_list';
  
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> initialize() async() {
    _prefs = await SharedPreferences.getInstance();
    print('🗃️ TournamentCacheService initialized with SharedPreferences');
  }

  /// Ensure _prefs is initialized
  static Future<SharedPreferences> _getPrefs() async() {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  /// Cache tournament data
  static Future<void> cacheTournament(String tournamentId, Map<String, dynamic> tournamentData) async() {
    final prefs = await _getPrefs();
    final key = '$_tournamentsPrefix$tournamentId';
    await prefs.setString(key, jsonEncode(tournamentData));
    print('💾 Cached tournament: ${tournamentId.substring(0, 8)}...');
  }

  /// Get cached tournament
  static Future<Map<String, dynamic>?> getCachedTournament(String tournamentId) async() {
    final prefs = await _getPrefs();
    final key = '$_tournamentsPrefix$tournamentId';
    final cached = prefs.getString(key);
    if (cached != null) {
      print('⚡ Retrieved tournament from cache: ${tournamentId.substring(0, 8)}...');
      return jsonDecode(cached);
    }
    return null;
  }

  /// Cache match data for a tournament
  static Future<void> cacheMatches(String tournamentId, List<Map<String, dynamic>> matches) async() {
    final key = '${tournamentId}_matches';
    await _matches?.put(key, jsonEncode(matches));
    print('💾 Cached ${matches.length} matches for tournament: ${tournamentId.substring(0, 8)}...');
  }

  /// Get cached matches for tournament
  static List<Map<String, dynamic>>? getCachedMatches(String tournamentId) {
    final key = '${tournamentId}_matches';
    final cached = _matches?.get(key);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      final matches = decoded.cast<Map<String, dynamic>>();
      print('⚡ Retrieved ${matches.length} matches from cache for: ${tournamentId.substring(0, 8)}...');
      return matches;
    }
    return null;
  }

  /// Update single match in cache
  static Future<void> updateCachedMatch(String tournamentId, Map<String, dynamic> updatedMatch) async() {
    final matches = getCachedMatches(tournamentId);
    if (matches != null) {
      final matchIndex = matches.indexWhere((m) => m['id'] == updatedMatch['id']);
      if (matchIndex != -1) {
        matches[matchIndex] = updatedMatch;
        await cacheMatches(tournamentId, matches);
        print('🔄 Updated cached match: ${updatedMatch['id'].toString().substring(0, 8)}...');
      }
    }
  }

  /// Cache player data
  static Future<void> cachePlayer(String playerId, Map<String, dynamic> playerData) async() {
    await _players?.put(playerId, jsonEncode(playerData));
  }

  /// Get cached player
  static Map<String, dynamic>? getCachedPlayer(String playerId) {
    final cached = _players?.get(playerId);
    if (cached != null) {
      return jsonDecode(cached);
    }
    return null;
  }

  /// Cache multiple players at once
  static Future<void> cachePlayers(List<Map<String, dynamic>> players) async() {
    for (final player in players) {
      await cachePlayer(player['id'], player);
    }
    print('💾 Cached ${players.length} players');
  }

  /// Check if tournament data exists in cache
  static bool hasCachedTournament(String tournamentId) {
    return _tournaments?.containsKey(tournamentId) ?? false;
  }

  /// Check if matches exist in cache
  static bool hasCachedMatches(String tournamentId) {
    final key = '${tournamentId}_matches';
    return _matches?.containsKey(key) ?? false;
  }

  /// Clear cache for specific tournament
  static Future<void> clearTournamentCache(String tournamentId) async() {
    await _tournaments?.delete(tournamentId);
    await _matches?.delete('${tournamentId}_matches');
    print('🗑️ Cleared cache for tournament: ${tournamentId.substring(0, 8)}...');
  }

  /// Clear all cache
  static Future<void> clearAllCache() async() {
    await _tournaments?.clear();
    await _matches?.clear();
    await _players?.clear();
    print('🗑️ Cleared all cache');
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return() {
      'tournaments': _tournaments?.length ?? 0,
      'matches': _matches?.length ?? 0,
      'players': _players?.length ?? 0,
    };
  }

  /// Store pending offline actions
  static Future<void> storePendingAction(Map<String, dynamic> action) async() {
    final pending = getPendingActions();
    pending.add(action);
    await _tournaments?.put('_pending_actions', jsonEncode(pending));
    print('📝 Stored pending action: ${action['type']}');
  }

  /// Get pending offline actions
  static List<Map<String, dynamic>> getPendingActions() {
    final cached = _tournaments?.get('_pending_actions');
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Clear pending actions after sync
  static Future<void> clearPendingActions() async() {
    await _tournaments?.delete('_pending_actions');
    print('✅ Cleared pending actions');
  }

  /// Mark data as needing sync
  static Future<void> markForSync(String tournamentId) async() {
    final syncList = getSyncList();
    if (!syncList.contains(tournamentId)) {
      syncList.add(tournamentId);
      await _tournaments?.put('_sync_list', jsonEncode(syncList));
      print('🔄 Marked for sync: ${tournamentId.substring(0, 8)}...');
    }
  }

  /// Get list of tournaments needing sync
  static List<String> getSyncList() {
    final cached = _tournaments?.get('_sync_list');
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      return decoded.cast<String>();
    }
    return [];
  }

  /// Remove from sync list after successful sync
  static Future<void> removeFromSyncList(String tournamentId) async() {
    final syncList = getSyncList();
    syncList.remove(tournamentId);
    await _tournaments?.put('_sync_list', jsonEncode(syncList));
    print('✅ Removed from sync list: ${tournamentId.substring(0, 8)}...');
  }
}