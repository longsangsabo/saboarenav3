
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TournamentCacheService {
  static const String _tournamentsPrefix = 'tournament_';
  static const String _matchesPrefix = 'matches_';
  static const String _playersPrefix = 'player_';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _syncListKey = 'sync_list';
  
  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    print('🗃️ TournamentCacheService initialized with SharedPreferences');
  }

  /// Ensure _prefs is initialized
  static Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await initialize();
    }
    return _prefs!;
  }

  /// Cache tournament data
  static Future<void> cacheTournament(String tournamentId, Map<String, dynamic> tournamentData) async {
    final prefs = await _getPrefs();
    final key = '$_tournamentsPrefix$tournamentId';
    await prefs.setString(key, jsonEncode(tournamentData));
    print('💾 Cached tournament: ${tournamentId.substring(0, 8)}...');
  }

  /// Get cached tournament
  static Future<Map<String, dynamic>?> getCachedTournament(String tournamentId) async {
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
  static Future<void> cacheMatches(String tournamentId, List<Map<String, dynamic>> matches) async {
    final prefs = await _getPrefs();
    final key = '$_matchesPrefix$tournamentId';
    await prefs.setString(key, jsonEncode(matches));
    print('💾 Cached ${matches.length} matches for tournament: ${tournamentId.substring(0, 8)}...');
  }

  /// Get cached matches for tournament
  static Future<List<Map<String, dynamic>>?> getCachedMatches(String tournamentId) async {
    final prefs = await _getPrefs();
    final key = '$_matchesPrefix$tournamentId';
    final cached = prefs.getString(key);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      final matches = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      print('⚡ Retrieved ${matches.length} matches from cache for: ${tournamentId.substring(0, 8)}...');
      return matches;
    }
    return null;
  }

  /// Update single match in cache
  static Future<void> updateCachedMatch(String tournamentId, Map<String, dynamic> updatedMatch) async {
    final matches = await getCachedMatches(tournamentId);
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
  static Future<void> cachePlayer(String playerId, Map<String, dynamic> playerData) async {
    final prefs = await _getPrefs();
    final key = '$_playersPrefix$playerId';
    await prefs.setString(key, jsonEncode(playerData));
  }

  /// Get cached player
  static Future<Map<String, dynamic>?> getCachedPlayer(String playerId) async {
    final prefs = await _getPrefs();
    final key = '$_playersPrefix$playerId';
    final cached = prefs.getString(key);
    if (cached != null) {
      return jsonDecode(cached);
    }
    return null;
  }

  /// Cache multiple players at once
  static Future<void> cachePlayers(List<Map<String, dynamic>> players) async {
    for (final player in players) {
      await cachePlayer(player['id'], player);
    }
    print('💾 Cached ${players.length} players');
  }

  /// Check if tournament data exists in cache
  static Future<bool> hasCachedTournament(String tournamentId) async {
    final prefs = await _getPrefs();
    final key = '$_tournamentsPrefix$tournamentId';
    return prefs.containsKey(key);
  }

  /// Check if matches exist in cache
  static Future<bool> hasCachedMatches(String tournamentId) async {
    final prefs = await _getPrefs();
    final key = '$_matchesPrefix$tournamentId';
    return prefs.containsKey(key);
  }

  /// Clear cache for specific tournament
  static Future<void> clearTournamentCache(String tournamentId) async {
    final prefs = await _getPrefs();
    final tournamentKey = '$_tournamentsPrefix$tournamentId';
    final matchesKey = '$_matchesPrefix$tournamentId';
    
    await prefs.remove(tournamentKey);
    await prefs.remove(matchesKey);
    print('🗑️ Cleared cache for tournament: ${tournamentId.substring(0, 8)}...');
  }

  /// Clear all cache (development/testing only)
  static Future<void> clearAllCache() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_tournamentsPrefix) || 
          key.startsWith(_matchesPrefix) || 
          key.startsWith(_playersPrefix) ||
          key == _pendingActionsKey ||
          key == _syncListKey) {
        await prefs.remove(key);
      }
    }
    print('🗑️ Cleared all tournament cache');
  }

  /// Get cache statistics
  static Future<Map<String, int>> getCacheStats() async {
    final prefs = await _getPrefs();
    final keys = prefs.getKeys();
    
    int tournaments = 0;
    int matches = 0;
    int players = 0;
    
    for (final key in keys) {
      if (key.startsWith(_tournamentsPrefix)) tournaments++;
      if (key.startsWith(_matchesPrefix)) matches++;
      if (key.startsWith(_playersPrefix)) players++;
    }
    
    return {
      'tournaments': tournaments,
      'matches': matches,
      'players': players,
    };
  }

  /// Store pending offline actions
  static Future<void> storePendingAction(Map<String, dynamic> action) async {
    final prefs = await _getPrefs();
    final pending = await getPendingActions();
    
    // Add timestamp to action
    action['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    
    pending.add(action);
    await prefs.setString(_pendingActionsKey, jsonEncode(pending));
    print('📝 Stored pending action: ${action['type']}');
  }

  /// Get pending offline actions
  static Future<List<Map<String, dynamic>>> getPendingActions() async {
    final prefs = await _getPrefs();
    final cached = prefs.getString(_pendingActionsKey);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  /// Clear pending actions after sync
  static Future<void> clearPendingActions() async {
    final prefs = await _getPrefs();
    await prefs.remove(_pendingActionsKey);
    print('✅ Cleared pending actions');
  }

  /// Mark data as needing sync
  static Future<void> markForSync(String tournamentId) async {
    final prefs = await _getPrefs();
    final syncList = await getSyncList();
    if (!syncList.contains(tournamentId)) {
      syncList.add(tournamentId);
      await prefs.setString(_syncListKey, jsonEncode(syncList));
      print('🔄 Marked for sync: ${tournamentId.substring(0, 8)}...');
    }
  }

  /// Get list of tournaments needing sync
  static Future<List<String>> getSyncList() async {
    final prefs = await _getPrefs();
    final cached = prefs.getString(_syncListKey);
    if (cached != null) {
      final List<dynamic> decoded = jsonDecode(cached);
      return decoded.cast<String>();
    }
    return [];
  }

  /// Remove from sync list after successful sync
  static Future<void> removeFromSyncList(String tournamentId) async {
    final prefs = await _getPrefs();
    final syncList = await getSyncList();
    syncList.remove(tournamentId);
    await prefs.setString(_syncListKey, jsonEncode(syncList));
    print('✅ Removed from sync list: ${tournamentId.substring(0, 8)}...');
  }

  /// Check if device is offline (simple version - can be enhanced)
  static bool isOfflineMode = false;
  
  /// Set offline mode
  static void setOfflineMode(bool offline) {
    isOfflineMode = offline;
    print(offline ? "📴 Switched to offline mode" : '📶 Switched to online mode');
  }

  /// Get cache age for data freshness check
  static Future<DateTime?> getCacheTimestamp(String key) async {
    final prefs = await _getPrefs();
    final timestamp = prefs.getInt('${key}_timestamp');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Set cache timestamp
  static Future<void> setCacheTimestamp(String key) async {
    final prefs = await _getPrefs();
    await prefs.setInt('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  /// Check if cache is stale (older than specified duration)
  static Future<bool> isCacheStale(String key, {Duration maxAge = const Duration(minutes: 5)}) async {
    final timestamp = await getCacheTimestamp(key);
    if (timestamp == null) return true;
    
    final age = DateTime.now().difference(timestamp);
    return age > maxAge;
  }
}