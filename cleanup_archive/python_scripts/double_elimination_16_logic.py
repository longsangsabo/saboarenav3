#!/usr/bin/env python3
"""
DOUBLE ELIMINATION 16 PLAYERS - COMPLETE BRACKET LOGIC
====================================================

Detailed mapping for every match in a 16-player double elimination tournament.
Each match has exact progression rules for winner and loser.

Tournament Structure:
- Winner Bracket: 4 rounds (15 matches total)
- Loser Bracket: 7 rounds (13 matches total) 
- Grand Finals: 2 rounds (2 matches total)
- Total: 30 matches for 16 players

Round Numbering System:
- WB Rounds: 1, 2, 3, 4
- LB Rounds: 101, 102, 103, 104, 105, 106, 107
- Grand Finals: 200, 201
"""

def get_double_elimination_16_bracket():
    """
    Complete Double Elimination 16 Player Bracket Logic
    Each match defined with exact progression rules
    """
    
    bracket = {
        # =============================================
        # WINNER BRACKET - 4 ROUNDS (15 matches)
        # =============================================
        
        # WINNER BRACKET ROUND 1 (8 matches)
        "R1M1": {
            "round": 1,
            "match_number": 1,
            "description": "WB R1 Match 1",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M9",
            "loser_advances_to": "R101M16",
            "initial_players": ["Seed1", "Seed16"]
        },
        "R1M2": {
            "round": 1,
            "match_number": 2,
            "description": "WB R1 Match 2",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M9",
            "loser_advances_to": "R101M16",
            "initial_players": ["Seed8", "Seed9"]
        },
        "R1M3": {
            "round": 1,
            "match_number": 3,
            "description": "WB R1 Match 3",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M10",
            "loser_advances_to": "R101M17",
            "initial_players": ["Seed4", "Seed13"]
        },
        "R1M4": {
            "round": 1,
            "match_number": 4,
            "description": "WB R1 Match 4",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M10",
            "loser_advances_to": "R101M17",
            "initial_players": ["Seed5", "Seed12"]
        },
        "R1M5": {
            "round": 1,
            "match_number": 5,
            "description": "WB R1 Match 5",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M11",
            "loser_advances_to": "R101M18",
            "initial_players": ["Seed2", "Seed15"]
        },
        "R1M6": {
            "round": 1,
            "match_number": 6,
            "description": "WB R1 Match 6",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M11",
            "loser_advances_to": "R101M18",
            "initial_players": ["Seed7", "Seed10"]
        },
        "R1M7": {
            "round": 1,
            "match_number": 7,
            "description": "WB R1 Match 7",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M12",
            "loser_advances_to": "R101M19",
            "initial_players": ["Seed3", "Seed14"]
        },
        "R1M8": {
            "round": 1,
            "match_number": 8,
            "description": "WB R1 Match 8",
            "ui_tab": "WB - VÒNG 1",
            "winner_advances_to": "R2M12",
            "loser_advances_to": "R101M19",
            "initial_players": ["Seed6", "Seed11"]
        },
        
        # WINNER BRACKET ROUND 2 (4 matches)
        "R2M9": {
            "round": 2,
            "match_number": 9,
            "description": "WB R2 Match 1",
            "ui_tab": "WB - VÒNG 2",
            "winner_advances_to": "R3M13",
            "loser_advances_to": "R102M20",
            "players_from": ["R1M1", "R1M2"]
        },
        "R2M10": {
            "round": 2,
            "match_number": 10,
            "description": "WB R2 Match 2",
            "ui_tab": "WB - VÒNG 2",
            "winner_advances_to": "R3M13",
            "loser_advances_to": "R102M21",
            "players_from": ["R1M3", "R1M4"]
        },
        "R2M11": {
            "round": 2,
            "match_number": 11,
            "description": "WB R2 Match 3",
            "ui_tab": "WB - VÒNG 2",
            "winner_advances_to": "R3M14",
            "loser_advances_to": "R102M20",
            "players_from": ["R1M5", "R1M6"]
        },
        "R2M12": {
            "round": 2,
            "match_number": 12,
            "description": "WB R2 Match 4",
            "ui_tab": "WB - VÒNG 2",
            "winner_advances_to": "R3M14",
            "loser_advances_to": "R102M21",
            "players_from": ["R1M7", "R1M8"]
        },
        
        # WINNER BRACKET ROUND 3 - SEMIFINALS (2 matches)
        "R3M13": {
            "round": 3,
            "match_number": 13,
            "description": "WB Semifinal 1",
            "ui_tab": "WB - BÁN KẾT",
            "winner_advances_to": "R4M15",
            "loser_advances_to": "R105M26",
            "players_from": ["R2M9", "R2M10"]
        },
        "R3M14": {
            "round": 3,
            "match_number": 14,
            "description": "WB Semifinal 2",
            "ui_tab": "WB - BÁN KẾT",
            "winner_advances_to": "R4M15",
            "loser_advances_to": "R105M26",
            "players_from": ["R2M11", "R2M12"]
        },
        
        # WINNER BRACKET ROUND 4 - FINAL (1 match)
        "R4M15": {
            "round": 4,
            "match_number": 15,
            "description": "WB Final",
            "ui_tab": "WB - CHUNG KẾT",
            "winner_advances_to": "R200M29",  # Grand Final
            "loser_advances_to": "R107M28",   # LB Final vs LB Champion
            "players_from": ["R3M13", "R3M14"]
        },
        
        # =============================================
        # LOSER BRACKET - 7 ROUNDS (13 matches)
        # =============================================
        
        # LOSER BRACKET ROUND 1 (4 matches) - WB R1 losers
        "R101M16": {
            "round": 101,
            "match_number": 16,
            "description": "LB R1 Match 1",
            "ui_tab": "LB - VÒNG 1",
            "winner_advances_to": "R102M20",
            "loser_eliminated": True,
            "players_from": ["R1M1", "R1M2"]  # Losers from WB R1
        },
        "R101M17": {
            "round": 101,
            "match_number": 17,
            "description": "LB R1 Match 2",
            "ui_tab": "LB - VÒNG 1",
            "winner_advances_to": "R102M21",
            "loser_eliminated": True,
            "players_from": ["R1M3", "R1M4"]  # Losers from WB R1
        },
        "R101M18": {
            "round": 101,
            "match_number": 18,
            "description": "LB R1 Match 3",
            "ui_tab": "LB - VÒNG 1",
            "winner_advances_to": "R102M20",
            "loser_eliminated": True,
            "players_from": ["R1M5", "R1M6"]  # Losers from WB R1
        },
        "R101M19": {
            "round": 101,
            "match_number": 19,
            "description": "LB R1 Match 4",
            "ui_tab": "LB - VÒNG 1",
            "winner_advances_to": "R102M21",
            "loser_eliminated": True,
            "players_from": ["R1M7", "R1M8"]  # Losers from WB R1
        },
        
        # LOSER BRACKET ROUND 2 (2 matches) - LB R1 winners vs WB R2 losers
        "R102M20": {
            "round": 102,
            "match_number": 20,
            "description": "LB R2 Match 1",
            "ui_tab": "LB - VÒNG 2",
            "winner_advances_to": "R103M22",
            "loser_eliminated": True,
            "players_from": ["R101M16", "R101M18", "R2M9", "R2M11"]  # LB R1 winners + WB R2 losers
        },
        "R102M21": {
            "round": 102,
            "match_number": 21,
            "description": "LB R2 Match 2",
            "ui_tab": "LB - VÒNG 2",
            "winner_advances_to": "R103M23",
            "loser_eliminated": True,
            "players_from": ["R101M17", "R101M19", "R2M10", "R2M12"]  # LB R1 winners + WB R2 losers
        },
        
        # LOSER BRACKET ROUND 3 (2 matches) - LB R2 winners 
        "R103M22": {
            "round": 103,
            "match_number": 22,
            "description": "LB R3 Match 1",
            "ui_tab": "LB - VÒNG 3",
            "winner_advances_to": "R104M24",
            "loser_eliminated": True,
            "players_from": ["R102M20"]
        },
        "R103M23": {
            "round": 103,
            "match_number": 23,
            "description": "LB R3 Match 2",
            "ui_tab": "LB - VÒNG 3",
            "winner_advances_to": "R104M25",
            "loser_eliminated": True,
            "players_from": ["R102M21"]
        },
        
        # LOSER BRACKET ROUND 4 (2 matches) - LB R3 winners meet here
        "R104M24": {
            "round": 104,
            "match_number": 24,
            "description": "LB R4 Match 1",
            "ui_tab": "LB - VÒNG 4",
            "winner_advances_to": "R105M26",
            "loser_eliminated": True,
            "players_from": ["R103M22"]
        },
        "R104M25": {
            "round": 104,
            "match_number": 25,
            "description": "LB R4 Match 2", 
            "ui_tab": "LB - VÒNG 4",
            "winner_advances_to": "R105M26",
            "loser_eliminated": True,
            "players_from": ["R103M23"]
        },
        
        # LOSER BRACKET ROUND 5 (1 match) - LB R4 winners vs WB Semifinal losers
        "R105M26": {
            "round": 105,
            "match_number": 26,
            "description": "LB R5 - Semifinal",
            "ui_tab": "LB - BÁN KẾT",
            "winner_advances_to": "R106M27",
            "loser_eliminated": True,
            "players_from": ["R104M24", "R104M25", "R3M13", "R3M14"]  # LB R4 winners + WB semifinal losers
        },
        
        # LOSER BRACKET ROUND 6 (1 match) - LB Semifinal winner
        "R106M27": {
            "round": 106,
            "match_number": 27,
            "description": "LB R6 - Before Final",
            "ui_tab": "LB - CHUNG KẾT",
            "winner_advances_to": "R107M28",
            "loser_eliminated": True,
            "players_from": ["R105M26"]
        },
        
        # LOSER BRACKET ROUND 7 (1 match) - LB Final vs WB Final loser
        "R107M28": {
            "round": 107,
            "match_number": 28,
            "description": "LB Final",
            "ui_tab": "LB - CHUNG KẾT",
            "winner_advances_to": "R200M29",  # Grand Final
            "loser_eliminated": True,
            "players_from": ["R106M27", "R4M15"]  # LB R6 winner + WB Final loser
        },
        
        # =============================================
        # GRAND FINALS - 2 ROUNDS (2 matches)
        # =============================================
        
        # GRAND FINAL ROUND 1
        "R200M29": {
            "round": 200,
            "match_number": 29,
            "description": "Grand Final",
            "ui_tab": "CHUNG KẾT CUỐI",
            "winner_advances_to": "CHAMPION",
            "loser_advances_to": "R201M30",  # Reset bracket if WB champion loses
            "players_from": ["R4M15", "R107M28"]  # WB Champion vs LB Champion
        },
        
        # GRAND FINAL ROUND 2 (Reset bracket - only if WB champion loses first grand final)
        "R201M30": {
            "round": 201,
            "match_number": 30,
            "description": "Grand Final Reset",
            "ui_tab": "CHUNG KẾT RESET",
            "winner_advances_to": "CHAMPION",
            "loser_advances_to": "RUNNER_UP",
            "players_from": ["R200M29"]  # Same players, reset bracket
        }
    }
    
    return bracket

def analyze_bracket_structure():
    """Analyze the complete bracket structure"""
    bracket = get_double_elimination_16_bracket()
    
    print("DOUBLE ELIMINATION 16 PLAYER BRACKET ANALYSIS")
    print("=" * 60)
    
    # Group by rounds
    rounds = {}
    for match_id, match_data in bracket.items():
        round_num = match_data["round"]
        if round_num not in rounds:
            rounds[round_num] = []
        rounds[round_num].append((match_id, match_data))
    
    # Display structure
    for round_num in sorted(rounds.keys()):
        matches = rounds[round_num]
        ui_tab = matches[0][1]["ui_tab"]
        
        print(f"\nRound {round_num} - {ui_tab} ({len(matches)} matches)")
        print("-" * 50)
        
        for match_id, match_data in matches:
            print(f"  {match_id}: {match_data['description']}")
            if 'winner_advances_to' in match_data:
                print(f"    Winner → {match_data['winner_advances_to']}")
            if 'loser_advances_to' in match_data:
                print(f"    Loser → {match_data['loser_advances_to']}")
            elif match_data.get('loser_eliminated'):
                print(f"    Loser → ELIMINATED")
    
    print(f"\nTotal matches: {len(bracket)}")
    print("Perfect for 16 players - everyone plays minimum 1 match, maximum 10 matches")

if __name__ == "__main__":
    analyze_bracket_structure()