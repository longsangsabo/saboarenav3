// 🎯 SABO ARENA - Swiss System Bracket
// Complete Swiss System tournament format implementation

import 'package:flutter/material.dart';
import '../components/bracket_components.dart';
import '../shared/tournament_data_generator.dart';

class SwissSystemBracket extends StatelessWidget() {
  final int playerCount;
  final VoidCallback? onFullscreenTap;

  const SwissSystemBracket({
    super.key,
    required this.playerCount,
    this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return BracketContainer(
      title: 'Swiss System',
      subtitle: '$playerCount players',
      onFullscreenTap: onFullscreenTap,
      onInfoTap: () => _showSwissSystemInfo(context),
      child: _buildBracketContent(context),
    );
  }

  Widget _buildBracketContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentStandings(),
          const SizedBox(height: 30),
          _buildRounds(),
        ],
      ),
    );
  }

  Widget _buildCurrentStandings() {
    final standings = TournamentDataGenerator.generateSwissStandings(playerCount);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '🏆 Bảng xếp hạng Swiss',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
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
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 40, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 3, child: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('Điểm', style: TextStyle(fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('Tiebreak', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              // Standings rows
              ...standings.map((standing) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRankColor(standing['rank']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${standing['rank']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        standing['name'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${standing['points']}',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${standing['tiebreak']}',
                        style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRounds() {
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
            '⚔️ Vòng đấu Swiss',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSwissRound(1),
                const SizedBox(width: 20),
                _buildSwissRound(2),
                const SizedBox(width: 20),
                _buildSwissRound(3),
                const SizedBox(width: 20),
                _buildSwissRound(4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwissRound(int roundNumber) {
    final matches = TournamentDataGenerator.generateSwissRoundMatches(roundNumber, playerCount);
    
    return RoundColumn(
      title: 'Vòng $roundNumber',
      matches: matches,
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.grey.shade500; // Silver
      case 3:
        return Colors.orange.shade700; // Bronze
      default:
        return Colors.deepPurple.shade400; // Regular
    }
  }

  void _showSwissSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Swiss System'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hệ thống Swiss Tournament',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '🧩 Nguyên tắc cơ bản:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 4),
              Text('• Số vòng cố định (thường log₂(n))'),
              Text('• Ghép cặp dựa trên điểm hiện tại'),
              Text('• Không loại ai trong quá trình'),
              Text('• Xếp hạng cuối theo điểm tích lũy'),
              SizedBox(height: 12),
              Text(
                '⚖️ Ghép cặp:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              Text('• Vòng 1: Ghép ngẫu nhiên hoặc seed'),
              Text('• Vòng 2+: Ghép theo điểm tương đương'),
              Text('• Tránh đấu lại người cũ'),
              Text('• Cân bằng màu/side nếu có'),
              SizedBox(height: 12),
              Text(
                '📊 Tính điểm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 4),
              Text('• Thắng = 1 điểm'),
              Text('• Hòa = 0.5 điểm'),
              Text('• Thua = 0 điểm'),
              Text('• Tiebreak: Buchholz, SB, etc.'),
              SizedBox(height: 12),
              Text(
                '⚡ Đặc điểm:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 4),
              Text('• Cân bằng giữa công bằng và hiệu quả'),
              Text('• Phù hợp với giải lớn'),
              Text('• Thời gian khả thi'),
              Text('• Đối thủ có trình độ tương đương'),
              SizedBox(height: 12),
              Text(
                '🏆 Ứng dụng:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 4),
              Text('• Giải cờ vua quốc tế'),
              Text('• Pokemon TCG Championships'),
              Text('• Magic: The Gathering'),
              Text('• Esports tournaments'),
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

// Full screen dialog for Swiss System
class SwissSystemFullscreenDialog extends StatelessWidget() {
  final int playerCount;

  const SwissSystemFullscreenDialog({
    super.key,
    required this.playerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Swiss System - $playerCount Players'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showSwissSystemInfo(context),
            ),
          ],
        ),
        body: SwissSystemBracket(playerCount: playerCount),
      ),
    );
  }

  void _showSwissSystemInfo(BuildContext context) {
    // Same info dialog as above
  }
}