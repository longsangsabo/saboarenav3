// 🧪 Test Losers Bracket Logic Fix
// Verify that the Double Elimination Losers Bracket logic is correct

import 'lib/presentation/tournament_detail_screen/widgets/demo_bracket/shared/tournament_data_generator.dart';

void main() {
  print('🧪 Testing Double Elimination Losers Bracket Logic');
  print('=' * 60);
  
  // Test với 8 players
  testLosersBracket(8);
  print('\n${'=' * 60}');
  
  // Test với 16 players  
  testLosersBracket(16);
}

void testLosersBracket(int playerCount) {
  print('\n🏆 Testing Losers Bracket for $playerCount players:');
  print('-' * 40);
  
  final losersRounds = TournamentDataGenerator.calculateDoubleEliminationLosers(playerCount);
  
  print('Total Losers Rounds: ${losersRounds.length}');
  
  for (int i = 0; i < losersRounds.length; i++) {
    final round = losersRounds[i];
    final matchCount = round['matchCount'] as int;
    final matches = round['matches'] as List;
    
    print('${round['title']}: $matchCount matches');
    
    // Print first match as example
    if (matches.isNotEmpty) {
      final firstMatch = matches[0] as Map<String, String>;
      print('  Example: ${firstMatch['matchId']} - ${firstMatch['player1']} vs ${firstMatch['player2']}');
    }
    
    // Verify match count consistency
    if (matches.length != matchCount) {
      print('  ❌ ERROR: Expected $matchCount matches, but got ${matches.length}');
    } else {
      print('  ✅ Match count correct');
    }
  }
  
  // Verify logical progression
  print('\n📊 Verification:');
  for (int i = 0; i < losersRounds.length - 1; i++) {
    final currentRound = losersRounds[i];
    final nextRound = losersRounds[i + 1];
    final currentMatches = currentRound['matchCount'] as int;
    final nextMatches = nextRound['matchCount'] as int;
    
    // Each match produces 1 winner, so next round shouldn't exceed current match count
    if (nextMatches > currentMatches) {
      print('  ❌ Logic Error: ${currentRound['title']} has $currentMatches matches but ${nextRound['title']} has $nextMatches matches');
      print('     This means ${nextRound['title']} expects $nextMatches winners from only $currentMatches matches!');
    } else {
      print('  ✅ ${currentRound['title']} → ${nextRound['title']}: $currentMatches → $nextMatches ✓');
    }
  }
}