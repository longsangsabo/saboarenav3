#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🏆 DOUBLE ELIMINATION 16 PLAYERS - MATCH LIST
Danh sách chi tiết 30 trận với mã trận và progression logic
Author: SABO Arena v1.0
Date: October 1, 2025
"""

def generate_double_elimination_16_matches():
    """Generate complete list of 30 matches for DE16 tournament"""
    
    matches = []
    
    # ==================== WINNERS BRACKET ====================
    
    print("🏆 WINNERS BRACKET (WB)")
    print("=" * 50)
    
    # WB Round 1 - 8 matches
    print("\n📍 WB ROUND 1 (8 matches)")
    wb_r1_matches = [
        {"id": "WB-R1-M1", "round": 1, "match": 1, "players": "P1 vs P16", "winner_to": "WB-R2-M1", "loser_to": "LB-R102-M17"},
        {"id": "WB-R1-M2", "round": 1, "match": 2, "players": "P8 vs P9", "winner_to": "WB-R2-M1", "loser_to": "LB-R102-M17"},
        {"id": "WB-R1-M3", "round": 1, "match": 3, "players": "P4 vs P13", "winner_to": "WB-R2-M2", "loser_to": "LB-R102-M18"},
        {"id": "WB-R1-M4", "round": 1, "match": 4, "players": "P5 vs P12", "winner_to": "WB-R2-M2", "loser_to": "LB-R102-M18"},
        {"id": "WB-R1-M5", "round": 1, "match": 5, "players": "P2 vs P15", "winner_to": "WB-R2-M3", "loser_to": "LB-R102-M19"},
        {"id": "WB-R1-M6", "round": 1, "match": 6, "players": "P7 vs P10", "winner_to": "WB-R2-M3", "loser_to": "LB-R102-M19"},
        {"id": "WB-R1-M7", "round": 1, "match": 7, "players": "P3 vs P14", "winner_to": "WB-R2-M4", "loser_to": "LB-R102-M20"},
        {"id": "WB-R1-M8", "round": 1, "match": 8, "players": "P6 vs P11", "winner_to": "WB-R2-M4", "loser_to": "LB-R102-M20"},
    ]
    
    for match in wb_r1_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:10} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # WB Round 2 - 4 matches
    print("\n📍 WB ROUND 2 (4 matches)")
    wb_r2_matches = [
        {"id": "WB-R2-M1", "round": 2, "match": 9, "players": "W(M1) vs W(M2)", "winner_to": "WB-R3-M1", "loser_to": "LB-R104-M23"},
        {"id": "WB-R2-M2", "round": 2, "match": 10, "players": "W(M3) vs W(M4)", "winner_to": "WB-R3-M1", "loser_to": "LB-R104-M23"},
        {"id": "WB-R2-M3", "round": 2, "match": 11, "players": "W(M5) vs W(M6)", "winner_to": "WB-R3-M2", "loser_to": "LB-R104-M24"},
        {"id": "WB-R2-M4", "round": 2, "match": 12, "players": "W(M7) vs W(M8)", "winner_to": "WB-R3-M2", "loser_to": "LB-R104-M24"},
    ]
    
    for match in wb_r2_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:10} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # WB Round 3 - 2 matches  
    print("\n📍 WB ROUND 3 (2 matches)")
    wb_r3_matches = [
        {"id": "WB-R3-M1", "round": 3, "match": 13, "players": "W(M9) vs W(M10)", "winner_to": "WB-R4-M1", "loser_to": "LB-R106-M27"},
        {"id": "WB-R3-M2", "round": 3, "match": 14, "players": "W(M11) vs W(M12)", "winner_to": "WB-R4-M1", "loser_to": "LB-R106-M27"},
    ]
    
    for match in wb_r3_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:10} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # WB Round 4 - 1 match (WB Final)
    print("\n📍 WB ROUND 4 - WB FINAL (1 match)")
    wb_r4_matches = [
        {"id": "WB-R4-M1", "round": 4, "match": 15, "players": "W(M13) vs W(M14)", "winner_to": "GF-R200-M1", "loser_to": "LB-R107-M28"},
    ]
    
    for match in wb_r4_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:10} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # ==================== LOSERS BRACKET ====================
    
    print("\n\n💀 LOSERS BRACKET (LB)")
    print("=" * 50)
    
    # LB Round 101 - 4 matches
    print("\n📍 LB ROUND 101 (4 matches)")
    lb_r101_matches = [
        {"id": "LB-R101-M1", "round": 101, "match": 16, "players": "L(M1) vs L(M8)", "winner_to": "LB-R102-M17", "loser_to": "ELIMINATED"},
        {"id": "LB-R101-M2", "round": 101, "match": 17, "players": "L(M2) vs L(M7)", "winner_to": "LB-R102-M17", "loser_to": "ELIMINATED"},
        {"id": "LB-R101-M3", "round": 101, "match": 18, "players": "L(M3) vs L(M6)", "winner_to": "LB-R102-M18", "loser_to": "ELIMINATED"},
        {"id": "LB-R101-M4", "round": 101, "match": 19, "players": "L(M4) vs L(M5)", "winner_to": "LB-R102-M18", "loser_to": "ELIMINATED"},
    ]
    
    for match in lb_r101_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # LB Round 102 - 4 matches
    print("\n📍 LB ROUND 102 (4 matches)")
    lb_r102_matches = [
        {"id": "LB-R102-M17", "round": 102, "match": 20, "players": "W(LB-M1) vs L(WB-M9)", "winner_to": "LB-R103-M21", "loser_to": "ELIMINATED"},
        {"id": "LB-R102-M18", "round": 102, "match": 21, "players": "W(LB-M2) vs L(WB-M10)", "winner_to": "LB-R103-M21", "loser_to": "ELIMINATED"},
        {"id": "LB-R102-M19", "round": 102, "match": 22, "players": "W(LB-M3) vs L(WB-M11)", "winner_to": "LB-R103-M22", "loser_to": "ELIMINATED"},
        {"id": "LB-R102-M20", "round": 102, "match": 23, "players": "W(LB-M4) vs L(WB-M12)", "winner_to": "LB-R103-M22", "loser_to": "ELIMINATED"},
    ]
    
    for match in lb_r102_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # LB Round 103 - 2 matches
    print("\n📍 LB ROUND 103 (2 matches)")
    lb_r103_matches = [
        {"id": "LB-R103-M21", "round": 103, "match": 24, "players": "W(LB-M17) vs W(LB-M18)", "winner_to": "LB-R104-M23", "loser_to": "ELIMINATED"},
        {"id": "LB-R103-M22", "round": 103, "match": 25, "players": "W(LB-M19) vs W(LB-M20)", "winner_to": "LB-R104-M24", "loser_to": "ELIMINATED"},
    ]
    
    for match in lb_r103_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # LB Round 104 - 2 matches
    print("\n📍 LB ROUND 104 (2 matches)")
    lb_r104_matches = [
        {"id": "LB-R104-M23", "round": 104, "match": 26, "players": "W(LB-M21) vs L(WB-M13)", "winner_to": "LB-R105-M25", "loser_to": "ELIMINATED"},
        {"id": "LB-R104-M24", "round": 104, "match": 27, "players": "W(LB-M22) vs L(WB-M14)", "winner_to": "LB-R105-M25", "loser_to": "ELIMINATED"},
    ]
    
    for match in lb_r104_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # LB Round 105 - 1 match
    print("\n📍 LB ROUND 105 (1 match)")
    lb_r105_matches = [
        {"id": "LB-R105-M25", "round": 105, "match": 28, "players": "W(LB-M23) vs W(LB-M24)", "winner_to": "LB-R106-M26", "loser_to": "ELIMINATED"},
    ]
    
    for match in lb_r105_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # LB Round 106 - 1 match  
    print("\n📍 LB ROUND 106 (1 match)")
    lb_r106_matches = [
        {"id": "LB-R106-M26", "round": 106, "match": 29, "players": "W(LB-M25) vs L(WB-M15)", "winner_to": "LB-R107-M27", "loser_to": "ELIMINATED"},
    ]
    
    for match in lb_r106_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # LB Round 107 - LB Final
    print("\n📍 LB ROUND 107 - LB FINAL (1 match)")
    lb_r107_matches = [
        {"id": "LB-R107-M27", "round": 107, "match": 30, "players": "W(LB-M26) = LB Champion", "winner_to": "GF-R200-M1", "loser_to": "3rd PLACE"},
    ]
    
    for match in lb_r107_matches:
        print(f"  {match['id']:12} | {match['players']:12} | → Win: {match['winner_to']:12} | → Lose: {match['loser_to']}")
        matches.append(match)
    
    # ==================== GRAND FINAL ====================
    
    print("\n\n🏆 GRAND FINAL")
    print("=" * 50)
    
    # Grand Final Round 200
    print("\n📍 GRAND FINAL ROUND 200")
    gf_r200_matches = [
        {"id": "GF-R200-M1", "round": 200, "match": 31, "players": "WB Champion vs LB Champion", "winner_to": "CHAMPION", "loser_to": "GF-R201-M1 or 2nd PLACE"},
    ]
    
    for match in gf_r200_matches:
        print(f"  {match['id']:12} | {match['players']:20} | → Win: {match['winner_to']:10} | → Lose: {match['loser_to']}")
    
    # Grand Final Reset Round 201 (if needed)
    print("\n📍 GRAND FINAL RESET ROUND 201 (if LB Champion wins R200)")
    gf_r201_matches = [
        {"id": "GF-R201-M1", "round": 201, "match": 32, "players": "Bracket Reset Match", "winner_to": "CHAMPION", "loser_to": "2nd PLACE"},
    ]
    
    for match in gf_r201_matches:
        print(f"  {match['id']:12} | {match['players']:20} | → Win: {match['winner_to']:10} | → Lose: {match['loser_to']}")
    
    # ==================== SUMMARY ====================
    
    print("\n\n📊 TOURNAMENT SUMMARY")
    print("=" * 50)
    print(f"🏆 Total Matches: {len(matches)} (guaranteed) + 1 (possible reset) = 31-32 matches")
    print(f"👥 Players: 16")
    print(f"🎯 WB Matches: 15 (8+4+2+1)")
    print(f"💀 LB Matches: 15 (4+4+2+2+1+1+1)")
    print(f"🏅 GF Matches: 1-2 (depends on bracket reset)")
    
    print("\n🔄 BRACKET PROGRESSION LOGIC:")
    print("  • WB losers drop to specific LB rounds")
    print("  • LB losers are eliminated immediately")
    print("  • WB Champion gets advantage in Grand Final")
    print("  • If LB Champion wins GF R200 → Bracket Reset (GF R201)")
    
    return matches

if __name__ == "__main__":
    print("🎯 DOUBLE ELIMINATION 16 PLAYERS - COMPLETE MATCH LIST")
    print("=" * 60)
    matches = generate_double_elimination_16_matches()
    
    print(f"\n✅ Generated {len(matches)} guaranteed matches for DE16 tournament")
    print("📋 This list shows exact progression logic for tournament bracket")