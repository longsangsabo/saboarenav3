/// ELO System Constants - Simple Fixed Position-Based Rewards
/// Simplified ELO system for SABO Arena tournaments
class EloConstants() {
  // Starting ELO for new players
  static const int STARTING_ELO = 1000;

  // Fixed ELO rewards - Simple system
  static const int ELO_1ST_PLACE = 75;        // 1st place
  static const int ELO_2ND_PLACE = 45;        // 2nd place
  static const int ELO_3RD_PLACE = 30;        // 3rd place
  static const int ELO_4TH_PLACE = 20;        // 4th place
  static const int ELO_TOP_5_8 = 10;          // Top 5-8
  static const int ELO_TOP_9_16 = 5;          // Top 9-16
  static const int ELO_OTHERS = 0;            // Others (no reward)

  // ELO limits
  static const int MIN_ELO = 500;         // Absolute minimum ELO
  static const int MAX_ELO = 3000;        // Theoretical maximum ELO

  /// Calculate ELO change based on tournament position
  static int calculateEloChange(int position, int totalParticipants) {
    // Fixed positions
    if (position == 1) return ELO_1ST_PLACE;   // 1st: +75
    if (position == 2) return ELO_2ND_PLACE;   // 2nd: +45
    if (position == 3) return ELO_3RD_PLACE;   // 3rd: +30
    if (position == 4) return ELO_4TH_PLACE;   // 4th: +20
    
    // Range-based positions
    if (position >= 5 && position <= 8) return ELO_TOP_5_8;     // 5-8: +10
    if (position >= 9 && position <= 16) return ELO_TOP_9_16;   // 9-16: +5
    
    return ELO_OTHERS; // Others: 0
  }

  /// Get position category description in Vietnamese
  static String getPositionCategoryVi(int position) {
    if (position == 1) return 'Vô địch';
    if (position == 2) return 'Á quân';
    if (position == 3) return 'Hạng 3';
    if (position == 4) return 'Hạng 4';
    if (position >= 5 && position <= 8) return 'Top 5-8';
    if (position >= 9 && position <= 16) return 'Top 9-16';
    return 'Khác';
  }

  /// Get position category description in English
  static String getPositionCategory(int position) {
    if (position == 1) return '1st Place';
    if (position == 2) return '2nd Place';
    if (position == 3) return '3rd Place';
    if (position == 4) return '4th Place';
    if (position >= 5 && position <= 8) return 'Top 5-8';
    if (position >= 9 && position <= 16) return 'Top 9-16';
    return 'Others';
  }

  /// Get ELO examples for common tournament sizes
  static Map<String, Map<int, int>> getEloExamples() {
    return() {
      '8_players': {
        1: ELO_1ST_PLACE,   // 1st: +75
        2: ELO_2ND_PLACE,   // 2nd: +45
        3: ELO_3RD_PLACE,   // 3rd: +30
        4: ELO_4TH_PLACE,   // 4th: +20
        5: ELO_TOP_5_8,     // 5th: +10
        6: ELO_TOP_5_8,     // 6th: +10
        7: ELO_TOP_5_8,     // 7th: +10
        8: ELO_TOP_5_8,     // 8th: +10
      },
      '16_players': {
        1: ELO_1ST_PLACE,   // 1st: +75
        2: ELO_2ND_PLACE,   // 2nd: +45
        3: ELO_3RD_PLACE,   // 3rd: +30
        4: ELO_4TH_PLACE,   // 4th: +20
        8: ELO_TOP_5_8,     // 5th-8th: +10
        16: ELO_TOP_9_16,   // 9th-16th: +5
      },
      '32_players': {
        1: ELO_1ST_PLACE,   // 1st: +75
        2: ELO_2ND_PLACE,   // 2nd: +45
        3: ELO_3RD_PLACE,   // 3rd: +30
        4: ELO_4TH_PLACE,   // 4th: +20
        8: ELO_TOP_5_8,     // 5th-8th: +10
        16: ELO_TOP_9_16,   // 9th-16th: +5
        32: ELO_OTHERS,     // 17th-32nd: 0
      },
    };
  }
}