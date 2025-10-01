import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sabo_arena/repositories/comment_repository.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:intl/intl.dart';

class CommentsModal extends StatefulWidget() {
  final String postId;
  final String postTitle;
  final VoidCallback? onCommentAdded;
  final VoidCallback? onCommentDeleted;

  const CommentsModal({
    super.key,
    required this.postId,
    required this.postTitle,
    this.onCommentAdded,
    this.onCommentDeleted,
  });

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final CommentRepository _commentRepository = CommentRepository();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;


  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
    _commentController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoading && _hasMore) {
      _loadMoreComments();
    }
  }

  Future<void> _refreshComments() async() {
    await _loadComments();
  }

  Future<void> _loadComments() async() {
    try() {
      setState(() {
        _isLoading = true;
        _hasMore = true;
        _offset = 0;
      });
      
      final comments = await _commentRepository.getPostComments(widget.postId, limit: _limit);
      
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
          _hasMore = comments.length >= _limit;
          _offset = comments.length;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tải bình luận: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: _loadComments,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreComments() async() {
    if (_isLoading || !_hasMore) return;

    try() {
      setState(() => _isLoading = true);
      
      final moreComments = await _commentRepository.getPostComments(
        widget.postId,
        limit: _limit,
        offset: _offset,
      );
      
      if (mounted) {
        setState(() {
          _comments.addAll(moreComments);
          _hasMore = moreComments.length >= _limit;
          _offset += moreComments.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tải thêm bình luận: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _postComment() async() {
    // Prevent double tapping
    if (_isPosting) {
      debugPrint('🚫 Already posting, ignoring tap');
      return;
    }

    final commentText = _commentController.text.trim();
    debugPrint('🧪 Creating comment with text: "$commentText"');
    
    // Validate comment
    if (commentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung bình luận'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (commentText.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bình luận không được vượt quá 1000 ký tự'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try() {
      setState(() => _isPosting = true);
      
      // Clear input immediately for better UX
      _commentController.clear();
      
      // Create optimistic comment
      final optimisticComment = {
        "id": 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'content': commentText,
        'created_at': DateTime.now().toIso8601String(),
        'user': {
          "full_name": 'Bạn',
          'avatar_url': null,
        },
        'is_temp': true, // Mark as temporary
      };
      
      // Add optimistic comment to UI
      setState(() {
        _comments.insert(0, optimisticComment);
      });
      
      // Scroll to top to show new comment
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      debugPrint('🧪 Post ID: ${widget.postId}');
      final newComment = await _commentRepository.createComment(widget.postId, commentText);
      
      if (newComment != null) {
        // Replace optimistic comment with real one
        setState(() {
          final index = _comments.indexWhere((c) => c['id'] == optimisticComment['id']);
          if (index != -1) {
            _comments[index] = newComment;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã đăng bình luận'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Notify parent about new comment
        widget.onCommentAdded?.call();
      } else() {
        // Remove optimistic comment if failed
        setState(() {
          _comments.removeWhere((c) => c['id'] == optimisticComment['id']);
        });
        throw Exception('Không thể tạo bình luận');
      }
    } catch (e) {
      // Remove optimistic comment if failed
      setState(() {
        _comments.removeWhere((c) => c['is_temp'] == true);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi đăng bình luận: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Restore comment text if failed
      _commentController.text = commentText;
    } finally() {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Future<void> _editComment(Map<String, dynamic> comment, int index) async() {
    final controller = TextEditingController(text: comment['content']);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa bình luận'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 1000,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung bình luận...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != comment['content']) {
      try() {
        final updatedComment = await _commentRepository.updateComment(comment['id'], result);
        if (updatedComment != null) {
          setState(() {
            _comments[index] = updatedComment;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Đã cập nhật bình luận'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi cập nhật bình luận: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteComment(String commentId, int index) async() {
    try() {
      final canDelete = await _commentRepository.canDeleteComment(commentId);
      if (!canDelete) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn không có quyền xóa bình luận này'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xóa bình luận'),
          content: const Text('Bạn có chắc chắn muốn xóa bình luận này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _commentRepository.deleteComment(commentId);
        setState(() {
          _comments.removeAt(index);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Đã xóa bình luận'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Notify parent about deleted comment
        widget.onCommentDeleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xóa bình luận: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Bình luận',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: _isLoading && _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải bình luận...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _comments.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _refreshComments,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Chưa có bình luận nào\nHãy là người đầu tiên bình luận!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Kéo xuống để làm mới',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshComments,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _comments.length + (_hasMore && !_isLoading ? 1 : 0) + (_isLoading && _comments.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _comments.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text(
                                        'Đang tải thêm...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final comment = _comments[index];
                            return _buildCommentItem(comment, index);
                          },
                        ),
                      ),
          ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Viết bình luận...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.primaryLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    maxLength: 1000,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                      return currentLength > 900
                          ? Text(
                              '$currentLength/$maxLength',
                              style: TextStyle(
                                color: currentLength >= maxLength! ? Colors.red : Colors.grey,
                                fontSize: 12,
                              ),
                            )
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                _isPosting
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _commentController.text.trim().isEmpty || _isPosting
                              ? Colors.grey.shade300
                              : AppTheme.primaryLight,
                        ),
                        child: IconButton(
                          onPressed: (_commentController.text.trim().isEmpty || _isPosting) 
                              ? null 
                              : _postComment,
                          icon: Icon(
                            Icons.send,
                            color: _commentController.text.trim().isEmpty || _isPosting
                                ? Colors.grey.shade600
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, int index) {
    final user = comment['user'] as Map<String, dynamic>?;
    final createdAt = DateTime.parse(comment['created_at']);
    final timeAgo = _formatTimeAgo(createdAt);
    final isTemp = comment['is_temp'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isTemp ? Colors.grey.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar with loading indicator for temp comments
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user?['avatar_url'] != null
                    ? NetworkImage(user!['avatar_url'])
                    : null,
                child: user?['avatar_url'] == null
                    ? Text(
                        user?['full_name']?.toString().substring(0, 1).toUpperCase() ??
                            user?['email']?.toString().substring(0, 1).toUpperCase() ??
                            '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
              if (isTemp)
                Positioned.fill(
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black26,
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name and time
                Row(
                  children: [
                    Text(
                      user?['full_name'] ?? user?['email'] ?? 'Unknown User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isTemp ? Colors.grey.shade600 : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTemp ? 'Đang gửi...' : timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: isTemp ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment text
                Text(
                  comment['content'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isTemp ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Action menu (only for own comments, not for temp comments)
          if (!isTemp)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editComment(comment, index);
                } else if (value == 'delete') {
                  _deleteComment(comment['id'], index);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Sửa'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Xóa'),
                    ],
                  ),
                ),
              ],
              child: Icon(
                Icons.more_vert,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else() {
      return 'Vừa xong';
    }
  }
}