import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget() {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Player Welcome Guide Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget() {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Player Welcome Guide'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => const PlayerWelcomeGuideSimple(),
            );
          },
          child: Text('Show Player Welcome Guide'),
        ),
      ),
    );
  }
}

class PlayerWelcomeGuideSimple extends StatefulWidget() {
  const PlayerWelcomeGuideSimple({Key? key}) : super(key: key);

  @override
  State<PlayerWelcomeGuideSimple> createState() => _PlayerWelcomeGuideSimpleState();
}

class _PlayerWelcomeGuideSimpleState extends State<PlayerWelcomeGuideSimple> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<GuideItem> _guideItems = [
    GuideItem(
      icon: Icons.sports_handball,
      title: 'Chào mừng đến với SABO!',
      description: 'Nền tảng bida số 1 Việt Nam\nKết nối cộng đồng yêu bida',
      actionText: 'Bắt đầu khám phá',
      color: Colors.blue,
    ),
    GuideItem(
      icon: Icons.group_add,
      title: 'Tìm bạn chơi bida',
      description: 'Kết nối với những người chơi cùng trình độ\n📍 Trang chủ → Tìm đối thủ',
      actionText: 'Tìm đối thủ ngay',
      color: Colors.green,
    ),
    GuideItem(
      icon: Icons.military_tech,
      title: 'Đăng ký hạng thi đấu',
      description: 'Xác minh trình độ để tham gia giải đấu chính thức\n👤 Hồ sơ cá nhân → Xếp hạng',
      actionText: 'Đăng ký hạng',
      color: Colors.purple,
    ),
    GuideItem(
      icon: Icons.emoji_events,
      title: 'Tham gia giải đấu',
      description: 'Thử thách bản thân trong các giải đấu hấp dẫn\n🏆 Giải đấu → Tìm giải phù hợp',
      actionText: 'Xem giải đấu',
      color: Colors.orange,
    ),
    GuideItem(
      icon: Icons.location_on,
      title: 'Tìm câu lạc bộ',
      description: 'Khám phá các CLB bida gần bạn\n🏢 Menu → Danh sách CLB',
      actionText: 'Khám phá CLB',
      color: Colors.teal,
    ),
    GuideItem(
      icon: Icons.forum,
      title: 'Chia sẻ & kết nối',
      description: 'Đăng bài, chia sẻ kinh nghiệm và kết nối cộng đồng\n📝 Trang chủ → Tạo bài viết',
      actionText: 'Tạo bài viết',
      color: Colors.indigo,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header with skip button
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hướng dẫn nhanh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Bỏ qua',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page indicator
              Container(
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: List.generate(
                    _guideItems.length,
                    (index) => Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: index <= _currentPage 
                              ? _guideItems[_currentPage].color
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _guideItems.length,
                  itemBuilder: (context, index) {
                    final item = _guideItems[index];
                    return _buildGuidePage(item);
                  },
                ),
              ),
              
              // Navigation buttons
              Padding(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text('Quay lại'),
                        ),
                      ),
                    if (_currentPage > 0) SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleActionButton,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _guideItems[_currentPage].color,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == _guideItems.length - 1
                              ? 'Hoàn thành'
                              : _guideItems[_currentPage].actionText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidePage(GuideItem item) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 48,
              color: item.color,
            ),
          ),
          
          SizedBox(height: 32),
          
          // Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 24),
          
          // Description
          Text(
            item.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _handleActionButton() {
    if (_currentPage == _guideItems.length - 1) {
      // Last page - complete guide
      Navigator.of(context).pop();
      return;
    }
    
    // Default: go to next page
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class GuideItem() {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final Color color;

  GuideItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.color,
  });
}