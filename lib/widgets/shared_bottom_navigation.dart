import 'package:flutter/material.dart';
import '../core/app_export.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';

class SharedBottomNavigation extends StatefulWidget {
  const SharedBottomNavigation({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final int currentIndex;
  final Function(String) onNavigate;

  const SharedBottomNavigation({
    
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  State<SharedBottomNavigation> createState() => _SharedBottomNavigationState();
}

class _SharedBottomNavigationState extends State<SharedBottomNavigation> {
  final MessagingService _messagingService = MessagingService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  int _unreadMessageCount = 0;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadMessageCount();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final count = await _messagingService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading unread message count: $e');
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading unread notification count: $e');
    }
  }

  int _getTotalUnreadCount() {
    return _unreadMessageCount + _unreadNotificationCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: widget.currentIndex,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: Colors.grey[500],
            backgroundColor: Colors.white,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            onTap: (index) {
              switch (index) {
                case 0:
                  widget.onNavigate(AppRoutes.homeFeedScreen);
                  break;
                case 1:
                  widget.onNavigate(AppRoutes.findOpponentsScreen);
                  break;
                case 2:
                  widget.onNavigate(AppRoutes.tournamentListScreen);
                  break;
                case 3:
                  widget.onNavigate(AppRoutes.clubMainScreen);
                  break;
                case 4:
                  widget.onNavigate(AppRoutes.userProfileScreen);
                  break;
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined, size: 24),
                activeIcon: Icon(Icons.home_rounded, size: 26),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sports_outlined, size: 24),
                activeIcon: Icon(Icons.sports_rounded, size: 26),
                label: 'Đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined, size: 24),
                activeIcon: Icon(Icons.emoji_events_rounded, size: 26),
                label: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_outlined, size: 24),
                activeIcon: Icon(Icons.groups_rounded, size: 26),
                label: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 24),
                    if (_unreadMessageCount > 0 || _unreadNotificationCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _getTotalUnreadCount() > 9 ? '9+' : _getTotalUnreadCount().toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.person_rounded, size: 26),
                    if (_unreadMessageCount > 0 || _unreadNotificationCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _getTotalUnreadCount() > 9 ? '9+' : _getTotalUnreadCount().toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }
}