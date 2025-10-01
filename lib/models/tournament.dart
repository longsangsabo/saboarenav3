class Tournament() {
  final String id;
  final String title;
  final String description;
  final String? clubId;
  final String? organizerId;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime registrationDeadline;
  final int maxParticipants;
  final int currentParticipants;
  final double entryFee;
  final double prizePool;
  final String status;
  final String? skillLevelRequired;
  final String format; // Game type (8-ball, 9-ball, 10-ball) 
  final String tournamentType; // Tournament elimination format (single_elimination, double_elimination)
  final String? rules;
  final String? requirements;
  final bool isPublic;
  final String? coverImageUrl;
  final Map<String, dynamic>? prizeDistribution;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tournament({
    required this.id,
    required this.title,
    required this.description,
    this.clubId,
    this.organizerId,
    required this.startDate,
    this.endDate,
    required this.registrationDeadline,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    this.skillLevelRequired,
    required this.format, // Game type  
    required this.tournamentType, // Tournament elimination format
    this.rules,
    this.requirements,
    required this.isPublic,
    this.coverImageUrl,
    this.prizeDistribution,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      clubId: json['club_id'],
      organizerId: json['organizer_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      registrationDeadline: DateTime.parse(json['registration_deadline']),
      maxParticipants: json['max_participants'] ?? 0,
      currentParticipants: json['current_participants'] ?? 0,
      entryFee: (json['entry_fee'] ?? 0).toDouble(),
      prizePool: (json['prize_pool'] ?? 0).toDouble(),
      status: json['status'] ?? 'upcoming',
      skillLevelRequired: json['skill_level_required'],
      // CLEAN SCHEMA: Use proper field mapping with new columns
      format: json['game_format'] ?? '8-ball', // Game type from game_format field
      tournamentType: json['bracket_format'] ?? 'single_elimination', // Tournament format from bracket_format field
      rules: json['rules'],
      requirements: json['requirements'],
      isPublic: json['is_public'] ?? true,
      coverImageUrl: json['cover_image_url'],
      prizeDistribution: json['prize_distribution'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Getter for cover image (for backward compatibility)
  String? get coverImage => coverImageUrl;
  
  // Helpers for clarity after migration
  String get gameFormat => format; // 8-ball, 9-ball, etc.
  String get bracketFormat => tournamentType; // single_elimination, double_elimination, etc.

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'title': title,
      'description': description,
      'club_id': clubId,
      'organizer_id': organizerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'registration_deadline': registrationDeadline.toIso8601String(),
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'entry_fee': entryFee,
      'prize_pool': prizePool,
      'status': status,
      'skill_level_required': skillLevelRequired,
      // CLEAN SCHEMA: Save to proper new columns
      'bracket_format': tournamentType, // Tournament format saved to bracket_format field
      'game_format': format, // Game type saved to game_format field
      'rules': rules,
      'requirements': requirements,
      'is_public': isPublic,
      'cover_image_url': coverImageUrl,
      'prize_distribution': prizeDistribution,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Tournament copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    int? maxParticipants,
    double? entryFee,
    double? prizePool,
    String? status,
    String? skillLevelRequired,
    String? format,
    String? tournamentType,
    String? rules,
    String? requirements,
    String? coverImageUrl,
  }) {
    return Tournament(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      clubId: clubId,
      organizerId: organizerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      status: status ?? this.status,
      skillLevelRequired: skillLevelRequired ?? this.skillLevelRequired,
      format: format ?? this.format,
      tournamentType: tournamentType ?? this.tournamentType,
      rules: rules ?? this.rules,
      requirements: requirements ?? this.requirements,
      isPublic: isPublic,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      prizeDistribution: prizeDistribution,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper getters for UI compatibility
  String get clubName => 'Unknown Club';

  // Format display name getter
  String get formatDisplayName() {
    switch (format) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss':
        return 'Swiss System';
      case 'sabo_double_elimination':
        return 'SABO DE16';
      case 'sabo_double_elimination_32':
        return 'SABO DE32';
      default:
        return format.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool get isRegistrationOpen() {
    return DateTime.now().isBefore(registrationDeadline) &&
        status == 'upcoming' &&
        currentParticipants < maxParticipants;
  }

  bool get isFull => currentParticipants >= maxParticipants;

  String get statusDisplay() {
    switch (status) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Sắp diễn ra';
    }
  }

  String get skillLevelDisplay() {
    switch (skillLevelRequired) {
      case 'beginner':
        return 'Người mới';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return 'Tất cả';
    }
  }

  Duration get timeToStart => startDate.difference(DateTime.now());
  Duration get timeToRegistrationEnd =>
      registrationDeadline.difference(DateTime.now());

  double get participationRate() {
    if (maxParticipants == 0) return 0.0;
    return (currentParticipants / maxParticipants) * 100;
  }
}
