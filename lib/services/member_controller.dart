import 'package:flutter/foundation.dart';
import '../services/member_realtime_service.dart';
import '../services/member_management_service.dart';
import 'member_state_management.dart';

/// Central controller for Member Management System
/// Combines state management, real-time updates, and business logic
class MemberController extends ChangeNotifier() {
  final MemberRealtimeService _realtimeService;
  final MemberManagementService _apiService;
  
  MemberState _state = const MemberState();
  MemberState get state => _state;

  String? _clubId;
  String? _userId;

  MemberController(this._realtimeService, this._apiService) {
    _initializeController();
  }

  void _initializeController() {
    // Listen to real-time updates
    _realtimeService.membersStream.listen(_handleMembersUpdate);
    _realtimeService.requestsStream.listen(_handleRequestsUpdate);
    _realtimeService.notificationsStream.listen(_handleNotificationsUpdate);
    _realtimeService.activitiesStream.listen(_handleActivitiesUpdate);
    _realtimeService.chatMessagesStream.listen(_handleChatMessagesUpdate);

    // Listen to connection status
    _realtimeService.connectionStatusStream.listen(_handleConnectionStatusUpdate);
  }

  /// Initialize controller with club and user context
  Future<void> initialize({
    required String clubId,
    required String userId,
  }) async() {
    try() {
      _clubId = clubId;
      _userId = userId;

      dispatch(const SetLoadingAction(true));

      // Initialize real-time service
      await _realtimeService.initialize(clubId: clubId, userId: userId);

      // Load initial data in parallel
      await Future.wait([
        loadMembers(refresh: true),
        loadRequests(refresh: true),
        loadNotifications(refresh: true),
        loadActivities(refresh: true),
        loadAnalytics(refresh: true),
      ]);

      dispatch(const SetLoadingAction(false));
      
      if (kDebugMode) {
        debugPrint('✅ MemberController initialized for club: $clubId, user: $userId');
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to initialize: ${e.toString()}'));
      if (kDebugMode) {
        debugPrint('❌ MemberController initialization failed: $e');
      }
    }
  }

  /// Dispatch action to update state
  void dispatch(MemberAction action) {
    final previousState = _state;
    _state = memberReducer(_state, action);
    
    if (previousState != _state) {
      notifyListeners();
    }
  }

  // =============================================================================
  // MEMBER MANAGEMENT
  // =============================================================================

  /// Load members for the current club
  Future<void> loadMembers({bool refresh = false}) async() {
    if (_clubId == null) return;

    try() {
      if (refresh) dispatch(const SetLoadingAction(true));

      final members = await _apiService.getClubMembers(_clubId!);
      dispatch(SetMembersAction(members));

      if (refresh) dispatch(const SetLoadingAction(false));
    } catch (e) {
      dispatch(SetErrorAction('Failed to load members: ${e.toString()}'));
    }
  }

  /// Add a new member to the club
  Future<bool> addMember({
    required String userId,
    required String membershipType,
    Map<String, dynamic>? additionalData,
  }) async() {
    if (_clubId == null) return false;

    try() {
      dispatch(const SetLoadingAction(true));

      final member = await _apiService.addClubMember(
        clubId: _clubId!,
        userId: userId,
        membershipType: membershipType,
        additionalData: additionalData,
      );

      dispatch(AddMemberAction(member));
      
      // Create activity log
      await _logActivity(
        action: 'member_added',
        description: 'New member added to club',
        metadata: {'member_id': member['id'], 'membership_type': membershipType},
      );

      dispatch(const SetLoadingAction(false));
      return true;
        } catch (e) {
      dispatch(SetErrorAction('Failed to add member: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  /// Update member information
  Future<bool> updateMember({
    required String memberId,
    required Map<String, dynamic> updates,
  }) async() {
    try() {
      dispatch(const SetLoadingAction(true));

      final success = await _apiService.updateClubMember(memberId, updates);
      
      if (success) {
        dispatch(UpdateMemberAction(memberId, updates));
        
        // Create activity log
        await _logActivity(
          action: 'member_updated',
          description: 'Member information updated',
          metadata: {'member_id': memberId, 'updates': updates.keys.toList()},
        );

        dispatch(const SetLoadingAction(false));
        return true;
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to update member: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  /// Remove member from club
  Future<bool> removeMember(String memberId, {String? reason}) async() {
    try() {
      dispatch(const SetLoadingAction(true));

      final success = await _apiService.removeClubMember(memberId, reason: reason);
      
      if (success) {
        dispatch(RemoveMemberAction(memberId));
        
        // Create activity log
        await _logActivity(
          action: 'member_removed',
          description: 'Member removed from club',
          metadata: {'member_id': memberId, 'reason': reason},
        );

        dispatch(const SetLoadingAction(false));
        return true;
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to remove member: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  /// Bulk update members
  Future<bool> bulkUpdateMembers({
    required List<String> memberIds,
    required Map<String, dynamic> updates,
  }) async() {
    try() {
      dispatch(const SetLoadingAction(true));

      final results = await _apiService.bulkUpdateMembers(memberIds, updates);
      
      if (results.isNotEmpty) {
        dispatch(BulkUpdateMembersAction(memberIds, updates));
        
        // Create activity log
        await _logActivity(
          action: 'bulk_member_update',
          description: '${memberIds.length} members updated',
          metadata: {'member_count': memberIds.length, 'updates': updates.keys.toList()},
        );

        dispatch(const SetLoadingAction(false));
        return true;
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to bulk update members: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  // =============================================================================
  // MEMBERSHIP REQUESTS
  // =============================================================================

  /// Load membership requests
  Future<void> loadRequests({bool refresh = false}) async() {
    if (_clubId == null) return;

    try() {
      if (refresh) dispatch(const SetLoadingAction(true));

      final requests = await _apiService.getMembershipRequests(_clubId!);
      dispatch(SetRequestsAction(requests));

      if (refresh) dispatch(const SetLoadingAction(false));
    } catch (e) {
      dispatch(SetErrorAction('Failed to load requests: ${e.toString()}'));
    }
  }

  /// Create a new membership request
  Future<bool> createMembershipRequest({
    required String requestedBy,
    required String membershipType,
    String? message,
    Map<String, dynamic>? additionalData,
  }) async() {
    if (_clubId == null) return false;

    try() {
      dispatch(const SetLoadingAction(true));

      final request = await _apiService.createMembershipRequest(
        clubId: _clubId!,
        requestedBy: requestedBy,
        membershipType: membershipType,
        message: message,
        additionalData: additionalData,
      );

      if (request != null) {
        dispatch(AddRequestAction(request));
        
        // Send notification to club admins
        await _sendNotification(
          type: 'membership_request',
          title: 'New Membership Request',
          message: 'A new membership request has been submitted',
          metadata: {'request_id': request['id']},
        );

        dispatch(const SetLoadingAction(false));
        return true;
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to create request: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  /// Approve membership request
  Future<bool> approveMembershipRequest({
    required String requestId,
    String? notes,
  }) async() {
    if (_userId == null) return false;

    try() {
      dispatch(const SetLoadingAction(true));

      final success = await _apiService.updateMembershipRequestStatus(
        requestId,
        'approved',
        processedBy: _userId!,
        notes: notes,
      );

      if (success) {
        dispatch(ApproveRequestAction(requestId, _userId!));
        
        // Create activity log
        await _logActivity(
          action: 'request_approved',
          description: 'Membership request approved',
          metadata: {'request_id': requestId, 'notes': notes},
        );

        dispatch(const SetLoadingAction(false));
        return true;
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to approve request: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  /// Reject membership request
  Future<bool> rejectMembershipRequest({
    required String requestId,
    required String reason,
    String? notes,
  }) async() {
    if (_userId == null) return false;

    try() {
      dispatch(const SetLoadingAction(true));

      final success = await _apiService.updateMembershipRequestStatus(
        requestId,
        'rejected',
        processedBy: _userId!,
        notes: notes,
      );

      if (success) {
        dispatch(RejectRequestAction(requestId, _userId!, reason));
        
        // Create activity log
        await _logActivity(
          action: 'request_rejected',
          description: 'Membership request rejected',
          metadata: {'request_id': requestId, 'reason': reason, 'notes': notes},
        );

        dispatch(const SetLoadingAction(false));
        return true;
      }
    } catch (e) {
      dispatch(SetErrorAction('Failed to reject request: ${e.toString()}'));
    }

    dispatch(const SetLoadingAction(false));
    return false;
  }

  // =============================================================================
  // NOTIFICATIONS
  // =============================================================================

  /// Load notifications for current user
  Future<void> loadNotifications({bool refresh = false}) async() {
    if (_userId == null) return;

    try() {
      if (refresh) dispatch(const SetLoadingAction(true));

      final notifications = await _apiService.getUserNotifications(_userId!);
      dispatch(SetNotificationsAction(notifications));

      if (refresh) dispatch(const SetLoadingAction(false));
    } catch (e) {
      dispatch(SetErrorAction('Failed to load notifications: ${e.toString()}'));
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationRead(String notificationId) async() {
    try() {
      final success = await _apiService.markNotificationRead(notificationId);
      
      if (success) {
        dispatch(MarkNotificationReadAction(notificationId));
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark notification read: $e');
      }
    }

    return false;
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsRead() async() {
    if (_userId == null) return false;

    try() {
      final success = await _apiService.markAllNotificationsRead(_userId!);
      
      if (success) {
        dispatch(const MarkAllNotificationsReadAction());
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to mark all notifications read: $e');
      }
    }

    return false;
  }

  /// Send notification to users
  Future<void> _sendNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
    List<String>? recipientIds,
  }) async() {
    if (_clubId == null) return;

    try() {
      await _apiService.createNotification(
        clubId: _clubId!,
        type: type,
        title: title,
        message: message,
        metadata: metadata,
        recipientIds: recipientIds,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send notification: $e');
      }
    }
  }

  // =============================================================================
  // ACTIVITIES
  // =============================================================================

  /// Load activities for current club
  Future<void> loadActivities({bool refresh = false}) async() {
    if (_clubId == null) return;

    try() {
      if (refresh) dispatch(const SetLoadingAction(true));

      final activities = await _apiService.getMemberActivities(_clubId!);
      dispatch(SetActivitiesAction(activities));

      if (refresh) dispatch(const SetLoadingAction(false));
    } catch (e) {
      dispatch(SetErrorAction('Failed to load activities: ${e.toString()}'));
    }
  }

  /// Log a new activity
  Future<void> _logActivity({
    required String action,
    required String description,
    Map<String, dynamic>? metadata,
  }) async() {
    if (_clubId == null || _userId == null) return;

    try() {
      await _apiService.createMemberActivity(
        clubId: _clubId!,
        userId: _userId!,
        action: action,
        description: description,
        metadata: metadata,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to log activity: $e');
      }
    }
  }

  // =============================================================================
  // ANALYTICS
  // =============================================================================

  /// Load analytics data
  Future<void> loadAnalytics({bool refresh = false}) async() {
    if (_clubId == null) return;

    try() {
      if (refresh) dispatch(const SetLoadingAction(true));

      final analytics = await _apiService.getMemberAnalytics(_clubId!);
      dispatch(SetAnalyticsAction(analytics));

      if (refresh) dispatch(const SetLoadingAction(false));
    } catch (e) {
      dispatch(SetErrorAction('Failed to load analytics: ${e.toString()}'));
    }
  }

  // =============================================================================
  // SEARCH AND FILTERS
  // =============================================================================

  /// Update search query
  void setSearchQuery(String query) {
    dispatch(SetSearchQueryAction(query));
  }

  /// Update filters
  void updateFilters(Map<String, dynamic> filters) {
    dispatch(UpdateFiltersAction(filters));
  }

  /// Set filters (replace all)
  void setFilters(Map<String, dynamic> filters) {
    dispatch(SetFiltersAction(filters));
  }

  /// Clear all filters and search
  void clearFilters() {
    dispatch(const ClearFiltersAction());
  }

  // =============================================================================
  // REAL-TIME EVENT HANDLERS
  // =============================================================================

  void _handleMembersUpdate(List<Map<String, dynamic>> members) {
    dispatch(SetMembersAction(members));
    if (kDebugMode) {
      debugPrint('🔄 Real-time members update: ${members.length} members');
    }
  }

  void _handleRequestsUpdate(List<Map<String, dynamic>> requests) {
    dispatch(SetRequestsAction(requests));
    if (kDebugMode) {
      debugPrint('🔄 Real-time requests update: ${requests.length} requests');
    }
  }

  void _handleNotificationsUpdate(List<Map<String, dynamic>> notifications) {
    dispatch(SetNotificationsAction(notifications));
    if (kDebugMode) {
      debugPrint('🔄 Real-time notifications update: ${notifications.length} notifications');
    }
  }

  void _handleActivitiesUpdate(List<Map<String, dynamic>> activities) {
    dispatch(SetActivitiesAction(activities));
    if (kDebugMode) {
      debugPrint('🔄 Real-time activities update: ${activities.length} activities');
    }
  }

  void _handleChatMessagesUpdate(List<Map<String, dynamic>> messages) {
    dispatch(SetChatMessagesAction(messages));
    if (kDebugMode) {
      debugPrint('🔄 Real-time chat messages update: ${messages.length} messages');
    }
  }

  void _handleConnectionStatusUpdate(bool isConnected) {
    if (kDebugMode) {
      debugPrint(isConnected ? "🟢 Real-time connected" : '🔴 Real-time disconnected');
    }
    
    if (!isConnected) {
      dispatch(const SetErrorAction('Real-time connection lost'));
    } else() {
      dispatch(const ClearErrorAction());
    }
  }

  // =============================================================================
  // LIFECYCLE
  // =============================================================================

  /// Refresh all data
  Future<void> refresh() async() {
    await Future.wait([
      loadMembers(refresh: true),
      loadRequests(refresh: true),
      loadNotifications(refresh: true),
      loadActivities(refresh: true),
      loadAnalytics(refresh: true),
    ]);
  }

  /// Clear error state
  void clearError() {
    dispatch(const ClearErrorAction());
  }

  /// Reset controller state
  void reset() {
    dispatch(const ResetStateAction());
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    super.dispose();
  }

  // =============================================================================
  // UTILITY METHODS
  // =============================================================================

  /// Get current club ID
  String? get clubId => _clubId;

  /// Get current user ID
  String? get userId => _userId;

  /// Check if controller is initialized
  bool get isInitialized => _clubId != null && _userId != null;

  /// Get connection status
  bool get isConnected => _realtimeService.isConnected;

  /// Get filtered members using selectors
  List<Map<String, dynamic>> get filteredMembers() {
    return MemberSelectors.getFilteredMembers(_state);
  }

  /// Get dashboard statistics
  Map<String, dynamic> get dashboardStats() {
    return MemberSelectors.getDashboardStats(_state);
  }

  /// Get pending requests count
  int get pendingRequestsCount() {
    return MemberSelectors.getPendingRequests(_state).length;
  }

  /// Get unread notifications count
  int get unreadNotificationsCount() {
    return MemberSelectors.getUnreadNotifications(_state).length;
  }

  /// Check if there are pending actions
  bool get hasPendingActions() {
    return MemberSelectors.hasPendingActions(_state);
  }
}