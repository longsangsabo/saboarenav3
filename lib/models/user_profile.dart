import '../core/utils/rank_migration_helper.dart';

class UserProfile() {
  final String id;
  final String email;
  final String fullName;
  final String displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final String? coverPhotoUrl;
  final String? phone;
  final DateTime? dateOfBirth;
  final String role;
  final String skillLevel;
  final String? rank; // Rank from database, null if not registered
  final int totalWins;
  final int totalLosses;
  final int totalTournaments;
  final int eloRating;
  final int spaPoints; // SPA reward points earned
  final double totalPrizePool; // Total prize money won from tournaments
  final bool isVerified;
  final bool isActive;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getter for compatibility
  int get rankingPoints => eloRating;

  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.coverPhotoUrl,
    this.phone,
    this.dateOfBirth,
    required this.role,
    required this.skillLevel,
    this.rank,
    required this.totalWins,
    required this.totalLosses,
    required this.totalTournaments,
    required this.eloRating,
    required this.spaPoints,
    required this.totalPrizePool,
    required this.isVerified,
    required this.isActive,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      displayName: json['display_name'] ?? json['full_name'] ?? '',
      username: json['username'],
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      coverPhotoUrl: json['cover_photo_url'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      role: json['role'] ?? 'player',
      skillLevel: json['skill_level'] ?? 'beginner',
      rank: json['rank'], // Can be null if user hasn't registered rank
      totalWins: json['total_wins'] ?? 0,
      totalLosses: json['total_losses'] ?? 0,
      totalTournaments: json['total_tournaments'] ?? 0,
      eloRating: json['elo_rating'] ?? 1200,
      spaPoints: json['spa_points'] ?? 0,
      totalPrizePool: (json['total_prize_pool'] ?? 0.0).toDouble(),
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
      location: json['location'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'email': email,
      'full_name': fullName,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'role': role,
      'skill_level': skillLevel,
      'rank': rank,
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_tournaments': totalTournaments,
      'elo_rating': eloRating,
      'spa_points': spaPoints,
      'total_prize_pool': totalPrizePool,
      'is_verified': isVerified,
      'is_active': isActive,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? coverPhotoUrl,
    String? phone,
    DateTime? dateOfBirth,
    String? skillLevel,
    String? location,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role,
      skillLevel: skillLevel ?? this.skillLevel,
      rank: rank ?? rank,
      totalWins: totalWins,
      totalLosses: totalLosses,
      totalTournaments: totalTournaments,
      eloRating: eloRating,
      spaPoints: spaPoints,
      totalPrizePool: totalPrizePool,
      isVerified: isVerified,
      isActive: isActive,
      location: location ?? this.location,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  double get winRate() {
    int totalGames = totalWins + totalLosses;
    if (totalGames == 0) return 0.0;
    return (totalWins / totalGames) * 100;
  }

  String get displayRank() {
    return RankMigrationHelper.getNewDisplayName(rank);
  }

  String get skillLevelDisplay() {
    switch (skillLevel) {
      case 'beginner':
        return 'Người mới';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return 'Người mới';
    }
  }

  String get roleDisplay() {
    switch (role) {
      case 'player':
        return 'Người chơi';
      case 'club_owner':
        return 'Chủ câu lạc bộ';
      case 'admin':
        return 'Quản trị viên';
      default:
        return 'Người chơi';
    }
  }
}
