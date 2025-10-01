import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../routes/app_routes.dart';

class PlayerWelcomeGuide extends StatefulWidget {
  const PlayerWelcomeGuide({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const PlayerWelcomeGuide({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  State<PlayerWelcomeGuide> createState() => _PlayerWelcomeGuideState();
}

class _PlayerWelcomeGuideState extends State<PlayerWelcomeGuide> {
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
      route: AppRoutes.findOpponentsScreen,
    ),
    GuideItem(
      icon: Icons.military_tech,
      title: 'Đăng ký hạng thi đấu',
      description: 'Xác minh trình độ để tham gia giải đấu chính thức\n👤 Hồ sơ cá nhân → Xếp hạng',
      actionText: 'Đăng ký hạng',
      color: Colors.purple,
      action: 'register_rank',
    ),
    GuideItem(
      icon: Icons.emoji_events,
      title: 'Tham gia giải đấu',
      description: 'Thử thách bản thân trong các giải đấu hấp dẫn\n🏆 Giải đấu → Tìm giải phù hợp',
      actionText: 'Xem giải đấu',
      color: Colors.orange,
      route: AppRoutes.tournamentListScreen,
    ),
    GuideItem(
      icon: Icons.location_on,
      title: 'Tìm câu lạc bộ',
      description: 'Khám phá các CLB bida gần bạn\n🏢 Menu → Danh sách CLB',
      actionText: 'Khám phá CLB',
      color: Colors.teal,
      action: 'find_clubs',
    ),
    GuideItem(
      icon: Icons.forum,
      title: 'Chia sẻ & kết nối',
      description: 'Đăng bài, chia sẻ kinh nghiệm và kết nối cộng đồng\n📝 Trang chủ → Tạo bài viết',
      actionText: 'Tạo bài viết',
      color: Colors.indigo,
      action: 'create_post',
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
                padding: EdgeInsets.all(4.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hướng dẫn nhanh',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Bỏ qua',
                        style: TextStyle(
                          fontSize: 14.sp,
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
                margin: EdgeInsets.symmetric(horizontal: 8.w),
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
                padding: EdgeInsets.all(6.w),
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
                    if (_currentPage > 0) SizedBox(width: 4.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleActionButton,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _guideItems[_currentPage].color,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentPage == _guideItems.length - 1
                              ? 'Hoàn thành'
                              : _guideItems[_currentPage].actionText,
                          style: TextStyle(
                            fontSize: 16.sp,
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
      padding: EdgeInsets.all(8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 25.w,
            height: 25.w,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 12.w,
              color: item.color,
            ),
          ),
          
          SizedBox(height: 4.h),
          
          // Title
          Text(
            item.title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 3.h),
          
          // Description
          Text(
            item.description,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  void _handleActionButton() {
    final currentItem = _guideItems[_currentPage];
    
    if (_currentPage == _guideItems.length - 1) {
      // Last page - complete guide
      Navigator.of(context).pop();
      return;
    }
    
    // Handle specific actions
    if (currentItem.route != null) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed(currentItem.route!);
      return;
    }
    
    if (currentItem.action != null) {
      Navigator.of(context).pop();
      _handleSpecialAction(currentItem.action!);
      return;
    }
    
    // Default: go to next page
    _pageController.nextPage(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleSpecialAction(String action) {
    switch (action) {
      case 'register_rank':
        // Navigate to profile and show rank registration
        Navigator.of(context).pushNamed(AppRoutes.userProfileScreen);
        // TODO: Add logic to show rank registration modal
        break;
      case 'find_clubs':
        // TODO: Navigate to club list screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tính năng đang phát triển - Danh sách CLB')),
        );
        break;
      case 'create_post':
        // Navigate back to home and show create post modal
        Navigator.of(context).pushNamed(AppRoutes.homeFeedScreen);
        // TODO: Add logic to show create post modal
        break;
    }
  }
}

class GuideItem {
  final IconData icon;
  final String title;
  final String description;
  final String actionText;
  final Color color;
  final String? route;
  final String? action;

  GuideItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionText,
    required this.color,
    this.route,
    this.action,
  });
}