class PostModel {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final List<String>? tags;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.tags,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      authorAvatarUrl: json['author_avatar_url'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'share_count': shareCount,
      'is_liked': isLiked,
      'tags': tags,
    };
  }

  PostModel copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    String? authorId,
    String? authorName,
    String? authorAvatarUrl,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    List<String>? tags,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      tags: tags ?? this.tags,
    );
  }
}