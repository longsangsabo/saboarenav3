/// 🎱 SABO ARENA - Ranking System Constants
/// Vietnamese billiards ranking system with verification requirements

class RankingConstants {
  // Rank codes in progression order
  static const String UNRANKED = 'UNRANKED';
  static const String RANK_K = 'K';
  static const String RANK_K_PLUS = 'K+';
  static const String RANK_I = 'I';
  static const String RANK_I_PLUS = 'I+';
  static const String RANK_H = 'H';
  static const String RANK_H_PLUS = 'H+';
  static const String RANK_G = 'G';
  static const String RANK_G_PLUS = 'G+';
  static const String RANK_F = 'F';
  static const String RANK_F_PLUS = 'F+';
  static const String RANK_E = 'E';
  static const String RANK_E_PLUS = 'E+';

  // Rank progression order (from lowest to highest)
  static const List<String> RANK_ORDER = [
    RANK_K,
    RANK_K_PLUS,
    RANK_I,
    RANK_I_PLUS,
    RANK_H,
    RANK_H_PLUS,
    RANK_G,
    RANK_G_PLUS,
    RANK_F,
    RANK_F_PLUS,
    RANK_E,
    RANK_E_PLUS,
  ];

  // ELO ranges for each rank
  static const Map<String, Map<String, int>> RANK_ELO_RANGES = {
    RANK_K: {'min': 1000, 'max': 1099},
    RANK_K_PLUS: {'min': 1100, 'max': 1199},
    RANK_I: {'min': 1200, 'max': 1299},
    RANK_I_PLUS: {'min': 1300, 'max': 1399},
    RANK_H: {'min': 1400, 'max': 1499},
    RANK_H_PLUS: {'min': 1500, 'max': 1599},
    RANK_G: {'min': 1600, 'max': 1699},
    RANK_G_PLUS: {'min': 1700, 'max': 1799},
    RANK_F: {'min': 1800, 'max': 1899},
    RANK_F_PLUS: {'min': 1900, 'max': 1999},
    RANK_E: {'min': 2000, 'max': 2099},
    RANK_E_PLUS: {'min': 2100, 'max': 9999},
  };

  // Icons for each rank
  static const Map<String, IconData> RANK_ICONS = {
    RANK_K: Icons.star_border,
    RANK_K_PLUS: Icons.star_half,
    RANK_I: Icons.star,
    RANK_I_PLUS: Icons.stars,
    RANK_H: Icons.military_tech_outlined,
    RANK_H_PLUS: Icons.military_tech,
    RANK_G: Icons.shield_outlined,
    RANK_G_PLUS: Icons.shield,
    RANK_F: Icons.local_fire_department_outlined,
    RANK_F_PLUS: Icons.local_fire_department,
    RANK_E: Icons.verified_user_outlined,
    RANK_E_PLUS: Icons.verified_user,
    UNRANKED: Icons.help_outline,
  };

  // Vietnamese rank names and descriptions - NEW NAMING SYSTEM
  static const Map<String, Map<String, String>> RANK_DETAILS = {
    RANK_K: {
      "name": 'K',
      "name_en": 'Beginner',
      "description": '2-4 bi khi hình dễ; mới tập',
      "description_en": '2-4 balls on easy shots; just starting',
      "color": '#8B4513',
    },
    RANK_K_PLUS: {
      "name": 'K+',
      "name_en": 'Apprentice',
      "description": 'Sắt ngưỡng lên Thợ 3',
      "description_en": 'About to reach Thợ 3 rank',
      "color": '#A0522D',
    },
    RANK_I: {
      "name": 'I',
      "name_en": 'Worker Level 3',
      "description": '3-5 bi; chưa điều được chấm',
      "description_en": '3-5 balls; cannot control dots yet',
      "color": '#CD853F',
    },
    RANK_I_PLUS: {
      "name": 'I+',
      "name_en": 'Worker Level 2',
      "description": 'Sắt ngưỡng lên Thợ 1',
      "description_en": 'About to reach Thợ 1 rank',
      "color": '#DEB887',
    },
    RANK_H: {
      "name": 'H',
      "name_en": 'Worker Level 1',
      "description": '5-8 bi; có thể "rứa" 1 chấm hình dễ',
      "description_en": '5-8 balls; can clear 1 dot on easy layouts',
      "color": '#C0C0C0',
    },
    RANK_H_PLUS: {
      "name": 'H+',
      "name_en": 'Chief Worker',
      "description": 'Chuẩn bị lên Thợ giỏi',
      "description_en": 'Preparing for skilled worker rank',
      "color": '#B0B0B0',
    },
    RANK_G: {
      "name": 'G',
      "name_en": 'Skilled Worker',
      "description": 'Clear 1 chấm + 3-7 bi kế; bắt đầu điều bi 3 băng',
      "description_en": 'Clear 1 dot + 3-7 balls; starting 3-cushion control',
      "color": '#FFD700',
    },
    RANK_G_PLUS: {
      "name": 'G+',
      "name_en": 'Master',
      "description": 'Trình phong trào "ngon"; sắt ngưỡng lên Chuyên gia',
      "description_en": 'Good recreational level; about to reach Expert',
      "color": '#FFA500',
    },
    RANK_F: {
      "name": 'F',
      "name_en": 'Expert',
      "description": '60-80% clear 1 chấm, đôi khi phá 2 chấm',
      "description_en": '60-80% clear 1 dot, sometimes break 2 dots',
      "color": '#FF6347',
    },
    RANK_F_PLUS: {
      "name": 'F+',
      "name_en": 'Grand Master',
      "description":
          'Safety & spin control khá chắc; sắt ngưỡng lên Huyền thoại',
      "description_en": 'Good safety & spin control; about to reach Legend',
      "color": '#FF4500',
    },
    RANK_E: {
      "name": 'E',
      "name_en": 'Legend',
      "description": '90-100% clear 1 chấm, 70% phá 2 chấm',
      "description_en": '90-100% clear 1 dot, 70% break 2 dots',
      "color": '#DC143C',
    },
    RANK_E_PLUS: {
      "name": 'E+',
      "name_en": 'Champion',
      "description": 'Điều bi phức tạp, safety chủ động; đỉnh cao kỹ thuật',
      "description_en":
          'Complex ball control, proactive safety; peak technical level',
      "color": '#B22222',
    },
  };

  // Verification requirements
  static const int MIN_VERIFICATION_MATCHES = 3;
  static const double MIN_VERIFICATION_WIN_RATE = 0.40;
  static const int AUTO_VERIFY_MATCH_THRESHOLD = 10;
  static const int RANK_PROTECTION_DAYS = 7;
  static const int MIN_GAMES_BEFORE_DEMOTION = 10;

  // Rank progression helpers
  static String? getNextRank(String currentRank) {
    final currentIndex = RANK_ORDER.indexOf(currentRank);
    if (currentIndex == -1 || currentIndex == RANK_ORDER.length - 1) {
      return null;
    }
    return RANK_ORDER[currentIndex + 1];
  }

  static String? getPreviousRank(String currentRank) {
    final currentIndex = RANK_ORDER.indexOf(currentRank);
    if (currentIndex <= 0) {
      return null;
    }
    return RANK_ORDER[currentIndex - 1];
  }

  static bool isRankUp(String fromRank, String toRank) {
    final fromIndex = RANK_ORDER.indexOf(fromRank);
    final toIndex = RANK_ORDER.indexOf(toRank);
    return toIndex > fromIndex;
  }

  static bool isRankDown(String fromRank, String toRank) {
    final fromIndex = RANK_ORDER.indexOf(fromRank);
    final toIndex = RANK_ORDER.indexOf(toRank);
    return toIndex < fromIndex;
  }

  static String getRankFromElo(int elo) {
    if (elo <= 0) {
      return UNRANKED;
    }
    if (elo > 0 && elo < 1000) {
      return RANK_K;
    }
    for (final entry in RANK_ELO_RANGES.entries) {
      final min = entry.value['min']!;
      final max = entry.value['max']!;
      if (elo >= min && elo <= max) {
        return entry.key;
      }
    }
    // If ELO is above all defined ranges, return highest rank
    return RANK_E_PLUS;
  }

  static int getRankIndex(String rank) {
    return RANK_ORDER.indexOf(rank);
  }

  static int getRankDifference(String rank1, String rank2) {
    final index1 = getRankIndex(rank1);
    final index2 = getRankIndex(rank2);
    return (index2 - index1).abs();
  }

  // Check if rank requires verification
  static bool requiresVerification(String rank) {
    return rank != UNRANKED;
  }

  // Get rank display info
  static Map<String, String> getRankDisplayInfo(String rank) {
    return RANK_DETAILS[rank] ??
        {
          "name": 'Unknown',
          "name_en": 'Unknown',
          "description": 'Unknown rank',
          "description_en": 'Unknown rank',
          "color": '#999999',
        };
  }
}
