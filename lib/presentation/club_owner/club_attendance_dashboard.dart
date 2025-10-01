import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/attendance_service.dart';

class ClubAttendanceDashboard extends StatefulWidget {
  const ClubAttendanceDashboard({super.key});

} 
  final String clubId;
  final String clubName;

  const ClubAttendanceDashboard({
    Key? key,
    required this.clubId,
    required this.clubName,
  }) : super(key: key);

  @override
  State<ClubAttendanceDashboard> createState() => _ClubAttendanceDashboardState();
}

class _ClubAttendanceDashboardState extends State<ClubAttendanceDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final AttendanceService _attendanceService = AttendanceService();

  List<Map<String, dynamic>> todayAttendance = [];
  List<Map<String, dynamic>> weeklyStats = [];
  Map<String, dynamic> summaryStats = {};
  
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await Future.wait([
        _loadTodayAttendance(),
        _loadWeeklyStats(),
        _loadSummaryStats(),
      ]);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Không thể tải dữ liệu: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadTodayAttendance() async {
    // Mock data - replace with actual API call
    todayAttendance = [
      {
        "id": '1',
        "staff_name": 'Nguyễn Văn A',
        "check_in_time": '2025-09-30T08:00:00Z',
        'check_out_time': null,
        "status": 'working',
        'late_minutes': 0,
        "shift_start": '08:00',
        "shift_end": '17:00',
      },
      {
        "id": '2',
        "staff_name": 'Trần Thị B',
        "check_in_time": '2025-09-30T08:15:00Z',
        'check_out_time': null,
        "status": 'on_break',
        'late_minutes': 15,
        "shift_start": '08:00',
        "shift_end": '17:00',
      },
      {
        "id": '3',
        "staff_name": 'Lê Văn C',
        "check_in_time": '2025-09-30T14:00:00Z',
        "check_out_time": '2025-09-30T22:00:00Z',
        "status": 'completed',
        'late_minutes': 0,
        'total_hours': 8.0,
        "shift_start": '14:00',
        "shift_end": '22:00',
      },
    ];
  }

  Future<void> _loadWeeklyStats() async {
    // Mock data - replace with actual API call
    weeklyStats = [
      {"day": 'T2', 'present': 12, 'total': 15, 'late': 2},
      {"day": 'T3', 'present': 14, 'total': 15, 'late': 1},
      {"day": 'T4', 'present': 13, 'total': 15, 'late': 3},
      {"day": 'T5', 'present': 15, 'total': 15, 'late': 0},
      {"day": 'T6', 'present': 11, 'total': 15, 'late': 4},
      {"day": 'T7', 'present': 8, 'total': 10, 'late': 1},
      {"day": 'CN', 'present': 6, 'total': 8, 'late': 0},
    ];
  }

  Future<void> _loadSummaryStats() async {
    // Mock data - replace with actual API call
    summaryStats = {
      'total_staff': 15,
      'present_today': 3,
      'late_today': 1,
      'on_break': 1,
      'avg_hours_week': 7.2,
      'attendance_rate': 86.7,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${widget.clubName}'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Thống kê'),
            Tab(text: 'Lịch sử'),
            Tab(text: 'Quản lý'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayTab(),
                    _buildStatsTab(),
                    _buildHistoryTab(),
                    _buildManagementTab(),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            SizedBox(height: 20),
            _buildTodayAttendanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Tổng nhân viên',
                '${summaryStats['total_staff'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Có mặt hôm nay',
                '${summaryStats['present_today'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Đi muộn',
                '${summaryStats['late_today'] ?? 0}',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Đang nghỉ',
                '${summaryStats['on_break'] ?? 0}',
                Icons.coffee,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Chấm công hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (todayAttendance.isEmpty) ...[
              Center(
                child: Text(
                  'Chưa có ai chấm công hôm nay',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ] else ...[
              ...todayAttendance.map((record) => _buildAttendanceItem(record)).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> record) {
    final status = record['status'];
    final checkInTime = DateTime.parse(record['check_in_time']);
    final lateMinutes = record['late_minutes'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _getStatusColor(status),
            child: Icon(
              _getStatusIcon(status),
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['staff_name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Ca: ${record['shift_start']} - ${record['shift_end']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Text(
                      'Vào: ${DateFormat('HH:mm').format(checkInTime)}',
                      style: TextStyle(fontSize: 14),
                    ),
                    if (record['check_out_time'] != null) ...[
                      Text(' • Ra: ${DateFormat('HH:mm').format(DateTime.parse(record['check_out_time']))}'),
                      Text(' • ${record['total_hours']?.toStringAsFixed(1)}h'),
                    ],
                  ],
                ),
                if (lateMinutes > 0)
                  Text(
                    'Muộn: ${lateMinutes} phút',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyChart(),
          SizedBox(height: 20),
          _buildAttendanceRateCard(),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê tuần này',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < weeklyStats.length) {
                            return Text(
                              weeklyStats[value.toInt()]['day'],
                              style: TextStyle(fontSize: 12),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeklyStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['total'].toDouble(),
                          color: Colors.grey[300],
                          width: 20,
                        ),
                        BarChartRodData(
                          toY: data['present'].toDouble(),
                          color: Colors.green,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Tổng ca', Colors.grey[300]!),
                SizedBox(width: 20),
                _buildLegendItem('Có mặt', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAttendanceRateCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tỷ lệ chấm công',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summaryStats['attendance_rate']?.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      Text(
                        'Tuần này',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: (summaryStats['attendance_rate'] ?? 0) / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Text(
        'Lịch sử chấm công\n(Đang phát triển)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildManagementTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quản lý chấm công',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.schedule, color: Colors.blue),
            title: Text('Tạo ca làm việc'),
            subtitle: Text('Tạo lịch làm việc cho nhân viên'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to shift creation
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.qr_code, color: Colors.green),
            title: Text('Quản lý mã QR'),
            subtitle: Text('Xem và tạo lại mã QR chấm công'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to QR management
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.assessment, color: Colors.purple),
            title: Text('Báo cáo chi tiết'),
            subtitle: Text('Xem báo cáo chấm công và thống kê'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to detailed reports
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.orange),
            title: Text('Cài đặt'),
            subtitle: Text('Cấu hình quy tắc chấm công'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'working':
        return Colors.green;
      case 'on_break':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'working':
        return Icons.work;
      case 'on_break':
        return Icons.coffee;
      case 'completed':
        return Icons.check;
      case 'absent':
        return Icons.close;
      default:
        return Icons.person;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'working':
        return 'Đang làm';
      case 'on_break':
        return 'Nghỉ giải lao';
      case 'completed':
        return 'Hoàn thành';
      case 'absent':
        return 'Vắng mặt';
      default:
        return status;
    }
  }
}
