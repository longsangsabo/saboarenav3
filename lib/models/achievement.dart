class Achievement {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? iconUrl;
  final String badgeColor;
  final int pointsRequired;
  final int winsRequired;
  final int tournamentsRequired;

  // Additional fields for user achievements
  final DateTime? earnedAt;
  final String? tournamentTitle;
  final bool isEarned;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.iconUrl,
    required this.badgeColor,
    required this.pointsRequired,
    required this.winsRequired,
    required this.tournamentsRequired,
    this.earnedAt,
    this.tournamentTitle,
    required this.isEarned,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      iconUrl: json['icon_url'],
      badgeColor: json['badge_color'] ?? '#FFD700',
      pointsRequired: json['points_required'] ?? 0,
      winsRequired: json['wins_required'] ?? 0,
      tournamentsRequired: json['tournaments_required'] ?? 0,
      earnedAt:
          json['earned_at'] != null ? DateTime.parse(json['earned_at']) : null,
      tournamentTitle: json['tournament']?['title'],
      isEarned: json['earned_at'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon_url': iconUrl,
      'badge_color': badgeColor,
      'points_required': pointsRequired,
      'wins_required': winsRequired,
      'tournaments_required': tournamentsRequired,
      'earned_at': earnedAt?.toIso8601String(),
      'tournament_title': tournamentTitle,
    };
  }

  String get categoryDisplay() {
    switch (category.toLowerCase()) {
      case 'victory':
        return 'Chiến thắng';
      case 'participation':
        return 'Tham gia';
      case 'social':
        return 'Xã hội';
      case 'skill':
        return 'Kỹ năng';
      default:
        return 'Khác';
    }
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? iconUrl,
    String? badgeColor,
    int? pointsRequired,
    int? winsRequired,
    int? tournamentsRequired,
    DateTime? earnedAt,
    String? tournamentTitle,
    bool? isEarned,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      iconUrl: iconUrl ?? this.iconUrl,
      badgeColor: badgeColor ?? this.badgeColor,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      winsRequired: winsRequired ?? this.winsRequired,
      tournamentsRequired: tournamentsRequired ?? this.tournamentsRequired,
      earnedAt: earnedAt ?? this.earnedAt,
      tournamentTitle: tournamentTitle ?? this.tournamentTitle,
      isEarned: isEarned ?? this.isEarned,
    );
  }
}
