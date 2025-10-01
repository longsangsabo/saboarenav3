// 🏆 SABO ARENA - Precise Double Elimination 16 Player Service
// Complete bracket logic with exact match progression mapping

import 'package:flutter/foundation.dart';

class DoubleElimination16Service {
  /// Complete bracket structure for 16-player double elimination
  /// Each match has exact progression rules for winner and loser
  static Map<String, Map<String, dynamic>> getBracketStructure() {
    return {
      // =============================================
      // WINNER BRACKET - ROUNDS 1-4 (15 matches)
      // =============================================

      // WB ROUND 1 (8 matches) - Initial seeding
      "R1M1": {
        "round": 1,
        "match_number": 1,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 1",
        "winner_advances_to": "R2M9",
        "loser_advances_to": "R101M16",
        "initial_seeds": [1, 16]
      },
      "R1M2": {
        "round": 1,
        "match_number": 2,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 2",
        "winner_advances_to": "R2M9",
        "loser_advances_to": "R101M16",
        "initial_seeds": [8, 9]
      },
      "R1M3": {
        "round": 1,
        "match_number": 3,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 3",
        "winner_advances_to": "R2M10",
        "loser_advances_to": "R101M17",
        "initial_seeds": [4, 13]
      },
      "R1M4": {
        "round": 1,
        "match_number": 4,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 4",
        "winner_advances_to": "R2M10",
        "loser_advances_to": "R101M17",
        "initial_seeds": [5, 12]
      },
      "R1M5": {
        "round": 1,
        "match_number": 5,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 5",
        "winner_advances_to": "R2M11",
        "loser_advances_to": "R101M18",
        "initial_seeds": [2, 15]
      },
      "R1M6": {
        "round": 1,
        "match_number": 6,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 6",
        "winner_advances_to": "R2M11",
        "loser_advances_to": "R101M18",
        "initial_seeds": [7, 10]
      },
      "R1M7": {
        "round": 1,
        "match_number": 7,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 7",
        "winner_advances_to": "R2M12",
        "loser_advances_to": "R101M19",
        "initial_seeds": [3, 14]
      },
      "R1M8": {
        "round": 1,
        "match_number": 8,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 1",
        "description": "WB R1 Match 8",
        "winner_advances_to": "R2M12",
        "loser_advances_to": "R101M19",
        "initial_seeds": [6, 11]
      },

      // WB ROUND 2 (4 matches)
      "R2M9": {
        "round": 2,
        "match_number": 9,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 2",
        "description": "WB R2 Match 1",
        "winner_advances_to": "R3M13",
        "loser_advances_to": "R102M20",
        "players_from": ["R1M1", "R1M2"]
      },
      "R2M10": {
        "round": 2,
        "match_number": 10,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 2",
        "description": "WB R2 Match 2",
        "winner_advances_to": "R3M13",
        "loser_advances_to": "R102M21",
        "players_from": ["R1M3", "R1M4"]
      },
      "R2M11": {
        "round": 2,
        "match_number": 11,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 2",
        "description": "WB R2 Match 3",
        "winner_advances_to": "R3M14",
        "loser_advances_to": "R102M20",
        "players_from": ["R1M5", "R1M6"]
      },
      "R2M12": {
        "round": 2,
        "match_number": 12,
        "bracket_type": "winner",
        "ui_tab": "WB - VÒNG 2",
        "description": "WB R2 Match 4",
        "winner_advances_to": "R3M14",
        "loser_advances_to": "R102M21",
        "players_from": ["R1M7", "R1M8"]
      },

      // WB ROUND 3 - SEMIFINALS (2 matches)
      "R3M13": {
        "round": 3,
        "match_number": 13,
        "bracket_type": "winner",
        "ui_tab": "WB - BÁN KẾT",
        "description": "WB Semifinal 1",
        "winner_advances_to": "R4M15",
        "loser_advances_to": "R105M26",
        "players_from": ["R2M9", "R2M10"]
      },
      "R3M14": {
        "round": 3,
        "match_number": 14,
        "bracket_type": "winner",
        "ui_tab": "WB - BÁN KẾT",
        "description": "WB Semifinal 2",
        "winner_advances_to": "R4M15",
        "loser_advances_to": "R105M26",
        "players_from": ["R2M11", "R2M12"]
      },

      // WB ROUND 4 - FINAL (1 match)
      "R4M15": {
        "round": 4,
        "match_number": 15,
        "bracket_type": "winner",
        "ui_tab": "WB - CHUNG KẾT",
        "description": "WB Final",
        "winner_advances_to": "R200M29",
        "loser_advances_to": "R107M28",
        "players_from": ["R3M13", "R3M14"]
      },

      // =============================================
      // LOSER BRACKET - ROUNDS 101-107 (13 matches)
      // =============================================

      // LB ROUND 1 (4 matches) - WB R1 losers
      "R101M16": {
        "round": 101,
        "match_number": 16,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 1",
        "description": "LB R1 Match 1",
        "winner_advances_to": "R102M20",
        "loser_eliminated": true,
        "players_from": ["R1M1", "R1M2"]
      },
      "R101M17": {
        "round": 101,
        "match_number": 17,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 1",
        "description": "LB R1 Match 2",
        "winner_advances_to": "R102M21",
        "loser_eliminated": true,
        "players_from": ["R1M3", "R1M4"]
      },
      "R101M18": {
        "round": 101,
        "match_number": 18,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 1",
        "description": "LB R1 Match 3",
        "winner_advances_to": "R102M20",
        "loser_eliminated": true,
        "players_from": ["R1M5", "R1M6"]
      },
      "R101M19": {
        "round": 101,
        "match_number": 19,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 1",
        "description": "LB R1 Match 4",
        "winner_advances_to": "R102M21",
        "loser_eliminated": true,
        "players_from": ["R1M7", "R1M8"]
      },

      // LB ROUND 2 (2 matches) - LB R1 winners vs WB R2 losers
      "R102M20": {
        "round": 102,
        "match_number": 20,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 2",
        "description": "LB R2 Match 1",
        "winner_advances_to": "R103M22",
        "loser_eliminated": true,
        "lb_winners_from": ["R101M16", "R101M18"],
        "wb_losers_from": ["R2M9", "R2M11"]
      },
      "R102M21": {
        "round": 102,
        "match_number": 21,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 2",
        "description": "LB R2 Match 2",
        "winner_advances_to": "R103M23",
        "loser_eliminated": true,
        "lb_winners_from": ["R101M17", "R101M19"],
        "wb_losers_from": ["R2M10", "R2M12"]
      },

      // LB ROUND 3 (2 matches)
      "R103M22": {
        "round": 103,
        "match_number": 22,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 3",
        "description": "LB R3 Match 1",
        "winner_advances_to": "R104M24",
        "loser_eliminated": true,
        "players_from": ["R102M20"]
      },
      "R103M23": {
        "round": 103,
        "match_number": 23,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 3",
        "description": "LB R3 Match 2",
        "winner_advances_to": "R104M25",
        "loser_eliminated": true,
        "players_from": ["R102M21"]
      },

      // LB ROUND 4 (2 matches)
      "R104M24": {
        "round": 104,
        "match_number": 24,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 4",
        "description": "LB R4 Match 1",
        "winner_advances_to": "R105M26",
        "loser_eliminated": true,
        "players_from": ["R103M22"]
      },
      "R104M25": {
        "round": 104,
        "match_number": 25,
        "bracket_type": "loser",
        "ui_tab": "LB - VÒNG 4",
        "description": "LB R4 Match 2",
        "winner_advances_to": "R105M26",
        "loser_eliminated": true,
        "players_from": ["R103M23"]
      },

      // LB ROUND 5 - SEMIFINAL (1 match)
      "R105M26": {
        "round": 105,
        "match_number": 26,
        "bracket_type": "loser",
        "ui_tab": "LB - BÁN KẾT",
        "description": "LB Semifinal",
        "winner_advances_to": "R106M27",
        "loser_eliminated": true,
        "lb_winners_from": ["R104M24", "R104M25"],
        "wb_losers_from": ["R3M13", "R3M14"]
      },

      // LB ROUND 106 - FINAL (1 match) - CORRECTED!
      "R106M29": {
        "round": 106,
        "match_number": 29,
        "bracket_type": "loser",
        "ui_tab": "LB - CHUNG KẾT", // FIXED: R106 is now LB Final
        "description": "LB Final",
        "winner_advances_to": "R200M30", // FIXED: Match 30
        "loser_eliminated": true,
        "players_from": [
          "R105M28",
          "WB_R4_LOSER"
        ], // LB semifinal winner + WB final loser
        "lb_winner_from": "R105M28",
        "wb_loser_from": "R4M15"
      },

      // =============================================
      // GRAND FINALS - ROUNDS 200-201 (2 matches)
      // =============================================

      "R200M30": {
        "round": 200,
        "match_number": 30, // FIXED: Match 30
        "bracket_type": "grand_final",
        "ui_tab": "CHUNG KẾT CUỐI",
        "description": "Grand Final",
        "winner_advances_to": "CHAMPION",
        "loser_advances_to": "R201M31", // Reset if WB champion loses
        "wb_champion_from": "R4M15",
        "lb_champion_from": "R106M29" // FIXED: From R106
      },

      "R201M31": {
        "round": 201,
        "match_number": 31,
        "bracket_type": "grand_final_reset",
        "ui_tab": "CHUNG KẾT RESET",
        "description": "Grand Final Reset",
        "winner_advances_to": "CHAMPION",
        "loser_advances_to": "RUNNER_UP",
        "players_from": ["R200M30"] // Same players, reset bracket
      }
    };
  }

  /// Get matches for a specific round
  static List<Map<String, dynamic>> getMatchesForRound(int roundNumber) {
    final bracket = getBracketStructure();
    final matches = <Map<String, dynamic>>[];

    bracket.forEach((matchId, matchData) {
      if (matchData['round'] == roundNumber) {
        matches.add({
          'match_id': matchId,
          ...matchData,
        });
      }
    });

    return matches
      ..sort((a, b) => a['match_number'].compareTo(b['match_number']));
  }

  /// Get the next match for a winner/loser
  static String? getNextMatch(String currentMatchId, bool isWinner) {
    final bracket = getBracketStructure();
    final currentMatch = bracket[currentMatchId];

    if (currentMatch == null) return null;

    if (isWinner) {
      return currentMatch['winner_advances_to'];
    } else {
      return currentMatch['loser_advances_to'];
    }
  }

  /// Get all rounds with their UI tab names
  static Map<int, String> getRoundTabMapping() {
    return {
      // Winner Bracket
      1: "WB - VÒNG 1",
      2: "WB - VÒNG 2",
      3: "WB - BÁN KẾT",
      4: "WB - CHUNG KẾT",

      // Loser Bracket
      101: "LB - VÒNG 1",
      102: "LB - VÒNG 2",
      103: "LB - VÒNG 3",
      104: "LB - VÒNG 4",
      105: "LB - BÁN KẾT",
      106: "LB - CHUNG KẾT", // FIXED: R106 is now LB Final

      // Grand Finals
      200: "CHUNG KẾT CUỐI",
      201: "CHUNG KẾT RESET"
    };
  }

  /// Validate bracket structure integrity
  static bool validateBracketIntegrity() {
    final bracket = getBracketStructure();
    bool isValid = true;

    // Check total matches (should be 30 for 16 players)
    if (bracket.length != 30) {
      debugPrint('❌ Expected 30 matches, got ${bracket.length}');
      isValid = false;
    }

    // Check each match has required fields
    bracket.forEach((matchId, matchData) {
      final required = [
        'round',
        'match_number',
        'bracket_type',
        'ui_tab',
        'description'
      ];
      for (String field in required) {
        if (!matchData.containsKey(field)) {
          debugPrint('❌ Match $matchId missing required field: $field');
          isValid = false;
        }
      }
    });

    if (isValid) {
      debugPrint('✅ Double Elimination 16 bracket structure is valid');
    }

    return isValid;
  }
}
