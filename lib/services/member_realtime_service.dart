import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberRealtimeService() {
  static final MemberRealtimeService _instance = MemberRealtimeService._internal();
  factory MemberRealtimeService() => _instance;
  MemberRealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controllers for real-time data
  final StreamController<List<Map<String, dynamic>>> _membersController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _requestsController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _chatMessagesController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _notificationsController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _activitiesController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Subscription references
  RealtimeChannel? _membersSubscription;
  RealtimeChannel? _requestsSubscription;
  RealtimeChannel? _chatMessagesSubscription;
  RealtimeChannel? _notificationsSubscription;
  RealtimeChannel? _activitiesSubscription;

  // Current data cache
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};

  // Connection status
  bool _isConnected = false;
  final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  // Getters for streams
  Stream<List<Map<String, dynamic>>> get membersStream => _membersController.stream;
  Stream<List<Map<String, dynamic>>> get requestsStream => _requestsController.stream;
  Stream<List<Map<String, dynamic>>> get chatMessagesStream => _chatMessagesController.stream;
  Stream<List<Map<String, dynamic>>> get notificationsStream => _notificationsController.stream;
  Stream<List<Map<String, dynamic>>> get activitiesStream => _activitiesController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  // ====================================
  // CONNECTION MANAGEMENT
  // ====================================

  /// Initialize real-time connections for a specific club
  Future<void> initializeForClub(String clubId) async() {
    try() {
      if (kDebugMode) {
        debugPrint('🔄 Initializing real-time connections for club: $clubId');
      }

      // Disconnect existing connections
      await disconnect();

      // Subscribe to club memberships
      await _subscribeToMembers(clubId);
      
      // Subscribe to membership requests
      await _subscribeToRequests(clubId);
      
      // Subscribe to activities
      await _subscribeToActivities(clubId);

      _isConnected = true;
      _connectionController.add(true);

      if (kDebugMode) {
        debugPrint('✅ Real-time connections initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing real-time connections: $e');
      }
      _connectionController.add(false);
      rethrow;
    }
  }

  /// Initialize real-time connections for a specific user
  Future<void> initializeForUser(String userId) async() {
    try() {
      if (kDebugMode) {
        debugPrint('🔄 Initializing real-time connections for user: $userId');
      }

      // Subscribe to user notifications
      await _subscribeToNotifications(userId);

      if (kDebugMode) {
        debugPrint('✅ User real-time connections initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing user real-time connections: $e');
      }
      rethrow;
    }
  }

  /// Initialize chat room real-time connections
  Future<void> initializeForChatRoom(String roomId) async() {
    try() {
      if (kDebugMode) {
        debugPrint('🔄 Initializing chat room connections: $roomId');
      }

      await _subscribeToChatMessages(roomId);

      if (kDebugMode) {
        debugPrint('✅ Chat room connections initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing chat room connections: $e');
      }
      rethrow;
    }
  }

  /// Disconnect all real-time subscriptions
  Future<void> disconnect() async() {
    try() {
      if (kDebugMode) {
        debugPrint('🔄 Disconnecting real-time connections');
      }

      // Unsubscribe from all channels
      await _membersSubscription?.unsubscribe();
      await _requestsSubscription?.unsubscribe();
      await _chatMessagesSubscription?.unsubscribe();
      await _notificationsSubscription?.unsubscribe();
      await _activitiesSubscription?.unsubscribe();

      // Clear subscriptions
      _membersSubscription = null;
      _requestsSubscription = null;
      _chatMessagesSubscription = null;
      _notificationsSubscription = null;
      _activitiesSubscription = null;

      _isConnected = false;
      _connectionController.add(false);

      if (kDebugMode) {
        debugPrint('✅ Real-time connections disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disconnecting: $e');
      }
    }
  }

  // ====================================
  // SUBSCRIPTION METHODS
  // ====================================

  /// Subscribe to club members changes
  Future<void> _subscribeToMembers(String clubId) async() {
    try() {
      _membersSubscription = _supabase
          .channel('club_memberships_$clubId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'club_memberships',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (payload) => _handleMembersChange(payload, clubId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialMembers(clubId);

      if (kDebugMode) {
        debugPrint('✅ Subscribed to club members');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to members: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to membership requests changes
  Future<void> _subscribeToRequests(String clubId) async() {
    try() {
      _requestsSubscription = _supabase
          .channel('membership_requests_$clubId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'membership_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (payload) => _handleRequestsChange(payload, clubId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialRequests(clubId);

      if (kDebugMode) {
        debugPrint('✅ Subscribed to membership requests');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to requests: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to chat messages changes
  Future<void> _subscribeToChatMessages(String roomId) async() {
    try() {
      _chatMessagesSubscription = _supabase
          .channel('chat_messages_$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) => _handleChatMessagesChange(payload, roomId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialChatMessages(roomId);

      if (kDebugMode) {
        debugPrint('✅ Subscribed to chat messages');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to chat messages: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to user notifications changes
  Future<void> _subscribeToNotifications(String userId) async() {
    try() {
      _notificationsSubscription = _supabase
          .channel('notifications_$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) => _handleNotificationsChange(payload, userId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialNotifications(userId);

      if (kDebugMode) {
        debugPrint('✅ Subscribed to user notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to notifications: $e');
      }
      rethrow;
    }
  }

  /// Subscribe to member activities changes
  Future<void> _subscribeToActivities(String clubId) async() {
    try() {
      _activitiesSubscription = _supabase
          .channel('member_activities_$clubId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'member_activities',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'club_id',
              value: clubId,
            ),
            callback: (payload) => _handleActivitiesChange(payload, clubId),
          )
          .subscribe();

      // Load initial data
      await _loadInitialActivities(clubId);

      if (kDebugMode) {
        debugPrint('✅ Subscribed to member activities');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error subscribing to activities: $e');
      }
      rethrow;
    }
  }

  // ====================================
  // CHANGE HANDLERS
  // ====================================

  void _handleMembersChange(PostgresChangePayload payload, String clubId) {
    if (kDebugMode) {
      debugPrint('📥 Members change: ${payload.eventType}');
    }

    final cacheKey = 'members_$clubId';
    final currentData = List<Map<String, dynamic>>.from(_dataCache[cacheKey] ?? []);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.add(payload.newRecord);
              break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere((item) => item['id'] == payload.newRecord['id']);
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
              break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere((item) => item['id'] == payload.oldRecord['id']);
              break;
    }

    _dataCache[cacheKey] = currentData;
    _membersController.add(currentData);
  }

  void _handleRequestsChange(PostgresChangePayload payload, String clubId) {
    if (kDebugMode) {
      debugPrint('📥 Requests change: ${payload.eventType}');
    }

    final cacheKey = 'requests_$clubId';
    final currentData = List<Map<String, dynamic>>.from(_dataCache[cacheKey] ?? []);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // Add to beginning for latest first
              break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere((item) => item['id'] == payload.newRecord['id']);
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
              break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere((item) => item['id'] == payload.oldRecord['id']);
              break;
    }

    _dataCache[cacheKey] = currentData;
    _requestsController.add(currentData);
  }

  void _handleChatMessagesChange(PostgresChangePayload payload, String roomId) {
    if (kDebugMode) {
      debugPrint('📥 Chat messages change: ${payload.eventType}');
    }

    final cacheKey = 'messages_$roomId';
    final currentData = List<Map<String, dynamic>>.from(_dataCache[cacheKey] ?? []);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // New messages at top
              break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere((item) => item['id'] == payload.newRecord['id']);
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
              break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere((item) => item['id'] == payload.oldRecord['id']);
              break;
    }

    _dataCache[cacheKey] = currentData;
    _chatMessagesController.add(currentData);
  }

  void _handleNotificationsChange(PostgresChangePayload payload, String userId) {
    if (kDebugMode) {
      debugPrint('📥 Notifications change: ${payload.eventType}');
    }

    final cacheKey = 'notifications_$userId';
    final currentData = List<Map<String, dynamic>>.from(_dataCache[cacheKey] ?? []);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // New notifications at top
        // Show local notification for new items
        _showLocalNotification(payload.newRecord);
              break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere((item) => item['id'] == payload.newRecord['id']);
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
              break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere((item) => item['id'] == payload.oldRecord['id']);
              break;
    }

    _dataCache[cacheKey] = currentData;
    _notificationsController.add(currentData);
  }

  void _handleActivitiesChange(PostgresChangePayload payload, String clubId) {
    if (kDebugMode) {
      debugPrint('📥 Activities change: ${payload.eventType}');
    }

    final cacheKey = 'activities_$clubId';
    final currentData = List<Map<String, dynamic>>.from(_dataCache[cacheKey] ?? []);

    switch (payload.eventType) {
      case PostgresChangeEvent.insert:
        currentData.insert(0, payload.newRecord); // New activities at top
              break;
      case PostgresChangeEvent.update:
        final index = currentData.indexWhere((item) => item['id'] == payload.newRecord['id']);
        if (index != -1) {
          currentData[index] = payload.newRecord;
        }
              break;
      case PostgresChangeEvent.delete:
        currentData.removeWhere((item) => item['id'] == payload.oldRecord['id']);
              break;
    }

    _dataCache[cacheKey] = currentData;
    _activitiesController.add(currentData);
  }

  // ====================================
  // INITIAL DATA LOADING
  // ====================================

  Future<void> _loadInitialMembers(String clubId) async() {
    try() {
      final response = await _supabase
          .from('club_memberships')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('joined_at', ascending: false);

      final cacheKey = 'members_$clubId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _membersController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading initial members: $e');
      }
    }
  }

  Future<void> _loadInitialRequests(String clubId) async() {
    try() {
      final response = await _supabase
          .from('membership_requests')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      final cacheKey = 'requests_$clubId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _requestsController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading initial requests: $e');
      }
    }
  }

  Future<void> _loadInitialChatMessages(String roomId) async() {
    try() {
      final response = await _supabase
          .from('chat_messages')
          .select('*, users(*)')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(50); // Load last 50 messages

      final cacheKey = 'messages_$roomId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _chatMessagesController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading initial messages: $e');
      }
    }
  }

  Future<void> _loadInitialNotifications(String userId) async() {
    try() {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final cacheKey = 'notifications_$userId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _notificationsController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading initial notifications: $e');
      }
    }
  }

  Future<void> _loadInitialActivities(String clubId) async() {
    try() {
      final response = await _supabase
          .from('member_activities')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(100);

      final cacheKey = 'activities_$clubId';
      _dataCache[cacheKey] = List<Map<String, dynamic>>.from(response);
      _activitiesController.add(_dataCache[cacheKey]!);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading initial activities: $e');
      }
    }
  }

  // ====================================
  // UTILITY METHODS
  // ====================================

  /// Show local notification for new items
  void _showLocalNotification(Map<String, dynamic> notification) {
    // This would integrate with flutter_local_notifications
    // For now, just log it
    if (kDebugMode) {
      debugPrint('🔔 New notification: ${notification['title']}');
    }
  }

  /// Get cached data for a specific key
  List<Map<String, dynamic>>? getCachedData(String key) {
    return _dataCache[key];
  }

  /// Clear all cached data
  void clearCache() {
    _dataCache.clear();
  }

  /// Get connection status
  bool getConnectionStatus() {
    return _isConnected;
  }

  /// Force refresh data for a specific subscription
  Future<void> refreshData(String type, String id) async() {
    switch (type) {
      case 'members':
        await _loadInitialMembers(id);
        break;
      case 'requests':
        await _loadInitialRequests(id);
        break;
      case 'messages':
        await _loadInitialChatMessages(id);
        break;
      case 'notifications':
        await _loadInitialNotifications(id);
        break;
      case 'activities':
        await _loadInitialActivities(id);
        break;
    }
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _membersController.close();
    _requestsController.close();
    _chatMessagesController.close();
    _notificationsController.close();
    _activitiesController.close();
    _connectionController.close();
  }
}
