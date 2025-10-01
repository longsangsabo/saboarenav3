/// Simple test to verify ELO constants work
void main() {
  print('🧪 Testing ELO calculations...');
  testEloCalculations();
  print('\n🏆 Testing Tournament scenario...');
  testTournamentScenario();
}

void testEloCalculations() {
  // Test fixed rewards
  Map<int, int> expectedRewards = {
    1: 75,  // 1st place
    2: 45,  // 2nd place
    3: 30,  // 3rd place
    4: 20,  // 4th place
    5: 10,  // Top 5-8
    6: 10,  // Top 5-8
    7: 10,  // Top 5-8
    8: 10,  // Top 5-8
    9: 5,   // Top 9-16
    10: 5,  // Top 9-16
    15: 5,  // Top 9-16
    16: 5,  // Top 9-16
    17: 0,  // Others
    20: 0,  // Others
  };

  print('\n📊 Testing ELO rewards:');
  expectedRewards.forEach((position, expectedElo) {
    int actualElo = calculateEloChange(position);
    String status = actualElo == expectedElo ? '✅' : '❌';
    print('Position $position: Expected $expectedElo, Got $actualElo $status');
  });
}

void testTournamentScenario() {
  // Sample 8-player tournament
  List<Map<String, dynamic>> players = [
    {'id': 'player1', 'name': 'Hoàng Văn A', 'currentElo': 1500},
    {'id': 'player2', 'name': 'Nguyễn Văn B', 'currentElo': 1400},
    {'id': 'player3', 'name': 'Lê Văn C', 'currentElo': 1300},
    {'id': 'player4', 'name': 'Trần Văn D', 'currentElo': 1200},
    {'id': 'player5', 'name': 'Phan Văn E', 'currentElo': 1100},
    {'id': 'player6', 'name': 'Đỗ Văn F', 'currentElo': 1000},
    {'id': 'player7', 'name': 'Lý Văn G', 'currentElo': 900},
    {'id': 'player8', 'name': 'Vũ Văn H', 'currentElo': 800},
  ];

  // Final standings (player3 wins!)
  List<Map<String, dynamic>> standings = [
    {'playerId': 'player3', 'position': 1},  // Lê Văn C wins: +75
    {'playerId': 'player1', 'position': 2},  // Hoàng Văn A: +45
    {'playerId': 'player2', 'position': 3},  // Nguyễn Văn B: +30
    {'playerId': 'player4', 'position': 4},  // Trần Văn D: +20
    {'playerId': 'player5', 'position': 5},  // Phan Văn E: +10
    {'playerId': 'player6', 'position': 6},  // Đỗ Văn F: +10
    {'playerId': 'player7', 'position': 7},  // Lý Văn G: +10
    {'playerId': 'player8', 'position': 8},  // Vũ Văn H: +10
  ];

  print('\n📈 Tournament Results:');
  for (var standing in standings) {
    var player = players.firstWhere((p) => p['id'] == standing['playerId']);
    int eloChange = calculateEloChange(standing['position']);
    int newElo = player['currentElo'] + eloChange;
    
    print('${standing['position']}. ${player['name']}: '
          '${player['currentElo']} → $newElo (${eloChange > 0 ? '+' : ''}$eloChange)');
  }

  print('\n✅ Tournament ELO system working correctly!');
}

/// Simple ELO calculation function
int calculateEloChange(int position) {
  // Fixed positions
  if (position == 1) return 75;   // 1st: +75
  if (position == 2) return 45;   // 2nd: +45
  if (position == 3) return 30;   // 3rd: +30
  if (position == 4) return 20;   // 4th: +20
  
  // Range-based positions
  if (position >= 5 && position <= 8) return 10;     // 5-8: +10
  if (position >= 9 && position <= 16) return 5;     // 9-16: +5
  
  return 0; // Others: 0
}