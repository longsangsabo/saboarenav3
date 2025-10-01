import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_models.dart';
import '../../services/shift_reporting_service.dart';
import '../../services/mock_shift_reporting_service.dart';
import '../../services/user_role_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';
import '../club_owner/active_shift_screen.dart';
import '../club_owner/shift_history_screen.dart';
import '../club_owner/shift_analytics_screen.dart';

class ShiftReportingDashboard extends StatefulWidget() {
  final String clubId;

  const ShiftReportingDashboard({
    Key? key,
    required this.clubId,
  }) : super(key: key);

  @override
  State<ShiftReportingDashboard> createState() => _ShiftReportingDashboardState();
}

class _ShiftReportingDashboardState extends State<ShiftReportingDashboard>
    with SingleTickerProviderStateMixin() {
  final ShiftReportingService _shiftService = ShiftReportingService();
  final UserRoleService _roleService = UserRoleService();
  
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;
  
  ShiftSession? _activeShift;
  List<ShiftReport> _recentReports = [];
  Map<String, dynamic>? _analytics;
  String? _userRole;
  String? _currentStaffId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async() {
    try() {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check user role
      final staffInfo = await _roleService.getCurrentUserStaffInfo(widget.clubId);
      if (staffInfo != null) {
        _userRole = staffInfo['role'];
        _currentStaffId = staffInfo['staff_id'];
      }

      // Load data based on role
      if (_currentStaffId != null) {
        // Get active shift for current staff
        _activeShift = await _shiftService.getActiveShift(_currentStaffId!);
      }

      // Get recent reports (last 7 days)
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      _recentReports = await _shiftService.getClubShiftReports(
        widget.clubId,
        startDate: startDate,
        endDate: endDate,
      );

      // Get analytics (last 30 days)
      final analyticsStartDate = endDate.subtract(const Duration(days: 30));
      _analytics = await _shiftService.getShiftAnalytics(
        widget.clubId,
        startDate: analyticsStartDate,
        endDate: endDate,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startNewShift() async() {
    if (_currentStaffId == null) return;

    try() {
      // Show start shift dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _StartShiftDialog(),
      );

      if (result != null) {
        final newShift = await _shiftService.startShift(
          clubId: widget.clubId,
          staffId: _currentStaffId!,
          shiftDate: result['date'],
          startTime: result['startTime'],
          endTime: result['endTime'],
          openingCash: result['openingCash'],
          notes: result['notes'],
        );

        setState(() {
          _activeShift = newShift;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ca làm việc đã bắt đầu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi bắt đầu ca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Đang tải báo cáo ca...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: ErrorWidget(
          message: _error!,
          onRetry: _loadDashboardData,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Ca Làm Việc'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.access_time), text: 'Ca Hiện Tại'),
            Tab(icon: Icon(Icons.history), text: 'Lịch Sử'),
            Tab(icon: Icon(Icons.analytics), text: 'Thống Kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Shift Tab
          _buildActiveShiftTab(),
          
          // History Tab
          ShiftHistoryScreen(clubId: widget.clubId),
          
          // Analytics Tab
          ShiftAnalyticsScreen(
            clubId: widget.clubId,
            analytics: _analytics,
          ),
        ],
      ),
      floatingActionButton: _activeShift == null && _canStartShift()
          ? FloatingActionButton.extended(
              onPressed: _startNewShift,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Bắt Đầu Ca'),
            )
          : null,
    );
  }

  Widget _buildActiveShiftTab() {
    if (_activeShift == null) {
      return _buildNoActiveShiftView();
    }

    return ActiveShiftScreen(
      shiftSession: _activeShift!,
      onShiftEnded: () {
        setState(() {
          _activeShift = null;
        });
        _loadDashboardData();
      },
    );
  }

  Widget _buildNoActiveShiftView() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Không có ca làm việc nào đang hoạt động',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu ca mới để theo dõi doanh thu và chi phí',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_canStartShift()) ...[
            ElevatedButton.icon(
              onPressed: _startNewShift,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Bắt Đầu Ca Mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chỉ nhân viên có quyền mới có thể bắt đầu ca làm việc',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_analytics == null) return const SizedBox.shrink();

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống Kê 30 Ngày Qua',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tổng Doanh Thu',
                  formatter.format(_analytics!['total_revenue']),
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Tổng Chi Phí',
                  formatter.format(_analytics!['total_expenses']),
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Lợi Nhuận',
                  formatter.format(_analytics!['total_profit']),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Số Ca',
                  '${_analytics!['shift_count']} ca',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _canStartShift() {
    return _userRole != null && 
           (_userRole == 'owner' || 
            _userRole == 'manager' || 
            _userRole == 'staff');
  }
}

class _StartShiftDialog extends StatefulWidget() {
  @override
  State<_StartShiftDialog> createState() => _StartShiftDialogState();
}

class _StartShiftDialogState extends State<_StartShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _openingCashController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: (TimeOfDay.now().hour + 8) % 24, minute: 0);

  @override
  void dispose() {
    _openingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bắt Đầu Ca Làm Việc'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Ngày làm việc'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                onTap: () async() {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 7)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              
              // Start time picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Giờ bắt đầu'),
                subtitle: Text(_startTime.format(context)),
                onTap: () async() {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (time != null) {
                    setState(() => _startTime = time);
                  }
                },
              ),
              
              // End time picker
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text('Giờ kết thúc'),
                subtitle: Text(_endTime.format(context)),
                onTap: () async() {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _endTime,
                  );
                  if (time != null) {
                    setState(() => _endTime = time);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Opening cash
              TextFormField(
                controller: _openingCashController,
                decoration: const InputDecoration(
                  labelText: 'Tiền mặt đầu ca (₫)',
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Vui lòng nhập số tiền đầu ca';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, {
                'date': _selectedDate,
                "startTime": '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00',
                "endTime": '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00',
                'openingCash': double.parse(_openingCashController.text),
                'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
              });
            }
          },
          child: const Text('Bắt Đầu'),
        ),
      ],
    );
  }
}