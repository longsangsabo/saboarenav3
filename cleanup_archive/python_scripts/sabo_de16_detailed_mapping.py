"""
🏆 SABO DE16 DETAILED MATCH MAPPING
Mapping chi tiết từng match với winner/loser destinations và match number synchronization

SABO DE16 Structure: 27 matches total
- Winner Bracket: 14 matches (R1: 8, R2: 4, R3: 2)
- Loser Branch A: 7 matches (R101: 4, R102: 2, R103: 1) 
- Loser Branch B: 3 matches (R201: 2, R202: 1)
- SABO Finals: 3 matches (R250: 1, R251: 1, R300: 1)
"""

def generate_sabo_de16_match_mapping():
    """Generate complete SABO DE16 match mapping with synchronized match numbers"""
    
    mapping = {}
    match_counter = 1  # Global match counter for synchronized numbering
    
    # ===========================================
    # WINNER BRACKET - 14 matches (1-14)
    # ===========================================
    
    print("🏆 WINNER BRACKET MAPPING:")
    print("=" * 50)
    
    # R1 Winner Bracket - 8 matches (1-8)
    print("\n📍 R1 WINNER BRACKET (8 matches):")
    for i in range(1, 9):  # R1M1 to R1M8
        winner_dest_match = (i + 1) // 2  # 1→1, 2→1, 3→2, 4→2, 5→3, 6→3, 7→4, 8→4
        winner_dest_number = 8 + winner_dest_match  # R2M9, R2M10, R2M11, R2M12
        
        loser_dest_match = i  # Direct mapping to LB-A
        loser_dest_number = 14 + loser_dest_match  # R101M15, R101M16, ..., R101M22
        
        mapping[f'R1M{i}'] = {
            'round': 1,
            'match_number': match_counter,
            'global_id': match_counter,
            'winner_destination': f'R2M{winner_dest_match}',
            'winner_match_number': winner_dest_number,
            'loser_destination': f'R101M{loser_dest_match}',
            'loser_match_number': loser_dest_number,
            'bracket_type': 'winner'
        }
        
        print(f"   R1M{i} (#{match_counter}): Winner→R2M{winner_dest_match}(#{winner_dest_number}), Loser→R101M{loser_dest_match}(#{loser_dest_number})")
        match_counter += 1
    
    # R2 Winner Bracket - 4 matches (9-12)
    print("\n📍 R2 WINNER BRACKET (4 matches):")
    for i in range(1, 5):  # R2M1 to R2M4
        winner_dest_match = (i + 1) // 2  # 1→1, 2→1, 3→2, 4→2
        winner_dest_number = 12 + winner_dest_match  # R3M13, R3M14
        
        loser_dest_match = i  # To LB-B
        loser_dest_number = 22 + loser_dest_match  # R201M23, R201M24, R201M25, R201M26
        
        mapping[f'R2M{i}'] = {
            'round': 2,
            'match_number': match_counter,
            'global_id': match_counter,
            'winner_destination': f'R3M{winner_dest_match}',
            'winner_match_number': winner_dest_number,
            'loser_destination': f'R201M{loser_dest_match}',
            'loser_match_number': loser_dest_number,
            'bracket_type': 'winner'
        }
        
        print(f"   R2M{i} (#{match_counter}): Winner→R3M{winner_dest_match}(#{winner_dest_number}), Loser→R201M{loser_dest_match}(#{loser_dest_number})")
        match_counter += 1
    
    # R3 Winner Bracket - 2 matches (13-14)
    print("\n📍 R3 WINNER BRACKET (2 matches):")
    for i in range(1, 3):  # R3M1 to R3M2
        # Both winners go to SABO Finals
        winner_dest_number = 24 + i  # R250M25, R251M26
        
        mapping[f'R3M{i}'] = {
            'round': 3,
            'match_number': match_counter,
            'global_id': match_counter,
            'winner_destination': f'R{249+i}M1',  # R250M1, R251M1 (always M1)
            'winner_match_number': winner_dest_number,
            'loser_destination': 'ELIMINATED',  # R3 losers are eliminated
            'loser_match_number': None,
            'bracket_type': 'winner'
        }
        
        print(f"   R3M{i} (#{match_counter}): Winner→R{249+i}M1(#{winner_dest_number}), Loser→ELIMINATED")
        match_counter += 1
    
    # ===========================================
    # LOSER BRACKET A - 7 matches (15-21)
    # ===========================================
    
    print("\n🥈 LOSER BRACKET A MAPPING:")
    print("=" * 50)
    
    # R101 Loser Branch A - 4 matches (15-18)
    print("\n📍 R101 LOSER BRACKET A (4 matches):")
    for i in range(1, 5):  # R101M1 to R101M4
        winner_dest_match = (i + 1) // 2  # 1→1, 2→1, 3→2, 4→2
        winner_dest_number = 18 + winner_dest_match  # R102M19, R102M20
        
        mapping[f'R101M{i}'] = {
            'round': 101,
            'match_number': match_counter,
            'global_id': match_counter,
            'winner_destination': f'R102M{winner_dest_match}',
            'winner_match_number': winner_dest_number,
            'loser_destination': 'ELIMINATED',
            'loser_match_number': None,
            'bracket_type': 'loser_a'
        }
        
        print(f"   R101M{i} (#{match_counter}): Winner→R102M{winner_dest_match}(#{winner_dest_number}), Loser→ELIMINATED")
        match_counter += 1
    
    # R102 Loser Branch A - 2 matches (19-20)
    print("\n📍 R102 LOSER BRACKET A (2 matches):")
    for i in range(1, 3):  # R102M1 to R102M2
        winner_dest_number = 20 + i  # R103M21
        
        mapping[f'R102M{i}'] = {
            'round': 102,
            'match_number': match_counter,
            'global_id': match_counter,
            'winner_destination': 'R103M1' if i <= 2 else None,
            'winner_match_number': winner_dest_number,
            'loser_destination': 'ELIMINATED',
            'loser_match_number': None,
            'bracket_type': 'loser_a'
        }
        
        print(f"   R102M{i} (#{match_counter}): Winner→R103M1(#{winner_dest_number}), Loser→ELIMINATED")
        match_counter += 1
    
    # R103 Loser Branch A Final - 1 match (21)
    print("\n📍 R103 LOSER BRACKET A FINAL (1 match):")
    mapping['R103M1'] = {
        'round': 103,
        'match_number': match_counter,
        'global_id': match_counter,
        'winner_destination': 'R250M1',  # LB-A Champion goes to SEMI FINAL 1
        'winner_match_number': 25,
        'loser_destination': 'ELIMINATED',
        'loser_match_number': None,
        'bracket_type': 'loser_a'
    }
    print(f"   R103M1 (#{match_counter}): Winner→R250M1(#25) - SEMI FINAL 1, Loser→ELIMINATED")
    match_counter += 1
    
    # ===========================================
    # LOSER BRACKET B - 3 matches (22-24)
    # ===========================================
    
    print("\n🥉 LOSER BRACKET B MAPPING:")
    print("=" * 50)
    
    # R201 Loser Branch B - 2 matches (22-23)
    print("\n📍 R201 LOSER BRACKET B (2 matches):")
    for i in range(1, 3):  # R201M1 to R201M2
        winner_dest_number = 23 + i  # R202M24
        
        mapping[f'R201M{i}'] = {
            'round': 201,
            'match_number': match_counter,
            'global_id': match_counter,
            'winner_destination': 'R202M1' if i <= 2 else None,
            'winner_match_number': winner_dest_number,
            'loser_destination': 'ELIMINATED',
            'loser_match_number': None,
            'bracket_type': 'loser_b'
        }
        
        print(f"   R201M{i} (#{match_counter}): Winner→R202M1(#{winner_dest_number}), Loser→ELIMINATED")
        match_counter += 1
    
    # R202 Loser Branch B Final - 1 match (24)
    print("\n📍 R202 LOSER BRACKET B FINAL (1 match):")
    mapping['R202M1'] = {
        'round': 202,
        'match_number': match_counter,
        'global_id': match_counter,
        'winner_destination': 'R251M1',  # LB-B Champion goes to SEMI FINAL 2
        'winner_match_number': 26,
        'loser_destination': 'ELIMINATED',
        'loser_match_number': None,
        'bracket_type': 'loser_b'
    }
    print(f"   R202M1 (#{match_counter}): Winner→R251M1(#26) - SEMI FINAL 2, Loser→ELIMINATED")
    match_counter += 1
    
    # ===========================================
    # SABO FINALS - 3 matches (25-27)
    # ===========================================
    
    print("\n🏆 SABO FINALS MAPPING:")
    print("=" * 50)
    
    # R250 Semi Final 1 - 1 match (25)
    print("\n📍 R250 SEMI FINAL 1 (1 match): WB Winner 1 vs LB-A Champion")
    mapping['R250M1'] = {
        'round': 250,
        'match_number': match_counter,
        'global_id': match_counter,
        'winner_destination': 'R300M1',  # To Final
        'winner_match_number': 27,
        'loser_destination': 'ELIMINATED',
        'loser_match_number': None,
        'bracket_type': 'sabo_final',
        'players': 'R3M1_winner vs R103M1_winner'
    }
    print(f"   R250M1 (#{match_counter}): WB Winner 1 vs LB-A Champion → Winner to R300M1(#27)")
    match_counter += 1
    
    # R251 Semi Final 2 - 1 match (26)
    print("\n📍 R251 SEMI FINAL 2 (1 match): WB Winner 2 vs LB-B Champion")
    mapping['R251M1'] = {
        'round': 251,
        'match_number': match_counter,
        'global_id': match_counter,
        'winner_destination': 'R300M1',  # To Final
        'winner_match_number': 27,
        'loser_destination': 'ELIMINATED',
        'loser_match_number': None,
        'bracket_type': 'sabo_final',
        'players': 'R3M2_winner vs R202M1_winner'
    }
    print(f"   R251M1 (#{match_counter}): WB Winner 2 vs LB-B Champion → Winner to R300M1(#27)")
    match_counter += 1
    
    # R300 Final - 1 match (27)
    print("\n📍 R300 FINAL (1 match):")
    mapping['R300M1'] = {
        'round': 300,
        'match_number': match_counter,
        'global_id': match_counter,
        'winner_destination': 'CHAMPION',
        'winner_match_number': None,
        'loser_destination': 'RUNNER_UP',
        'loser_match_number': None,
        'bracket_type': 'sabo_final'
    }
    print(f"   R300M1 (#{match_counter}): Winner→CHAMPION, Loser→RUNNER_UP")
    match_counter += 1
    
    print(f"\n🎯 TOTAL MATCHES: {match_counter - 1}")
    print(f"📊 MAPPING COMPLETE: All {len(mapping)} matches mapped with synchronized numbers")
    
    return mapping

def generate_dart_implementation(mapping):
    """Generate Dart code for CompleteSaboDE16Service"""
    
    print("\n" + "="*60)
    print("🎯 DART IMPLEMENTATION FOR CompleteSaboDE16Service:")
    print("="*60)
    
    print("\n/// Hard-coded progression mapping for SABO DE16")
    print("static Map<String, Map<String, dynamic>> getProgressionMapping() {")
    print("  return {")
    
    for key, value in mapping.items():
        winner_dest = value['winner_destination']
        loser_dest = value['loser_destination']
        
        winner_line = f"'winner': '{winner_dest}'" if winner_dest != 'CHAMPION' else "'winner': 'CHAMPION'"
        loser_line = f"'loser': '{loser_dest}'" if loser_dest not in ['ELIMINATED', 'RUNNER_UP'] else f"'loser': '{loser_dest}'"
        
        print(f"    '{key}': {{{winner_line}, {loser_line}}},")
    
    print("  };")
    print("}")
    
    print("\n/// Synchronized match numbers for database")
    print("static Map<String, int> getMatchNumbers() {")
    print("  return {")
    
    for key, value in mapping.items():
        print(f"    '{key}': {value['global_id']},")
    
    print("  };")
    print("}")

if __name__ == "__main__":
    mapping = generate_sabo_de16_match_mapping()
    
    # Generate Dart implementation
    generate_dart_implementation(mapping)
    
    # Export to use in services
    print("\n" + "="*60)
    print("📋 SUMMARY FOR IMPLEMENTATION:")
    print("="*60)
    
    for round_type in ['Winner Bracket', 'Loser Branch A', 'Loser Branch B', 'SABO Finals']:
        print(f"\n{round_type}:")
        for key, value in mapping.items():
            if (round_type == 'Winner Bracket' and value['bracket_type'] == 'winner') or \
               (round_type == 'Loser Branch A' and value['bracket_type'] == 'loser_a') or \
               (round_type == 'Loser Branch B' and value['bracket_type'] == 'loser_b') or \
               (round_type == 'SABO Finals' and value['bracket_type'] == 'sabo_final'):
                print(f"  {key} (#{value['global_id']}): {value['winner_destination']} | {value['loser_destination']}")