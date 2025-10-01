/// Notification models for SABO Arena app
/// Chứa tất cả data models liên quan đến notification system
library;

import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? actionUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final NotificationPriority priority;
  final String? imageUrl;
  final String? sourceUserId; // User who triggered this notification
  final String? sourceUserName;
  final String? sourceUserAvatar;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.actionUrl,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.priority = NotificationPriority.normal,
    this.imageUrl,
    this.sourceUserId,
    this.sourceUserName,
    this.sourceUserAvatar,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      actionUrl: json['action_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      priority: NotificationPriority.fromString(json['priority'] as String? ?? 'normal'),
      imageUrl: json['image_url'] as String?,
      sourceUserId: json['source_user_id'] as String?,
      sourceUserName: json['source_user_name'] as String?,
      sourceUserAvatar: json['source_user_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'action_url': actionUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'priority': priority.value,
      'image_url': imageUrl,
      'source_user_id': sourceUserId,
      'source_user_name': sourceUserName,
      'source_user_avatar': sourceUserAvatar,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    NotificationPriority? priority,
    String? imageUrl,
    String? sourceUserId,
    String? sourceUserName,
    String? sourceUserAvatar,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      priority: priority ?? this.priority,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUserId: sourceUserId ?? this.sourceUserId,
      sourceUserName: sourceUserName ?? this.sourceUserName,
      sourceUserAvatar: sourceUserAvatar ?? this.sourceUserAvatar,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, type: ${type.value}, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Notification types với display names và descriptions
enum NotificationType {
  tournamentInvitation('tournament_invitation'),
  tournamentRegistration('tournament_registration'),
  matchResult('match_result'),
  clubAnnouncement('club_announcement'),
  rankUpdate('rank_update'),
  friendRequest('friend_request'),
  challengeRequest('challenge_request'),
  systemNotification('system_notification'),
  general('general');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.general,
    );
  }

  String get displayName() {
    switch (this) {
      case NotificationType.tournamentInvitation:
        return 'Tournament Invitations';
      case NotificationType.tournamentRegistration:
        return 'Tournament Registration';
      case NotificationType.matchResult:
        return 'Match Results';
      case NotificationType.clubAnnouncement:
        return 'Club Announcements';
      case NotificationType.rankUpdate:
        return 'Rank Updates';
      case NotificationType.friendRequest:
        return 'Friend Requests';
      case NotificationType.challengeRequest:
        return 'Challenge Requests';
      case NotificationType.systemNotification:
        return 'System Notifications';
      case NotificationType.general:
        return 'General Notifications';
    }
  }

  String get description() {
    switch (this) {
      case NotificationType.tournamentInvitation:
        return 'Get notified when invited to tournaments';
      case NotificationType.tournamentRegistration:
        return 'Updates about tournament registrations';
      case NotificationType.matchResult:
        return 'Results from your matches and games';
      case NotificationType.clubAnnouncement:
        return 'Important announcements from your clubs';
      case NotificationType.rankUpdate:
        return 'Changes in your ranking position';
      case NotificationType.friendRequest:
        return 'New friend requests and acceptances';
      case NotificationType.challengeRequest:
        return 'Challenge invitations from other players';
      case NotificationType.systemNotification:
        return 'System updates and maintenance notices';
      case NotificationType.general:
        return 'Other notifications';
    }
  }
}

/// Notification priority levels
enum NotificationPriority {
  low('low'),
  normal('normal'),
  high('high'),
  urgent('urgent');

  const NotificationPriority(this.value);
  final String value;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => NotificationPriority.normal,
    );
  }

  String get displayName() {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  int get androidPriority() {
    switch (this) {
      case NotificationPriority.low:
        return 0; // PRIORITY_MIN
      case NotificationPriority.normal:
        return 1; // PRIORITY_DEFAULT
      case NotificationPriority.high:
        return 2; // PRIORITY_HIGH
      case NotificationPriority.urgent:
        return 2; // PRIORITY_MAX
    }
  }
}

/// Local notification payload for action handling
class LocalNotificationPayload {
  final String notificationId;
  final NotificationType type;
  final String? actionUrl;
  final Map<String, dynamic> data;

  LocalNotificationPayload({
    required this.notificationId,
    required this.type,
    this.actionUrl,
    this.data = const {},
  });

  factory LocalNotificationPayload.fromJson(String json) {
    final Map<String, dynamic> map = 
        Map<String, dynamic>.from(Uri.splitQueryString(json));
    
    return LocalNotificationPayload(
      notificationId: map['notificationId'] as String,
      type: NotificationType.fromString(map['type'] as String),
      actionUrl: map['actionUrl'] as String?,
      data: map['data'] != null 
          ? Map<String, dynamic>.from(Uri.splitQueryString(map['data'] as String))
          : {},
    );
  }

  String toJson() {
    final Map<String, String> map = {
      'notificationId': notificationId,
      'type': type.value,
    };
    
    if (actionUrl != null) {
      map['actionUrl'] = actionUrl!;
    }
    
    if (data.isNotEmpty) {
      map['data'] = Uri.encodeQueryComponent(data.toString());
    }
    
    return Uri(queryParameters: map).query;
  }
}

/// Notification statistics for analytics
class NotificationStats {
  final int totalNotifications;
  final int unreadCount;
  final int readCount;
  final double readRate;
  final Map<NotificationType, int> typeBreakdown;
  final Map<NotificationType, double> typeReadRates;
  final DateTime? lastNotificationAt;
  final DateTime? lastReadAt;

  NotificationStats({
    required this.totalNotifications,
    required this.unreadCount,
    required this.readCount,
    required this.readRate,
    required this.typeBreakdown,
    required this.typeReadRates,
    this.lastNotificationAt,
    this.lastReadAt,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      totalNotifications: json['total_notifications'] as int,
      unreadCount: json['unread_count'] as int,
      readCount: json['read_count'] as int,
      readRate: (json['read_rate'] as num).toDouble(),
      typeBreakdown: Map<NotificationType, int>.from(
        (json['type_breakdown'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(NotificationType.fromString(k), v as int),
        ),
      ),
      typeReadRates: Map<NotificationType, double>.from(
        (json['type_read_rates'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(NotificationType.fromString(k), (v as num).toDouble()),
        ),
      ),
      lastNotificationAt: json['last_notification_at'] != null
          ? DateTime.parse(json['last_notification_at'] as String)
          : null,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'total_notifications': totalNotifications,
      'unread_count': unreadCount,
      'read_count': readCount,
      'read_rate': readRate,
      'type_breakdown': typeBreakdown.map((k, v) => MapEntry(k.value, v)),
      'type_read_rates': typeReadRates.map((k, v) => MapEntry(k.value, v)),
      'last_notification_at': lastNotificationAt?.toIso8601String(),
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }
}

/// Notification action (for action buttons)
class NotificationAction {
  final String id;
  final String title;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final bool destructive;

  NotificationAction({
    required this.id,
    required this.title,
    this.actionUrl,
    this.data,
    this.destructive = false,
  });

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] as String,
      title: json['title'] as String,
      actionUrl: json['action_url'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      destructive: json['destructive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'title': title,
      'action_url': actionUrl,
      'data': data,
      'destructive': destructive,
    };
  }
}

/// Notification template for creating consistent notifications
class NotificationTemplate {
  final NotificationType type;
  final String titleTemplate;
  final String bodyTemplate;
  final NotificationPriority defaultPriority;
  final List<NotificationAction>? actions;
  final String? defaultActionUrl;

  NotificationTemplate({
    required this.type,
    required this.titleTemplate,
    required this.bodyTemplate,
    this.defaultPriority = NotificationPriority.normal,
    this.actions,
    this.defaultActionUrl,
  });

  /// Create notification from template with variables
  NotificationModel createNotification({
    required String userId,
    required Map<String, String> variables,
    String? imageUrl,
    String? sourceUserId,
    String? sourceUserName,
    String? sourceUserAvatar,
    NotificationPriority? priority,
  }) {
    String title = titleTemplate;
    String body = bodyTemplate;
    String? actionUrl = defaultActionUrl;

    // Replace variables in templates
    variables.forEach((key, value) {
      title = title.replaceAll('{{$key}}', value);
      body = body.replaceAll('{{$key}}', value);
      actionUrl = actionUrl?.replaceAll('{{$key}}', value);
    });

    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: variables,
      actionUrl: actionUrl,
      createdAt: DateTime.now(),
      priority: priority ?? defaultPriority,
      imageUrl: imageUrl,
      sourceUserId: sourceUserId,
      sourceUserName: sourceUserName,
      sourceUserAvatar: sourceUserAvatar,
    );
  }
}

/// Built-in notification templates
class NotificationTemplates {
  static final Map<NotificationType, NotificationTemplate> templates = {
    NotificationType.tournamentInvitation: NotificationTemplate(
      type: NotificationType.tournamentInvitation,
      titleTemplate: 'Tournament Invitation',
      bodyTemplate: 'You\'re invited to join {{tournament_name}} by {{inviter_name}}',
      defaultPriority: NotificationPriority.high,
      defaultActionUrl: '/tournaments/{{tournament_id}}',
      actions: [
        NotificationAction(
          id: 'accept',
          title: 'Accept',
          actionUrl: '/tournaments/{{tournament_id}}/join',
        ),
        NotificationAction(
          id: 'decline',
          title: 'Decline',
          destructive: true,
        ),
      ],
    ),
    
    NotificationType.matchResult: NotificationTemplate(
      type: NotificationType.matchResult,
      titleTemplate: 'Match Result',
      bodyTemplate: 'Your match against {{opponent_name}} has finished. {{result}}',
      defaultActionUrl: '/matches/{{match_id}}',
    ),
    
    NotificationType.friendRequest: NotificationTemplate(
      type: NotificationType.friendRequest,
      titleTemplate: 'Friend Request',
      bodyTemplate: '{{sender_name}} wants to be your friend',
      defaultActionUrl: '/friends/requests',
      actions: [
        NotificationAction(
          id: 'accept',
          title: 'Accept',
        ),
        NotificationAction(
          id: 'decline',
          title: 'Decline',
          destructive: true,
        ),
      ],
    ),
    
    NotificationType.rankUpdate: NotificationTemplate(
      type: NotificationType.rankUpdate,
      titleTemplate: 'Rank Update',
      bodyTemplate: 'Your rank has {{change_type}} to #{{new_rank}} in {{category}}!',
      defaultActionUrl: '/profile/ranks',
    ),
    
    NotificationType.clubAnnouncement: NotificationTemplate(
      type: NotificationType.clubAnnouncement,
      titleTemplate: 'Club Announcement',
      bodyTemplate: '{{club_name}}: {{message}}',
      defaultActionUrl: '/clubs/{{club_id}}/announcements',
    ),
  };

  static NotificationTemplate? getTemplate(NotificationType type) {
    return templates[type];
  }
}

/// Notification preferences model for user settings
class NotificationPreferences {
  final String userId;
  final bool enablePushNotifications;
  final bool enableInAppNotifications;
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final Map<NotificationType, NotificationTypeSetting> typeSettings;
  final bool enableQuietHours;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final NotificationSound soundSetting;
  final bool vibrationEnabled;
  final DateTime? lastUpdated;

  NotificationPreferences({
    required this.userId,
    this.enablePushNotifications = true,
    this.enableInAppNotifications = true,
    this.enableEmailNotifications = false,
    this.enableSmsNotifications = false,
    this.typeSettings = const {},
    this.enableQuietHours = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.soundSetting = NotificationSound.defaultSound,
    this.vibrationEnabled = true,
    this.lastUpdated,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'] as String,
      enablePushNotifications: json['enable_push_notifications'] as bool? ?? true,
      enableInAppNotifications: json['enable_in_app_notifications'] as bool? ?? true,
      enableEmailNotifications: json['enable_email_notifications'] as bool? ?? false,
      enableSmsNotifications: json['enable_sms_notifications'] as bool? ?? false,
      typeSettings: (json['type_settings'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          NotificationType.fromString(key),
          NotificationTypeSetting.fromJson(value as Map<String, dynamic>),
        ),
      ) ?? {},
      enableQuietHours: json['enable_quiet_hours'] as bool? ?? false,
      quietHoursStart: json['quiet_hours_start'] != null 
        ? TimeOfDay.fromDateTime(DateTime.parse(json['quiet_hours_start'] as String))
        : null,
      quietHoursEnd: json['quiet_hours_end'] != null
        ? TimeOfDay.fromDateTime(DateTime.parse(json['quiet_hours_end'] as String))
        : null,
      soundSetting: NotificationSound.fromString(json['sound_setting'] as String? ?? 'default'),
      vibrationEnabled: json['vibration_enabled'] as bool? ?? true,
      lastUpdated: json['last_updated'] != null
        ? DateTime.parse(json['last_updated'] as String)
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'user_id': userId,
      'enable_push_notifications': enablePushNotifications,
      'enable_in_app_notifications': enableInAppNotifications,
      'enable_email_notifications': enableEmailNotifications,
      'enable_sms_notifications': enableSmsNotifications,
      'type_settings': typeSettings.map(
        (key, value) => MapEntry(key.toString(), value.toJson()),
      ),
      'enable_quiet_hours': enableQuietHours,
      'quiet_hours_start': quietHoursStart?.format24Hour(),
      'quiet_hours_end': quietHoursEnd?.format24Hour(),
      'sound_setting': soundSetting.toString(),
      'vibration_enabled': vibrationEnabled,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

/// Notification type specific settings
class NotificationTypeSetting {
  final NotificationType type;
  final bool enabled;
  final NotificationSound? customSound;
  final bool useVibration;
  final NotificationPriority priority;

  NotificationTypeSetting({
    required this.type,
    this.enabled = true,
    this.customSound,
    this.useVibration = true,
    this.priority = NotificationPriority.normal,
  });

  factory NotificationTypeSetting.fromJson(Map<String, dynamic> json) {
    return NotificationTypeSetting(
      type: NotificationType.fromString(json['type'] as String),
      enabled: json['enabled'] as bool? ?? true,
      customSound: json['custom_sound'] != null
        ? NotificationSound.fromString(json['custom_sound'] as String)
        : null,
      useVibration: json['use_vibration'] as bool? ?? true,
      priority: NotificationPriority.fromString(json['priority'] as String? ?? 'normal'),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'type': type.toString(),
      'enabled': enabled,
      'custom_sound': customSound?.toString(),
      'use_vibration': useVibration,
      'priority': priority.toString(),
    };
  }
}

/// Notification sound settings
enum NotificationSound {
  defaultSound,
  none,
  chime,
  bell,
  alert,
  custom;

  static NotificationSound fromString(String value) {
    switch (value.toLowerCase()) {
      case 'default':
        return NotificationSound.defaultSound;
      case 'none':
        return NotificationSound.none;
      case 'chime':
        return NotificationSound.chime;
      case 'bell':
        return NotificationSound.bell;
      case 'alert':
        return NotificationSound.alert;
      case 'custom':
        return NotificationSound.custom;
      default:
        return NotificationSound.defaultSound;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NotificationSound.defaultSound:
        return 'default';
      case NotificationSound.none:
        return 'none';
      case NotificationSound.chime:
        return 'chime';
      case NotificationSound.bell:
        return 'bell';
      case NotificationSound.alert:
        return 'alert';
      case NotificationSound.custom:
        return 'custom';
    }
  }
}

/// Notification channel for Android
class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final NotificationPriority importance;
  final NotificationSound sound;
  final bool enableVibration;
  final bool enableLights;

  NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    this.importance = NotificationPriority.normal,
    this.sound = NotificationSound.defaultSound,
    this.enableVibration = true,
    this.enableLights = true,
  });

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'name': name,
      'description': description,
      'importance': importance.toString(),
      'sound': sound.toString(),
      'enable_vibration': enableVibration,
      'enable_lights': enableLights,
    };
  }
}

/// Extensions for TimeOfDay
extension TimeOfDayExtension on TimeOfDay {
  String format24Hour() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static TimeOfDay fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }
}