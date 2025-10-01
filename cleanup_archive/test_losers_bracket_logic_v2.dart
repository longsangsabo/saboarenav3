// Test Double Elimination Losers Bracket Logic V2
import 'lib/presentation/tournament_detail_screen/widgets/demo_bracket/shared/tournament_data_generator.dart';

void main() {
  print('🧪 Testing Double Elimination Losers Bracket Logic V2...\n');
  
  // Test with 8 players
  final losersRounds = TournamentDataGenerator.calculateDoubleEliminationLosers(8);
  
  print('📊 Losers Bracket Structure for 8 players:');
  print('═══════════════════════════════════════════\n');
  
  for (int i = 0; i < losersRounds.length; i++) {
    final round = losersRounds[i];
    final title = round['title'];
    final matches = round['matches'] as List<Map<String, String>>;
    final matchCount = round['matchCount'];
    
    print('🔥 $title ($matchCount matches):');
    for (final match in matches) {
      print('   ${match['matchId']}: ${match['player1']} vs ${match['player2']}');
    }
    print('');
  }
  
  // Validate logic specifically for LB Round 2
  print('🎯 Validation: LB Round 2 Logic');
  print('═══════════════════════════════════════════');
  
  if (losersRounds.length >= 2) {
    final lbRound2 = losersRounds[1];
    final matches = lbRound2['matches'] as List<Map<String, String>>;
    
    print('Expected: LB R2 should mix winners from LB R1 with losers from WB R2');
    
    for (final match in matches) {
      final player1 = match['player1']!;
      final player2 = match['player2']!;
      
      bool hasLBR1Winner = player1.contains('LB R1 Winner') || player2.contains('LB R1 Winner');
      bool hasWBR2Loser = player1.contains('WB R2 Loser') || player2.contains('WB R2 Loser');
      
      print('   ${match['matchId']}: $player1 vs $player2');
      print('   ✓ Has LB R1 Winner: $hasLBR1Winner');
      print('   ✓ Has WB R2 Loser: $hasWBR2Loser');
      
      if (hasLBR1Winner && hasWBR2Loser) {
        print('   ✅ CORRECT: Mix of LB R1 Winner and WB R2 Loser');
      } else {
        print('   ❌ INCORRECT: Should be LB R1 Winner vs WB R2 Loser');
      }
      print('');
    }
  }
  
  print('🏁 Test completed!');
}