import './club_model.dart';

/// @deprecated Use Tournament model instead (lib/models/tournament.dart)
/// This legacy model will be removed in future versions
@Deprecated('Use Tournament model from lib/models/tournament.dart instead')
class TournamentModel() {
  final String id;
  final String title;
  final ClubModel club;
  final String format;
  final double entryFee;
  final double? prizePool;
  final int currentParticipants;
  final int maxParticipants;
  final DateTime startDate;
  final DateTime? registrationDeadline;
  final String status;
  final String? coverImageUrl;
  final bool hasLiveStream;
  final String skillLevelRequired;

  TournamentModel({
    required this.id,
    required this.title,
    required this.club,
    required this.format,
    required this.entryFee,
    this.prizePool,
    required this.currentParticipants,
    required this.maxParticipants,
    required this.startDate,
    this.registrationDeadline,
    required this.status,
    this.coverImageUrl,
    required this.hasLiveStream,
    required this.skillLevelRequired,
  });
}
