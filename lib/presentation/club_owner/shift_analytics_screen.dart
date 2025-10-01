import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/loading_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class ShiftAnalyticsScreen extends StatefulWidget() {
  final String clubId;
  final Map<String, dynamic>? analytics;

  const ShiftAnalyticsScreen({
    Key? key,
    required this.clubId,
    this.analytics,
  }) : super(key: key);

  @override
  State<ShiftAnalyticsScreen> createState() => _ShiftAnalyticsScreenState();
}

class _ShiftAnalyticsScreenState extends State<ShiftAnalyticsScreen> {
  String _selectedPeriod = '30_days';
  
  @override
  Widget build(BuildContext context) {
    if (widget.analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          
          // Key metrics cards
          _buildKeyMetricsCards(),
          const SizedBox(height: 24),
          
          // Revenue chart
          _buildRevenueChart(),
          const SizedBox(height: 24),
          
          // Profit margin chart
          _buildProfitChart(),
          const SizedBox(height: 24),
          
          // Performance breakdown
          _buildPerformanceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khoảng thời gian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodChip('7_days', '7 ngày'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodChip('30_days', '30 ngày'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodChip('90_days', '3 tháng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        // In real app, reload data here
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final analytics = widget.analytics!;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Tổng Doanh Thu',
                formatter.format(analytics['total_revenue']),
                Icons.trending_up,
                Colors.green,
                '${_getPeriodText()} qua',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Tổng Chi Phí',
                formatter.format(analytics['total_expenses']),
                Icons.trending_down,
                Colors.red,
                '${_getPeriodText()} qua',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Lợi Nhuận',
                formatter.format(analytics['total_profit']),
                Icons.account_balance_wallet,
                analytics['total_profit'] >= 0 ? Colors.blue : Colors.red,
                'Tỉ lệ: ${analytics['profit_margin'].toStringAsFixed(1)}%',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Số Ca Làm',
                '${analytics['shift_count']} ca',
                Icons.schedule,
                Colors.orange,
                'TB: ${formatter.format(analytics['average_revenue_per_shift'])}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xu hướng doanh thu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000000).toStringAsFixed(0)}M',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
                          if (value.toInt() < days.length) {
                            return Text(days[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateRevenueSpots(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân bổ doanh thu vs chi phí',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _generateProfitSections(),
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildChartLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final analytics = widget.analytics!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          'Doanh thu',
          formatter.format(analytics['total_revenue']),
          Colors.green,
        ),
        _buildLegendItem(
          'Chi phí',
          formatter.format(analytics['total_expenses']),
          Colors.red,
        ),
        _buildLegendItem(
          'Lợi nhuận',
          formatter.format(analytics['total_profit']),
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân tích hiệu suất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPerformanceItem(
              'Hiệu suất trung bình',
              '${widget.analytics!['profit_margin'].toStringAsFixed(1)}%',
              widget.analytics!['profit_margin'] >= 20 ? Colors.green : Colors.orange,
              _getPerformanceDescription(widget.analytics!['profit_margin']),
            ),
            const Divider(),
            
            _buildPerformanceItem(
              'Doanh thu bình quân/ca',
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(widget.analytics!['average_revenue_per_shift']),
              Colors.blue,
              'So với tiêu chuẩn ngành',
            ),
            const Divider(),
            
            _buildPerformanceItem(
              'Lợi nhuận bình quân/ca',
              NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                  .format(widget.analytics!['average_profit_per_shift']),
              widget.analytics!['average_profit_per_shift'] >= 0 ? Colors.green : Colors.red,
              'Xu hướng ${widget.analytics!['average_profit_per_shift'] >= 0 ? "tăng" : 'giảm'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceItem(String title, String value, Color color, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateRevenueSpots() {
    // Mock data for revenue trend
    return [
      const FlSpot(0, 1500000),
      const FlSpot(1, 1800000),
      const FlSpot(2, 1200000),
      const FlSpot(3, 2100000),
      const FlSpot(4, 1900000),
      const FlSpot(5, 2200000),
      const FlSpot(6, 2500000),
    ];
  }

  List<PieChartSectionData> _generateProfitSections() {
    final analytics = widget.analytics!;
    final totalRevenue = analytics['total_revenue'] as double;
    final totalExpenses = analytics['total_expenses'] as double;
    final totalProfit = analytics['total_profit'] as double;
    
    final total = totalRevenue + totalExpenses;
    
    return [
      PieChartSectionData(
        value: (totalRevenue / total) * 100,
        color: Colors.green,
        title: '${((totalRevenue / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
      ),
      PieChartSectionData(
        value: (totalExpenses / total) * 100,
        color: Colors.red,
        title: '${((totalExpenses / total) * 100).toStringAsFixed(1)}%',
        radius: 50,
      ),
    ];
  }

  String _getPeriodText() {
    switch (_selectedPeriod) {
      case '7_days':
        return '7 ngày';
      case '30_days':
        return '30 ngày';
      case '90_days':
        return '3 tháng';
      default:
        return '30 ngày';
    }
  }

  String _getPerformanceDescription(double profitMargin) {
    if (profitMargin >= 30) return 'Xuất sắc - Vượt mục tiêu';
    if (profitMargin >= 20) return 'Tốt - Đạt mục tiêu';
    if (profitMargin >= 10) return 'Trung bình - Cần cải thiện';
    if (profitMargin >= 0) return 'Yếu - Cần xem xét';
    return 'Thua lỗ - Cần hành động khẩn cấp';
  }
}