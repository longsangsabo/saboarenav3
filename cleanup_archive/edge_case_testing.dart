// EDGE CASE TESTING: Critical ELO values
void main() {
  print('🧪 EDGE CASE TESTING - CRITICAL ELO VALUES');
  print('=' * 60);
  
  // Test cases that might cause different results
  List<int> criticalElos = [
    999,   // Just below K threshold
    1000,  // Exactly K threshold  
    1099,  // Top of K range
    1100,  // Exactly K+ threshold
    1199,  // Top of K+ range
    1200,  // Exactly I threshold (CRITICAL for business logic)
    1299,  // Top of I range
    1300,  // Exactly I+ threshold (CRITICAL for business logic)
    500,   // Very low ELO
    3000,  // Very high ELO
  ];
  
  print('\n🔍 TESTING CRITICAL ELO VALUES:');
  print('ELO\t| SaboRankSystem\t| RankingConstants\t| Business Impact');
  print('-' * 80);
  
  for (int elo in criticalElos) {
    String saboResult = getSaboRankFromElo(elo);
    String constantsResult = getConstantsRankFromElo(elo);
    String businessImpact = getBusinessImpact(elo, saboResult, constantsResult);
    String match = (saboResult == constantsResult) ? '✅' : '❌';
    
    print('$elo\t| $saboResult\t\t\t| $constantsResult\t\t\t| $businessImpact $match');
  }
  
  print('\n🎯 CRITICAL USER SCENARIOS:');
  
  // Scenario 1: New user registration
  print('\n1. NEW USER REGISTRATION (ELO 1000):');
  String newUserSabo = getSaboRankFromElo(1000);
  String newUserConstants = getConstantsRankFromElo(1000);
  print('  UI shows: $newUserSabo');
  print('  Tournament calculates: $newUserConstants');
  print('  Consistent: ${newUserSabo == newUserConstants ? '✅' : '❌ PROBLEM!'}');
  
  // Scenario 2: Club verification sets I rank (ELO 1200)
  print('\n2. CLUB VERIFICATION - I RANK (ELO 1200):');
  String clubVerifiedSabo = getSaboRankFromElo(1200);
  String clubVerifiedConstants = getConstantsRankFromElo(1200);
  print('  UI shows: $clubVerifiedSabo');
  print('  Tournament calculates: $clubVerifiedConstants'); 
  print('  Consistent: ${clubVerifiedSabo == clubVerifiedConstants ? '✅' : '❌ PROBLEM!'}');
  
  // Scenario 3: Tournament promotion to I+ (ELO 1300)
  print('\n3. TOURNAMENT PROMOTION - I+ RANK (ELO 1300):');
  String promotedSabo = getSaboRankFromElo(1300);
  String promotedConstants = getConstantsRankFromElo(1300);
  print('  UI shows: $promotedSabo');
  print('  Tournament calculates: $promotedConstants');
  print('  Consistent: ${promotedSabo == promotedConstants ? '✅' : '❌ PROBLEM!'}');
  
  // Scenario 4: Very low ELO edge case
  print('\n4. VERY LOW ELO EDGE CASE (ELO 500):');
  String lowEloSabo = getSaboRankFromElo(500);
  String lowEloConstants = getConstantsRankFromElo(500);
  print('  UI shows: $lowEloSabo');
  print('  Tournament calculates: $lowEloConstants');
  print('  Consistent: ${lowEloSabo == lowEloConstants ? '✅' : '❌ CRITICAL PROBLEM!'}');
  
  print('\n${'=' * 60}');
  print('🚨 CRITICAL FINDINGS SUMMARY:');
  
  // Check for any inconsistencies
  List<String> inconsistencies = [];
  for (int elo in criticalElos) {
    String saboResult = getSaboRankFromElo(elo);
    String constantsResult = getConstantsRankFromElo(elo);
    if (saboResult != constantsResult) {
      inconsistencies.add('ELO $elo: $saboResult vs $constantsResult');
    }
  }
  
  if (inconsistencies.isEmpty) {
    print('✅ No inconsistencies found in edge cases!');
  } else {
    print('❌ FOUND ${inconsistencies.length} CRITICAL INCONSISTENCIES:');
    for (String issue in inconsistencies) {
      print('  $issue');
    }
  }
  
  print('\n💡 IMMEDIATE ACTION REQUIRED:');
  print('1. Fix any inconsistencies found above');
  print('2. Standardize to ONE getRankFromElo function');
  print('3. Update all imports across codebase');
  print('4. Test user registration → club verification → tournament flow');
  
  print('\n🔧 RECOMMENDED SOLUTION:');
  print('Use RankingConstants.getRankFromElo() as the single source of truth:');
  print('  ✅ More robust with min/max ranges');
  print('  ✅ Already used by tournament services');
  print('  ✅ Handles edge cases better');
  print('  ❗ Update UI components to use RankingConstants instead of SaboRankSystem');
}

// Simulate SaboRankSystem.getRankFromElo logic
String getSaboRankFromElo(int elo) {
  if (elo < 1000) return 'K';
  
  Map<String, int> rankEloMapping = {
    'K': 1000, 'K+': 1100, 'I': 1200, 'I+': 1300,
    'H': 1400, 'H+': 1500, 'G': 1600, 'G+': 1700,
    'F': 1800, 'F+': 1900, 'E': 2000, 'E+': 2100,
  };
  
  List<MapEntry<String, int>> sortedRanks = rankEloMapping.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  
  String currentRank = 'K';
  for (var entry in sortedRanks) {
    if (elo >= entry.value) {
      currentRank = entry.key;
    } else {
      break;
    }
  }
  return currentRank;
}

// Simulate RankingConstants.getRankFromElo logic  
String getConstantsRankFromElo(int elo) {
  Map<String, Map<String, int>> ranges = {
    'K': {'min': 1000, 'max': 1099},
    'K+': {'min': 1100, 'max': 1199},
    'I': {'min': 1200, 'max': 1299},
    'I+': {'min': 1300, 'max': 1399},
    'H': {'min': 1400, 'max': 1499},
    'H+': {'min': 1500, 'max': 1599},
    'G': {'min': 1600, 'max': 1699},
    'G+': {'min': 1700, 'max': 1799},
    'F': {'min': 1800, 'max': 1899},
    'F+': {'min': 1900, 'max': 1999},
    'E': {'min': 2000, 'max': 2099},
    'E+': {'min': 2100, 'max': 2999},
  };
  
  for (var entry in ranges.entries) {
    int min = entry.value['min']!;
    int max = entry.value['max']!;
    if (elo >= min && elo <= max) {
      return entry.key;
    }
  }
  return 'UNRANKED';
}

String getBusinessImpact(int elo, String saboResult, String constantsResult) {
  if (saboResult == constantsResult) return 'OK';
  
  // Critical business logic ELOs
  if (elo == 1000) return 'NEW USER REG';
  if (elo == 1200) return 'CLUB VERIFICATION';
  if (elo == 1300) return 'TOURNAMENT PROMOTION';
  if (elo < 1000) return 'EDGE CASE';
  
  return 'INCONSISTENT';
}