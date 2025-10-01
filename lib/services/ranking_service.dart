import 'package:flutter/material.dart';
import 'package:sabo_arena/core/constants/ranking_constants.dart';
import 'package:sabo_arena/models/user_profile.dart';

/// 🎯 Ranking Service
///
/// Handles all logic related to calculating, updating, and verifying player ranks.
/// This service uses the ELO rating of a user to determine their appropriate rank
/// based on the definitions in [RankingConstants].
class RankingService() {
  /// Returns display information for a given rank code.
  ///
  /// - [rankCode]: The rank code (e.g., 'K', 'I+').
  ///
  /// Returns a [RankDisplayInfo] object with name, color, and icon.
  RankDisplayInfo getRankDisplayInfo(String? rankCode) {
    final details = RankingConstants.RANK_DETAILS[rankCode];
    if (details == null) {
      return RankDisplayInfo(
        code: RankingConstants.UNRANKED,
        name: 'Chưa xếp hạng',
        color: Colors.grey,
        icon: Icons.help_outline,
      );
    }
    return RankDisplayInfo(
      code: rankCode!,
      name: details['name']!, // Sử dụng tên mới từ RANK_DETAILS
      color: Color(int.parse(details['color']!.replaceFirst('#', '0xFF'))),
      icon: RankingConstants.RANK_ICONS[rankCode] ?? Icons.star,
    );
  }

  /// Calculates a user's rank based on their ELO rating.
  ///
  /// Returns the corresponding rank code (e.g., 'K', 'I+', 'G') from [RankingConstants].
  /// If the ELO does not fall into any defined range, it returns [RankingConstants.UNRANKED].
  String getRankFromElo(int elo) {
    for (final entry in RankingConstants.RANK_ELO_RANGES.entries) {
      final min = entry.value['min']!;
      final max = entry.value['max']!;
      if (elo >= min && elo <= max) {
        return entry.key;
      }
    }
    return RankingConstants.UNRANKED;
  }

  /// Determines if a user's rank should be updated based on their current ELO.
  ///
  /// This function checks if the rank calculated from the user's ELO is different
  /// from their current rank.
  ///
  /// - [currentUserProfile]: The user's current profile.
  ///
  /// Returns `true` if the rank needs an update, otherwise `false`.
  bool shouldUpdateRank(UserProfile currentUserProfile) {
    final currentRank = currentUserProfile.rank;
    final newRank = getRankFromElo(currentUserProfile.eloRating);
    return currentRank != newRank;
  }

  /// Checks if a user is eligible for rank verification.
  ///
  /// Verification is required for a player to officially hold a rank.
  /// Eligibility is based on the minimum number of matches played and win rate.
  ///
  /// - [totalMatches]: The total number of matches the user has played.
  /// - [winRate]: The user's win rate (as a percentage, e.g., 55.0 for 55%).
  ///
  /// Returns `true` if the user meets the verification criteria.
  bool isEligibleForVerification(int totalMatches, double winRate) {
    return totalMatches >= RankingConstants.MIN_VERIFICATION_MATCHES &&
        winRate >= (RankingConstants.MIN_VERIFICATION_WIN_RATE * 100);
  }

  /// Checks if a user qualifies for automatic rank verification.
  ///
  /// Players with a significant number of matches may be automatically verified.
  ///
  /// - [totalMatches]: The total number of matches the user has played.
  ///
  /// Returns `true` if the user meets the auto-verification criteria.
  bool shouldAutoVerify(int totalMatches) {
    return totalMatches >= RankingConstants.AUTO_VERIFY_MATCH_THRESHOLD;
  }

  /// Determines the next rank in the progression.
  ///
  /// - [currentRank]: The user's current rank code.
  ///
  /// Returns the next rank code, or `null` if the user is at the highest rank.
  String? getNextRank(String currentRank) {
    return RankingConstants.getNextRank(currentRank);
  }

  /// Determines the previous rank in the progression.
  ///
  /// - [currentRank]: The user's current rank code.
  ///
  /// Returns the previous rank code, or `null` if the user is at the lowest rank.
  String? getPreviousRank(String currentRank) {
    return RankingConstants.getPreviousRank(currentRank);
  }

  /// Compares two ranks to see if the change is a promotion.
  ///
  /// - [fromRank]: The original rank.
  /// - [toRank]: The new rank.
  ///
  /// Returns `true` if `toRank` is higher than `fromRank`.
  bool isRankUp(String fromRank, String toRank) {
    return RankingConstants.isRankUp(fromRank, toRank);
  }

  /// Compares two ranks to see if the change is a demotion.
  ///
  /// - [fromRank]: The original rank.
  /// - [toRank]: The new rank.
  ///
  /// Returns `true` if `toRank` is lower than `fromRank`.
  bool isRankDown(String fromRank, String toRank) {
    return RankingConstants.isRankDown(fromRank, toRank);
  }
}

/// A data class to hold display-friendly information about a rank.
class RankDisplayInfo() {
  final String code;
  final String name;
  final Color color;
  final IconData icon;

  RankDisplayInfo({
    required this.code,
    required this.name,
    required this.color,
    required this.icon,
  });
}
