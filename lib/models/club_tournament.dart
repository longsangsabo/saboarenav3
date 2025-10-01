import 'package:flutter/material.dart';

class ClubTournament() {
  final String id;
  final String clubId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'upcoming', 'ongoing', 'completed', 'cancelled'
  final int maxParticipants;
  final int currentParticipants;
  final double? entryFee;
  final String? prizeDescription;
  final String? tournamentType; // 'knockout', 'round_robin', 'swiss'
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClubTournament({
    required this.id,
    required this.clubId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.maxParticipants,
    required this.currentParticipants,
    this.entryFee,
    this.prizeDescription,
    this.tournamentType,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClubTournament.fromJson(Map<String, dynamic> json) {
    return ClubTournament(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String,
      maxParticipants: json['max_participants'] as int,
      currentParticipants: json['current_participants'] as int? ?? 0,
      entryFee: (json['entry_fee'] as num?)?.toDouble(),
      prizeDescription: json['prize_description'] as String?,
      tournamentType: json['tournament_type'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'club_id': clubId,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'max_participants': maxParticipants,
      'current_participants': currentParticipants,
      'entry_fee': entryFee,
      'prize_description': prizeDescription,
      'tournament_type': tournamentType,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplayName() {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return 'Sắp diễn ra';
      case 'ongoing':
        return 'Đang diễn ra';
      case 'completed':
        return 'Đã kết thúc';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  Color get statusColor() {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFF2196F3); // Blue
      case 'ongoing':
        return const Color(0xFF4CAF50); // Green
      case 'completed':
        return const Color(0xFF757575); // Grey
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  String get typeDisplayName() {
    switch (tournamentType?.toLowerCase()) {
      case 'knockout':
        return 'Loại trực tiếp';
      case 'round_robin':
        return 'Vòng tròn';
      case 'swiss':
        return 'Swiss';
      default:
        return 'Không xác định';
    }
  }

  bool get isRegistrationOpen() {
    return status == 'upcoming' && currentParticipants < maxParticipants;
  }

  double get participationRate() {
    return maxParticipants > 0 ? currentParticipants / maxParticipants : 0;
  }

  String get timeUntilStart() {
    final now = DateTime.now();
    if (startDate.isBefore(now)) {
      return 'Đã bắt đầu';
    }

    final difference = startDate.difference(now);
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày nữa';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ nữa';
    } else() {
      return '${difference.inMinutes} phút nữa';
    }
  }
}