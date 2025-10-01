import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';
import '../../models/member_data.dart';
import '../chat_room_screen/chat_room_screen.dart';

class MemberCommunicationScreen extends StatefulWidget {
  const MemberCommunicationScreen({super.key});

@override
  _MemberCommunicationScreenState createState() => _MemberCommunicationScreenState();
}

class _MemberCommunicationScreenState extends State<MemberCommunicationScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<ChatRoom> _chatRooms = [];
  List<Announcement> _announcements = [];
  List<Notification> _notifications = [];

  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChatTab(),
                  _buildAnnouncementsTab(),
                  _buildNotificationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Giao tiếp thành viên',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _refreshData,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 8),
                  Text('Cài đặt chat'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'broadcast',
              child: Row(
                children: [
                  Icon(Icons.campaign, size: 20),
                  SizedBox(width: 8),
                  Text('Thông báo chung'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'moderation',
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, size: 20),
                  SizedBox(width: 8),
                  Text('Kiểm duyệt'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tin nhắn, thông báo...',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            text: 'Chat',
            icon: Badge(
              label: Text('${_getUnreadChatCount()}'),
              child: Icon(Icons.chat),
            ),
          ),
          Tab(
            text: 'Thông báo',
            icon: Badge(
              label: Text('${_announcements.length}'),
              backgroundColor: Colors.blue,
              child: Icon(Icons.campaign),
            ),
          ),
          Tab(
            text: 'Tin nhắn',
            icon: Badge(
              label: Text('${_getUnreadNotificationCount()}'),
              backgroundColor: Colors.orange,
              child: Icon(Icons.notifications),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final filteredRooms = _filterChatRooms(_chatRooms);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (filteredRooms.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'Chưa có phòng chat',
        subtitle: 'Tạo phòng chat để bắt đầu trò chuyện',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredRooms.length,
        itemBuilder: (context, index) {
          return _buildChatRoomItem(filteredRooms[index]);
        },
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    final filteredAnnouncements = _filterAnnouncements(_announcements);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (filteredAnnouncements.isEmpty) {
      return _buildEmptyState(
        icon: Icons.campaign_outlined,
        title: 'Chưa có thông báo',
        subtitle: 'Các thông báo sẽ xuất hiện ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredAnnouncements.length,
        itemBuilder: (context, index) {
          return _buildAnnouncementItem(filteredAnnouncements[index]);
        },
      ),
    );
  }

  Widget _buildNotificationsTab() {
    final filteredNotifications = _filterNotifications(_notifications);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        title: 'Không có thông báo',
        subtitle: 'Thông báo sẽ xuất hiện ở đây',
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationItem(filteredNotifications[index]);
        },
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _openChatRoom(room),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getChatRoomColor(room.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getChatRoomIcon(room.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  if (room.unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${room.unreadCount > 99 ? '99+' : room.unreadCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (room.lastMessage != null)
                          Text(
                            _formatTime(room.lastMessage!.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${room.memberCount} thành viên',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    if (room.lastMessage != null) ...[
                      SizedBox(height: 4),
                      Text(
                        room.lastMessage!.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: room.unreadCount > 0
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: room.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementItem(Announcement announcement) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _viewAnnouncement(announcement),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAnnouncementColor(announcement.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAnnouncementIcon(announcement.priority),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bởi ${announcement.author.displayName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDate(announcement.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      if (!announcement.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                announcement.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (announcement.tags.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: announcement.tags.map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Notification notification) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: notification.isRead
                ? null
                : Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        notification.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatRelativeTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_tabController.index == 0) // Chat tab
          FloatingActionButton(
            heroTag: 'create_chat',
            onPressed: _createChatRoom,
            child: Icon(Icons.add_comment),
          ),
        if (_tabController.index == 1) // Announcements tab
          FloatingActionButton(
            heroTag: 'create_announcement',
            onPressed: _createAnnouncement,
            child: Icon(Icons.campaign),
          ),
        if (_tabController.index == 2) // Notifications tab
          FloatingActionButton(
            heroTag: 'mark_all_read',
            onPressed: _markAllNotificationsRead,
            child: Icon(Icons.done_all),
          ),
      ],
    );
  }

  // Helper methods
  List<ChatRoom> _filterChatRooms(List<ChatRoom> rooms) {
    if (_searchQuery.isEmpty) return rooms;
    return rooms.where((room) {
      return room.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (room.lastMessage?.content.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<Announcement> _filterAnnouncements(List<Announcement> announcements) {
    if (_searchQuery.isEmpty) return announcements;
    return announcements.where((announcement) {
      return announcement.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          announcement.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          announcement.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }

  List<Notification> _filterNotifications(List<Notification> notifications) {
    if (_searchQuery.isEmpty) return notifications;
    return notifications.where((notification) {
      return notification.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          notification.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  int _getUnreadChatCount() {
    return _chatRooms.fold(0, (sum, room) => sum + room.unreadCount);
  }

  int _getUnreadNotificationCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  Color _getChatRoomColor(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.general:
        return Colors.blue;
      case ChatRoomType.tournament:
        return Colors.orange;
      case ChatRoomType.private:
        return Colors.green;
      case ChatRoomType.announcement:
        return Colors.purple;
    }
  }

  IconData _getChatRoomIcon(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.general:
        return Icons.chat;
      case ChatRoomType.tournament:
        return Icons.emoji_events;
      case ChatRoomType.private:
        return Icons.lock;
      case ChatRoomType.announcement:
        return Icons.campaign;
    }
  }

  Color _getAnnouncementColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return Colors.grey;
      case AnnouncementPriority.normal:
        return Colors.blue;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.urgent:
        return Colors.red;
    }
  }

  IconData _getAnnouncementIcon(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.low:
        return Icons.info;
      case AnnouncementPriority.normal:
        return Icons.campaign;
      case AnnouncementPriority.high:
        return Icons.priority_high;
      case AnnouncementPriority.urgent:
        return Icons.warning;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.tournament:
        return Colors.orange;
      case NotificationType.system:
        return Colors.purple;
      case NotificationType.achievement:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.tournament:
        return Icons.emoji_events;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.achievement:
        return Icons.star;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return _formatDate(time);
    }
  }

  // Event handlers
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API calls
      await Future.delayed(Duration(seconds: 1));

      _chatRooms = _generateMockChatRooms();
      _announcements = _generateMockAnnouncements();
      _notifications = _generateMockNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _openChatRoom(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(room: room),
      ),
    );
  }

  void _viewAnnouncement(Announcement announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(announcement: announcement),
      ),
    );
  }

  void _handleNotificationTap(Notification notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });

    // Handle notification action based on type
    switch (notification.type) {
      case NotificationType.tournament:
        // Navigate to tournament
        break;
      case NotificationType.message:
        // Navigate to message
        break;
      case NotificationType.achievement:
        // Show achievement details
        break;
      case NotificationType.system:
        // Navigate to settings or relevant screen
        break;
    }
  }

  void _createChatRoom() {
    showDialog(
      context: context,
      builder: (context) => CreateChatRoomDialog(),
    );
  }

  void _createAnnouncement() {
    showDialog(
      context: context,
      builder: (context) => CreateAnnouncementDialog(),
    );
  }

  void _markAllNotificationsRead() {
    setState(() {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showChatSettings();
        break;
      case 'broadcast':
        _createBroadcastMessage();
        break;
      case 'moderation':
        _showModerationPanel();
        break;
    }
  }

  void _showChatSettings() {
    // Implementation for chat settings
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  void _createBroadcastMessage() {
    // Implementation for broadcast message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  void _showModerationPanel() {
    // Implementation for moderation panel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tính năng đang phát triển')),
    );
  }

  // Mock data generation
  List<ChatRoom> _generateMockChatRooms() {
    return [
      ChatRoom(
        id: 'room_1',
        name: 'Thảo luận chung',
        type: ChatRoomType.general,
        memberCount: 25,
        unreadCount: 3,
        lastMessage: ChatMessage(
          id: 'msg_1',
          content: 'Ai muốn tham gia giải đấu cuối tuần không?',
          sender: User(
            id: 'user_1',
            displayName: 'Nguyễn Văn A',
            email: 'a@email.com',
            avatar: 'https://i.pravatar.cc/150?img=1',
            rank: RankType.intermediate,
          ),
          timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        ),
      ),
      ChatRoom(
        id: 'room_2',
        name: 'Giải đấu mùa thu',
        type: ChatRoomType.tournament,
        memberCount: 12,
        unreadCount: 0,
        lastMessage: ChatMessage(
          id: 'msg_2',
          content: 'Lịch thi đấu đã được cập nhật',
          sender: User(
            id: 'user_2',
            displayName: 'Trần Thị B',
            email: 'b@email.com',
            avatar: 'https://i.pravatar.cc/150?img=2',
            rank: RankType.advanced,
          ),
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
        ),
      ),
      ChatRoom(
        id: 'room_3',
        name: 'Thông báo CLB',
        type: ChatRoomType.announcement,
        memberCount: 50,
        unreadCount: 1,
        lastMessage: ChatMessage(
          id: 'msg_3',
          content: 'Thông báo về buổi họp tháng 10',
          sender: User(
            id: 'admin',
            displayName: 'Admin',
            email: 'admin@email.com',
            avatar: 'https://i.pravatar.cc/150?img=10',
            rank: RankType.professional,
          ),
          timestamp: DateTime.now().subtract(Duration(hours: 6)),
        ),
      ),
    ];
  }

  List<Announcement> _generateMockAnnouncements() {
    return [
      Announcement(
        id: 'ann_1',
        title: 'Thông báo về giải đấu mùa thu',
        content: 'Giải đấu sẽ bắt đầu vào ngày 1/10. Tất cả thành viên đều có thể tham gia.',
        author: User(
          id: 'admin',
          displayName: 'Admin',
          email: 'admin@email.com',
          avatar: 'https://i.pravatar.cc/150?img=10',
          rank: RankType.professional,
        ),
        priority: AnnouncementPriority.high,
        tags: ['giải đấu', 'quan trọng'],
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        isRead: false,
      ),
      Announcement(
        id: 'ann_2',
        title: 'Cập nhật quy định CLB',
        content: 'Một số quy định mới đã được cập nhật. Vui lòng xem chi tiết.',
        author: User(
          id: 'admin',
          displayName: 'Admin',
          email: 'admin@email.com',
          avatar: 'https://i.pravatar.cc/150?img=10',
          rank: RankType.professional,
        ),
        priority: AnnouncementPriority.normal,
        tags: ['quy định'],
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        isRead: true,
      ),
    ];
  }

  List<Notification> _generateMockNotifications() {
    return [
      Notification(
        id: 'notif_1',
        title: 'Tin nhắn mới',
        content: 'Bạn có tin nhắn mới từ Nguyễn Văn A',
        type: NotificationType.message,
        createdAt: DateTime.now().subtract(Duration(minutes: 30)),
        isRead: false,
      ),
      Notification(
        id: 'notif_2',
        title: 'Giải đấu sắp bắt đầu',
        content: 'Giải đấu mùa thu sẽ bắt đầu trong 2 ngày',
        type: NotificationType.tournament,
        createdAt: DateTime.now().subtract(Duration(hours: 2)),
        isRead: false,
      ),
      Notification(
        id: 'notif_3',
        title: 'Thành tích mới',
        content: 'Bạn đã đạt được thành tích "Chiến thắng liên tiếp"',
        type: NotificationType.achievement,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        isRead: true,
      ),
    ];
  }
}

// Supporting classes and enums
enum ChatRoomType { general, tournament, private, announcement }
enum AnnouncementPriority { low, normal, high, urgent }
enum NotificationType { message, tournament, system, achievement }

class User {
  final String id;
  final String displayName;
  final String email;
  final String avatar;
  final RankType rank;

  const User({
    required this.id,
    required this.displayName,
    required this.email,
    required this.avatar,
    required this.rank,
  });
}

class ChatRoom {
  final String id;
  final String name;
  final ChatRoomType type;
  final int memberCount;
  final int unreadCount;
  final ChatMessage? lastMessage;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.memberCount,
    required this.unreadCount,
    this.lastMessage,
  });
}

class ChatMessage {
  final String id;
  final String content;
  final User sender;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
  });
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final User author;
  final AnnouncementPriority priority;
  final List<String> tags;
  final DateTime createdAt;
  final bool isRead;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.priority,
    required this.tags,
    required this.createdAt,
    required this.isRead,
  });
}

class Notification {
  final String id;
  final String title;
  final String content;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const Notification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  Notification copyWith({
    String? id,
    String? title,
    String? content,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

// Placeholder screens for navigation
// ChatRoomScreen moved to separate file

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({super.key});

} 
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết thông báo')),
      body: Center(child: Text('Announcement Detail Screen - Coming Soon')),
    );
  }
}

class CreateChatRoomDialog extends StatelessWidget {
  const CreateChatRoomDialog({super.key});

} 
  const CreateChatRoomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tạo phòng chat'),
      content: Text('Tính năng đang phát triển'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đóng'),
        ),
      ],
    );
  }
}

class CreateAnnouncementDialog extends StatelessWidget {
  const CreateAnnouncementDialog({super.key});

} 
  const CreateAnnouncementDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tạo thông báo'),
      content: Text('Tính năng đang phát triển'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Đóng'),
        ),
      ],
    );
  }
}

