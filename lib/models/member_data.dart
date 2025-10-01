// Enums for member management
enum MembershipType { regular, vip, premium }
enum MemberStatus { active, inactive, suspended, pending }
enum RankType { beginner, amateur, intermediate, advanced, professional }

class AdvancedFilters() {
  final List<MembershipType> membershipTypes;
  final String? minRank;
  final String? maxRank;
  final int? minElo;
  final int? maxElo;
  final DateTime? joinStartDate;
  final DateTime? joinEndDate;  
  final List<String> activityLevels;

  const AdvancedFilters({
    this.membershipTypes = const [],
    this.minRank,
    this.maxRank,
    this.minElo,
    this.maxElo,
    this.joinStartDate,
    this.joinEndDate,
    this.activityLevels = const [],
  });
}

class MemberData() {
  final String id;
  final UserInfo user;
  final MembershipInfo membershipInfo;
  final ActivityStats activityStats;

  const MemberData({
    required this.id,
    required this.user,
    required this.membershipInfo,
    required this.activityStats,
  });

  factory MemberData.fromJson(Map<String, dynamic> json) {
    return MemberData(
      id: json['id'] ?? '',
      user: UserInfo.fromJson(json['user'] ?? {}),
      membershipInfo: MembershipInfo.fromJson(json['membership_info'] ?? {}),
      activityStats: ActivityStats.fromJson(json['activity_stats'] ?? {}),
    );
  }

  factory MemberData.fromSupabaseData(Map<String, dynamic> data) {
    print('🔍 Converting member data: ${data.keys}');
    print('🔍 Users data: ${data['users']}');
    
    // Handle nested users data
    final userData = data['users'] ?? {};
    
    return MemberData(
      id: data['id'] ?? '',
      user: UserInfo(
        id: userData['id'] ?? data['user_id'] ?? '',
        name: userData['name'] ?? data['user_name'] ?? userData['display_name'] ?? 'Chưa có tên',
        username: userData['username'] ?? data['username'] ?? 'user',
        avatar: userData['avatar_url'] ?? data['avatar_url'] ?? '',
        elo: userData['elo_rating'] ?? data['elo_rating'] ?? 1000,
        rank: userData['rank'] ?? data['rank'] ?? 'beginner',
        isOnline: userData['is_online'] ?? data['is_online'] ?? false,
      ),
      membershipInfo: MembershipInfo(
        membershipId: data['id'] ?? '',
        joinDate: data['joined_at'] != null 
            ? DateTime.parse(data['joined_at']) 
            : DateTime.now(),
        status: data['status'] ?? 'active',
        type: data['role'] ?? 'member',
        autoRenewal: data['auto_renewal'] ?? false,
      ),
      activityStats: ActivityStats(
        activityScore: data['activity_score'] ?? 0,
        winRate: (data['win_rate'] ?? 0.0).toDouble(),
        totalMatches: data['total_matches'] ?? 0,
        lastActive: data['last_active'] != null 
            ? DateTime.parse(data['last_active']) 
            : DateTime.now(),
        tournamentsJoined: data['tournaments_joined'] ?? 0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'user': user.toJson(),
      'membership_info': membershipInfo.toJson(),
      'activity_stats': activityStats.toJson(),
    };
  }
}

class UserInfo() {
  final String id;
  final String name;
  final String username;
  final String avatar;
  final int elo;
  final String rank;
  final bool isOnline;

  const UserInfo({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.elo,
    required this.rank,
    required this.isOnline,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      elo: json['elo'] ?? 1000,
      rank: json['rank'] ?? 'Bronze',
      isOnline: json['is_online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'name': name,
      'username': username,
      'avatar': avatar,
      'elo': elo,
      'rank': rank,
      'is_online': isOnline,
    };
  }
}

class MembershipInfo() {
  final String membershipId;
  final DateTime joinDate;
  final String status; // 'active', 'inactive', 'banned'
  final String type; // 'owner', 'admin', 'member', 'vip'
  final bool autoRenewal;

  const MembershipInfo({
    required this.membershipId,
    required this.joinDate,
    required this.status,
    required this.type,
    required this.autoRenewal,
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    return MembershipInfo(
      membershipId: json['membership_id'] ?? '',
      joinDate: json['join_date'] != null 
          ? DateTime.parse(json['join_date']) 
          : DateTime.now(),
      status: json['status'] ?? 'active',
      type: json['type'] ?? 'member',
      autoRenewal: json['auto_renewal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'membership_id': membershipId,
      'join_date': joinDate.toIso8601String(),
      'status': status,
      'type': type,
      'auto_renewal': autoRenewal,
    };
  }
}

class ActivityStats() {
  final int activityScore;
  final double winRate;
  final int totalMatches;
  final DateTime lastActive;
  final int tournamentsJoined;

  const ActivityStats({
    required this.activityScore,
    required this.winRate,
    required this.totalMatches,
    required this.lastActive,
    required this.tournamentsJoined,
  });

  factory ActivityStats.fromJson(Map<String, dynamic> json) {
    return ActivityStats(
      activityScore: json['activity_score'] ?? 0,
      winRate: (json['win_rate'] ?? 0.0).toDouble(),
      totalMatches: json['total_matches'] ?? 0,
      lastActive: json['last_active'] != null 
          ? DateTime.parse(json['last_active']) 
          : DateTime.now(),
      tournamentsJoined: json['tournaments_joined'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'activity_score': activityScore,
      'win_rate': winRate,
      'total_matches': totalMatches,
      'last_active': lastActive.toIso8601String(),
      'tournaments_joined': tournamentsJoined,
    };
  }
}