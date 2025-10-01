// 🎯 SABO ARENA - Double Elimination Bracket
// Complete Double Elimination tournament format implementation

import 'package:flutter/material.dart';
import '../components/bracket_components.dart';
import '../shared/tournament_data_generator.dart';

class DoubleEliminationBracket extends StatelessWidget {
  const DoubleEliminationBracket({super.key});

} 
  final int playerCount;
  final VoidCallback? onFullscreenTap;

  const DoubleEliminationBracket({
    super.key,
    required this.playerCount,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return BracketContainer(
      title: 'Double Elimination',
      subtitle: '$playerCount players',
      height: 650, // Increased height for losers bracket info
      onFullscreenTap: onFullscreenTap,
      onInfoTap: () => _showDoubleEliminationInfo(context),
      child: _buildBracketContent(context),
    );
  }

  Widget _buildBracketContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWinnersBracket(),
          const SizedBox(height: 20),
          _buildLosersBracket(),
          const SizedBox(height: 20),
          _buildGrandFinal(),
        ],
      ),
    );
  }

  Widget _buildWinnersBracket() {
    final winnersRounds = TournamentDataGenerator.calculateDoubleEliminationWinners(playerCount);
    debugPrint('🏆 Double Elimination Winners Rounds: ${winnersRounds.length}'); // Debug
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏆 Winners Bracket',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detailed info about Winners Bracket logic
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Winners Bracket Logic',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Single elimination format\n• Losers drop to Losers Bracket (second chance)\n• Winner advances to Grand Final',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRoundsWithConnectors(winnersRounds),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLosersBracket() {
    final losersRounds = TournamentDataGenerator.calculateDoubleEliminationLosers(playerCount);
    debugPrint('🔥 Double Elimination Losers Rounds: ${losersRounds.length}'); // Debug
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🔥 Losers Bracket',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detailed info about Losers Bracket logic
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Losers Bracket Complex Logic',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• LB R1: WB R1 losers compete (${playerCount == 8 ? "4→2" : "8→4"} survivors)\n• LB R2: LB R1 winners vs WB R2 losers (mixed round)\n• LB R3+: Advancement rounds until 1 survivor\n• Winner faces WB Champion in Grand Final',
                style: TextStyle(
                  color: Colors.orange.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220, // Increased height for better visibility
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRoundsWithConnectors(losersRounds),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrandFinal() {
    final grandFinalRounds = TournamentDataGenerator.calculateDoubleEliminationGrandFinal(playerCount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏅 Grand Final',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detailed Grand Final info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.purple.shade700, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Grand Final Rules',
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '• Winners Bracket Champion vs Losers Bracket Champion\n• If LB Champion wins: Bracket Reset (both have 1 loss)\n• If WB Champion wins: Tournament ends (LB had 2 losses)',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildRoundsWithConnectors(grandFinalRounds),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to build rounds with connectors
  List<Widget> _buildRoundsWithConnectors(List<Map<String, dynamic>> rounds) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final isLastRound = i == rounds.length - 1;
      
      // Add round column
      widgets.add(
        Container(
          width: 120,
          margin: const EdgeInsets.only(right: 4),
          child: RoundColumn(
            title: round['title'] ?? 'Round',
            matches: List<Map<String, String>>.from(round['matches'] ?? []),
            isFullscreen: false,
          ),
        ),
      );
      
      // Add connector if not the last round
      if (!isLastRound && i < rounds.length - 1) {
        final nextRound = rounds[i + 1];
        widgets.add(
          BracketConnector(
            fromMatchCount: (round['matches'] as List).length,
            toMatchCount: (nextRound['matches'] as List).length,
            isLastRound: isLastRound,
          ),
        );
      }
    }
    
    return widgets;
  }

  void _showDoubleEliminationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_tree, color: Colors.purple),
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
                'Hệ thống thi đấu loại kép',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text('🏆 Winners Bracket:'),
              Text('• Tất cả players bắt đầu ở đây'),
              Text('• Thua 1 trận → rơi xuống Losers Bracket'),
              Text('• Winner WB Final → Grand Final'),
              SizedBox(height: 8),
              Text('🔥 Losers Bracket:'),
              Text('• Nhận players bị loại từ Winners Bracket'),
              Text('• Cơ chế loại trực tiếp (thua là bye)'),
              Text('• Winner LB Final → Grand Final'),
              SizedBox(height: 8),
              Text('🏅 Grand Final:'),
              Text('• Winner WB vs Winner LB'),
              Text('• Nếu Winner LB thắng → bracket reset'),
              Text('• Winner WB cần thua 2 trận mới bị loại'),
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
