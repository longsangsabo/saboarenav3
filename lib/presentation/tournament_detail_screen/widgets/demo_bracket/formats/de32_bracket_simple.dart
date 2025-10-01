import 'package:flutter/material.dart';

// 🎯 DE32 Tournament Bracket - Clean & Simple Version
class DE32Bracket extends StatefulWidget {
  const DE32Bracket({super.key});

@override
  State<DE32Bracket> createState() => _DE32BracketState();
}

class _DE32BracketState extends State<DE32Bracket> with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    
    // Sync tab and page controller
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.indigo[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giải Đấu DE32',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                    Text(
                      '32 người • 55 trận đấu',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Bảng A'),
              Tab(text: 'Bảng B'),
              Tab(text: 'Chung Kết Liên Bảng'),
            ],
            indicator: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Page View
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              _tabController.animateTo(index);
            },
            children: const [
              DE32GroupPage(groupName: 'A', color: Colors.blue),
              DE32GroupPage(groupName: 'B', color: Colors.green),
              DE32CrossBracketPage(),
            ],
          ),
        ),
      ],
    );
  }
}

// 📋 Group Page - Simple group bracket display
class DE32GroupPage extends StatelessWidget {
  const DE32GroupPage({super.key});

} 
  final String groupName;
  final Color color;

  const DE32GroupPage({
    super.key,
    required this.groupName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Group Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.group, color: color, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Bảng $groupName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '16 người thi đấu',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Simple bracket display
          _buildSimpleBracket(),
          
          const SizedBox(height: 20),
          
          // Group Winner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[400]!, Colors.amber[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhất Bảng $groupName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Đại diện vào Chung Kết Liên Bảng',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBracket() {
    return Column(
      children: [
        // Round 1
        _buildRound('Vòng 1 (8 trận)', 8, 'P$groupName'),
        const SizedBox(height: 16),
        
        // Round 2
        _buildRound('Vòng 2 (4 trận)', 4, 'Thắng'),
        const SizedBox(height: 16),
        
        // Semifinals
        _buildRound('Bán Kết (2 trận)', 2, 'Thắng BK'),
        const SizedBox(height: 16),
        
        // Final
        _buildRound('Chung Kết Bảng', 1, 'Thắng CK'),
      ],
    );
  }

  Widget _buildRound(String title, int matchCount, String playerPrefix) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            matchCount,
            (i) => _buildSimpleMatch('$playerPrefix${i + 1}', '$playerPrefix${i + 2}'),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMatch(String player1, String player2) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            player1,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Text('vs', style: TextStyle(fontSize: 8, color: Colors.grey)),
          ),
          Text(
            player2,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// 🏅 Cross Bracket Page - Finals page
class DE32CrossBracketPage extends StatelessWidget {
  const DE32CrossBracketPage({super.key});

} 
  const DE32CrossBracketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Finals Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.withOpacity(0.1), Colors.purple.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.military_tech, color: Colors.purple[700], size: 40),
                const SizedBox(height: 12),
                Text(
                  'Chung Kết Liên Bảng',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
                Text(
                  '4 đại diện xuất sắc nhất',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Finals Bracket
          Column(
            children: [
              Text(
                'Sơ Đồ Chung Kết',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 20),
              
              // Semifinals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFinalMatch('BK1', 'Nhất A', 'Nhì B'),
                  _buildFinalMatch('BK2', 'Nhất B', 'Nhì A'),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Arrow to final
              Icon(Icons.keyboard_arrow_down, color: Colors.purple, size: 40),
              
              const SizedBox(height: 20),
              
              // Final
              _buildFinalMatch('CK', 'Thắng BK1', 'Thắng BK2'),
              
              const SizedBox(height: 32),
              
              // Champion
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[400]!, Colors.amber[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      '🏆 VÔ ĐỊCH DE32',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Người chiến thắng cuối cùng',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalMatch(String matchId, String player1, String player2) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              matchId,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player1,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('vs', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
          Text(
            player2,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

