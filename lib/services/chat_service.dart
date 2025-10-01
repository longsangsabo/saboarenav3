class ChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ====================================
  // CHAT ROOMS
  // ====================================

  /// Get chat rooms for current user's clubs
  static Future<List<Map<String, dynamic>>> getChatRooms(
      {String? clubId}) async {
    try {
      var query = _supabase.from('chat_rooms').select('''
        *,
        clubs!inner(name, id),
        chat_room_members!inner(user_id, last_read_at, role),
        chat_messages(
          id,
          message,
          created_at,
          sender_id,
          users!chat_messages_sender_id_fkey(display_name, avatar_url)
        )
      ''');

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }

      final response = await query
          .eq('is_active', true)
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load chat rooms: $e');
    }
  }

  /// Create a new chat room
  static Future<Map<String, dynamic>> createChatRoom({
    required String clubId,
    required String name,
    String? description,
    String type = 'general',
    bool isPrivate = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('chat_rooms')
          .insert({
            'club_id': clubId,
            'name': name,
            'description': description,
            'type': type,
            'is_private': isPrivate,
            'created_by': user.id,
          })
          .select()
          .single();

      // Add creator as admin member
      await _supabase.from('chat_room_members').insert({
        'room_id': response['id'],
        'user_id': user.id,
        "role": 'admin',
      });

      return response;
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  /// Join a chat room
  static Future<void> joinChatRoom(String roomId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('chat_room_members').upsert({
        'room_id': roomId,
        'user_id': user.id,
        "role": 'member',
      });
    } catch (e) {
      throw Exception('Failed to join chat room: $e');
    }
  }

  // ====================================
  // CHAT MESSAGES
  // ====================================

  /// Get messages for a chat room
  static Future<List<Map<String, dynamic>>> getMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            *,
            users!chat_messages_sender_id_fkey(
              id,
              display_name,
              avatar_url,
              rank_type
            ),
            reply_message:chat_messages!chat_messages_reply_to_fkey(
              id,
              message,
              users!chat_messages_sender_id_fkey(display_name)
            )
          ''')
          .eq('room_id', roomId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response.reversed);
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send a message
  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String message,
    String messageType = 'text',
    String? replyTo,
    List<String>? attachments,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'room_id': roomId,
        'sender_id': user.id,
        'message': message,
        'message_type': messageType,
        'reply_to': replyTo,
        'attachments': attachments,
      };

      final response =
          await _supabase.from('chat_messages').insert(messageData).select('''
            *,
            users!chat_messages_sender_id_fkey(
              id,
              display_name,
              avatar_url,
              rank_type
            )
          ''').single();

      // Update last activity in chat room
      await _supabase.from('chat_rooms').update(
          {'updated_at': DateTime.now().toIso8601String()}).eq('id', roomId);

      // Update user's last read time
      await updateLastReadTime(roomId);

      return response;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Update last read time for user in chat room
  static Future<void> updateLastReadTime(String roomId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('chat_room_members')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('room_id', roomId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Failed to update last read time: $e');
    }
  }

  // ====================================
  // REAL-TIME SUBSCRIPTIONS
  // ====================================

  /// Subscribe to new messages in a chat room
  static RealtimeChannel subscribeToMessages({
    required String roomId,
    required Function(Map<String, dynamic>) onMessage,
    Function(Map<String, dynamic>)? onUpdate,
    Function(Map<String, dynamic>)? onDelete,
  }) {
    return _supabase
        .channel('chat_messages_$roomId')
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
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (onUpdate != null) onUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (onDelete != null) onDelete(payload.oldRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to chat room updates
  static RealtimeChannel subscribeToRoomUpdates({
    required String roomId,
    Function(Map<String, dynamic>)? onRoomUpdate,
    Function(Map<String, dynamic>)? onMemberJoin,
    Function(Map<String, dynamic>)? onMemberLeave,
  }) {
    return _supabase
        .channel('chat_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            if (onRoomUpdate != null) onRoomUpdate(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (onMemberJoin != null) onMemberJoin(payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'chat_room_members',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (onMemberLeave != null) onMemberLeave(payload.oldRecord);
          },
        )
        .subscribe();
  }

  // ====================================
  // UTILITY FUNCTIONS
  // ====================================

  /// Get unread message count for a room
  static Future<int> getUnreadCount(String roomId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      // Get user's last read time
      final memberData = await _supabase
          .from('chat_room_members')
          .select('last_read_at')
          .eq('room_id', roomId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberData == null) return 0;

      final lastReadAt = DateTime.parse(memberData['last_read_at']);

      // Count messages after last read time
      final response = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('room_id', roomId)
          .neq('sender_id', user.id) // Don't count own messages
          .gt('created_at', lastReadAt.toIso8601String());

      return response.length;
    } catch (e) {
      debugPrint('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Search messages in a room
  static Future<List<Map<String, dynamic>>> searchMessages({
    required String roomId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('''
            *,
            users!chat_messages_sender_id_fkey(
              id,
              display_name,
              avatar_url
            )
          ''')
          .eq('room_id', roomId)
          .ilike('message', '%$query%')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  /// Delete message (soft delete)
  static Future<void> deleteMessage(String messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('chat_messages')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', user.id); // Can only delete own messages
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Edit message
  static Future<void> editMessage(String messageId, String newMessage) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('chat_messages')
          .update({
            'message': newMessage,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('sender_id', user.id); // Can only edit own messages
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }
}
