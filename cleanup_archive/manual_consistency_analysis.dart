// CRITICAL ELO-RANK CONSISTENCY ANALYSIS
// Manual comparison between SaboRankSystem and RankingConstants

void main() {
  print('🔥 MANUAL ELO-RANK CONSISTENCY ANALYSIS');
  print('=' * 60);
  
  // SaboRankSystem mapping (từ sabo_rank_system.dart lines 6-18)
  Map<String, int> saboMapping = {
    'K': 1000,      // Người mới
    'K+': 1100,     // Học việc
    'I': 1200,      // Thợ 3
    'I+': 1300,     // Thợ 2
    'H': 1400,      // Thợ 1
    'H+': 1500,     // Thợ chính
    'G': 1600,      // Thợ giỏi
    'G+': 1700,     // Cao thủ
    'F': 1800,      // Chuyên gia
    'F+': 1900,     // Đại cao thủ
    'E': 2000,      // Huyền thoại
    'E+': 2100,     // Vô địch
  };
  
  // RankingConstants.RANK_ELO_RANGES (từ ranking_constants.dart lines 50-69)
  Map<String, Map<String, int>> constantsRanges = {
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
  
  print('\n🧪 MAPPING COMPARISON:');
  print('Rank\t| SaboSystem ELO\t| Constants Range\t| Compatible?');
  print('-' * 70);
  
  bool allCompatible = true;
  List<String> issues = [];
  
  for (String rank in saboMapping.keys) {
    int saboElo = saboMapping[rank]!;
    Map<String, int>? range = constantsRanges[rank];
    
    bool isCompatible = false;
    String rangeStr = 'MISSING';
    
    if (range != null) {
      int min = range['min']!;
      int max = range['max']!;
      rangeStr = '$min-$max';
      
      // SaboSystem uses exact ELO thresholds, check if they align with Constants ranges
      isCompatible = (saboElo == min);
    }
    
    if (!isCompatible) {
      allCompatible = false;
      issues.add('Rank $rank: SaboSystem=$saboElo vs ConstantsRange=$rangeStr');
    }
    
    String icon = isCompatible ? '✅' : '❌';
    print('$rank\t| $saboElo\t\t\t| $rangeStr\t\t| $icon');
  }
  
  print('\n${'=' * 60}');
  
  if (allCompatible) {
    print('✅ SUCCESS: Mappings are COMPATIBLE!');
  } else {
    print('🚨 CRITICAL ISSUES FOUND: ${issues.length} incompatibilities');
    print('\n❌ DETAILED ISSUES:');
    for (String issue in issues) {
      print('  $issue');
    }
  }
  
  print('\n🎯 CRITICAL BUSINESS LOGIC TEST:');
  print('Testing user requirements...');
  
  // Test: "rank I thì elo là 1200"
  print('\n• Requirement: rank I thì elo là 1200');
  int rankiSaboelo = saboMapping['I']!;
  Map<String, int>? rankiConstantsrange = constantsRanges['I'];
  
  print('  SaboSystem: I rank starts at ELO $rankiSaboelo');
  if (rankiConstantsrange != null) {
    print('  Constants: I rank range ${rankiConstantsrange['min']}-${rankiConstantsrange['max']}');
    bool matches1200 = (rankiSaboelo == 1200 && rankiConstantsrange['min'] == 1200);
    print('  Business rule satisfied: ${matches1200 ? '✅' : '❌'}');
  }
  
  // Test: "elo đạt 1300 thì user lên hạng I+"
  print('\n• Requirement: elo đạt 1300 thì user lên hạng I+');
  int rankiplusSaboelo = saboMapping['I+']!;
  Map<String, int>? rankiplusConstantsrange = constantsRanges['I+'];
  
  print('  SaboSystem: I+ rank starts at ELO $rankiplusSaboelo');
  if (rankiplusConstantsrange != null) {
    print('  Constants: I+ rank range ${rankiplusConstantsrange['min']}-${rankiplusConstantsrange['max']}');
    bool matches1300 = (rankiplusSaboelo == 1300 && rankiplusConstantsrange['min'] == 1300);
    print('  Business rule satisfied: ${matches1300 ? '✅' : '❌'}');
  }
  
  print('\n🔧 ALGORITHM COMPARISON:');
  print('SaboRankSystem.getRankFromElo() algorithm:');
  print('  - Uses exact ELO thresholds (elo >= threshold)');
  print('  - Iterates through sorted ranks, picks highest matching');
  print('  - Default: K rank for ELO < 1000');
  
  print('\nRankingConstants.getRankFromElo() algorithm:');
  print('  - Uses ELO ranges (min <= elo <= max)');
  print('  - Iterates through ranges and returns first match');
  print('  - Default: UNRANKED for no match');
  
  print('\n🚨 POTENTIAL ISSUES:');
  print('1. Different algorithms may return different results');
  print('2. Different default values (K vs UNRANKED)');
  print('3. Tournament services use Constants, UI uses SaboSystem');
  print('4. This creates FRONTEND-BACKEND INCONSISTENCY!');
  
  print('\n💡 RECOMMENDATIONS:');
  print('1. Standardize to ONE getRankFromElo implementation');
  print('2. Update all services to use the same system');
  print('3. Test critical paths: registration, tournaments, UI display');
  print('4. Verify business rules are satisfied end-to-end');
  
  print('\n${'=' * 60}');
  print('ANALYSIS COMPLETED - Review above for critical action items!');
}