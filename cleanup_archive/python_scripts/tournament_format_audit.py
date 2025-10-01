#!/usr/bin/env python3
"""
Comprehensive Tournament Format Audit
Analyzes all tournament formats and their bracket structures
"""

from supabase import create_client

# Initialize Supabase
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def analyze_tournament_formats():
    print('🔍 COMPREHENSIVE TOURNAMENT FORMAT AUDIT')
    print('=' * 60)
    
    # Get all tournaments
    tournaments = supabase.table('tournaments').select(
        'id, title, bracket_format, game_format, max_participants, status'
    ).order('title').execute()
    
    format_analysis = {}
    
    print('\n📋 ALL TOURNAMENTS IN DATABASE:')
    print('-' * 40)
    
    for i, t in enumerate(tournaments.data):
        title = t['title']
        bracket_format = t['bracket_format'] 
        game_format = t['game_format']
        max_participants = t['max_participants']
        status = t['status']
        
        print(f'{i+1:2d}. {title}:')
        print(f'    Bracket: {bracket_format}')
        print(f'    Game: {game_format}') 
        print(f'    Max Players: {max_participants}')
        print(f'    Status: {status}')
        print()
        
        # Group by format
        if bracket_format not in format_analysis:
            format_analysis[bracket_format] = {}
        
        if max_participants not in format_analysis[bracket_format]:
            format_analysis[bracket_format][max_participants] = []
        
        format_analysis[bracket_format][max_participants].append({
            'title': title,
            'game_format': game_format,
            'id': t['id'],
            'status': status
        })
    
    print('\n📊 FORMAT ANALYSIS SUMMARY:')
    print('=' * 40)
    
    # Analyze each format type
    for format_type, player_groups in format_analysis.items():
        print(f'\n🎯 {format_type.upper().replace("_", " ")} FORMAT:')
        
        for player_count, tournaments_list in sorted(player_groups.items()):
            print(f'  📈 {player_count} players: {len(tournaments_list)} tournaments')
            
            # Analyze bracket structure from a sample tournament
            sample_tournament = tournaments_list[0]
            matches = supabase.table('matches').select(
                'round_number, match_number, status'
            ).eq('tournament_id', sample_tournament['id']).execute()
            
            if matches.data:
                rounds = {}
                total_matches = len(matches.data)
                
                for match in matches.data:
                    round_num = match['round_number']
                    if round_num not in rounds:
                        rounds[round_num] = 0
                    rounds[round_num] += 1
                
                print(f'     📄 Sample: {sample_tournament["title"]} ({total_matches} matches)')
                
                # Show round structure
                round_structure = []
                for round_num in sorted(rounds.keys()):
                    round_structure.append(f'R{round_num}:{rounds[round_num]}')
                
                print(f'     🏗️  Structure: {" | ".join(round_structure)}')
                
                # Calculate theoretical bracket requirements
                if format_type == 'single_elimination':
                    expected_matches = player_count - 1
                    print(f'     ✅ Expected SE matches: {expected_matches}')
                elif format_type == 'double_elimination':
                    # Double elimination: 2*(n-1) for n players (worst case)
                    expected_matches = 2 * (player_count - 1)
                    print(f'     ✅ Expected DE matches: ~{expected_matches} (max)')
                    
            else:
                print(f'     📄 Sample: {sample_tournament["title"]} (⚠️  no matches generated)')
    
    return format_analysis

def identify_missing_formats():
    print('\n\n🔍 IDENTIFYING MISSING TOURNAMENT FORMATS:')
    print('=' * 50)
    
    # Standard tournament sizes
    standard_sizes = [4, 8, 16, 32, 64]
    format_types = ['single_elimination', 'double_elimination']
    
    print('📋 RECOMMENDED TOURNAMENT FORMATS TO IMPLEMENT:')
    print('-' * 45)
    
    # Get existing combinations
    tournaments = supabase.table('tournaments').select(
        'bracket_format, max_participants'
    ).execute()
    
    existing_combinations = set()
    for t in tournaments.data:
        existing_combinations.add((t['bracket_format'], t['max_participants']))
    
    missing_formats = []
    for format_type in format_types:
        for size in standard_sizes:
            if (format_type, size) not in existing_combinations:
                missing_formats.append((format_type, size))
    
    for format_type, size in missing_formats:
        print(f'  ❌ {format_type.upper().replace("_", " ")} - {size} players')
    
    if not missing_formats:
        print('  ✅ All standard formats are represented!')
    
    return missing_formats

def calculate_bracket_requirements():
    print('\n\n📊 BRACKET GENERATION REQUIREMENTS:')
    print('=' * 45)
    
    formats_info = {
        'single_elimination': {
            4: {'rounds': 2, 'matches': 3},
            8: {'rounds': 3, 'matches': 7}, 
            16: {'rounds': 4, 'matches': 15},
            32: {'rounds': 5, 'matches': 31},
            64: {'rounds': 6, 'matches': 63}
        },
        'double_elimination': {
            4: {'wb_rounds': 2, 'lb_rounds': 2, 'matches': 6},
            8: {'wb_rounds': 3, 'lb_rounds': 5, 'matches': 14},
            16: {'wb_rounds': 4, 'lb_rounds': 7, 'matches': 30},
            32: {'wb_rounds': 5, 'lb_rounds': 9, 'matches': 62},  
            64: {'wb_rounds': 6, 'lb_rounds': 11, 'matches': 126}
        }
    }
    
    for format_type, sizes in formats_info.items():
        print(f'\n🎯 {format_type.upper().replace("_", " ")}:')
        for size, info in sizes.items():
            if format_type == 'single_elimination':
                print(f'  {size:2d} players: {info["rounds"]} rounds, {info["matches"]} matches')
            else:
                print(f'  {size:2d} players: WB {info["wb_rounds"]} + LB {info["lb_rounds"]} rounds, {info["matches"]} matches')

if __name__ == '__main__':
    # Run comprehensive analysis
    format_analysis = analyze_tournament_formats()
    missing_formats = identify_missing_formats()
    calculate_bracket_requirements()
    
    print('\n\n🎯 NEXT STEPS FOR UNIVERSAL BRACKET SYSTEM:')
    print('=' * 50)
    print('1. ✅ Audit Complete - Found all existing formats')
    print('2. 🔧 Create universal bracket generation algorithms') 
    print('3. 🏗️  Build dynamic match creation functions')
    print('4. ⚡ Implement automatic advancement system')
    print('5. 📊 Add database triggers and functions')
    print('6. 🧪 Test all tournament formats')