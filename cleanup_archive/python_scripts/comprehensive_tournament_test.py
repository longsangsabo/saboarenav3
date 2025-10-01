#!/usr/bin/env python3
"""
Comprehensive Tournament Format Testing
Test bracket generation, match creation, and advancement for all formats
"""

from supabase import create_client
from dynamic_match_creator import DynamicMatchCreator
from enhanced_match_progression import EnhancedMatchProgressionService

# Initialize
SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

def test_all_tournament_formats():
    """Test all tournament formats comprehensively"""
    print('🧪 COMPREHENSIVE TOURNAMENT FORMAT TESTING')
    print('=' * 60)
    
    # Get all tournaments
    tournaments = supabase.table('tournaments').select(
        'id, title, bracket_format, max_participants, status'
    ).execute()
    
    creator = DynamicMatchCreator()
    progression_service = EnhancedMatchProgressionService()
    
    results = []
    
    for tournament in tournaments.data:
        tournament_id = tournament['id']
        title = tournament['title']
        bracket_format = tournament['bracket_format']
        max_participants = tournament['max_participants']
        
        print(f'\\n🏆 TESTING: {title}')
        print(f'   Format: {bracket_format}')
        print(f'   Players: {max_participants}')
        print('   ' + '-' * 40)
        
        # Test 1: Bracket Status
        print('   📊 Step 1: Getting bracket status...')
        status = progression_service.get_tournament_bracket_status(tournament_id)
        
        if 'error' in status:
            print(f'   ❌ Error getting status: {status["error"]}')
            results.append({'tournament': title, 'test': 'bracket_status', 'result': 'FAILED', 'error': status['error']})
            continue
        
        print(f'   ✅ Status: {status["completed_matches"]}/{status["total_matches"]} matches ({status["progress_percentage"]}%)')
        print(f'   📈 Ready to play: {status["ready_matches"]} matches')
        
        # Test 2: Bracket Structure Verification
        print('   🏗️  Step 2: Verifying bracket structure...')
        expected_matches = _get_expected_matches(bracket_format, max_participants)
        actual_matches = status['total_matches']
        
        if actual_matches == expected_matches:
            print(f'   ✅ Structure: {actual_matches} matches (correct)')
            results.append({'tournament': title, 'test': 'bracket_structure', 'result': 'PASSED'})
        else:
            print(f'   ❌ Structure: {actual_matches} matches (expected {expected_matches})')
            results.append({'tournament': title, 'test': 'bracket_structure', 'result': 'FAILED', 'expected': expected_matches, 'actual': actual_matches})
        
        # Test 3: Immediate Advancement (if ready matches available)
        if status['ready_matches'] > 0:
            print('   ⚡ Step 3: Testing immediate advancement...')
            advancement_test = _test_immediate_advancement(tournament_id, progression_service)
            
            if advancement_test['success']:
                print(f'   ✅ Advancement: {advancement_test["advancement_count"]} players advanced immediately')
                results.append({'tournament': title, 'test': 'immediate_advancement', 'result': 'PASSED', 'advancement_count': advancement_test['advancement_count']})
            else:
                print(f'   ❌ Advancement failed: {advancement_test.get("error", "Unknown error")}')
                results.append({'tournament': title, 'test': 'immediate_advancement', 'result': 'FAILED', 'error': advancement_test.get('error')})
        else:
            print('   ⏭️  Step 3: Skipping advancement test (no ready matches)')
            results.append({'tournament': title, 'test': 'immediate_advancement', 'result': 'SKIPPED', 'reason': 'no_ready_matches'})
    
    # Print comprehensive results
    print('\\n\\n📋 COMPREHENSIVE TEST RESULTS')
    print('=' * 50)
    
    test_types = ['bracket_status', 'bracket_structure', 'immediate_advancement']
    
    for test_type in test_types:
        print(f'\\n🧪 {test_type.upper().replace("_", " ")}:')
        test_results = [r for r in results if r['test'] == test_type]
        
        passed = len([r for r in test_results if r['result'] == 'PASSED'])
        failed = len([r for r in test_results if r['result'] == 'FAILED'])
        skipped = len([r for r in test_results if r['result'] == 'SKIPPED'])
        
        print(f'   ✅ Passed: {passed}')
        print(f'   ❌ Failed: {failed}')
        print(f'   ⏭️  Skipped: {skipped}')
        
        # Show failures
        failures = [r for r in test_results if r['result'] == 'FAILED']
        for failure in failures:
            print(f'     Failed: {failure["tournament"]} - {failure.get("error", "Structure mismatch")}')
    
    # Overall results
    total_tests = len(results)
    passed_tests = len([r for r in results if r['result'] == 'PASSED'])
    success_rate = (passed_tests / total_tests * 100) if total_tests > 0 else 0
    
    print(f'\\n🎯 OVERALL RESULTS:')
    print(f'   Total Tests: {total_tests}')
    print(f'   Passed: {passed_tests}')
    print(f'   Success Rate: {success_rate:.1f}%')
    
    if success_rate >= 80:
        print('   🎉 EXCELLENT! Universal tournament system is working great!')
    elif success_rate >= 60:
        print('   👍 GOOD! Most features working, minor issues to address')
    else:
        print('   ⚠️  NEEDS WORK! Several issues need to be fixed')

def _get_expected_matches(bracket_format, max_participants):
    """Get expected number of matches for format"""
    if bracket_format == 'single_elimination':
        return max_participants - 1
    elif bracket_format == 'double_elimination':
        expected_matches = {
            4: 6, 8: 14, 16: 30, 32: 62, 64: 126
        }
        return expected_matches.get(max_participants, max_participants * 2 - 2)
    else:
        return 0

def _test_immediate_advancement(tournament_id, progression_service):
    """Test immediate advancement with a sample match"""
    try:
        # Get first ready match
        ready_matches = progression_service._get_next_ready_matches(tournament_id)
        
        if not ready_matches:
            return {'success': False, 'error': 'No ready matches for testing'}
        
        # Get match details
        first_match = ready_matches[0]
        match_details = supabase.table('matches').select(
            'id, match_number, player1_id, player2_id'
        ).eq('id', first_match['id']).execute()
        
        if not match_details.data:
            return {'success': False, 'error': 'Could not get match details'}
        
        match_info = match_details.data[0]
        
        # Simulate match completion
        result = progression_service.update_match_result_with_immediate_advancement(
            match_id=match_info['id'],
            tournament_id=tournament_id,
            winner_id=match_info['player1_id'],
            loser_id=match_info['player2_id'],
            scores={'player1': 9, 'player2': 3}
        )
        
        if 'error' in result:
            return {'success': False, 'error': result['error']}
        
        return {
            'success': True,
            'advancement_count': len(result.get('advancement_details', [])),
            'immediate_advancement': result.get('immediate_advancement', False)
        }
        
    except Exception as e:
        return {'success': False, 'error': str(e)}

def show_format_coverage():
    """Show coverage of tournament formats"""
    print('\\n📈 TOURNAMENT FORMAT COVERAGE')
    print('=' * 40)
    
    # Standard formats we should support
    standard_formats = {
        'single_elimination': [4, 8, 16, 32, 64],
        'double_elimination': [4, 8, 16, 32, 64]
    }
    
    # Get existing tournaments
    tournaments = supabase.table('tournaments').select(
        'bracket_format, max_participants'
    ).execute()
    
    existing_combinations = set()
    for t in tournaments.data:
        existing_combinations.add((t['bracket_format'], t['max_participants']))
    
    print('🎯 FORMAT COVERAGE:')
    for format_type, sizes in standard_formats.items():
        print(f'\\n{format_type.upper().replace("_", " ")}:')
        for size in sizes:
            status = '✅' if (format_type, size) in existing_combinations else '❌'
            print(f'  {status} {size} players')
    
    coverage_count = len(existing_combinations)
    total_standard = sum(len(sizes) for sizes in standard_formats.values())
    coverage_percent = (coverage_count / total_standard * 100)
    
    print(f'\\n📊 Overall Coverage: {coverage_count}/{total_standard} ({coverage_percent:.1f}%)')

if __name__ == '__main__':
    # Show format coverage
    show_format_coverage()
    
    # Run comprehensive tests
    test_all_tournament_formats()