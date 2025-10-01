// 🏆 SABO ARENA - Tournament Constants
// Defines tournament formats, status, types, and other constants
// Based on CORE_LOGIC_ARCHITECTURE.md hybrid approach

/// Tournament Formats với định nghĩa đầy đủ
class TournamentFormats {
  /// Loại trực tiếp (Single Elimination)
  static const String singleElimination = 'single_elimination';

  /// Loại kép truyền thống (Traditional Double Elimination)
  static const String doubleElimination = 'double_elimination';

  /// Loại kép Sabo DE16 (Sabo Double Elimination 16 players)
  static const String saboDoubleElimination = 'sabo_double_elimination';
  static const String saboDE16 = 'sabo_de16';

  /// Loại kép Sabo DE32 (Sabo Double Elimination 32 players)
  static const String saboDoubleElimination32 = 'sabo_double_elimination_32';

  /// Vòng tròn (Round Robin)
  static const String roundRobin = 'round_robin';

  /// Swiss System
  static const String swiss = 'swiss';

  /// Parallel Groups + Finals
  static const String parallelGroups = 'parallel_groups';

  /// Winner Takes All
  static const String winnerTakesAll = 'winner_takes_all';

  /// Danh sách tất cả các format hỗ trợ
  static const List<String> allFormats = [
    singleElimination,
    doubleElimination,
    saboDoubleElimination,
    saboDoubleElimination32,
    roundRobin,
    swiss,
    parallelGroups,
    winnerTakesAll,
  ];

  /// Chi tiết format bao gồm tên hiển thị và mô tả
  static final Map<String, Map<String, dynamic>> formatDetails = {
    singleElimination: {
      "name": 'Single Elimination',
      "nameVi": 'Loại trực tiếp',
      "description": 'Players are eliminated after losing one match',
      "descriptionVi": 'Người chơi bị loại sau khi thua một trận',
      'minPlayers': 4,
      'maxPlayers': 64,
      "eliminationType": 'single',
      "bracketType": 'standard',
      "roundsFormula": 'log2(players)',
      'icon': Icons.trending_down,
      'color': Colors.red,
    },
    doubleElimination: {
      "name": 'Traditional Double Elimination',
      "nameVi": 'Loại kép truyền thống',
      "description": 'Classic double elimination with Winners Final',
      "descriptionVi": 'Loại kép truyền thống với chung kết Winners',
      'minPlayers': 4,
      'maxPlayers': 32,
      "eliminationType": 'double',
      "bracketType": 'double_bracket',
      "roundsFormula": 'log2(players)+log2(players/2)',
      'icon': Icons.double_arrow,
      'color': Colors.orange,
    },
    saboDoubleElimination: {
      "name": 'Sabo Double Elimination (DE16)',
      "nameVi": 'Loại kép Sabo (DE16)',
      "description": 'SABO Arena DE16 with 2 Loser Branches + SABO Finals',
      "descriptionVi": 'DE16 Sabo Arena với 2 nhánh thua + chung kết Sabo',
      'minPlayers': 16,
      'maxPlayers': 16,
      "eliminationType": 'sabo_double',
      "bracketType": 'sabo_de16',
      "roundsFormula": '27', // Fixed 27 matches for DE16
      'icon': Icons.star,
      'color': Colors.deepPurple,
      'totalMatches': 27,
      'winnersMatches': 14, // 8+4+2
      'losersAMatches': 7, // 4+2+1
      'losersBMatches': 3, // 2+1
      'finalsMatches': 3, // 2 semifinals + 1 final
    },
    saboDoubleElimination32: {
      "name": 'Sabo Double Elimination (DE32)',
      "nameVi": 'Loại kép Sabo (DE32)',
      "description":
          'SABO Arena DE32 with Two-Group System + Cross-Bracket Finals',
      "descriptionVi": 'DE32 Sabo Arena với hệ thống 2 nhóm + chung kết chéo',
      'minPlayers': 32,
      'maxPlayers': 32,
      "eliminationType": 'sabo_double_32',
      "bracketType": 'sabo_de32',
      "roundsFormula": '55', // Fixed 55 matches for DE32
      'icon': Icons.workspaces,
      'color': Colors.indigo,
      'totalMatches': 55,
      'groupAMatches': 26, // Group A: 14+7+3+2
      'groupBMatches': 26, // Group B: 14+7+3+2
      'crossBracketMatches': 3, // 2 semifinals + 1 final
      'hasGroups': true,
      'groupCount': 2,
      'playersPerGroup': 16,
      'qualifiersPerGroup': 2,
    },
    'sabo_de16': {
      'name': 'Sabo Double Elimination (DE16)',
      'nameVi': 'Loại kép Sabo (DE16)',
      'description': 'SABO Arena DE16 with 2 Loser Branches + SABO Finals',
      'descriptionVi': 'DE16 Sabo Arena với 2 nhánh thua + chung kết Sabo',
      'minPlayers': 16,
      'maxPlayers': 16,
      'eliminationType': 'sabo_double',
      'bracketType': 'sabo_de16',
      'roundsFormula': '27', // Fixed 27 matches for DE16
      'icon': Icons.star,
      'color': Colors.deepPurple,
      'totalMatches': 27,
      'winnersMatches': 14, // 8+4+2
      'losersAMatches': 7, // 4+2+1
      'losersBMatches': 3, // 2+1
      'finalsMatches': 3, // 2 semifinals + 1 final
    },
    roundRobin: {
      "name": 'Round Robin',
      "nameVi": 'Vòng tròn',
      "description": 'Every player plays against every other player',
      "descriptionVi": 'Mỗi người chơi đấu với tất cả các đối thủ khác',
      'minPlayers': 3,
      'maxPlayers': 12,
      "eliminationType": 'none',
      "bracketType": 'round_robin',
      "roundsFormula": '(players-1)',
      'icon': Icons.refresh,
      'color': Colors.blue,
    },
    swiss: {
      "name": 'Swiss System',
      "nameVi": 'Hệ thống Swiss',
      "description": 'Players paired based on performance, no elimination',
      "descriptionVi": 'Ghép cặp dựa trên thành tích, không loại trực tiếp',
      'minPlayers': 6,
      'maxPlayers': 128,
      "eliminationType": 'none',
      "bracketType": 'swiss_pairing',
      "roundsFormula": 'log2(players)+2',
      'icon': Icons.shuffle,
      'color': Colors.green,
    },
    parallelGroups: {
      "name": 'Parallel Groups',
      "nameVi": 'Bảng đấu song song',
      "description": 'Multiple groups with top players advancing to finals',
      "descriptionVi":
          'Nhiều bảng đấu với những người đứng đầu vào vòng chung kết',
      'minPlayers': 8,
      'maxPlayers': 64,
      "eliminationType": 'group_stage',
      "bracketType": 'parallel_groups',
      "roundsFormula": 'log2(players/2)+2',
      'icon': Icons.view_module,
      'color': Colors.purple,
    },
    winnerTakesAll: {
      "name": 'Winner Takes All',
      "nameVi": 'Người thắng nhận tất cả',
      "description": 'Single winner tournament with all prizes',
      "descriptionVi": 'Giải đấu một người thắng nhận tất cả giải thưởng',
      'minPlayers': 4,
      'maxPlayers': 32,
      "eliminationType": 'single',
      "bracketType": 'winner_only',
      "roundsFormula": 'log2(players)',
      'icon': Icons.emoji_events,
      'color': Colors.amber,
    },
  };
}

/// Tournament Status Constants
class TournamentStatus {
  /// Chưa mở đăng ký
  static const String draft = 'draft';

  /// Đang mở đăng ký
  static const String registrationOpen = 'registration_open';

  /// Đã đóng đăng ký, chờ bắt đầu
  static const String upcoming = 'upcoming';

  /// Đang diễn ra
  static const String live = 'live';

  /// Tạm dừng
  static const String paused = 'paused';

  /// Đã hoàn thành
  static const String completed = 'completed';

  /// Đã hủy
  static const String cancelled = 'cancelled';

  static const List<String> allStatuses = [
    draft,
    registrationOpen,
    upcoming,
    live,
    paused,
    completed,
    cancelled,
  ];

  static final Map<String, Map<String, dynamic>> statusDetails = {
    draft: {
      "name": 'Draft',
      "nameVi": 'Nháp',
      'color': Colors.grey,
      'icon': Icons.edit,
      "description": 'Tournament is being prepared',
      "descriptionVi": 'Giải đấu đang được chuẩn bị',
    },
    registrationOpen: {
      "name": 'Registration Open',
      "nameVi": 'Đang mở ĐK',
      'color': Colors.green,
      'icon': Icons.how_to_reg,
      "description": 'Players can register for the tournament',
      "descriptionVi": 'Người chơi có thể đăng ký tham gia',
    },
    upcoming: {
      "name": 'Upcoming',
      "nameVi": 'Sắp diễn ra',
      'color': Colors.blue,
      'icon': Icons.schedule,
      "description": 'Tournament will start soon',
      "descriptionVi": 'Giải đấu sẽ bắt đầu sớm',
    },
    live: {
      "name": 'Live',
      "nameVi": 'Đang diễn ra',
      'color': Colors.red,
      'icon': Icons.live_tv,
      "description": 'Tournament is currently running',
      "descriptionVi": 'Giải đấu đang diễn ra',
    },
    paused: {
      "name": 'Paused',
      "nameVi": 'Tạm dừng',
      'color': Colors.orange,
      'icon': Icons.pause,
      "description": 'Tournament is temporarily paused',
      "descriptionVi": 'Giải đấu tạm thời dừng lại',
    },
    completed: {
      "name": 'Completed',
      "nameVi": 'Đã hoàn thành',
      'color': Colors.purple,
      'icon': Icons.emoji_events,
      "description": 'Tournament has finished',
      "descriptionVi": 'Giải đấu đã kết thúc',
    },
    cancelled: {
      "name": 'Cancelled',
      "nameVi": 'Đã hủy',
      'color': Colors.red,
      'icon': Icons.cancel,
      "description": 'Tournament was cancelled',
      "descriptionVi": 'Giải đấu đã bị hủy',
    },
  };
}

/// Game Types - Các loại hình bi-a
class GameTypes {
  static const String eightBall = '8-ball';
  static const String nineBall = '9-ball';
  static const String tenBall = '10-ball';
  static const String straightPool = 'straight-pool';
  static const String onePocket = 'one-pocket';
  static const String rotation = 'rotation';
  static const String carom = 'carom';

  static const List<String> allGameTypes = [
    eightBall,
    nineBall,
    tenBall,
    straightPool,
    onePocket,
    rotation,
    carom,
  ];

  static final Map<String, Map<String, dynamic>> gameTypeDetails = {
    eightBall: {
      "name": '8-Ball',
      "nameVi": 'Bi lỗ 8',
      "description": 'Classic pool game with solid and striped balls',
      "descriptionVi": 'Trò chơi bi-a cổ điển với bi đặc và bi sọc',
      'ballCount': 15,
      'icon': Icons.sports_baseball,
      'color': Colors.black,
      'popularity': 10,
    },
    nineBall: {
      "name": '9-Ball',
      "nameVi": 'Bi lỗ 9',
      "description": 'Fast-paced game with balls 1-9',
      "descriptionVi": 'Trò chơi nhanh với bi từ 1-9',
      'ballCount': 9,
      'icon': Icons.filter_9,
      'color': Colors.yellow,
      'popularity': 9,
    },
    tenBall: {
      "name": '10-Ball',
      "nameVi": 'Bi lỗ 10',
      "description": 'Professional game with strict call-shot rules',
      "descriptionVi": 'Trò chơi chuyên nghiệp với luật gọi lỗ nghiêm ngặt',
      'ballCount': 10,
      'icon': Icons.sports_baseball,
      'color': Colors.blue,
      'popularity': 7,
    },
    straightPool: {
      "name": 'Straight Pool',
      "nameVi": 'Bi thẳng',
      "description": 'First to reach target score wins',
      "descriptionVi": 'Người đầu tiên đạt điểm mục tiêu thắng',
      'ballCount': 15,
      'icon': Icons.straighten,
      'color': Colors.green,
      'popularity': 5,
    },
    onePocket: {
      "name": 'One Pocket',
      "nameVi": 'Một lỗ',
      "description": 'Strategic game with designated pocket',
      "descriptionVi": 'Trò chơi chiến thuật với lỗ được chỉ định',
      'ballCount': 15,
      'icon': Icons.lens,
      'color': Colors.indigo,
      'popularity': 4,
    },
    rotation: {
      "name": 'Rotation',
      "nameVi": 'Xoay vòng',
      "description": 'Must hit lowest numbered ball first',
      "descriptionVi": 'Phải đánh bi có số thấp nhất trước',
      'ballCount': 15,
      'icon': Icons.rotate_right,
      'color': Colors.teal,
      'popularity': 3,
    },
    carom: {
      "name": 'Carom',
      "nameVi": 'Carom (Libre)',
      "description": 'Three-ball billiards without pockets',
      "descriptionVi": 'Bi-a ba bi không có lỗ',
      'ballCount': 3,
      'icon': Icons.circle_outlined,
      'color': Colors.brown,
      'popularity': 6,
    },
  };
}

/// Prize Distribution Templates
class PrizeDistribution {
  /// Standard tournament distribution
  static const Map<String, List<double>> standardDistribution = {
    '4': [0.60, 0.40], // Top 2 get prizes
    '8': [0.50, 0.30, 0.20], // Top 3 get prizes
    '16': [0.40, 0.25, 0.15, 0.10, 0.05, 0.05], // Top 6 get prizes
    '32': [0.35, 0.20, 0.15, 0.10, 0.08, 0.06, 0.03, 0.03], // Top 8 get prizes
    '64': [
      0.30,
      0.18,
      0.12,
      0.08,
      0.06,
      0.05,
      0.04,
      0.04,
      0.03,
      0.03,
      0.02,
      0.02,
      0.02,
      0.01
    ], // Top 14 get prizes
  };

  /// Winner takes all distribution
  static const Map<String, List<double>> winnerTakesAllDistribution = {
    '4': [1.00],
    '8': [1.00],
    '16': [1.00],
    '32': [1.00],
    '64': [1.00],
  };

  /// Top heavy distribution (favors winner)
  static const Map<String, List<double>> topHeavyDistribution = {
    '4': [0.80, 0.20],
    '8': [0.70, 0.20, 0.10],
    '16': [0.60, 0.20, 0.10, 0.05, 0.05],
    '32': [0.50, 0.20, 0.15, 0.08, 0.04, 0.03],
    '64': [0.45, 0.20, 0.12, 0.08, 0.05, 0.04, 0.03, 0.03],
  };

  /// Flat distribution (more equal)
  static const Map<String, List<double>> flatDistribution = {
    '4': [0.55, 0.45],
    '8': [0.35, 0.25, 0.20, 0.20],
    '16': [0.25, 0.20, 0.15, 0.15, 0.10, 0.08, 0.04, 0.03],
    '32': [
      0.20,
      0.15,
      0.12,
      0.10,
      0.08,
      0.07,
      0.06,
      0.05,
      0.04,
      0.04,
      0.03,
      0.03,
      0.02,
      0.01
    ],
  };

  static const Map<String, Map<String, List<double>>> allDistributions = {
    'standard': standardDistribution,
    'winner_takes_all': winnerTakesAllDistribution,
    'top_heavy': topHeavyDistribution,
    'flat': flatDistribution,
  };

  static const Map<String, Map<String, String>> distributionNames = {
    'standard': {
      "name": 'Standard',
      "nameVi": 'Tiêu chuẩn',
      "description": 'Balanced prize distribution',
      "descriptionVi": 'Phân chia giải thưởng cân bằng',
    },
    'winner_takes_all': {
      "name": 'Winner Takes All',
      "nameVi": 'Người thắng nhận tất cả',
      "description": 'All prizes go to winner',
      "descriptionVi": 'Tất cả giải thưởng cho người thắng',
    },
    'top_heavy': {
      "name": 'Top Heavy',
      "nameVi": 'Ưu tiên người thắng',
      "description": 'Higher percentage to winner',
      "descriptionVi": 'Tỷ lệ cao hơn cho người thắng',
    },
    'flat': {
      "name": 'Flat Distribution',
      "nameVi": 'Phân chia đều',
      "description": 'More equal prize distribution',
      "descriptionVi": 'Phân chia giải thưởng đều hơn',
    },
  };
}

/// Prize Types
class PrizeTypes {
  static const String cash = 'CASH';
  static const String spaPoints = 'SPA_POINTS';
  static const String trophy = 'TROPHY';
  static const String medal = 'MEDAL';
  static const String flag = 'FLAG';
  static const String certificate = 'CERTIFICATE';

  static const List<String> allPrizeTypes = [
    cash,
    spaPoints,
    trophy,
    medal,
    flag,
    certificate,
  ];

  static final Map<String, Map<String, dynamic>> prizeTypeDetails = {
    cash: {
      "name": 'Cash',
      "nameVi": 'Tiền mặt',
      'icon': Icons.attach_money,
      'color': Colors.green,
      'canCombine': true,
    },
    spaPoints: {
      "name": 'SPA Points',
      "nameVi": 'Điểm SPA',
      'icon': Icons.stars,
      'color': Colors.amber,
      'canCombine': true,
    },
    trophy: {
      "name": 'Trophy',
      "nameVi": 'Cúp',
      'icon': Icons.emoji_events,
      'color': Colors.orange,
      'canCombine': false,
    },
    medal: {
      "name": 'Medal',
      "nameVi": 'Huy chương',
      'icon': Icons.military_tech,
      'color': Colors.brown,
      'canCombine': false,
    },
    flag: {
      "name": 'Flag',
      "nameVi": 'Cờ',
      'icon': Icons.flag,
      'color': Colors.red,
      'canCombine': false,
    },
    certificate: {
      "name": 'Certificate',
      "nameVi": 'Giấy chứng nhận',
      'icon': Icons.card_membership,
      'color': Colors.blue,
      'canCombine': false,
    },
  };
}

/// Seeding Methods
class SeedingMethods {
  static const String random = 'random';
  static const String eloRating = 'elo_rating';
  static const String clubRanking = 'club_ranking';
  static const String previousTournaments = 'previous_tournaments';
  static const String hybrid = 'hybrid'; // Combination of methods

  static const List<String> allSeedingMethods = [
    random,
    eloRating,
    clubRanking,
    previousTournaments,
    hybrid,
  ];

  static const Map<String, Map<String, String>> seedingMethodDetails = {
    random: {
      "name": 'Random Seeding',
      "nameVi": 'Xếp hạng ngẫu nhiên',
      "description": 'Completely random player placement',
      "descriptionVi": 'Xếp người chơi hoàn toàn ngẫu nhiên',
    },
    eloRating: {
      "name": 'ELO Rating',
      "nameVi": 'Điểm ELO',
      "description": 'Based on current ELO rating',
      "descriptionVi": 'Dựa trên điểm ELO hiện tại',
    },
    clubRanking: {
      "name": 'Club Ranking',
      "nameVi": 'Xếp hạng CLB',
      "description": 'Based on club internal ranking',
      "descriptionVi": 'Dựa trên xếp hạng nội bộ CLB',
    },
    previousTournaments: {
      "name": 'Tournament History',
      "nameVi": 'Lịch sử giải đấu',
      "description": 'Based on previous tournament performance',
      "descriptionVi": 'Dựa trên thành tích giải đấu trước',
    },
    hybrid: {
      "name": 'Hybrid Method',
      "nameVi": 'Phương pháp kết hợp',
      "description": 'Combination of multiple seeding criteria',
      "descriptionVi": 'Kết hợp nhiều tiêu chí xếp hạng',
    },
  };
}

/// Helper functions
class TournamentHelper {
  /// Tính số vòng đấu dựa trên format và số người chơi
  static int calculateRounds(String format, int playerCount) {
    final details = TournamentFormats.formatDetails[format];
    if (details == null) return 0;

    final formula = details['roundsFormula'] as String;

    switch (formula) {
      case 'log2(players)':
        return (log2(playerCount)).ceil();
      case 'log2(players)+log2(players/2)':
        return (log2(playerCount) + log2(playerCount / 2)).ceil();
      case '(players-1)':
        return playerCount - 1;
      case 'log2(players)+2':
        return (log2(playerCount) + 2).ceil();
      case 'log2(players/2)+2':
        return (log2(playerCount / 2) + 2).ceil();
      default:
        return (log2(playerCount)).ceil();
    }
  }

  /// Kiểm tra số người chơi có hợp lệ cho format không
  static bool isValidPlayerCount(String format, int playerCount) {
    final details = TournamentFormats.formatDetails[format];
    if (details == null) return false;

    final minPlayers = details['minPlayers'] as int;
    final maxPlayers = details['maxPlayers'] as int;

    return playerCount >= minPlayers && playerCount <= maxPlayers;
  }

  /// Lấy prize distribution cho số người chơi
  static List<double> getPrizeDistribution(
      String distributionType, int playerCount) {
    final distributions = PrizeDistribution.allDistributions[distributionType];
    if (distributions == null) return [];

    // Tìm distribution phù hợp nhất
    final playerCountStr =
        _getNearestPlayerCountKey(playerCount, distributions.keys.toList());
    return distributions[playerCountStr] ?? [];
  }

  /// Tìm key gần nhất cho số người chơi
  static String _getNearestPlayerCountKey(
      int playerCount, List<String> availableKeys) {
    final numericKeys = availableKeys.map(int.parse).toList()..sort();

    for (int key in numericKeys) {
      if (playerCount <= key) {
        return key.toString();
      }
    }

    return numericKeys.last.toString();
  }

  /// Helper function để tính log2
  static double log2(num x) => log(x) / log(2);
}
