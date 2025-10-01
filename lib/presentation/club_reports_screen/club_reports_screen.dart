import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class ClubReportsScreen extends StatefulWidget {
  const ClubReportsScreen({super.key});

} 
  final String clubId;

  const ClubReportsScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubReportsScreen> createState() => _ClubReportsScreenState();
}

class _ClubReportsScreenState extends State<ClubReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Báo cáo & Phân tích'),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Period Filter
          _buildPeriodFilter(),
          
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryLight,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryLight,
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Doanh thu'),
                Tab(text: 'Thành viên'),
                Tab(text: 'Hoạt động'),
              ],
            ),
          ),
          
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewReport(),
                _buildRevenueReport(),
                _buildMemberReport(),
                _buildActivityReport(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Text(
            'Thời gian:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                _buildPeriodChip('week', 'Tuần'),
                const SizedBox(width: 8),
                _buildPeriodChip('month', 'Tháng'),
                const SizedBox(width: 8),
                _buildPeriodChip('quarter', 'Quý'),
                const SizedBox(width: 8),
                _buildPeriodChip('year', 'Năm'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = value;
        });
      },
      selectedColor: AppTheme.primaryLight.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryLight,
    );
  }

  Widget _buildOverviewReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          
          // Performance Chart
          _buildPerformanceChart(),
          const SizedBox(height: 24),
          
          // Top Performers
          _buildTopPerformers(),
          const SizedBox(height: 24),
          
          // Recent Trends
          _buildRecentTrends(),
        ],
      ),
    );
  }

  Widget _buildRevenueReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Summary
          _buildRevenueCards(),
          const SizedBox(height: 24),
          
          // Revenue Chart
          _buildRevenueChart(),
          const SizedBox(height: 24),
          
          // Revenue Sources
          _buildRevenueSources(),
          const SizedBox(height: 24),
          
          // Payment Methods
          _buildPaymentMethods(),
        ],
      ),
    );
  }

  Widget _buildMemberReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member Stats
          _buildMemberStats(),
          const SizedBox(height: 24),
          
          // Growth Chart
          _buildMemberGrowthChart(),
          const SizedBox(height: 24),
          
          // Member Activity
          _buildMemberActivity(),
          const SizedBox(height: 24),
          
          // Retention Rate
          _buildRetentionRate(),
        ],
      ),
    );
  }

  Widget _buildActivityReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Activity Summary
          _buildActivitySummary(),
          const SizedBox(height: 24),
          
          // Popular Times
          _buildPopularTimes(),
          const SizedBox(height: 24),
          
          // Equipment Usage
          _buildEquipmentUsage(),
          const SizedBox(height: 24),
          
          // Event Statistics
          _buildEventStatistics(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMetricCard('Tổng doanh thu', '15.5M VND', Icons.monetization_on, AppTheme.successLight, '+12%'),
        _buildMetricCard('Thành viên mới', '25', Icons.person_add, AppTheme.primaryLight, '+5%'),
        _buildMetricCard('Giải đấu', '3', Icons.emoji_events, AppTheme.accentLight, '+1'),
        _buildMetricCard('Tỷ lệ hoạt động', '78%', Icons.trending_up, AppTheme.warningLight, '+3%'),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return _buildChartCard(
      'Hiệu suất tổng quan',
      'Biểu đồ hiệu suất sẽ được hiển thị ở đây',
      Icons.show_chart,
    );
  }

  Widget _buildRevenueCards() {
    return Row(
      children: [
        Expanded(
          child: _buildRevenueCard('Doanh thu hôm nay', '850K VND', AppTheme.successLight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRevenueCard('Doanh thu tháng', '15.5M VND', AppTheme.primaryLight),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return _buildChartCard(
      'Biểu đồ doanh thu',
      'Biểu đồ doanh thu theo thời gian sẽ được hiển thị ở đây',
      Icons.bar_chart,
    );
  }

  Widget _buildRevenueSources() {
    return _buildListCard(
      'Nguồn doanh thu',
      [
        {"title": 'Phí thành viên', "value": '45%', "amount": '6.9M VND'},
        {"title": 'Thuê sân', "value": '35%', "amount": '5.4M VND'},
        {"title": 'Giải đấu', "value": '15%', "amount": '2.3M VND'},
        {"title": 'Khác', "value": '5%', "amount": '0.9M VND'},
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return _buildListCard(
      'Phương thức thanh toán',
      [
        {"title": 'Chuyển khoản', "value": '60%', "amount": '9.3M VND'},
        {"title": 'Tiền mặt', "value": '25%', "amount": '3.9M VND'},
        {"title": 'Ví điện tử', "value": '15%', "amount": '2.3M VND'},
      ],
    );
  }

  Widget _buildMemberStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard('Tổng TV', '150', AppTheme.primaryLight),
        _buildStatCard('TV mới', '25', AppTheme.successLight),
        _buildStatCard('TV hoạt động', '118', AppTheme.accentLight),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMemberGrowthChart() {
    return _buildChartCard(
      'Tăng trưởng thành viên',
      'Biểu đồ tăng trưởng thành viên sẽ được hiển thị ở đây',
      Icons.trending_up,
    );
  }

  Widget _buildMemberActivity() {
    return _buildListCard(
      'Hoạt động thành viên',
      [
        {"title": 'Thành viên tích cực', "value": '78%', "amount": '118 người'},
        {"title": 'Thành viên bình thường', "value": '15%', "amount": '23 người'},
        {"title": 'Thành viên ít hoạt động', "value": '7%', "amount": '9 người'},
      ],
    );
  }

  Widget _buildRetentionRate() {
    return _buildChartCard(
      'Tỷ lệ giữ chân thành viên',
      'Biểu đồ tỷ lệ giữ chân thành viên sẽ được hiển thị ở đây',
      Icons.people_outline,
    );
  }

  Widget _buildActivitySummary() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildActivityCard('Giờ cao điểm', '18:00-21:00', Icons.access_time),
        _buildActivityCard('Sân được dùng nhiều', 'Sân số 2', Icons.sports_tennis),
      ],
    );
  }

  Widget _buildActivityCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryLight, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularTimes() {
    return _buildChartCard(
      'Giờ hoạt động phổ biến',
      'Biểu đồ giờ hoạt động sẽ được hiển thị ở đây',
      Icons.schedule,
    );
  }

  Widget _buildEquipmentUsage() {
    return _buildListCard(
      'Sử dụng thiết bị',
      [
        {"title": 'Sân cầu lông', "value": '85%', "amount": '120 giờ'},
        {"title": 'Vợt cho thuê', "value": '60%', "amount": '45 lượt'},
        {"title": 'Shuttle cock', "value": '95%', "amount": '200 quả'},
      ],
    );
  }

  Widget _buildEventStatistics() {
    return _buildListCard(
      'Thống kê sự kiện',
      [
        {"title": 'Giải đấu tháng này', "value": '3', "amount": '45 người tham gia'},
        {"title": 'Lớp học', "value": '8', "amount": '25 học viên'},
        {"title": 'Sự kiện đặc biệt', "value": '2', "amount": '60 người tham gia'},
      ],
    );
  }

  Widget _buildTopPerformers() {
    return _buildListCard(
      'Top thành viên tích cực',
      [
        {"title": 'Nguyễn Văn A', "value": '45h', "amount": 'Chơi nhiều nhất'},
        {"title": 'Trần Thị B', "value": '38h', "amount": 'Tham gia giải đấu'},
        {"title": 'Lê Văn C', "value": '32h', "amount": 'Thành viên VIP'},
      ],
    );
  }

  Widget _buildRecentTrends() {
    return _buildChartCard(
      'Xu hướng gần đây',
      'Phân tích xu hướng hoạt động sẽ được hiển thị ở đây',
      Icons.insights,
    );
  }

  Widget _buildChartCard(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, List<Map<String, String>> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item['title']!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['value']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    item['amount']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
