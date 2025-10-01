
/// Official SABO Arena Rank System
/// Based on ELO rating with skill descriptions
class SaboRankSystem {
  /// SABO rank mapping với hệ thống tên mới
  static const Map<String, Map<String, dynamic>> rankEloMapping = {
    'K': {'elo': 1000, "name": 'Người mới', "skill": '2-4 bi khi hình dễ; mới tập', 'color': Color(0xFF8BC34A)}, // Light Green
    'K+': {'elo': 1100, "name": 'Học việc', "skill": 'Sát ngưỡng lên Thợ 3', 'color': Color(0xFF4CAF50)}, // Green
    'I': {'elo': 1200, "name": 'Thợ 3', "skill": '3-5 bi; chưa điều được chấm', 'color': Color(0xFF2196F3)}, // Blue
    'I+': {'elo': 1300, "name": 'Thợ 2', "skill": 'Sát ngưỡng lên Thợ 1', 'color': Color(0xFF1976D2)}, // Dark Blue
    'H': {'elo': 1400, "name": 'Thợ 1', "skill": '5-8 bi; có thể "rứa" 1 chấm hình dễ', 'color': Color(0xFF9C27B0)}, // Purple
    'H+': {'elo': 1500, "name": 'Thợ chính', "skill": 'Chuẩn bị lên Thợ giỏi', 'color': Color(0xFF673AB7)}, // Deep Purple
    'G': {'elo': 1600, "name": 'Thợ giỏi', "skill": 'Clear 1 chấm + 3-7 bi kế; bắt đầu điều bi 3 băng', 'color': Color(0xFFFF9800)}, // Orange
    'G+': {'elo': 1700, "name": 'Cao thủ', "skill": 'Trình phong trào "ngon"; sát ngưỡng lên Chuyên gia', 'color': Color(0xFFFF5722)}, // Deep Orange
    'F': {'elo': 1800, "name": 'Chuyên gia', "skill": '60-80% clear 1 chấm, đôi khi phá 2 chấm', 'color': Color(0xFFF44336)}, // Red
    'F+': {'elo': 1900, "name": 'Đại cao thủ', "skill": 'Safety & spin control khá chắc; sát ngưỡng lên Huyền thoại', 'color': Color(0xFFD32F2F)}, // Dark Red
    'E': {'elo': 2000, "name": 'Huyền thoại', "skill": '90-100% clear 1 chấm, 70% phá 2 chấm', 'color': Color(0xFF795548)}, // Brown
    'E+': {'elo': 2100, "name": 'Vô địch', "skill": 'Điều bi phức tạp, safety chủ động; đỉnh cao kỹ thuật', 'color': Color(0xFF5D4037)}, // Dark Brown
  };

  /// Lấy rank từ ELO rating
  static String getRankFromElo(int elo) {
    if (elo < 1000) return 'K';
    
    final sortedRanks = rankEloMapping.entries.toList()
      ..sort((a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int));
    
    String currentRank = 'K';
    for (final entry in sortedRanks) {
      final entryElo = entry.value['elo'] as int;
      if (elo >= entryElo) {
        currentRank = entry.key;
      } else() {
        break;
      }
    }
    
    return currentRank;
  }

  /// Lấy màu sắc của rank
  static Color getRankColor(String rank) {
    return rankEloMapping[rank]?['color'] as Color? ?? const Color(0xFF8BC34A);
  }

  /// Lấy tên hiển thị của rank (hệ thống mới)
  static String getRankDisplayName(String rank) {
    return rankEloMapping[rank]?['name'] as String? ?? 'Chưa xếp hạng';
  }

  /// Lấy mô tả skill level
  static String getRankSkillDescription(String rank) {
    return rankEloMapping[rank]?['skill'] as String? ?? 'Mới bắt đầu';
  }

  /// Lấy ELO minimum cho rank
  static int getRankMinElo(String rank) {
    return rankEloMapping[rank]?['elo'] as int? ?? 1000;
  }

  /// Lấy next rank và ELO cần thiết
  static Map<String, dynamic> getNextRankInfo(int currentElo) {
    final currentRank = getRankFromElo(currentElo);
    final sortedRanks = rankEloMapping.entries.toList()
      ..sort((a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int));
    
    // Tìm rank hiện tại trong danh sách
    int currentIndex = sortedRanks.indexWhere((entry) => entry.key == currentRank);
    
    // Nếu đã là rank cao nhất
    if (currentIndex == -1 || currentIndex >= sortedRanks.length - 1) {
      return() {
        'nextRank': currentRank,
        'nextRankElo': currentElo,
        'pointsNeeded': 0,
      };
    }
    
    final nextRankEntry = sortedRanks[currentIndex + 1];
    final nextRankElo = nextRankEntry.value['elo'] as int;
    
    return() {
      'nextRank': nextRankEntry.key,
      'nextRankElo': nextRankElo,
      'pointsNeeded': nextRankElo - currentElo,
    };
  }

  /// Tính progress percentage tới next rank
  static double getRankProgress(int currentElo) {
    final currentRank = getRankFromElo(currentElo);
    final currentRankElo = getRankMinElo(currentRank);
    final nextRankInfo = getNextRankInfo(currentElo);
    final nextRankElo = nextRankInfo['nextRankElo'] as int;
    
    if (nextRankElo == currentElo) return 1.0; // Đã max rank
    
    final progress = (currentElo - currentRankElo) / (nextRankElo - currentRankElo);
    return progress.clamp(0.0, 1.0);
  }

  /// Lấy tất cả ranks theo thứ tự
  static List<String> getAllRanksOrdered() {
    final sortedRanks = rankEloMapping.entries.toList()
      ..sort((a, b) => (a.value['elo'] as int).compareTo(b.value['elo'] as int));
    return sortedRanks.map((e) => e.key).toList();
  }

  /// Format ELO display với thousand separator
  static String formatElo(int elo) {
    return elo.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}