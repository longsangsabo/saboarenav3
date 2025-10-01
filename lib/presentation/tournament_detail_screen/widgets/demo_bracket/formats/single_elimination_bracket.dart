// 🎯 SABO ARENA - Single Elimination Bracket
// Complete Single Elimination tournament format implementation

import 'package:flutter/material.dart';
import '../components/bracket_components.dart';
import '../shared/tournament_data_generator.dart';

class SingleEliminationBracket extends StatelessWidget {
  const SingleEliminationBracket({super.key});

} 
  final int playerCount;
  final VoidCallback? onFullscreenTap;

  const SingleEliminationBracket({
    super.key,
    required this.playerCount,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = TournamentDataGenerator.calculateSingleEliminationRounds(playerCount);
    debugPrint('🎾 Single Elimination Rounds: ${rounds.length}'); // Debug
    
    return BracketContainer(
      title: 'Single Elimination',
      subtitle: '$playerCount players',
      height: playerCount >= 32 ? 500 : 400, // Dynamic height based on player count
      onFullscreenTap: onFullscreenTap,
      onInfoTap: () => _showSingleEliminationInfo(context),
      child: _buildBracketContent(context, rounds),
    );
  }

  Widget _buildBracketContent(BuildContext context, List<Map<String, dynamic>> rounds) {
    debugPrint('🏗️ Building Single Elimination content with ${rounds.length} rounds'); // Debug
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildRoundsWithConnectors(rounds),
      ),
    );
  }

  List<Widget> _buildRoundsWithConnectors(List<Map<String, dynamic>> rounds) {
    List<Widget> widgets = [];
    
    for (int i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      final isLastRound = i == rounds.length - 1;
      
      // Add round column
      widgets.add(
        RoundColumn(
          title: round['title'],
          matches: round['matches'],
          roundIndex: i,
          totalRounds: rounds.length,
        ),
      );
      
      // Add connector if not the last round
      if (!isLastRound) {
        final nextRound = rounds[i + 1];
        widgets.add(
          BracketConnector(
            fromMatchCount: round['matches'].length,
            toMatchCount: nextRound['matches'].length,
            isLastRound: isLastRound,
          ),
        );
      }
    }
    
    return widgets;
  }

  void _showSingleEliminationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Single Elimination'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hình thức thi đấu loại trực tiếp',
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
              Text('• Mỗi người chơi chỉ được thua 1 lần duy nhất'),
              Text('• Thua 1 trận = bị loại khỏi giải đấu'),
              Text('• Người thắng tiến vào vòng tiếp theo'),
              Text('• Chỉ còn 1 người cuối cùng = Vô địch'),
              SizedBox(height: 12),
              Text(
                '⚡ Đặc điểm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Text('• Nhanh và đơn giản'),
              Text('• Số trận ít nhất'),
              Text('• Không có cơ hội sửa sai'),
              Text('• Tính kịch tính cao'),
              SizedBox(height: 12),
              Text(
                '🏆 Ứng dụng:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• Các giải đấu lớn (World Cup, Olympics)'),
              Text('• Giải đấu có thời gian hạn chế'),
              Text('• Khi cần xác định nhà vô địch nhanh'),
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

// Full screen dialog for Single Elimination
class SingleEliminationFullscreenDialog extends StatelessWidget {
  const SingleEliminationFullscreenDialog({super.key});

} 
  final int playerCount;

  const SingleEliminationFullscreenDialog({
    super.key,
    required this.playerCount,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = TournamentDataGenerator.calculateSingleEliminationRounds(playerCount);
    
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Single Elimination - $playerCount Players'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showSingleEliminationInfo(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: rounds.asMap().entries.map((entry) {
                  final index = entry.key;
                  final round = entry.value;
                  
                  return RoundColumn(
                    title: round['title'],
                    matches: round['matches'],
                    roundIndex: index,
                    totalRounds: rounds.length,
                    isFullscreen: true,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSingleEliminationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Single Elimination'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hình thức thi đấu loại trực tiếp',
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
              Text('• Mỗi người chơi chỉ được thua 1 lần duy nhất'),
              Text('• Thua 1 trận = bị loại khỏi giải đấu'),
              Text('• Người thắng tiến vào vòng tiếp theo'),
              Text('• Chỉ còn 1 người cuối cùng = Vô địch'),
              SizedBox(height: 12),
              Text(
                '⚡ Đặc điểm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Text('• Nhanh và đơn giản'),
              Text('• Số trận ít nhất'),
              Text('• Không có cơ hội sửa sai'),
              Text('• Tính kịch tính cao'),
              SizedBox(height: 12),
              Text(
                '🏆 Ứng dụng:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• Các giải đấu lớn (World Cup, Olympics)'),
              Text('• Giải đấu có thời gian hạn chế'),
              Text('• Khi cần xác định nhà vô địch nhanh'),
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
