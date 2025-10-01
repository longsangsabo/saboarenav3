import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

class MessagingService() {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  static MessagingService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  /// Get unread message count for current user
  Future<int> getUnreadMessageCount() async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return 0;

      // Get all chat rooms where user is a participant
      final roomsResponse = await _supabase
          .from('chat_rooms')
          .select('id')
          .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}');

      if (roomsResponse.isEmpty) return 0;

      final roomIds = roomsResponse.map((room) => room['id']).toList();

      // Count unread messages in those rooms
      final messagesResponse = await _supabase
          .from('chat_messages')
          .select('id')
          .inFilter('room_id', roomIds)
          .neq('sender_id', currentUser.id) // Not sent by current user
          .eq('is_read', false); // Unread messages

      return messagesResponse.length;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }

  /// Get all chat rooms for current user with last message info
  Future<List<Map<String, dynamic>>> getChatRooms() async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase.rpc('get_user_chat_rooms', params: {
        'current_user_id': currentUser.id,
      });

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Error getting chat rooms: $e');
      return [];
    }
  }

  /// Get messages for a specific chat room
  Future<List<Map<String, dynamic>>> getChatMessages(String roomId, {int limit = 50}) async() {
    try() {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            id,
            content,
            sender_id,
            created_at,
            message_type,
            file_url,
            is_read,
            sender:sender_id(full_name, avatar_url)
          ''')
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }

  /// Send a new message
  Future<bool> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
  }) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase.from('chat_messages').insert({
        'room_id': roomId,
        'sender_id': currentUser.id,
        'content': content,
        'message_type': messageType,
        'file_url': fileUrl,
        'is_read': false,
      });

      // Update room's last message timestamp
      await _supabase.from('chat_rooms').update({
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String roomId) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', currentUser.id); // Only mark messages not sent by current user

    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Create or get existing chat room with another user
  Future<String?> createOrGetChatRoom(String otherUserId) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      // Check if room already exists
      final existingRoom = await _supabase
          .from('chat_rooms')
          .select('id')
          .or('and(user1_id.eq.${currentUser.id},user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.${currentUser.id})')
          .maybeSingle();

      if (existingRoom != null) {
        return existingRoom['id'];
      }

      // Create new room
      final newRoom = await _supabase.from('chat_rooms').insert({
        'user1_id': currentUser.id,
        'user2_id': otherUserId,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      return newRoom['id'];
    } catch (e) {
      debugPrint('Error creating/getting chat room: $e');
      return null;
    }
  }

  /// Subscribe to real-time message updates for a room
  RealtimeChannel subscribeToRoom(String roomId, Function(Map<String, dynamic>) onMessage) {
    return _supabase
        .channel('room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to unread message count changes
  RealtimeChannel subscribeToUnreadCount(Function(int) onCountChanged) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    return _supabase
        .channel('unread_messages_${currentUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) async() {
            // Recalculate unread count when messages change
            final count = await getUnreadMessageCount();
            onCountChanged(count);
          },
        )
        .subscribe();
  }
}