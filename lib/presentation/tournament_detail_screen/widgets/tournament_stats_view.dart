import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TournamentStatsView extends StatefulWidget() {
  final String tournamentId;
  final String tournamentStatus;

  const TournamentStatsView({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
  });

  @override
  _TournamentStatsViewState createState() => _TournamentStatsViewState();
}

class _TournamentStatsViewState extends State<TournamentStatsView>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardAnimations = List.generate(6, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          0.6 + (index * 0.1),
          curve: Curves.easeInOut,
        ),
      ));
    });

    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async() {
    // Simulate loading
    await Future.delayed(Duration(milliseconds: 800));
    
    setState(() {
      _stats = _generateMockStats();
      _isLoading = false;
    });
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.w)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildStatsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[600] ?? Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Thống kê giải đấu",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900] ?? Colors.black,
                  ),
                ),
                Text(
                  "Chi tiết và phân tích dữ liệu",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600] ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.grey[600] ?? Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.grey[600] ?? Colors.grey),
          SizedBox(height: 16.w),
          Text(
            "Đang tải thống kê...",
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600] ?? Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildOverviewCards(),
          SizedBox(height: 24.w),
          _buildProgressChart(),
          SizedBox(height: 24.w),
          _buildParticipationAnalysis(),
          SizedBox(height: 24.w),
          _buildMatchStatistics(),
          SizedBox(height: 24.w),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final overviewData = [
      {
        "title": 'Tổng người chơi',
        'value': _stats['total_participants']?.toString() ?? '0',
        "subtitle": 'Đã đăng ký',
        'icon': Icons.people,
        'color': Colors.grey[600] ?? Colors.grey,
      },
      {
        "title": 'Tỷ lệ hoàn thành',
        "value": '${_stats['completion_rate'] ?? 0}%',
        "subtitle": 'Trận đấu',
        'icon': Icons.pie_chart,
        'color': Colors.grey[600] ?? Colors.grey,
      },
      {
        "title": 'Trận đấu',
        "value": '${_stats['completed_matches']}/${_stats['total_matches']}',
        "subtitle": 'Hoàn thành',
        'icon': Icons.sports_tennis,
        'color': Colors.grey[600] ?? Colors.grey,
      },
    ];

    return Row(
      children: overviewData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        return Expanded(
          child: AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[index].value,
                child: Container(
                  margin: EdgeInsets.only(right: index < 2 ? 8.w : 0),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        data['color'] as Color,
                        (data['color'] as Color).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.w),
                    boxShadow: [
                      BoxShadow(
                        color: (data['color'] as Color).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        data['icon'] as IconData,
                        color: Colors.white.withOpacity(0.8),
                        size: 20.sp,
                      ),
                      SizedBox(height: 8.w),
                      
                      Text(
                        data['value'] as String,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      Text(
                        data['title'] as String,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      Text(
                        data['subtitle'] as String,
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressChart() {
    return AnimatedBuilder(
      animation: _cardAnimations[3],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimations[3].value)),
          child: Opacity(
            opacity: _cardAnimations[3].value,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: Colors.grey[600] ?? Colors.grey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[600] ?? Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.grey[600] ?? Colors.grey, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Tiến độ giải đấu",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900] ?? Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.w),
                  
                  // Progress timeline
                  Column(
                    children: _getProgressSteps().asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final isCompleted = step['completed'] as bool;
                      final isCurrent = step['current'] as bool;
                      
                      return Row(
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 20.w,
                                height: 20.w,
                                decoration: BoxDecoration(
                                  color: isCompleted 
                                    ? Colors.grey[600] ?? Colors.grey 
                                    : (isCurrent ? Colors.grey[600] ?? Colors.grey : Colors.grey[600] ?? Colors.grey),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCompleted ? Icons.check : Icons.circle,
                                  size: 12.sp,
                                  color: Colors.white,
                                ),
                              ),
                              
                              if (index < _getProgressSteps().length - 1)
                                Container(
                                  width: 2.w,
                                  height: 30.w,
                                  color: isCompleted ? Colors.grey[600] ?? Colors.grey : Colors.grey[600] ?? Colors.grey,
                                ),
                            ],
                          ),
                          
                          SizedBox(width: 12.w),
                          
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted || isCurrent 
                                        ? Colors.grey[900] ?? Colors.black 
                                        : Colors.grey[600] ?? Colors.grey,
                                    ),
                                  ),
                                  
                                  Text(
                                    step['subtitle'] as String,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600] ?? Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          if (step['date'] != null)
                            Text(
                              step['date'] as String,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600] ?? Colors.grey,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticipationAnalysis() {
    return AnimatedBuilder(
      animation: _cardAnimations[4],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimations[4].value)),
          child: Opacity(
            opacity: _cardAnimations[4].value,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: Colors.grey[600] ?? Colors.grey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[600] ?? Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.grey[600] ?? Colors.grey, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Phân tích tham gia",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900] ?? Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.w),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalysisItem(
                          "Theo rank",
                          _getRankDistribution(),
                          Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                      
                      SizedBox(width: 16.w),
                      
                      Expanded(
                        child: _buildAnalysisItem(
                          "Theo club",
                          _getClubDistribution(),
                          Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisItem(String title, List<Map<String, dynamic>> data, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600] ?? Colors.grey,
          ),
        ),
        
        SizedBox(height: 8.w),
        
        ...data.map((item) => Container(
          margin: EdgeInsets.only(bottom: 4.w),
          child: Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              
              SizedBox(width: 6.w),
              
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600] ?? Colors.grey,
                  ),
                ),
              ),
              
              Text(
                "${item['count']}",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMatchStatistics() {
    return AnimatedBuilder(
      animation: _cardAnimations[5],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimations[5].value)),
          child: Opacity(
            opacity: _cardAnimations[5].value,
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(color: Colors.grey[600] ?? Colors.grey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey[600] ?? Colors.grey.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sports_score, color: Colors.grey[600] ?? Colors.grey, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Thống kê trận đấu",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900] ?? Colors.black,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.w),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          "Trung bình",
                          "${_stats['avg_match_duration']} phút",
                          "Thời gian/trận",
                          Icons.timer,
                          Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                      
                      Expanded(
                        child: _buildStatItem(
                          "Tỷ số cao nhất",
                          _stats['highest_score']?.toString() ?? "3-0",
                          "Trong giải",
                          Icons.trending_up,
                          Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12.w),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          "Trận kịch tính",
                          "${_stats['close_matches']}",
                          "Hiệp phụ/Deuce",
                          Icons.flash_on,
                          Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                      
                      Expanded(
                        child: _buildStatItem(
                          "Thắng nhanh",
                          "${_stats['quick_wins']}",
                          "< 15 phút",
                          Icons.speed,
                          Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String value, String subtitle, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.only(right: 8.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.w),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 4.w),
          
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600] ?? Colors.grey,
            ),
          ),
          
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.grey[600] ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    final topPerformers = _getTopPerformers();
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[600] ?? Colors.grey.withOpacity(0.1), Colors.grey[600] ?? Colors.grey.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.w),
        border: Border.all(color: Colors.grey[600] ?? Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.grey[600] ?? Colors.grey, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                "Thành tích xuất sắc",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900] ?? Colors.black,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.w),
          
          ...topPerformers.asMap().entries.map((entry) {
            final index = entry.key;
            final performer = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: 8.w),
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8.w),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: _getRankColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  CircleAvatar(
                    radius: 16.sp,
                    backgroundImage: NetworkImage(performer['avatar'] as String),
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          performer['name'] as String,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900] ?? Colors.black,
                          ),
                        ),
                        
                        Text(
                          performer['achievement'] as String,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600] ?? Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text(
                    performer['stat'] as String,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: _getRankColor(index),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0: return Colors.grey[600] ?? Colors.grey; // Gold
      case 1: return Colors.grey[600] ?? Colors.grey;  // Silver
      case 2: return Colors.grey[600] ?? Colors.grey; // Bronze
      default: return Colors.grey[600] ?? Colors.grey;
    }
  }

  Map<String, dynamic> _generateMockStats() {
    return() {
      'total_participants': 18,
      'completion_rate': 65,
      'completed_matches': 11,
      'total_matches': 17,
      'avg_match_duration': 22,
      "highest_score": '3-0',
      'close_matches': 4,
      'quick_wins': 2,
    };
  }

  List<Map<String, dynamic>> _getProgressSteps() {
    return [
      {
        "title": 'Mở đăng ký',
        "subtitle": 'Bắt đầu nhận đăng ký từ người chơi',
        'completed': true,
        'current': false,
        "date": '10/01',
      },
      {
        "title": 'Đóng đăng ký',
        "subtitle": 'Hoàn thành việc tuyển chọn người chơi',
        'completed': true,
        'current': false,
        "date": '15/01',
      },
      {
        "title": 'Vòng bảng',
        "subtitle": 'Đang diễn ra các trận đấu vòng bảng',
        'completed': false,
        'current': true,
        'date': null,
      },
      {
        "title": 'Vòng loại trực tiếp',
        "subtitle": 'Tứ kết, bán kết và chung kết',
        'completed': false,
        'current': false,
        'date': null,
      },
      {
        "title": 'Trao giải',
        "subtitle": 'Lễ trao giải và kết thúc giải đấu',
        'completed': false,
        'current': false,
        'date': null,
      },
    ];
  }

  List<Map<String, dynamic>> _getRankDistribution() {
    return [
      {"label": 'Dưới 1000', 'count': 3},
      {"label": '1000-1500', 'count': 8},
      {"label": '1500-2000', 'count': 5},
      {"label": 'Trên 2000', 'count': 2},
    ];
  }

  List<Map<String, dynamic>> _getClubDistribution() {
    return [
      {"label": 'Saigon PP', 'count': 8},
      {"label": 'Hanoi TT', 'count': 5},
      {"label": 'Da Nang Sports', 'count': 3},
      {"label": 'Cá nhân', 'count': 2},
    ];
  }

  List<Map<String, dynamic>> _getTopPerformers() {
    return [
      {
        "name": 'Player 1',
        "achievement": 'Tỷ lệ thắng cao nhất',
        "stat": '100%',
        "avatar": 'https://images.unsplash.com/photo-1580000000001?w=100&h=100&fit=crop&crop=face',
      },
      {
        "name": 'Lê Văn B',
        "achievement": 'Nhiều trận thắng nhất',
        "stat": '8 trận',
        "avatar": 'https://images.unsplash.com/photo-1580000000002?w=100&h=100&fit=crop&crop=face',
      },
      {
        "name": 'Trần Văn C',
        "achievement": 'Trận đấu nhanh nhất',
        "stat": '12 phút',
        "avatar": 'https://images.unsplash.com/photo-1580000000003?w=100&h=100&fit=crop&crop=face',
      },
    ];
  }
}
