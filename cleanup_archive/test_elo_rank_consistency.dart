import 'lib/core/utils/sabo_rank_system.dart';
import 'lib/core/constants/ranking_constants.dart';

void main() {
  print('🔥 TESTING ELO-RANK CONSISTENCY BETWEEN SYSTEMS');
  print('=' * 60);
  
  // Test với các ELO values quan trọng
  final testElos = [
    900, 1000, 1100,  // K ranks
    1200, 1300,       // I ranks (quan trọng cho club verification)
    1400, 1500,       // H ranks
    1600, 1700,       // G ranks
    1800, 1900,       // F ranks
    2000, 2100        // E ranks
  ];
  
  print('\n🧪 COMPARISON TEST:');
  print('ELO\t| SaboRankSystem\t| RankingConstants\t| MATCH?');
  print('-' * 70);
  
  bool allMatched = true;
  List<Map<String, dynamic>> mismatches = [];
  
  for (final elo in testElos) {
    final saboRank = SaboRankSystem.getRankFromElo(elo);
    final constantsRank = RankingConstants.getRankFromElo(elo);
    final isMatch = saboRank == constantsRank;
    
    if (!isMatch) {
      allMatched = false;
      mismatches.add({
        'elo': elo,
        'saboRank': saboRank,
        'constantsRank': constantsRank,
      });
    }
    
    final matchIcon = isMatch ? '✅' : '❌';
    print('$elo\t| $saboRank\t\t\t| $constantsRank\t\t\t| $matchIcon');
  }
  
  print('\n' + '=' * 60);
  
  if (allMatched) {
    print('✅ SUCCESS: All ELO-rank mappings are CONSISTENT!');
  } else {
    print('🚨 CRITICAL ISSUE: Found ${mismatches.length} INCONSISTENCIES!');
    print('\n❌ MISMATCHED CASES:');
    for (final mismatch in mismatches) {
      print('  ELO ${mismatch['elo']}: SaboRankSystem="${mismatch['saboRank']}" != RankingConstants="${mismatch['constantsRank']}"');
    }
    
    print('\n🔧 IMPACT ANALYSIS:');
    print('• Tournament services use RankingConstants.getRankFromElo()');
    print('• UI screens use SaboRankSystem.getRankFromElo()');
    print('• This creates FRONTEND-BACKEND INCONSISTENCY!');
    
    print('\n💡 REQUIRED FIXES:');
    print('1. Standardize to ONE getRankFromElo implementation');
    print('2. Update all imports to use the chosen system');
    print('3. Test all rank-dependent features after fix');
  }
  
  print('\n🎯 CRITICAL BUSINESS LOGIC VALIDATION:');
  print('Testing key user requirements...');
  
  // Test specific user requirement: "rank I thì elo là 1200"
  final rank_I_elo_sabo = SaboRankSystem.getRankFromElo(1200);
  final rank_I_elo_constants = RankingConstants.getRankFromElo(1200);
  
  print('• ELO 1200 should be rank I:');
  print('  SaboRankSystem: $rank_I_elo_sabo ${rank_I_elo_sabo == 'I' ? '✅' : '❌'}');
  print('  RankingConstants: $rank_I_elo_constants ${rank_I_elo_constants == 'I' ? '✅' : '❌'}');
  
  // Test specific user requirement: "elo đạt 1300 thì user lên hạng I+"
  final rank_I_plus_elo_sabo = SaboRankSystem.getRankFromElo(1300);
  final rank_I_plus_elo_constants = RankingConstants.getRankFromElo(1300);
  
  print('• ELO 1300 should be rank I+:');
  print('  SaboRankSystem: $rank_I_plus_elo_sabo ${rank_I_plus_elo_sabo == 'I+' ? '✅' : '❌'}');
  print('  RankingConstants: $rank_I_plus_elo_constants ${rank_I_plus_elo_constants == 'I+' ? '✅' : '❌'}');
  
  print('\n🔍 SYSTEM USAGE ANALYSIS:');
  print('Services using RankingConstants.getRankFromElo():');
  print('• tournament_elo_service.dart');
  print('• simple_tournament_elo_service.dart');
  print('');
  print('Services using SaboRankSystem.getRankFromElo():');
  print('• user_profile_screen widgets');
  print('• club_profile_screen');
  
  print('\n' + '=' * 60);
  print('TEST COMPLETED - Review results above for action items!');
}