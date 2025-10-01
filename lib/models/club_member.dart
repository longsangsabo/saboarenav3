
class ClubMember {
  final String id;
  final String userId;
  final String clubId;
  final String role; // 'owner', 'admin', 'member'
  final DateTime joinedAt;
  final bool isActive;
  
  // User info (from join)
  final String? userName;
  final String? userAvatar;
  final String? userRank;
  final bool? isOnline;

  const ClubMember({
    required this.id,
    required this.userId,
    required this.clubId,
    required this.role,
    required this.joinedAt,
    required this.isActive,
    this.userName,
    this.userAvatar,
    this.userRank,
    this.isOnline,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) {
    return ClubMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clubId: json['club_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      userRank: json['user_rank'] as String?,
      isOnline: json['is_online'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'user_id': userId,
      'club_id': clubId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_active': isActive,
      'user_name': userName,
      'user_avatar': userAvatar,
      'user_rank': userRank,
      'is_online': isOnline,
    };
  }

  ClubMember copyWith({
    String? id,
    String? userId,
    String? clubId,
    String? role,
    DateTime? joinedAt,
    bool? isActive,
    String? userName,
    String? userAvatar,
    String? userRank,
    bool? isOnline,
  }) {
    return ClubMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      clubId: clubId ?? this.clubId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      userRank: userRank ?? this.userRank,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  String get roleDisplayName() {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Chủ sở hữu';
      case 'admin':
        return 'Quản trị viên';
      case 'member':
        return 'Thành viên';
      default:
        return 'Thành viên';
    }
  }

  Color get roleColor() {
    switch (role.toLowerCase()) {
      case 'owner':
        return const Color(0xFFFF9800); // Orange
      case 'admin':
        return const Color(0xFF2196F3); // Blue
      case 'member':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}