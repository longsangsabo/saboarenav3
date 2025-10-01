import 'package:flutter/material.dart';

/// 🔄 RANK MIGRATION HELPER
///
/// Utility class để hỗ trợ migration từ hệ thống rank cũ sang mới
/// và đảm bảo compatibility giữa các phiên bản
class RankMigrationHelper {
  // Temporarily simplified for compilation
  static String getNewDisplayName(String? input) {
    if (input == null || input.isEmpty) return 'Chưa xếp hạng';
    return input; // Return input as-is for now
  }
  
  /*
  // Original complex implementation commented out until dependencies are fixed
  /// Mapping từ tên rank cũ sang mã rank (ELO-based system)
  /// Điều này đảm bảo backwards compatibility
  static const Map<String, String> oldNameToRankCode = {
    "Tập Sự": 'K',
    "Tập Sự+": 'K+',
    "Sơ Cấp": 'I',
    "Sơ Cấp+": 'I+',
    "Trung Cấp": 'H',
    "Trung Cấp+": 'H+',
    "Khá": 'G',
    "Khá+": 'G+',
    "Giỏi": 'F',
    "Giỏi+": 'F+',
    "Xuất Sắc": 'E',
    "Chuyên Gia": 'E+',
    // Legacy rank codes that shouldn't exist
    "B": 'I', // Map legacy "B" to appropriate rank "I" (Thợ 3)
  };

  /// Mapping từ tên rank mới sang mã rank
  static const Map<String, String> newNameToRankCode = {
    "Người mới": 'K',
    "Học việc": 'K+',
    "Thợ 3": 'I',
    "Thợ 2": 'I+',
    "Thợ 1": 'H',
    "Thợ chính": 'H+',
    "Thợ giỏi": 'G',
    "Cao thủ": 'G+',
    "Chuyên gia": 'F',
    "Đại cao thủ": 'F+',
    "Huyền thoại": 'E',
    "Vô địch": 'E+',
  };

  /// Chuyển đổi rank name (cũ hoặc mới) thành rank code
  /// @param rankName - Tên rank (có thể là tên cũ hoặc mới)
  /// @return Rank code (K, K+, I, etc.) hoặc null nếu không tìm thấy
  static String? getRankCodeFromName(String? rankName) {
    if (rankName == null || rankName.isEmpty) return null;

    // Thử tìm trong system mới trước
    String? code = newNameToRankCode[rankName];
    if (code != null) return code;

    // Nếu không có, thử trong system cũ (backward compatibility)
    code = oldNameToRankCode[rankName];
    if (code != null) return code;

    // Nếu input đã là rank code rồi, return luôn
    if (RankingConstants.RANK_ORDER.contains(rankName)) {
      return rankName;
    }

    return null;
  }

  /// Lấy tên hiển thị mới từ rank code hoặc tên cũ
  /// @param input - Có thể là rank code (K, I+) hoặc tên rank cũ/mới
  /// @return Tên hiển thị mới
  static String getNewDisplayName(String? input) {
    if (input == null || input.isEmpty) return 'Chưa xếp hạng';
    
    // Temporary fallback until dependencies are fixed
    return input; // Return input as-is for now
  }

  /// Kiểm tra xem có phải là tên rank cũ không
  static bool isOldRankName(String? rankName) {
    return rankName != null && oldNameToRankCode.containsKey(rankName);
  }

  /// Kiểm tra xem có phải là tên rank mới không
  static bool isNewRankName(String? rankName) {
    return rankName != null && newNameToRankCode.containsKey(rankName);
  }

  /// Migration script: Chuyển đổi data cũ sang format mới
  /// @param userData - Map chứa data user từ database
  /// @return Map đã được migrate
  static Map<String, dynamic> migrateUserRankData(
      Map<String, dynamic> userData) {
    final Map<String, dynamic> migratedData = Map.from(userData);

    // Migrate rank field
    if (userData.containsKey('rank')) {
      String? currentRank = userData['rank'];
      if (currentRank != null && isOldRankName(currentRank)) {
        String? newCode = getRankCodeFromName(currentRank);
        if (newCode != null) {
          // Lưu rank code thay vì tên để đảm bảo consistency
          migratedData['rank'] = newCode;
          migratedData['rank_display_name'] = getNewDisplayName(newCode);
        }
      }
    }

    return migratedData;
  }

  /// Lấy danh sách tất cả rank names mới theo thứ tự
  static List<String> getAllNewRankNames() {
    return RankingConstants.RANK_ORDER
        .map((code) => SaboRankSystem.getRankDisplayName(code))
        .toList();
  }

  /// Lấy rank color từ bất kỳ input nào (code hoặc name)
  static Color getRankColor(String? input) {
    String? code = getRankCodeFromName(input) ?? input;
    if (code != null && RankingConstants.RANK_ORDER.contains(code)) {
      return SaboRankSystem.getRankColor(code);
    }
    return Colors.grey;
  }

  /// Debug method: In ra mapping comparison
  static void printRankMappingComparison() {
    debugPrint('🔄 RANK MIGRATION MAPPING:');
    debugPrint('=' * 50);

    for (String code in RankingConstants.RANK_ORDER) {
      String newName = SaboRankSystem.getRankDisplayName(code);
      String? oldName = oldNameToRankCode.entries
          .firstWhere((entry) => entry.value == code,
              orElse: () => const MapEntry('', ''))
          .key;

      debugPrint('$code: ${oldName.isNotEmpty ? oldName : 'N/A'} → $newName');
    }
  }
  */
}
