import 'package:flutter/foundation.dart';

/// State management for Member Management System
/// Using a simple state management pattern similar to Redux
class MemberState {
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> activities;
  final List<Map<String, dynamic>> chatMessages;
  final Map<String, dynamic> analytics;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic> filters;
  final String searchQuery;

  const MemberState({
    this.members = const [],
    this.requests = const [],
    this.notifications = const [],
    this.activities = const [],
    this.chatMessages = const [],
    this.analytics = const {},
    this.isLoading = false,
    this.error,
    this.filters = const {},
    this.searchQuery = '',
  });

  MemberState copyWith({
    List<Map<String, dynamic>>? members,
    List<Map<String, dynamic>>? requests,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? activities,
    List<Map<String, dynamic>>? chatMessages,
    Map<String, dynamic>? analytics,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? filters,
    String? searchQuery,
  }) {
    return MemberState(
      members: members ?? this.members,
      requests: requests ?? this.requests,
      notifications: notifications ?? this.notifications,
      activities: activities ?? this.activities,
      chatMessages: chatMessages ?? this.chatMessages,
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filters: filters ?? this.filters,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  String toString() => 'MemberState(members: ${members.length}, requests: ${requests.length}, '
      'notifications: ${notifications.length}, isLoading: $isLoading, error: $error)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberState &&
        listEquals(other.members, members) &&
        listEquals(other.requests, requests) &&
        listEquals(other.notifications, notifications) &&
        listEquals(other.activities, activities) &&
        listEquals(other.chatMessages, chatMessages) &&
        mapEquals(other.analytics, analytics) &&
        other.isLoading == isLoading &&
        other.error == error &&
        mapEquals(other.filters, filters) &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode() {
    return members.hashCode ^
        requests.hashCode ^
        notifications.hashCode ^
        activities.hashCode ^
        chatMessages.hashCode ^
        analytics.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        filters.hashCode ^
        searchQuery.hashCode;
  }
}

/// Actions for state management
abstract class MemberAction {
  const MemberAction();
}

// Loading actions
class SetLoadingAction extends MemberAction {
  final bool isLoading;
  const SetLoadingAction(this.isLoading);
}

class SetErrorAction extends MemberAction {
  final String? error;
  const SetErrorAction(this.error);
}

// Member actions
class LoadMembersAction extends MemberAction {
  final String clubId;
  const LoadMembersAction(this.clubId);
}

class SetMembersAction extends MemberAction {
  final List<Map<String, dynamic>> members;
  const SetMembersAction(this.members);
}

class AddMemberAction extends MemberAction {
  final Map<String, dynamic> member;
  const AddMemberAction(this.member);
}

class UpdateMemberAction extends MemberAction {
  final String memberId;
  final Map<String, dynamic> updates;
  const UpdateMemberAction(this.memberId, this.updates);
}

class RemoveMemberAction extends MemberAction {
  final String memberId;
  const RemoveMemberAction(this.memberId);
}

// Request actions
class LoadRequestsAction extends MemberAction {
  final String clubId;
  const LoadRequestsAction(this.clubId);
}

class SetRequestsAction extends MemberAction {
  final List<Map<String, dynamic>> requests;
  const SetRequestsAction(this.requests);
}

class AddRequestAction extends MemberAction {
  final Map<String, dynamic> request;
  const AddRequestAction(this.request);
}

class UpdateRequestAction extends MemberAction {
  final String requestId;
  final Map<String, dynamic> updates;
  const UpdateRequestAction(this.requestId, this.updates);
}

class ApproveRequestAction extends MemberAction {
  final String requestId;
  final String processedBy;
  const ApproveRequestAction(this.requestId, this.processedBy);
}

class RejectRequestAction extends MemberAction {
  final String requestId;
  final String processedBy;
  final String reason;
  const RejectRequestAction(this.requestId, this.processedBy, this.reason);
}

// Notification actions
class LoadNotificationsAction extends MemberAction {
  final String userId;
  const LoadNotificationsAction(this.userId);
}

class SetNotificationsAction extends MemberAction {
  final List<Map<String, dynamic>> notifications;
  const SetNotificationsAction(this.notifications);
}

class AddNotificationAction extends MemberAction {
  final Map<String, dynamic> notification;
  const AddNotificationAction(this.notification);
}

class MarkNotificationReadAction extends MemberAction {
  final String notificationId;
  const MarkNotificationReadAction(this.notificationId);
}

class MarkAllNotificationsReadAction extends MemberAction {
  const MarkAllNotificationsReadAction();
}

// Activity actions
class LoadActivitiesAction extends MemberAction {
  final String clubId;
  const LoadActivitiesAction(this.clubId);
}

class SetActivitiesAction extends MemberAction {
  final List<Map<String, dynamic>> activities;
  const SetActivitiesAction(this.activities);
}

class AddActivityAction extends MemberAction {
  final Map<String, dynamic> activity;
  const AddActivityAction(this.activity);
}

// Chat message actions
class LoadChatMessagesAction extends MemberAction {
  final String roomId;
  const LoadChatMessagesAction(this.roomId);
}

class SetChatMessagesAction extends MemberAction {
  final List<Map<String, dynamic>> messages;
  const SetChatMessagesAction(this.messages);
}

class AddChatMessageAction extends MemberAction {
  final Map<String, dynamic> message;
  const AddChatMessageAction(this.message);
}

class UpdateChatMessageAction extends MemberAction {
  final String messageId;
  final Map<String, dynamic> updates;
  const UpdateChatMessageAction(this.messageId, this.updates);
}

// Analytics actions
class LoadAnalyticsAction extends MemberAction {
  final String clubId;
  const LoadAnalyticsAction(this.clubId);
}

class SetAnalyticsAction extends MemberAction {
  final Map<String, dynamic> analytics;
  const SetAnalyticsAction(this.analytics);
}

// Filter and search actions
class SetSearchQueryAction extends MemberAction {
  final String query;
  const SetSearchQueryAction(this.query);
}

class SetFiltersAction extends MemberAction {
  final Map<String, dynamic> filters;
  const SetFiltersAction(this.filters);
}

class UpdateFiltersAction extends MemberAction {
  final Map<String, dynamic> updates;
  const UpdateFiltersAction(this.updates);
}

class ClearFiltersAction extends MemberAction {
  const ClearFiltersAction();
}

// Bulk actions
class BulkUpdateMembersAction extends MemberAction {
  final List<String> memberIds;
  final Map<String, dynamic> updates;
  const BulkUpdateMembersAction(this.memberIds, this.updates);
}

class BulkDeleteMembersAction extends MemberAction {
  final List<String> memberIds;
  const BulkDeleteMembersAction(this.memberIds);
}

// Reset actions
class ResetStateAction extends MemberAction {
  const ResetStateAction();
}

class ClearErrorAction extends MemberAction {
  const ClearErrorAction();
}

/// Reducer function to handle state changes
MemberState memberReducer(MemberState state, MemberAction action) {
  if (kDebugMode) {
    debugPrint('🔄 Reducer: ${action.runtimeType}');
  }

  switch (action.runtimeType) {
    // Loading and error actions
    case SetLoadingAction:
      final loadingAction = action as SetLoadingAction;
      return state.copyWith(isLoading: loadingAction.isLoading);

    case SetErrorAction:
      final errorAction = action as SetErrorAction;
      return state.copyWith(error: errorAction.error, isLoading: false);

    case ClearErrorAction:
      return state.copyWith(error: null);

    // Member actions
    case SetMembersAction:
      final membersAction = action as SetMembersAction;
      return state.copyWith(members: membersAction.members, isLoading: false);

    case AddMemberAction:
      final addAction = action as AddMemberAction;
      final newMembers = List<Map<String, dynamic>>.from(state.members)
        ..add(addAction.member);
      return state.copyWith(members: newMembers);

    case UpdateMemberAction:
      final updateAction = action as UpdateMemberAction;
      final updatedMembers = state.members.map((member) {
        if (member['id'] == updateAction.memberId) {
          return {...member, ...updateAction.updates};
        }
        return member;
      }).toList();
      return state.copyWith(members: updatedMembers);

    case RemoveMemberAction:
      final removeAction = action as RemoveMemberAction;
      final filteredMembers = state.members
          .where((member) => member['id'] != removeAction.memberId)
          .toList();
      return state.copyWith(members: filteredMembers);

    // Request actions
    case SetRequestsAction:
      final requestsAction = action as SetRequestsAction;
      return state.copyWith(requests: requestsAction.requests, isLoading: false);

    case AddRequestAction:
      final addRequestAction = action as AddRequestAction;
      final newRequests = List<Map<String, dynamic>>.from(state.requests)
        ..insert(0, addRequestAction.request); // Add to beginning
      return state.copyWith(requests: newRequests);

    case UpdateRequestAction:
      final updateRequestAction = action as UpdateRequestAction;
      final updatedRequests = state.requests.map((request) {
        if (request['id'] == updateRequestAction.requestId) {
          return {...request, ...updateRequestAction.updates};
        }
        return request;
      }).toList();
      return state.copyWith(requests: updatedRequests);

    // Notification actions
    case SetNotificationsAction:
      final notificationsAction = action as SetNotificationsAction;
      return state.copyWith(notifications: notificationsAction.notifications, isLoading: false);

    case AddNotificationAction:
      final addNotificationAction = action as AddNotificationAction;
      final newNotifications = List<Map<String, dynamic>>.from(state.notifications)
        ..insert(0, addNotificationAction.notification); // Add to beginning
      return state.copyWith(notifications: newNotifications);

    case MarkNotificationReadAction:
      final markReadAction = action as MarkNotificationReadAction;
      final updatedNotifications = state.notifications.map((notification) {
        if (notification['id'] == markReadAction.notificationId) {
          return() {
            ...notification,
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          };
        }
        return notification;
      }).toList();
      return state.copyWith(notifications: updatedNotifications);

    case MarkAllNotificationsReadAction:
      final allReadNotifications = state.notifications.map((notification) {
        return() {
          ...notification,
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        };
      }).toList();
      return state.copyWith(notifications: allReadNotifications);

    // Activity actions
    case SetActivitiesAction:
      final activitiesAction = action as SetActivitiesAction;
      return state.copyWith(activities: activitiesAction.activities, isLoading: false);

    case AddActivityAction:
      final addActivityAction = action as AddActivityAction;
      final newActivities = List<Map<String, dynamic>>.from(state.activities)
        ..insert(0, addActivityAction.activity); // Add to beginning
      return state.copyWith(activities: newActivities);

    // Chat message actions
    case SetChatMessagesAction:
      final chatMessagesAction = action as SetChatMessagesAction;
      return state.copyWith(chatMessages: chatMessagesAction.messages, isLoading: false);

    case AddChatMessageAction:
      final addMessageAction = action as AddChatMessageAction;
      final newMessages = List<Map<String, dynamic>>.from(state.chatMessages)
        ..insert(0, addMessageAction.message); // Add to beginning
      return state.copyWith(chatMessages: newMessages);

    case UpdateChatMessageAction:
      final updateMessageAction = action as UpdateChatMessageAction;
      final updatedMessages = state.chatMessages.map((message) {
        if (message['id'] == updateMessageAction.messageId) {
          return {...message, ...updateMessageAction.updates};
        }
        return message;
      }).toList();
      return state.copyWith(chatMessages: updatedMessages);

    // Analytics actions
    case SetAnalyticsAction:
      final analyticsAction = action as SetAnalyticsAction;
      return state.copyWith(analytics: analyticsAction.analytics, isLoading: false);

    // Filter and search actions
    case SetSearchQueryAction:
      final searchAction = action as SetSearchQueryAction;
      return state.copyWith(searchQuery: searchAction.query);

    case SetFiltersAction:
      final filtersAction = action as SetFiltersAction;
      return state.copyWith(filters: filtersAction.filters);

    case UpdateFiltersAction:
      final updateFiltersAction = action as UpdateFiltersAction;
      final updatedFilters = {...state.filters, ...updateFiltersAction.updates};
      return state.copyWith(filters: updatedFilters);

    case ClearFiltersAction:
      return state.copyWith(filters: {}, searchQuery: '');

    // Bulk actions
    case BulkUpdateMembersAction:
      final bulkUpdateAction = action as BulkUpdateMembersAction;
      final bulkUpdatedMembers = state.members.map((member) {
        if (bulkUpdateAction.memberIds.contains(member['id'])) {
          return {...member, ...bulkUpdateAction.updates};
        }
        return member;
      }).toList();
      return state.copyWith(members: bulkUpdatedMembers);

    case BulkDeleteMembersAction:
      final bulkDeleteAction = action as BulkDeleteMembersAction;
      final bulkFilteredMembers = state.members
          .where((member) => !bulkDeleteAction.memberIds.contains(member['id']))
          .toList();
      return state.copyWith(members: bulkFilteredMembers);

    // Reset actions
    case ResetStateAction:
      return const MemberState();

    default:
      if (kDebugMode) {
        debugPrint('⚠️ Unknown action: ${action.runtimeType}');
      }
      return state;
  }
}

/// Selectors for derived state
class MemberSelectors {
  /// Get active members
  static List<Map<String, dynamic>> getActiveMembers(MemberState state) {
    return state.members.where((member) => member['status'] == 'active').toList();
  }

  /// Get pending membership requests
  static List<Map<String, dynamic>> getPendingRequests(MemberState state) {
    return state.requests.where((request) => request['status'] == 'pending').toList();
  }

  /// Get unread notifications
  static List<Map<String, dynamic>> getUnreadNotifications(MemberState state) {
    return state.notifications.where((notification) => notification['is_read'] != true).toList();
  }

  /// Get recent activities (last 24 hours)
  static List<Map<String, dynamic>> getRecentActivities(MemberState state) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return state.activities.where((activity) {
      final createdAt = DateTime.tryParse(activity['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(yesterday);
    }).toList();
  }

  /// Get filtered members based on search query and filters
  static List<Map<String, dynamic>> getFilteredMembers(MemberState state) {
    var filteredMembers = List<Map<String, dynamic>>.from(state.members);

    // Apply search query
    if (state.searchQuery.isNotEmpty) {
      final query = state.searchQuery.toLowerCase();
      filteredMembers = filteredMembers.where((member) {
        final profile = member['users'];
        if (profile == null) return false;

        final name = (profile['display_name'] ?? '').toLowerCase();
        final email = (profile['email'] ?? '').toLowerCase();
        final membershipId = (member['membership_id'] ?? '').toLowerCase();

        return name.contains(query) || email.contains(query) || membershipId.contains(query);
      }).toList();
    }

    // Apply filters
    final filters = state.filters;

    if (filters['status'] != null) {
      filteredMembers = filteredMembers.where((member) => member['status'] == filters['status']).toList();
    }

    if (filters['membership_type'] != null) {
      filteredMembers = filteredMembers.where((member) => member['membership_type'] == filters['membership_type']).toList();
    }

    if (filters['joined_after'] != null) {
      final afterDate = DateTime.tryParse(filters['joined_after']);
      if (afterDate != null) {
        filteredMembers = filteredMembers.where((member) {
          final joinedAt = DateTime.tryParse(member['joined_at'] ?? '');
          return joinedAt != null && joinedAt.isAfter(afterDate);
        }).toList();
      }
    }

    return filteredMembers;
  }

  /// Get member count by status
  static Map<String, int> getMemberCountByStatus(MemberState state) {
    final counts = <String, int>{};
    for (final member in state.members) {
      final status = member['status'] ?? 'unknown';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  /// Get member count by membership type
  static Map<String, int> getMemberCountByType(MemberState state) {
    final counts = <String, int>{};
    for (final member in state.members) {
      final type = member['membership_type'] ?? 'regular';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Get notification count by type
  static Map<String, int> getNotificationCountByType(MemberState state) {
    final counts = <String, int>{};
    for (final notification in getUnreadNotifications(state)) {
      final type = notification['type'] ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  /// Check if there are any pending actions
  static bool hasPendingActions(MemberState state) {
    return getPendingRequests(state).isNotEmpty || getUnreadNotifications(state).isNotEmpty;
  }

  /// Get dashboard statistics
  static Map<String, dynamic> getDashboardStats(MemberState state) {
    final activeMembers = getActiveMembers(state);
    final pendingRequests = getPendingRequests(state);
    final unreadNotifications = getUnreadNotifications(state);
    final recentActivities = getRecentActivities(state);

    return() {
      'total_members': state.members.length,
      'active_members': activeMembers.length,
      'pending_requests': pendingRequests.length,
      'unread_notifications': unreadNotifications.length,
      'recent_activities': recentActivities.length,
      'member_growth_rate': _calculateGrowthRate(state.members),
      'engagement_score': _calculateEngagementScore(state.activities),
    };
  }

  /// Calculate member growth rate (simplified)
  static double _calculateGrowthRate(List<Map<String, dynamic>> members) {
    if (members.isEmpty) return 0.0;

    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));
    
    final recentMembers = members.where((member) {
      final joinedAt = DateTime.tryParse(member['joined_at'] ?? '');
      return joinedAt != null && joinedAt.isAfter(lastMonth);
    }).length;

    return recentMembers / members.length * 100;
  }

  /// Calculate engagement score based on activities
  static double _calculateEngagementScore(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) return 0.0;

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    
    final recentActivities = activities.where((activity) {
      final createdAt = DateTime.tryParse(activity['created_at'] ?? '');
      return createdAt != null && createdAt.isAfter(lastWeek);
    }).length;

    // Simple engagement score calculation
    return (recentActivities / 7).clamp(0.0, 10.0); // Activities per day, capped at 10
  }
}