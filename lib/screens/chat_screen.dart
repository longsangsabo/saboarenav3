import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/messaging_service.dart';
import '../widgets/chat_ui_components.dart';

/// Simplified Chat Screen that works with existing messaging system
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

} 
  final String chatId;
  final String? otherUserName;
  final String? otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.otherUserName,
    this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final MessagingService _messagingService = MessagingService.instance;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoading = true);
      final messages = await _messagingService.getChatMessages(widget.chatId);
      setState(() {
        _messages = messages.reversed.toList(); // Reverse to show newest at bottom
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'Failed to load messages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      final success = await _messagingService.sendMessage(
        roomId: widget.chatId,
        content: content.trim(),
      );

      if (success) {
        // Add message to local list optimistically
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content.trim(),
            "sender_id": 'current_user', // This should come from auth service
            'created_at': DateTime.now().toIso8601String(),
            "message_type": 'text',
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(
        title: widget.otherUserName ?? 'Chat',
        avatarUrl: widget.otherUserAvatar,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          MessageInput(
            onSendMessage: _sendMessage,
            hintText: 'Type a message...',
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(color: Colors.grey[500], fontSize: 10.sp),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromCurrentUser = message['sender_id'] == 'current_user'; // This should come from auth service
        
        return Container(
          margin: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 4.w),
          child: Row(
            mainAxisAlignment: isFromCurrentUser 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            children: [
              if (!isFromCurrentUser) ...[
                CircleAvatar(
                  radius: 2.h,
                  backgroundImage: widget.otherUserAvatar != null
                      ? NetworkImage(widget.otherUserAvatar!)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: widget.otherUserAvatar == null
                      ? Text(
                          widget.otherUserName?.isNotEmpty == true
                              ? widget.otherUserName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 2.w),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 70.w),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4.w),
                      topRight: Radius.circular(4.w),
                      bottomLeft: Radius.circular(isFromCurrentUser ? 4.w : 1.w),
                      bottomRight: Radius.circular(isFromCurrentUser ? 1.w : 4.w),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['content'] ?? '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isFromCurrentUser ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        _formatTime(DateTime.tryParse(message['created_at'] ?? '') ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: isFromCurrentUser 
                              ? Colors.white70 
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isFromCurrentUser) ...[
                SizedBox(width: 2.w),
                CircleAvatar(
                  radius: 2.h,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    'Me'[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else {
      () {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  
    }}
}