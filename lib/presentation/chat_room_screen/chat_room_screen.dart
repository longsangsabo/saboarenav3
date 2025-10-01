import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/chat_service.dart';
import '../member_communication_screen/member_communication_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

} 
  final ChatRoom room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMore = false;
  String? _replyToMessageId;
  Map<String, dynamic>? _replyToMessage;
  
  RealtimeChannel? _messageSubscription;
  RealtimeChannel? _roomSubscription;
  
  int _currentOffset = 0;
  final int _messageLimit = 50;
  bool _hasMoreMessages = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupRealtimeSubscriptions();
    _scrollController.addListener(_onScroll);
    
    // Mark room as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatService.updateLastReadTime(widget.room.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messageSubscription?.unsubscribe();
    _roomSubscription?.unsubscribe();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoading = true);
      
      final messages = await ChatService.getMessages(
        roomId: widget.room.id,
        limit: _messageLimit,
        offset: 0,
      );
      
      setState(() {
        _messages = messages;
        _currentOffset = messages.length;
        _hasMoreMessages = messages.length == _messageLimit;
        _isLoading = false;
      });
      
      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Không thể tải tin nhắn: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;
    
    try {
      setState(() => _isLoadingMore = true);
      
      final newMessages = await ChatService.getMessages(
        roomId: widget.room.id,
        limit: _messageLimit,
        offset: _currentOffset,
      );
      
      setState(() {
        _messages.insertAll(0, newMessages.reversed);
        _currentOffset += newMessages.length;
        _hasMoreMessages = newMessages.length == _messageLimit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showErrorSnackBar('Không thể tải thêm tin nhắn: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    // Subscribe to new messages
    _messageSubscription = ChatService.subscribeToMessages(
      roomId: widget.room.id,
      onMessage: (message) async {
        // Get full message data with user info
        try {
          final fullMessage = await ChatService.getMessages(
            roomId: widget.room.id,
            limit: 1,
            offset: 0,
          );
          
          if (fullMessage.isNotEmpty) {
            setState(() {
              _messages.add(fullMessage.first);
            });
            
            // Auto-scroll to bottom for new messages
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
            
            // Update last read time
            ChatService.updateLastReadTime(widget.room.id);
          }
        } catch (e) {
          debugPrint('Error loading new message: $e');
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    try {
      setState(() => _isSending = true);
      
      await ChatService.sendMessage(
        roomId: widget.room.id,
        message: messageText,
        replyTo: _replyToMessageId,
      );

      _messageController.clear();
      _clearReply();
      
    } catch (e) {
      _showErrorSnackBar('Không thể gửi tin nhắn: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showMessageOptions(Map<String, dynamic> message) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnMessage = message['sender_id'] == currentUser?.id;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.pop(context);
                _setReplyTo(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message['message']));
                _showSuccessSnackBar('Đã sao chép tin nhắn');
              },
            ),
            if (isOwnMessage) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteMessage(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _setReplyTo(Map<String, dynamic> message) {
    setState(() {
      _replyToMessageId = message['id'];
      _replyToMessage = message;
    });
    _messageFocusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToMessage = null;
    });
  }

  void _editMessage(Map<String, dynamic> message) {
    final controller = TextEditingController(text: message['message']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập tin nhắn...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ChatService.editMessage(message['id'], controller.text.trim());
                Navigator.pop(context);
                _showSuccessSnackBar('Đã cập nhật tin nhắn');
                _loadMessages(); // Reload to show edited message
              } catch (e) {
                _showErrorSnackBar('Không thể cập nhật tin nhắn: $e');
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMessage(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Bạn có chắc chắn muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ChatService.deleteMessage(message['id']);
                Navigator.pop(context);
                _showSuccessSnackBar('Đã xóa tin nhắn');
                _loadMessages(); // Reload to remove deleted message
              } catch (e) {
                _showErrorSnackBar('Không thể xóa tin nhắn: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.room.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            '${widget.room.memberCount} thành viên',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchDialog,
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'info', child: Text('Thông tin phòng')),
            const PopupMenuItem(value: 'members', child: Text('Thành viên')),
            const PopupMenuItem(value: 'settings', child: Text('Cài đặt')),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có tin nhắn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy bắt đầu cuộc trò chuyện!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0 && _isLoadingMore) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final messageIndex = _isLoadingMore ? index - 1 : index;
        final message = _messages[messageIndex];
        final previousMessage = messageIndex > 0 ? _messages[messageIndex - 1] : null;
        
        return _buildMessageItem(message, previousMessage);
      },
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message, Map<String, dynamic>? previousMessage) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnMessage = message['sender_id'] == currentUser?.id;
    final user = message['users'];
    final messageTime = DateTime.parse(message['created_at']);
    
    // Check if we should show date separator
    final showDateSeparator = previousMessage == null ||
        !_isSameDay(DateTime.parse(previousMessage['created_at']), messageTime);
    
    // Check if we should show user avatar/name
    final showUserInfo = previousMessage == null ||
        previousMessage['sender_id'] != message['sender_id'] ||
        _isMoreThanMinutesApart(DateTime.parse(previousMessage['created_at']), messageTime, 5);

    return Column(
      children: [
        if (showDateSeparator) _buildDateSeparator(messageTime),
        GestureDetector(
          onLongPress: () => _showMessageOptions(message),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isOwnMessage && showUserInfo) _buildUserAvatar(user),
                if (!isOwnMessage && !showUserInfo) const SizedBox(width: 40),
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    margin: EdgeInsets.only(
                      left: isOwnMessage ? 48 : 0,
                      right: isOwnMessage ? 0 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: isOwnMessage 
                          ? CrossAxisAlignment.end 
                          : CrossAxisAlignment.start,
                      children: [
                        if (!isOwnMessage && showUserInfo) _buildUserName(user),
                        _buildMessageBubble(message, isOwnMessage),
                        _buildMessageTime(messageTime, message['is_edited'] == true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic>? user) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundImage: user?['avatar_url'] != null 
            ? NetworkImage(user!['avatar_url'])
            : null,
        child: user?['avatar_url'] == null 
            ? Text(
                (user?['display_name'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              )
            : null,
      ),
    );
  }

  Widget _buildUserName(Map<String, dynamic>? user) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 4),
      child: Text(
        user?['display_name'] ?? 'Unknown User',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: _getUserColor(user?['id']),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isOwnMessage) {
    final replyMessage = message['reply_message'];
    
    return Container(
      decoration: BoxDecoration(
        color: isOwnMessage 
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
          bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replyMessage != null) _buildReplyPreviewInMessage(replyMessage),
          Text(
            message['message'],
            style: TextStyle(
              color: isOwnMessage 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreviewInMessage(Map<String, dynamic> replyMessage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMessage['users']?['display_name'] ?? 'Unknown User',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            replyMessage['message'],
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTime(DateTime time, bool isEdited) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(time),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          if (isEdited) ...[
            const SizedBox(width: 4),
            Text(
              '(đã sửa)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trả lời ${_replyToMessage!['users']?['display_name'] ?? 'Unknown User'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToMessage!['message'],
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _clearReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getUserColor(String? userId) {
    if (userId == null) return Colors.grey;
    
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.indigo, Colors.pink,
    ];
    
    return colors[userId.hashCode % colors.length];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  bool _isMoreThanMinutesApart(DateTime date1, DateTime date2, int minutes) {
    return date2.difference(date1).inMinutes > minutes;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Hôm nay';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(roomId: widget.room.id),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _showRoomInfo();
        break;
      case 'members':
        _showRoomMembers();
        break;
      case 'settings':
        _showRoomSettings();
        break;
    }
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin phòng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên: ${widget.room.name}'),
            const SizedBox(height: 8),
            Text('Loại: ${_getRoomTypeText(widget.room.type)}'),
            const SizedBox(height: 8),
            Text('Thành viên: ${widget.room.memberCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showRoomMembers() {
    _showErrorSnackBar('Tính năng đang phát triển');
  }

  void _showRoomSettings() {
    _showErrorSnackBar('Tính năng đang phát triển');
  }

  String _getRoomTypeText(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.general:
        return 'Thảo luận chung';
      case ChatRoomType.tournament:
        return 'Giải đấu';
      case ChatRoomType.private:
        return 'Riêng tư';
      case ChatRoomType.announcement:
        return 'Thông báo';
    }
  }
}

class _SearchDialog extends StatefulWidget {
  final String roomId;

  const _SearchDialog({required this.roomId});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final results = await ChatService.searchMessages(
        roomId: widget.roomId,
        query: query,
      );

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tìm kiếm tin nhắn'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text('Không có kết quả'))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final message = _searchResults[index];
                            final user = message['users'];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user?['avatar_url'] != null
                                    ? NetworkImage(user!['avatar_url'])
                                    : null,
                                child: user?['avatar_url'] == null
                                    ? Text((user?['display_name'] ?? 'U')[0])
                                    : null,
                              ),
                              title: Text(user?['display_name'] ?? 'Unknown User'),
                              subtitle: Text(
                                message['message'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                _formatTime(DateTime.parse(message['created_at'])),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
