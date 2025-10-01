class ChatRoomService {
  static final ChatRoomService _instance = ChatRoomService._internal();
  factory ChatRoomService() => _instance;
  ChatRoomService._internal();

  static ChatRoomService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  /// Get all chat rooms for current user
  Future<List<ChatRoom>> getUserChatRooms() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      final response =
          await _supabase.rpc('get_user_chat_rooms_detailed', params: {
        'current_user_id': currentUser.id,
      });

      return (response as List).map((item) => ChatRoom.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting user chat rooms: $e');
      return [];
    }
  }

  /// Get specific chat room details
  Future<ChatRoom?> getChatRoom(String roomId) async {
    try {
      final response = await _supabase.from('chat_rooms').select('''
            id,
            name,
            description,
            room_type,
            created_at,
            updated_at,
            last_message_at,
            user1_id,
            user2_id,
            user1:user1_id(id, full_name, avatar_url),
            user2:user2_id(id, full_name, avatar_url)
          ''').eq('id', roomId).single();

      return ChatRoom.fromJson(response);
    } catch (e) {
      debugPrint('Error getting chat room: $e');
      return null;
    }
  }

  /// Create a new chat room
  Future<ChatRoom?> createChatRoom({
    required String otherUserId,
    String? name,
    String? description,
    String roomType = 'direct',
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      // Check if direct message room already exists
      if (roomType == 'direct') {
        final existingRoom = await getDirectMessageRoom(otherUserId);
        if (existingRoom != null) return existingRoom;
      }

      final roomData = {
        'name': name,
        'description': description,
        'room_type': roomType,
        'user1_id': currentUser.id,
        'user2_id': otherUserId,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('chat_rooms').insert(roomData).select('''
            id,
            name,
            description,
            room_type,
            created_at,
            updated_at,
            last_message_at,
            user1_id,
            user2_id,
            user1:user1_id(id, full_name, avatar_url),
            user2:user2_id(id, full_name, avatar_url)
          ''').single();

      return ChatRoom.fromJson(response);
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      return null;
    }
  }

  /// Get or create direct message room
  Future<ChatRoom?> getDirectMessageRoom(String otherUserId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('chat_rooms')
          .select('''
            id,
            name,
            description,
            room_type,
            created_at,
            updated_at,
            last_message_at,
            user1_id,
            user2_id,
            user1:user1_id(id, full_name, avatar_url),
            user2:user2_id(id, full_name, avatar_url)
          ''')
          .eq('room_type', 'direct')
          .or('and(user1_id.eq.${currentUser.id},user2_id.eq.$otherUserId),and(user1_id.eq.$otherUserId,user2_id.eq.${currentUser.id})')
          .maybeSingle();

      if (response != null) {
        return ChatRoom.fromJson(response);
      }

      // Create new room if doesn't exist
      return await createChatRoom(otherUserId: otherUserId, roomType: 'direct');
    } catch (e) {
      debugPrint('Error getting direct message room: $e');
      return null;
    }
  }

  /// Update chat room details
  Future<bool> updateChatRoom({
    required String roomId,
    String? name,
    String? description,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('chat_rooms')
          .update(updateData)
          .eq('id', roomId)
          .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}');

      return true;
    } catch (e) {
      debugPrint('Error updating chat room: $e');
      return false;
    }
  }

  /// Delete chat room
  Future<bool> deleteChatRoom(String roomId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      // Only allow deletion if user is participant
      await _supabase
          .from('chat_rooms')
          .delete()
          .eq('id', roomId)
          .or('user1_id.eq.${currentUser.id},user2_id.eq.${currentUser.id}');

      return true;
    } catch (e) {
      debugPrint('Error deleting chat room: $e');
      return false;
    }
  }

  /// Add participant to group chat
  Future<bool> addParticipant({
    required String roomId,
    required String userId,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase.from('chat_participants').insert({
        'room_id': roomId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
        'added_by': currentUser.id,
      });

      return true;
    } catch (e) {
      debugPrint('Error adding participant: $e');
      return false;
    }
  }

  /// Remove participant from group chat
  Future<bool> removeParticipant({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('chat_participants')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error removing participant: $e');
      return false;
    }
  }

  /// Get room participants
  Future<List<ChatParticipant>> getRoomParticipants(String roomId) async {
    try {
      final response = await _supabase.from('chat_participants').select('''
            user_id,
            joined_at,
            role,
            user:user_id(id, full_name, avatar_url, status)
          ''').eq('room_id', roomId);

      return response.map((item) => ChatParticipant.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting room participants: $e');
      return [];
    }
  }

  /// Mute/unmute chat room
  Future<bool> muteRoom(String roomId, bool mute) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase.from('chat_room_settings').upsert({
        'room_id': roomId,
        'user_id': currentUser.id,
        'is_muted': mute,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error muting/unmuting room: $e');
      return false;
    }
  }

  /// Get room settings for current user
  Future<Map<String, dynamic>?> getRoomSettings(String roomId) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('chat_room_settings')
          .select('*')
          .eq('room_id', roomId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error getting room settings: $e');
      return null;
    }
  }

  /// Search chat rooms
  Future<List<ChatRoom>> searchChatRooms(String query) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      final response = await _supabase.rpc('search_user_chat_rooms', params: {
        'current_user_id': currentUser.id,
        'search_query': query,
      });

      return (response as List).map((item) => ChatRoom.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error searching chat rooms: $e');
      return [];
    }
  }

  /// Get room message statistics
  Future<Map<String, dynamic>> getRoomStats(String roomId) async {
    try {
      final response = await _supabase.rpc('get_chat_room_stats', params: {
        'room_id_param': roomId,
      });

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      debugPrint('Error getting room stats: $e');
      return {};
    }
  }

  /// Subscribe to chat room updates
  RealtimeChannel subscribeToRoomUpdates(
      String roomId, Function(Map<String, dynamic>) onUpdate) {
    return _supabase
        .channel('room_updates_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
}
