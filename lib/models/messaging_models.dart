/// Messaging models for SABO Arena app
/// Contains comprehensive data models for chat system
library;

import 'package:flutter/material.dart';

/// Message model representing a single chat message
class MessageModel() {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final Map<String, dynamic> metadata;
  final String? replyToMessageId;
  final DateTime createdAt;
  final DateTime? serverTimestamp;
  final DateTime? editedAt;
  final bool isEdited;
  final MessageStatus status;
  final List<MessageReaction> reactions;
  final MessageModel? replyToMessage;
  final UserProfile? sender;
  final bool isEncrypted;
  final List<String> mentionedUserIds;
  final bool isForwarded;
  final String? forwardedFromChatId;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.metadata = const {},
    this.replyToMessageId,
    required this.createdAt,
    this.serverTimestamp,
    this.editedAt,
    this.isEdited = false,
    this.status = MessageStatus.sending,
    this.reactions = const [],
    this.replyToMessage,
    this.sender,
    this.isEncrypted = false,
    this.mentionedUserIds = const [],
    this.isForwarded = false,
    this.forwardedFromChatId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      type: MessageType.fromString(json['type'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      replyToMessageId: json['reply_to_message_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      serverTimestamp: json['server_timestamp'] != null 
          ? DateTime.parse(json['server_timestamp'] as String) 
          : null,
      editedAt: json['edited_at'] != null 
          ? DateTime.parse(json['edited_at'] as String) 
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
      status: MessageStatus.fromString(json['status'] as String? ?? 'sent'),
      reactions: (json['reactions'] as List?)
          ?.map((r) => MessageReaction.fromJson(r))
          .toList() ?? [],
      replyToMessage: json['reply_to'] != null 
          ? MessageModel.fromJson(json['reply_to']) 
          : null,
      sender: json['sender'] != null 
          ? UserProfile.fromJson(json['sender']) 
          : null,
      isEncrypted: json['is_encrypted'] as bool? ?? false,
      mentionedUserIds: List<String>.from(json['mentioned_user_ids'] ?? []),
      isForwarded: json['is_forwarded'] as bool? ?? false,
      forwardedFromChatId: json['forwarded_from_chat_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'type': type.value,
      'metadata': metadata,
      'reply_to_message_id': replyToMessageId,
      'created_at': createdAt.toIso8601String(),
      'server_timestamp': serverTimestamp?.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'is_edited': isEdited,
      'status': status.value,
      'reactions': reactions.map((r) => r.toJson()).toList(),
      'is_encrypted': isEncrypted,
      'mentioned_user_ids': mentionedUserIds,
      'is_forwarded': isForwarded,
      'forwarded_from_chat_id': forwardedFromChatId,
    };
  }

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    Map<String, dynamic>? metadata,
    String? replyToMessageId,
    DateTime? createdAt,
    DateTime? serverTimestamp,
    DateTime? editedAt,
    bool? isEdited,
    MessageStatus? status,
    List<MessageReaction>? reactions,
    MessageModel? replyToMessage,
    UserProfile? sender,
    bool? isEncrypted,
    List<String>? mentionedUserIds,
    bool? isForwarded,
    String? forwardedFromChatId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      createdAt: createdAt ?? this.createdAt,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      editedAt: editedAt ?? this.editedAt,
      isEdited: isEdited ?? this.isEdited,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      sender: sender ?? this.sender,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFromChatId: forwardedFromChatId ?? this.forwardedFromChatId,
    );
  }

  /// Get display content based on message type
  String get displayContent() {
    switch (type) {
      case MessageType.text:
        return content;
      case MessageType.image:
        return '📷 Image';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.file:
        return '📎 ${metadata['file_name'] ?? 'File'}';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.location:
        return '📍 Location';
      case MessageType.system:
        return content;
    }
  }

  /// Check if message is from current user
  bool isFromCurrentUser(String currentUserId) => senderId == currentUserId;

  /// Get image URL from metadata
  String? get imageUrl => metadata['image_url'] as String?;

  /// Get file URL from metadata
  String? get fileUrl => metadata['file_url'] as String?;

  /// Get audio URL from metadata
  String? get audioUrl => metadata['audio_url'] as String?;

  /// Get file size from metadata
  int? get fileSize => metadata['file_size'] as int?;

  /// Get duration for voice messages
  int? get durationMs => metadata['duration_ms'] as int?;

  @override
  String toString() => 'MessageModel(id: $id, type: ${type.value}, content: $content)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Chat model representing a conversation
class ChatModel() {
  final String id;
  final String name;
  final String? description;
  final ChatType type;
  final String? avatarUrl;
  final List<ChatParticipant> participants;
  final MessageModel? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final ChatSettings settings;
  final int unreadCount;
  final bool isArchived;
  final bool isMuted;
  final DateTime? mutedUntil;
  final Map<String, dynamic> metadata;

  ChatModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.avatarUrl,
    required this.participants,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.settings,
    this.unreadCount = 0,
    this.isArchived = false,
    this.isMuted = false,
    this.mutedUntil,
    this.metadata = const {},
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: ChatType.fromString(json['type'] as String),
      avatarUrl: json['avatar_url'] as String?,
      participants: (json['participants'] as List?)
          ?.map((p) => ChatParticipant.fromJson(p))
          .toList() ?? [],
      lastMessage: json['last_message'] != null 
          ? MessageModel.fromJson(json['last_message']) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
      settings: json['settings'] != null 
          ? ChatSettings.fromJson(json['settings']) 
          : ChatSettings.defaultSettings(),
      unreadCount: json['unread_count'] as int? ?? 0,
      isArchived: json['is_archived'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
      mutedUntil: json['muted_until'] != null 
          ? DateTime.parse(json['muted_until']) 
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'name': name,
      'description': description,
      'type': type.value,
      'avatar_url': avatarUrl,
      'participants': participants.map((p) => p.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'settings': settings.toJson(),
      'unread_count': unreadCount,
      'is_archived': isArchived,
      'is_muted': isMuted,
      'muted_until': mutedUntil?.toIso8601String(),
      'metadata': metadata,
    };
  }

  ChatModel copyWith({
    String? id,
    String? name,
    String? description,
    ChatType? type,
    String? avatarUrl,
    List<ChatParticipant>? participants,
    MessageModel? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    ChatSettings? settings,
    int? unreadCount,
    bool? isArchived,
    bool? isMuted,
    DateTime? mutedUntil,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      settings: settings ?? this.settings,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get other participant in private chat
  ChatParticipant? getOtherParticipant(String currentUserId) {
    if (type == ChatType.private) {
      return participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => participants.first,
      );
    }
    return null;
  }

  /// Get display name for chat
  String getDisplayName(String currentUserId) {
    if (type == ChatType.private) {
      final otherParticipant = getOtherParticipant(currentUserId);
      return otherParticipant?.user?.username ?? 'Unknown';
    }
    return name;
  }

  /// Get display avatar for chat
  String? getDisplayAvatar(String currentUserId) {
    if (type == ChatType.private) {
      final otherParticipant = getOtherParticipant(currentUserId);
      return otherParticipant?.user?.avatarUrl;
    }
    return avatarUrl;
  }

  /// Check if user is admin
  bool isUserAdmin(String userId) {
    final participant = participants.firstWhere(
      (p) => p.userId == userId,
      orElse: () => ChatParticipant(
        userId: userId,
        role: ChatRole.member,
        joinedAt: DateTime.now(),
      ),
    );
    return participant.role == ChatRole.admin;
  }

  /// Get participant count
  int get participantCount => participants.length;

  /// Get online participants
  List<ChatParticipant> get onlineParticipants() {
    return participants
        .where((p) => p.user?.status == UserStatus.online)
        .toList();
  }
}

/// Chat participant model
class ChatParticipant() {
  final String userId;
  final ChatRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isActive;
  final UserProfile? user;
  final DateTime? lastSeenAt;
  final Map<String, dynamic> permissions;

  ChatParticipant({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.isActive = true,
    this.user,
    this.lastSeenAt,
    this.permissions = const {},
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['user_id'] as String,
      role: ChatRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] != null 
          ? DateTime.parse(json['left_at']) 
          : null,
      isActive: json['is_active'] as bool? ?? true,
      user: json['user'] != null 
          ? UserProfile.fromJson(json['user']) 
          : null,
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.parse(json['last_seen_at']) 
          : null,
      permissions: json['permissions'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'user_id': userId,
      'role': role.value,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_active': isActive,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'permissions': permissions,
    };
  }
}

/// User profile model for messaging
class UserProfile() {
  final String id;
  final String username;
  final String? avatarUrl;
  final UserStatus status;
  final DateTime? lastSeenAt;
  final String? statusMessage;

  UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.status = UserStatus.offline,
    this.lastSeenAt,
    this.statusMessage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      status: UserStatus.fromString(json['status'] as String? ?? 'offline'),
      lastSeenAt: json['last_seen_at'] != null 
          ? DateTime.parse(json['last_seen_at']) 
          : null,
      statusMessage: json['status_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'status': status.value,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'status_message': statusMessage,
    };
  }
}

/// Message reaction model
class MessageReaction() {
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;
  final UserProfile? user;

  MessageReaction({
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
    this.user,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null 
          ? UserProfile.fromJson(json['user']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'message_id': messageId,
      'user_id': userId,
      'emoji': emoji,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Chat settings model
class ChatSettings() {
  final bool allowMembersToAddOthers;
  final bool allowMembersToEditInfo;
  final bool onlyAdminsCanSendMessages;
  final bool disappearingMessages;
  final Duration? disappearingMessagesDuration;
  final bool readReceipts;
  final bool typingIndicators;
  final int maxParticipants;

  ChatSettings({
    this.allowMembersToAddOthers = true,
    this.allowMembersToEditInfo = false,
    this.onlyAdminsCanSendMessages = false,
    this.disappearingMessages = false,
    this.disappearingMessagesDuration,
    this.readReceipts = true,
    this.typingIndicators = true,
    this.maxParticipants = 256,
  });

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      allowMembersToAddOthers: json['allow_members_to_add_others'] as bool? ?? true,
      allowMembersToEditInfo: json['allow_members_to_edit_info'] as bool? ?? false,
      onlyAdminsCanSendMessages: json['only_admins_can_send_messages'] as bool? ?? false,
      disappearingMessages: json['disappearing_messages'] as bool? ?? false,
      disappearingMessagesDuration: json['disappearing_messages_duration'] != null
          ? Duration(seconds: json['disappearing_messages_duration'] as int)
          : null,
      readReceipts: json['read_receipts'] as bool? ?? true,
      typingIndicators: json['typing_indicators'] as bool? ?? true,
      maxParticipants: json['max_participants'] as int? ?? 256,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'allow_members_to_add_others': allowMembersToAddOthers,
      'allow_members_to_edit_info': allowMembersToEditInfo,
      'only_admins_can_send_messages': onlyAdminsCanSendMessages,
      'disappearing_messages': disappearingMessages,
      'disappearing_messages_duration': disappearingMessagesDuration?.inSeconds,
      'read_receipts': readReceipts,
      'typing_indicators': typingIndicators,
      'max_participants': maxParticipants,
    };
  }

  static ChatSettings defaultSettings() => ChatSettings();
}

/// Typing indicator model
class TypingIndicator() {
  final String chatId;
  final String userId;
  final bool isTyping;
  final DateTime lastTypedAt;
  final UserProfile? user;

  TypingIndicator({
    required this.chatId,
    required this.userId,
    required this.isTyping,
    required this.lastTypedAt,
    this.user,
  });

  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      chatId: json['chat_id'] as String,
      userId: json['user_id'] as String,
      isTyping: json['is_typing'] as bool,
      lastTypedAt: DateTime.parse(json['last_typed_at'] as String),
      user: json['user'] != null 
          ? UserProfile.fromJson(json['user']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'chat_id': chatId,
      'user_id': userId,
      'is_typing': isTyping,
      'last_typed_at': lastTypedAt.toIso8601String(),
    };
  }
}

/// Enums

enum MessageType() {
  text('text'),
  image('image'),
  video('video'),
  file('file'),
  voice('voice'),
  location('location'),
  system('system');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }

  String get displayName() {
    switch (this) {
      case MessageType.text:
        return 'Text';
      case MessageType.image:
        return 'Image';
      case MessageType.video:
        return 'Video';
      case MessageType.file:
        return 'File';
      case MessageType.voice:
        return 'Voice';
      case MessageType.location:
        return 'Location';
      case MessageType.system:
        return 'System';
    }
  }

  IconData get icon() {
    switch (this) {
      case MessageType.text:
        return Icons.text_fields;
      case MessageType.image:
        return Icons.image;
      case MessageType.video:
        return Icons.videocam;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.voice:
        return Icons.mic;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.system:
        return Icons.info;
    }
  }
}

enum MessageStatus() {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);
  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => MessageStatus.sent,
    );
  }

  String get displayName() {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  IconData get icon() {
    switch (this) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  Color get color() {
    switch (this) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }
}

enum ChatType() {
  private('private'),
  group('group'),
  channel('channel');

  const ChatType(this.value);
  final String value;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ChatType.private,
    );
  }

  String get displayName() {
    switch (this) {
      case ChatType.private:
        return 'Private Chat';
      case ChatType.group:
        return 'Group Chat';
      case ChatType.channel:
        return 'Channel';
    }
  }

  IconData get icon() {
    switch (this) {
      case ChatType.private:
        return Icons.person;
      case ChatType.group:
        return Icons.group;
      case ChatType.channel:
        return Icons.campaign;
    }
  }
}

enum ChatRole() {
  member('member'),
  admin('admin'),
  owner('owner');

  const ChatRole(this.value);
  final String value;

  static ChatRole fromString(String value) {
    return ChatRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => ChatRole.member,
    );
  }

  String get displayName() {
    switch (this) {
      case ChatRole.member:
        return 'Member';
      case ChatRole.admin:
        return 'Admin';
      case ChatRole.owner:
        return 'Owner';
    }
  }
}

enum UserStatus() {
  online('online'),
  away('away'),
  busy('busy'),
  offline('offline');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.offline,
    );
  }

  String get displayName() {
    switch (this) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.away:
        return 'Away';
      case UserStatus.busy:
        return 'Busy';
      case UserStatus.offline:
        return 'Offline';
    }
  }

  Color get color() {
    switch (this) {
      case UserStatus.online:
        return Colors.green;
      case UserStatus.away:
        return Colors.orange;
      case UserStatus.busy:
        return Colors.red;
      case UserStatus.offline:
        return Colors.grey;
    }
  }
}

/// Message templates for common message types
class MessageTemplates() {
  static MessageModel createSystemMessage({
    required String chatId,
    required String content,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: 'system',
      content: content,
      type: MessageType.system,
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
      metadata: metadata ?? {},
    );
  }

  static MessageModel createUserJoinedMessage({
    required String chatId,
    required String username,
  }) {
    return createSystemMessage(
      chatId: chatId,
      content: '$username joined the chat',
      metadata: {"event_type": 'user_joined'},
    );
  }

  static MessageModel createUserLeftMessage({
    required String chatId,
    required String username,
  }) {
    return createSystemMessage(
      chatId: chatId,
      content: '$username left the chat',
      metadata: {"event_type": 'user_left'},
    );
  }

  static MessageModel createChatCreatedMessage({
    required String chatId,
    required String creatorName,
  }) {
    return createSystemMessage(
      chatId: chatId,
      content: '$creatorName created this chat',
      metadata: {"event_type": 'chat_created'},
    );
  }
}