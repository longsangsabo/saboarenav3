// 🎯 SABO ARENA - Demo Bracket Visualization Tab
// Cho phép CLB owner xem trước các format bảng đấu với data mẫu

import 'package:flutter/material.dart';
import 'demo_bracket/formats/single_elimination_bracket.dart';
import 'demo_bracket/formats/double_elimination_bracket.dart';
import 'demo_bracket/formats/de32_bracket_simple.dart';
import 'demo_bracket/formats/round_robin_bracket.dart';
import 'demo_bracket/formats/swiss_system_bracket.dart';
import 'demo_bracket/components/bracket_components.dart';
import 'demo_bracket/shared/tournament_data_generator.dart';

class DemoBracketTab extends StatefulWidget {
  const DemoBracketTab({super.key});

@override
  State<DemoBracketTab> createState() => _DemoBracketTabState();
}

class _DemoBracketTabState extends State<DemoBracketTab> {
  String _selectedFormat = 'single_elimination';
  int _selectedPlayerCount = 8;

  final Map<String, String> _formats = {
    "single_elimination": 'Single Elimination',
    "double_elimination": 'Double Elimination',
    "round_robin": 'Round Robin',
    "swiss": 'Swiss System',
  };

  final List<int> _playerCounts = [8, 16, 32, 64];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildControls(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildBracketView(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎮 Demo Tournament Formats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E86AB),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xem trước các hình thức thi đấu với dữ liệu mẫu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildFormatSelector(),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 1,
                child: _buildPlayerCountSelector(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình thức thi đấu',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFormat,
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedFormat = newValue;
                  });
                }
              },
              items: _formats.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCountSelector() {
    final availableCounts = _playerCounts;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số người chơi',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedPlayerCount,
              isExpanded: true,
              onChanged: (int? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPlayerCount = newValue;
                  });
                }
              },
              items: availableCounts.map((count) {
                String label = '$count players';
                // Add DE32 indicator for Double Elimination + 32 players
                if (_selectedFormat == 'double_elimination' && count == 32) {
                  label += ' (DE32 Two-Group)';
                }
                
                return DropdownMenuItem<int>(
                  value: count,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: (_selectedFormat == 'double_elimination' && count == 32)
                          ? Colors.indigo[700]
                          : Colors.black,
                      fontWeight: (_selectedFormat == 'double_elimination' && count == 32)
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBracketView() {
    switch (_selectedFormat) {
      case 'single_elimination':
        return _buildSingleEliminationBracket();
      case 'double_elimination':
        return _buildDoubleEliminationBracket();
      case 'round_robin':
        return _buildRoundRobinBracket();
      case 'swiss':
        return _buildSwissBracket();
      default:
        return _buildSingleEliminationBracket();
    }
  }

  Widget _buildSingleEliminationBracket() {
    return SingleEliminationBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  Widget _buildDoubleEliminationBracket() {
    // SABO Arena rule: Double Elimination with 32 players uses DE32 Two-Group System
    if (_selectedPlayerCount == 32) {
      return const DE32Bracket();
    }
    
    // Traditional Double Elimination for other player counts
    return DoubleEliminationBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  Widget _buildRoundRobinBracket() {
    return RoundRobinBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }

  Widget _buildSwissBracket() {
    return SwissSystemBracket(
      playerCount: _selectedPlayerCount,
      onFullscreenTap: _showFullscreenBracket,
    );
  }



  void _showFullscreenBracket() {
    Widget dialog;
    
    switch (_selectedFormat) {
      case 'single_elimination':
        dialog = SingleEliminationFullscreenDialog(playerCount: _selectedPlayerCount);
        break;
      case 'double_elimination':
        // SABO Arena rule: Double Elimination with 32 players uses DE32 format
        if (_selectedPlayerCount == 32) {
          dialog = _buildDE32FullscreenDialog();
        } else {
          () {
          dialog = _buildDoubleEliminationFullscreenDialog();
        }
        
        }break;
      case 'round_robin':
        dialog = RoundRobinFullscreenDialog(playerCount: _selectedPlayerCount);
        break;
      case 'swiss':
        dialog = SwissSystemFullscreenDialog(playerCount: _selectedPlayerCount);
        break;
      default:
        dialog = SingleEliminationFullscreenDialog(playerCount: _selectedPlayerCount);
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => dialog,
    );
  }

  void _showDoubleEliminationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Double Elimination'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hình thức thi đấu loại kép',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '🎯 Nguyên tắc cơ bản:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('• Mỗi người chơi có 2 cơ hội'),
              Text('• Thua 1 lần = rớt xuống Losers Bracket'),
              Text('• Thua 2 lần = bị loại khỏi giải đấu'),
              Text('• Winner WB vs Winner LB ở Grand Final'),
              SizedBox(height: 12),
              Text(
                '🏆 Winners Bracket (WB):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('• Player chưa thua lần nào'),
              Text('• Thua = rớt xuống Losers Bracket'),
              Text('• Thắng = tiến lên vòng tiếp theo'),
              Text('• Winner WB Final vào Grand Final'),
              SizedBox(height: 12),
              Text(
                '⚡ Losers Bracket (LB):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Text('• Player đã thua 1 lần từ WB'),
              Text('• Thua thêm 1 lần = bị loại'),
              Text('• Thắng = có cơ hội phục sinh'),
              Text('• Winner LB Final vào Grand Final'),
              SizedBox(height: 12),
              Text(
                '🏅 Grand Final:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• Winner WB vs Winner LB'),
              Text('• Nếu Winner WB thắng = Vô địch'),
              Text('• Nếu Winner LB thắng = Reset bracket'),
              Text('• Reset bracket = đấu thêm 1 trận'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleEliminationFullscreenDialog() {
    // Use the SAME logic as the main bracket display
    final winnersRounds = TournamentDataGenerator.calculateDoubleEliminationWinners(_selectedPlayerCount);
    final losersRounds = TournamentDataGenerator.calculateDoubleEliminationLosers(_selectedPlayerCount);
    final grandFinalRounds = TournamentDataGenerator.calculateDoubleEliminationGrandFinal(_selectedPlayerCount);
    
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Double Elimination - $_selectedPlayerCount Players'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDoubleEliminationInfo(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Winners Bracket
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.green, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Winners Bracket',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: winnersRounds.map((round) => 
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: RoundColumn(
                                title: round['title'] ?? 'Round',
                                matches: List<Map<String, String>>.from(round['matches'] ?? []),
                                isFullscreen: true,
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Losers Bracket
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.trending_down, color: Colors.orange, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Losers Bracket',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      losersRounds.isNotEmpty 
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: losersRounds.map((round) => 
                                  Container(
                                    margin: const EdgeInsets.only(right: 16),
                                    child: RoundColumn(
                                      title: round['title'] ?? 'Round',
                                      matches: List<Map<String, String>>.from(round['matches'] ?? []),
                                      isFullscreen: true,
                                    ),
                                  ),
                                ).toList(),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(32),
                              child: const Center(
                                child: Text(
                                  'Losers bracket will populate as players are eliminated from Winners Bracket',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                
                // Grand Final
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.purple.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.military_tech, color: Colors.purple, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Grand Final',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: grandFinalRounds.map((round) => 
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              child: RoundColumn(
                                title: round['title'] ?? 'Grand Final',
                                matches: List<Map<String, String>>.from(round['matches'] ?? []),
                                isFullscreen: true,
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDE32FullscreenDialog() {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SABO Double Elimination DE32'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showDE32Info(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament Info
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.workspaces, color: Colors.indigo[700], size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SABO DE32 Two-Group Tournament System',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '32 players • 2 groups of 16 • 55 total matches\n'
                              'Each group: Modified DE16 → 2 qualifiers\n'
                              'Cross-Bracket: 4 qualifiers → 1 champion',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.indigo[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Group A Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GROUP A',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '16 players • 26 matches • Modified DE16 Format',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Structure: Winners Bracket (15 matches) + Losers Bracket (11 matches)\n'
                        'Produces: Group Winner (1st) + Group Runner-up (2nd)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Group B Section
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'GROUP B',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '16 players • 26 matches • Modified DE16 Format',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Structure: Winners Bracket (15 matches) + Losers Bracket (11 matches)\n'
                        'Produces: Group Winner (1st) + Group Runner-up (2nd)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Cross-Bracket Finals Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.purple.withOpacity(0.1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CROSS-BRACKET FINALS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '4 qualifiers • 3 matches (2 Semis + 1 Final)',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bracket Structure:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Semifinal 1: Group A Winner vs Group B Winner\n'
                            '• Semifinal 2: Group A Runner-up vs Group B Runner-up\n'
                            '• DE32 Final: SF1 Winner vs SF2 Winner',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.purple[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDE32Info() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.workspaces, color: Colors.indigo),
            SizedBox(width: 8),
            Text('SABO DE32 Tournament'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SABO Double Elimination DE32',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '🎯 Tournament Structure:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              SizedBox(height: 4),
              Text('• 32 players split into 2 groups (A & B)'),
              Text('• Each group: 16 players, modified DE16 format'),
              Text('• Group matches: 26 per group (52 total)'),
              Text('• Cross-bracket finals: 3 matches'),
              Text('• Total tournament: 55 matches'),
              SizedBox(height: 12),
              Text(
                '🏆 Group Phase:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              Text('• Winners Bracket: 15 matches per group'),
              Text('• Losers Bracket: 11 matches per group'),
              Text('• Each group produces 2 qualifiers'),
              Text('• 1st place: Group Winner'),
              Text('• 2nd place: Group Runner-up'),
              SizedBox(height: 12),
              Text(
                '⚡ Cross-Bracket Finals:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• SF1: Group A Winner vs Group B Winner'),
              Text('• SF2: Group A Runner-up vs Group B Runner-up'),
              Text('• Final: SF1 Winner vs SF2 Winner'),
              Text('• Single elimination format'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }


}

