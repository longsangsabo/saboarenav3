// 🎯 Test SPA Challenge Integration
// Test that challenge matches award SPA bonuses correctly

import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/match_progression_service.dart';
import 'lib/services/club_spa_service.dart';

void main() async {
  print('🧪 Testing SPA Challenge Integration');
  print('=' * 50);
  
  // Note: This test requires:
  // 1. A test match with stakes_type='spa_points' and spa_stakes_amount > 0
  // 2. A club with available SPA balance
  // 3. Valid user IDs for winner and loser
  
  await testChallengeMatchCompletion();
}

Future<void> testChallengeMatchCompletion() async {
  try {
    print('\n1️⃣ Testing Challenge Match Completion with SPA Awards');
    
    // These would need to be real IDs from your database for testing
    const testMatchId = 'test-match-id';
    const winnerId = 'test-winner-id';
    const loserId = 'test-loser-id';
    
    print('🎯 Completing challenge match:');
    print('   Match ID: $testMatchId');
    print('   Winner: $winnerId');
    print('   Loser: $loserId');
    
    // Call the updated match progression service
    final result = await MatchProgressionService.instance.updateMatchResult(
      matchId: testMatchId,
      tournamentId: null, // null means this is a challenge match
      winnerId: winnerId,
      loserId: loserId,
      scores: {'player1': 15, 'player2': 10},
      notes: 'Test challenge completion',
    );
    
    print('\n✅ Result: $result');
    
    if (result['success'] == true) {
      print('🎉 Challenge match completed successfully!');
      print('   Message: ${result['message']}');
      print('   Tournament complete: ${result['tournament_complete']}');
      print('   Progression: ${result['progression_completed']}');
    } else {
      print('❌ Challenge match completion failed');
      print('   Error: ${result['error']}');
    }
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}

// Helper function to create test data (for future use)
Future<void> createTestChallengeMatch() async {
  print('\n2️⃣ Creating Test Challenge Match Data');
  
  // This would create a test match with SPA stakes
  // You'd need to implement this based on your database structure
  
  print('⚠️ Test data creation not implemented yet');
  print('   Please create a test match manually with:');
  print('   - stakes_type: "spa_points"');
  print('   - spa_stakes_amount: 100');
  print('   - spa_payout_processed: false');
}