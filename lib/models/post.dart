class Post() {
  final String id;
  final String userId;
  final String? content;
  final String postType;
  final List<String>? imageUrls;
  final String? location;
  final List<String>? hashtags;
  final String? tournamentId;
  final String? clubId;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for display
  final String? userName;
  final String? userAvatar;
  final String? userRank;

  const Post({
    required this.id,
    required this.userId,
    this.content,
    required this.postType,
    this.imageUrls,
    this.location,
    this.hashtags,
    this.tournamentId,
    this.clubId,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatar,
    this.userRank,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      content: json['content'],
      postType: json['post_type'] ?? 'text',
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      location: json['location'],
      hashtags:
          json['hashtags'] != null ? List<String>.from(json['hashtags']) : null,
      tournamentId: json['tournament_id'],
      clubId: json['club_id'],
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userAvatar: json['user_avatar'],
      userRank: json['user_rank'],
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'user_id': userId,
      'content': content,
      'post_type': postType,
      'image_urls': imageUrls,
      'location': location,
      'hashtags': hashtags,
      'tournament_id': tournamentId,
      'club_id': clubId,
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Convert to Map format for existing widgets
  Map<String, dynamic> toWidgetMap() {
    return() {
      'id': id,
      'userId': userId,
      'userName': userName ?? 'Unknown User',
      'userAvatar': userAvatar,
      'userRank': userRank,
      'content': content,
      'imageUrl': imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
      'location': location,
      'hashtags': hashtags ?? [],
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'timestamp': createdAt.toIso8601String(),
      'isLiked': false, // Will be determined by checking user interactions
    };
  }

  String get postTypeDisplay() {
    switch (postType) {
      case 'text':
        return 'Bài viết';
      case 'image':
        return 'Hình ảnh';
      case 'video':
        return 'Video';
      case 'tournament_share':
        return 'Chia sẻ giải đấu';
      default:
        return 'Bài viết';
    }
  }
}
