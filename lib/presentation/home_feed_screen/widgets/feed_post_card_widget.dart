import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class FeedPostCardWidget extends StatefulWidget {
  const FeedPostCardWidget({super.key});

} 
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onUserTap;

  const FeedPostCardWidget({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onUserTap,
  });

  @override
  State<FeedPostCardWidget> createState() => _FeedPostCardWidgetState();
}

class _FeedPostCardWidgetState extends State<FeedPostCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onLike?.call();
  }

  Color _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze':
      case 'b':
        return Colors.brown;
      case 'silver':
      case 's':
        return Colors.grey;
      case 'gold':
      case 'g':
        return Colors.amber;
      case 'platinum':
      case 'p':
        return Colors.teal;
      case 'diamond':
      case 'd':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20), // More modern rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // Softer shadow
            blurRadius: 20, // More blur for modern depth
            offset: const Offset(0, 4), // Slight vertical offset
            spreadRadius: -2, // Negative spread for crisp edges
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Very subtle second shadow
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User header
          _buildUserHeader(context, theme, colorScheme),

          // Post content
          if (widget.post['content'] != null && widget.post['content'].toString().isNotEmpty)
            _buildPostContent(context, theme),

          // Post image
          if (widget.post['imageUrl'] != null)
            _buildPostMedia(context),

          // Location and hashtags
          if (widget.post['location'] != null && widget.post['location'].toString().isNotEmpty ||
              (widget.post['hashtags'] as List?)?.isNotEmpty == true)
            _buildLocationAndHashtags(context, theme),

          // Engagement section
          _buildEngagementSection(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onUserTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 6.w,
                  backgroundColor: Colors.grey[300],
                  child: ClipOval(
                    child: CustomImageWidget(
                      imageUrl: widget.post['userAvatar'] ??
                          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
                      width: 12.w,
                      height: 12.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Rank badge
                if (widget.post['userRank'] != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 4.w,
                      height: 4.w,
                      decoration: BoxDecoration(
                        color: _getRankColor(widget.post['userRank']),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          widget.post['userRank'].toString().substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onUserTap,
                  child: Text(
                    widget.post['userName']?.toString() ?? 'Unknown User',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  widget.post['timestamp'] != null
                      ? _formatTime(widget.post['timestamp'] as DateTime)
                      : 'Vừa xong',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Show post options
              _showPostOptions(context);
            },
            icon: Icon(
              Icons.more_horiz,
              color: Colors.grey[600],
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.post['content'].toString(),
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface,
              height: 1.4,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildPostMedia(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9, // Flexible aspect ratio
          child: CustomImageWidget(
            imageUrl: widget.post['imageUrl'].toString(),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationAndHashtags(BuildContext context, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          if (widget.post['location'] != null && widget.post['location'].toString().isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(width: 1.w),
                Flexible(
                  child: Text(
                    widget.post['location'].toString(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          
          // Hashtags
          if ((widget.post['hashtags'] as List?)?.isNotEmpty == true)
            Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Wrap(
                spacing: 2.w,
                runSpacing: 1.w,
                children: (widget.post['hashtags'] as List).map((hashtag) {
                  return Text(
                    '#$hashtag',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagementSection(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final isLiked = widget.post['isLiked'] == true;
    final likeCount = widget.post['likeCount'] ?? 0;
    final commentCount = widget.post['commentCount'] ?? 0;
    final shareCount = widget.post['shareCount'] ?? 0;

    return Column(
      children: [
        // Stats row
        if (likeCount > 0 || commentCount > 0 || shareCount > 0)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            child: Row(
              children: [
                if (likeCount > 0) ...[
                  Icon(
                    Icons.favorite,
                    size: 14.sp,
                    color: Colors.red,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$likeCount',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const Spacer(),
                if (commentCount > 0 || shareCount > 0) ...[
                  Flexible(
                    child: Text(
                      '${commentCount > 0 ? "$commentCount bình luận" : ''}${commentCount > 0 && shareCount > 0 ? " • " : ''}${shareCount > 0 ? "$shareCount lượt chia sẻ" : ''}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        
        // Divider
        if (likeCount > 0 || commentCount > 0 || shareCount > 0)
          Divider(
            height: 1,
            color: Colors.grey[300],
            indent: 4.w,
            endIndent: 4.w,
          ),

        // Action buttons
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Like button
              Expanded(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isLiked ? _scaleAnimation.value : 1.0,
                      child: _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        label: 'Thích',
                        color: isLiked ? Colors.red : Colors.grey[600],
                        onTap: _handleLike,
                      ),
                    );
                  },
                ),
              ),

              // Comment button
              Expanded(
                child: _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Bình luận',
                  color: Colors.grey[600],
                  onTap: widget.onComment,
                ),
              ),

              // Share button
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Chia sẻ',
                  color: Colors.grey[600],
                  onTap: widget.onShare,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: color,
            ),
            SizedBox(width: 1.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Lưu bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu bài viết')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Báo cáo bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi báo cáo')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Ẩn bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã ẩn bài viết')),
                  );
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }
}
