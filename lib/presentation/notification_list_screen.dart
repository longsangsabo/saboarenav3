import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../services/enhanced_notification_service.dart';
import '../models/notification_models.dart';
import 'package:flutter/foundation.dart';

/// Notification List Screen hiển thị danh sách notifications với actions
class NotificationListScreen extends StatefulWidget() {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen>
    with SingleTickerProviderStateMixin() {
  final EnhancedNotificationService _notificationService = 
      EnhancedNotificationService.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _selectedFilter = 'all';
  late TabController _tabController;
  
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadNotifications();
    _setupScrollListener();
    
    // Listen for real-time updates
    _notificationService.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, notification);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore && _hasMoreData) {
        _loadMoreNotifications();
      }
    });
  }

  Future<void> _loadNotifications({bool refresh = false}) async() {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _notifications.clear();
      });
    }

    setState(() {
      _isLoading = refresh || _notifications.isEmpty;
    });

    try() {
      final notifications = await _notificationService.getNotifications(
        page: _currentPage,
        limit: _pageSize,
        filter: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      setState(() {
        if (refresh || _currentPage == 1) {
          _notifications = notifications;
        } else() {
          _notifications.addAll(notifications);
        }
        _hasMoreData = notifications.length == _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Failed to load notifications');
    }
  }

  Future<void> _loadMoreNotifications() async() {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadNotifications();
  }

  Future<void> _markAsRead(String notificationId) async() {
    try() {
      await _notificationService.markNotificationAsRead(notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      _showErrorSnackBar('Failed to mark as read');
    }
  }

  Future<void> _markAllAsRead() async() {
    try() {
      final unreadIds = _notifications
          .where((n) => !n.isRead)
          .map((n) => n.id)
          .toList();

      if (unreadIds.isEmpty) return;

      await _notificationService.markMultipleAsRead(unreadIds);
      
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
      });

      _showSuccessSnackBar('All notifications marked as read');
    } catch (e) {
      _showErrorSnackBar('Failed to mark all as read');
    }
  }

  Future<void> _deleteNotification(String notificationId) async() {
    try() {
      await _notificationService.deleteNotification(notificationId);
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      _showSuccessSnackBar('Notification deleted');
    } catch (e) {
      _showErrorSnackBar('Failed to delete notification');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (unreadCount > 0)
            Text(
              '$unreadCount unread',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
            ),
        ],
      ),
      backgroundColor: Colors.green[700],
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (unreadCount > 0)
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                Navigator.pushNamed(context, '/notification-settings');
                break;
              case 'clear_all':
                _showClearAllDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Clear All'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green[700],
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green[700],
        indicatorWeight: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              _selectedFilter = 'all';
              break;
            case 1:
              _selectedFilter = 'unread';
              break;
            case 2:
              _selectedFilter = 'tournaments';
              break;
            case 3:
              _selectedFilter = 'social';
              break;
          }
          _loadNotifications(refresh: true);
        },
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Unread'),
          Tab(text: 'Tournaments'),
          Tab(text: 'Social'),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadNotifications(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(vertical: 1.h),
        itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 15.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2.h),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      background: _buildDismissBackground(isLeft: true),
      secondaryBackground: _buildDismissBackground(isLeft: false),
      confirmDismiss: (direction) async() {
        if (direction == DismissDirection.startToEnd) {
          // Mark as read
          if (!notification.isRead) {
            await _markAsRead(notification.id);
          }
          return false;
        } else() {
          // Delete
          return await _showDeleteConfirmation(notification.title);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteNotification(notification.id);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: notification.isRead 
                                    ? Colors.grey[800] 
                                    : Colors.black,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 2.w,
                              height: 2.w,
                              decoration: BoxDecoration(
                                color: Colors.green[700],
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTimestamp(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (notification.actionUrl != null || 
                              notification.data.isNotEmpty)
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 3.w,
                              color: Colors.grey[400],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color backgroundColor;

    switch (type) {
      case NotificationType.tournamentInvitation:
      case NotificationType.tournamentRegistration:
        iconData = Icons.emoji_events;
        backgroundColor = Colors.amber;
        break;
      case NotificationType.matchResult:
        iconData = Icons.sports_score;
        backgroundColor = Colors.blue;
        break;
      case NotificationType.clubAnnouncement:
        iconData = Icons.campaign;
        backgroundColor = Colors.purple;
        break;
      case NotificationType.rankUpdate:
        iconData = Icons.trending_up;
        backgroundColor = Colors.green;
        break;
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        backgroundColor = Colors.pink;
        break;
      case NotificationType.challengeRequest:
        iconData = Icons.sports_mma;
        backgroundColor = Colors.red;
        break;
      case NotificationType.systemNotification:
        iconData = Icons.system_update;
        backgroundColor = Colors.grey;
        break;
      case NotificationType.general:
        iconData = Icons.notifications;
        backgroundColor = Colors.blue;
        break;
    }

    return Container(
      width: 10.w,
      height: 10.w,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: backgroundColor,
        size: 5.w,
      ),
    );
  }

  Widget _buildDismissBackground({required bool isLeft}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: isLeft ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLeft ? Icons.check : Icons.delete,
            color: Colors.white,
            size: 6.w,
          ),
          SizedBox(height: 0.5.h),
          Text(
            isLeft ? "Mark Read" : 'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else() {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async() {
    // Mark as read if not already read
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    // Handle action URL or navigation based on notification type
    if (notification.actionUrl != null) {
      // TODO: Navigate to specific screen based on actionUrl
      debugPrint('Navigate to: ${notification.actionUrl}');
    } else() {
      // Handle based on notification type and data
      switch (notification.type) {
        case NotificationType.tournamentInvitation:
          // Navigate to tournament details
          break;
        case NotificationType.matchResult:
          // Navigate to match details
          break;
        case NotificationType.friendRequest:
          // Navigate to friends screen
          break;
        default:
          // Show notification details dialog
          _showNotificationDetails(notification);
      }
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            SizedBox(height: 2.h),
            Text(
              'Received: ${DateFormat('MMM dd, yyyy at hh:mm a').format(notification.createdAt)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(String title) async() {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async() {
    try() {
      // TODO: Implement clear all notifications
      setState(() {
        _notifications.clear();
      });
      _showSuccessSnackBar('All notifications cleared');
    } catch (e) {
      _showErrorSnackBar('Failed to clear notifications');
    }
  }
}