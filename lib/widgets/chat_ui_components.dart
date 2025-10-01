import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../models/messaging_models.dart';

/// Chat App Bar widget for chat screen
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget() {
  final String title;
  final String? subtitle;
  final String? avatarUrl;
  final VoidCallback? onBackPressed;
  final VoidCallback? onUserPressed;
  final List<Widget>? actions;

  const ChatAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarUrl,
    this.onBackPressed,
    this.onUserPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 1,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: onUserPressed,
        child: Row(
          children: [
            if (avatarUrl != null)
              CircleAvatar(
                radius: 2.h,
                backgroundImage: NetworkImage(avatarUrl!),
                backgroundColor: Colors.grey[300],
              )
            else
              CircleAvatar(
                radius: 2.h,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: actions ?? [
        IconButton(
          icon: Icon(Icons.videocam_outlined, color: Theme.of(context).primaryColor),
          onPressed: () {
            // TODO: Implement video call
          },
        ),
        IconButton(
          icon: Icon(Icons.call_outlined, color: Theme.of(context).primaryColor),
          onPressed: () {
            // TODO: Implement voice call
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).primaryColor),
          onSelected: (value) {
            // TODO: Handle menu actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'info', child: Text('Chat Info')),
            const PopupMenuItem(value: 'mute', child: Text('Mute')),
            const PopupMenuItem(value: 'search', child: Text('Search')),
            const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Message Input widget for sending messages
class MessageInput extends StatefulWidget() {
  final Function(String) onSendMessage;
  final Function(String)? onTyping;
  final VoidCallback? onAttachFile;
  final VoidCallback? onRecordVoice;
  final bool isEnabled;
  final String? hintText;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.onTyping,
    this.onAttachFile,
    this.onRecordVoice,
    this.isEnabled = true,
    this.hintText,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      widget.onTyping?.call(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.onAttachFile != null)
              IconButton(
                icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                onPressed: widget.isEnabled ? widget.onAttachFile : null,
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _controller,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: widget.hintText ?? 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                  ),
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            if (_controller.text.trim().isEmpty && widget.onRecordVoice != null)
              GestureDetector(
                onLongPress: () {
                  setState(() => _isRecording = true);
                  // TODO: Start recording
                },
                onLongPressEnd: (_) {
                  setState(() => _isRecording = false);
                  // TODO: Stop recording and send
                },
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: widget.isEnabled ? _sendMessage : null,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 6.w,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Message Bubble widget for displaying messages
class MessageBubble extends StatelessWidget() {
  final MessageModel message;
  final bool isFromCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showAvatar;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.onTap,
    this.onLongPress,
    this.showAvatar = true,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 0.5.h, horizontal: 4.w),
        child: Row(
          mainAxisAlignment: isFromCurrentUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isFromCurrentUser && showAvatar)
              CircleAvatar(
                radius: 2.h,
                backgroundImage: message.sender?.avatarUrl != null
                    ? NetworkImage(message.sender!.avatarUrl!)
                    : null,
                backgroundColor: Colors.grey[300],
                child: message.sender?.avatarUrl == null
                    ? Text(
                        message.sender?.fullName?.isNotEmpty == true
                            ? message.sender!.fullName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            if (!isFromCurrentUser && showAvatar) SizedBox(width: 2.w),
            Flexible(
              child: Column(
                crossAxisAlignment: isFromCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  if (!isFromCurrentUser && message.sender?.fullName != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Text(
                        message.sender!.fullName!,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Container(
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
                        if (message.replyToMessage != null)
                          Container(
                            margin: EdgeInsets.only(bottom: 1.h),
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToMessage!.sender?.fullName ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isFromCurrentUser ? Colors.white70 : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  message.replyToMessage!.content,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        _buildMessageContent(),
                        if (showTimestamp)
                          Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: isFromCurrentUser 
                                        ? Colors.white70 
                                        : Colors.grey[600],
                                  ),
                                ),
                                if (isFromCurrentUser) ...[
                                  SizedBox(width: 1.w),
                                  Icon(
                                    _getStatusIcon(),
                                    size: 3.w,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isFromCurrentUser && showAvatar) SizedBox(width: 2.w),
            if (isFromCurrentUser && showAvatar)
              CircleAvatar(
                radius: 2.h,
                backgroundImage: message.sender?.avatarUrl != null
                    ? NetworkImage(message.sender!.avatarUrl!)
                    : null,
                backgroundColor: Theme.of(context).primaryColor,
                child: message.sender?.avatarUrl == null
                    ? Text(
                        message.sender?.fullName?.isNotEmpty == true
                            ? message.sender!.fullName![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 12.sp,
            color: isFromCurrentUser ? Colors.white : Colors.black87,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.metadata.containsKey('image_url'))
              ClipRRect(
                borderRadius: BorderRadius.circular(2.w),
                child: Image.network(
                  message.metadata['image_url'],
                  width: 50.w,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50.w,
                      height: 30.w,
                      color: Colors.grey[300],
                      child: Icon(Icons.broken_image),
                    );
                  },
                ),
              ),
            if (message.content.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 1.h),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isFromCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
              ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              color: isFromCurrentUser ? Colors.white : Colors.grey[600],
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isFromCurrentUser ? Colors.white : Colors.black87,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: isFromCurrentUser ? Colors.white : Colors.grey[600],
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Container(
              width: 30.w,
              height: 1.w,
              decoration: BoxDecoration(
                color: isFromCurrentUser ? Colors.white38 : Colors.grey[400],
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              message.metadata['duration'] ?? '0:00',
              style: TextStyle(
                fontSize: 10.sp,
                color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 12.sp,
            color: isFromCurrentUser ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else() {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Typing Indicator widget
class TypingIndicatorWidget extends StatefulWidget() {
  final List<String> usernames;

  const TypingIndicatorWidget({
    super.key,
    required this.usernames,
  });

  @override
  State<TypingIndicatorWidget> createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usernames.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.usernames.length == 1
                ? "${widget.usernames.first} is typing"
                : '${widget.usernames.join(', ')} are typing',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(width: 2.w),
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Row(
                children: List.generate(3, (index) {
                  final delay = index * 0.2;
                  final opacity = (Curves.easeInOut.transform(
                    (_animationController.value + delay) % 1.0,
                  ) * 0.7) + 0.3;
                  
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                    width: 1.5.w,
                    height: 1.5.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[600]?.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}