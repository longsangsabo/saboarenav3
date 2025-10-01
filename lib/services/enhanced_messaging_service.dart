import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/messaging_service.dart';
import '../models/messaging_models.dart';
import 'package:flutter/foundation.dart';

class EnhancedMessagingService extends MessagingService() {
  static final EnhancedMessagingService _instance = EnhancedMessagingService._internal();
  factory EnhancedMessagingService() => _instance;
  EnhancedMessagingService._internal();

  static EnhancedMessagingService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  /// Get typing indicators for a chat room
  Future<List<TypingIndicator>> getTypingIndicators(String chatId) async() {
    try() {
      final response = await _supabase
          .from('typing_indicators')
          .select('''
            chat_id,
            user_id,
            is_typing,
            last_typed_at,
            user:user_id(full_name, avatar_url)
          ''')
          .eq('chat_id', chatId)
          .eq('is_typing', true)
          .gt('last_typed_at', DateTime.now().subtract(Duration(seconds: 10)).toIso8601String());

      return response.map((item) => TypingIndicator.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting typing indicators: $e');
      return [];
    }
  }

  /// Update typing status
  Future<void> updateTypingStatus({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async() {
    try() {
      await _supabase.from('typing_indicators').upsert({
        'chat_id': chatId,
        'user_id': userId,
        'is_typing': isTyping,
        'last_typed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  /// Get chat participants with extended info
  Future<List<ChatParticipant>> getChatParticipants(String chatId) async() {
    try() {
      final response = await _supabase.rpc('get_chat_participants', params: {
        'chat_room_id': chatId,
      });

      return (response as List).map((item) => ChatParticipant.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting chat participants: $e');
      return [];
    }
  }

  /// Send message with extended features
  Future<ChatMessage?> sendEnhancedMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
    String? fileUrl,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final messageData = {
        'room_id': roomId,
        'sender_id': currentUser.id,
        'content': content,
        'message_type': messageType,
        'file_url': fileUrl,
        'reply_to_message_id': replyToMessageId,
        'metadata': metadata,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select('''
            id,
            content,
            sender_id,
            created_at,
            message_type,
            file_url,
            is_read,
            reply_to_message_id,
            metadata,
            sender:sender_id(full_name, avatar_url)
          ''')
          .single();

      // Update room's last message timestamp
      await _supabase.from('chat_rooms').update({
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);

      return ChatMessage.fromJson(response);
    } catch (e) {
      debugPrint('Error sending enhanced message: $e');
      return null;
    }
  }

  /// Delete message
  Future<bool> deleteMessage(String messageId) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('chat_messages')
          .update({
            "content": 'Message deleted',
            "message_type": 'deleted',
            'metadata': {'deleted_at': DateTime.now().toIso8601String()}
          })
          .eq('id', messageId)
          .eq('sender_id', currentUser.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Edit message
  Future<bool> editMessage(String messageId, String newContent) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('chat_messages')
          .update({
            'content': newContent,
            'metadata': {'edited_at': DateTime.now().toIso8601String()}
          })
          .eq('id', messageId)
          .eq('sender_id', currentUser.id);

      return true;
    } catch (e) {
      debugPrint('Error editing message: $e');
      return false;
    }
  }

  /// Search messages in a chat room
  Future<List<ChatMessage>> searchMessages({
    required String roomId,
    required String query,
    int limit = 20,
  }) async() {
    try() {
      final response = await _supabase.rpc('search_chat_messages', params: {
        'room_id_param': roomId,
        'search_query': query,
        'result_limit': limit,
      });

      return (response as List).map((item) => ChatMessage.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  /// Get online status of users
  Future<Map<String, bool>> getUsersOnlineStatus(List<String> userIds) async() {
    try() {
      final response = await _supabase.rpc('get_users_online_status', params: {
        'user_ids': userIds,
      });

      return Map<String, bool>.from(response ?? {});
    } catch (e) {
      debugPrint('Error getting users online status: $e');
      return {};
    }
  }

  /// Subscribe to typing indicators
  RealtimeChannel subscribeToTypingIndicators(String chatId, Function(List<TypingIndicator>) onTypingChanged) {
    return _supabase
        .channel('typing_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'typing_indicators',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) async() {
            final indicators = await getTypingIndicators(chatId);
            onTypingChanged(indicators);
          },
        )
        .subscribe();
  }

  /// Subscribe to user online status changes
  RealtimeChannel subscribeToUserPresence(List<String> userIds, Function(Map<String, bool>) onPresenceChanged) {
    return _supabase
        .channel('presence_${userIds.join('_')}')
        .onPresenceSync((syncs) async() {
          final status = await getUsersOnlineStatus(userIds);
          onPresenceChanged(status);
        })
        .subscribe();
  }

  /// Upload file for messaging
  Future<String?> uploadMessageFile(String filePath, String fileName) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final fileBytes = await _readFileBytes(filePath);
      final storagePath = 'chat_files/${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('chat-files')
          .uploadBinary(storagePath, fileBytes);

      final url = _supabase.storage
          .from('chat-files')
          .getPublicUrl(storagePath);

      return url;
    } catch (e) {
      debugPrint('Error uploading message file: $e');
      return null;
    }
  }

  /// Helper method to read file bytes (implementation depends on platform)
  Future<List<int>> _readFileBytes(String filePath) async() {
    // This is a placeholder - actual implementation would depend on platform
    // For mobile: use dart:io File
    // For web: use html FileReader
    throw UnimplementedError('File reading not implemented for this platform');
  }
}