import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/attendance_service.dart';
import '../../services/mock_attendance_service.dart';
import '../../services/user_role_service.dart';
import '../../widgets/qr_attendance_scanner.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

@override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Use mock service for demo purposes
  final MockAttendanceService _attendanceService = MockAttendanceService();
  
  Map<String, dynamic>? currentAttendance;
  List<Map<String, dynamic>> todayShifts = [];
  List<Map<String, dynamic>> attendanceHistory = [];
  String? activeBreakId;
  
  // User role information
  Map<String, dynamic>? staffInfo;
  String? userRole;
  
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadAttendanceData();
  }

  Future<void> _loadUserRole() async {
    try {
      staffInfo = await UserRoleService.getCurrentUserStaffInfo();
      if (staffInfo != null) {
        userRole = staffInfo!['staff_role'];
      }
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  Future<void> _loadAttendanceData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _attendanceService.getCurrentAttendance(),
        _attendanceService.getTodayShifts(),
        _attendanceService.getAttendanceHistory(days: 7),
      ]);

      setState(() {
        currentAttendance = results[0] as Map<String, dynamic>?;
        todayShifts = results[1] as List<Map<String, dynamic>>;
        attendanceHistory = results[2] as List<Map<String, dynamic>>;
        activeBreakId = _attendanceService.activeBreakId;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Không thể tải dữ liệu chấm công: $e';
        isLoading = false;
      });
    }
  }

  void _showQRScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRAttendanceScanner(
          onScanResult: _handleQRScanResult,
        ),
      ),
    );
  }

  Future<void> _handleQRScanResult(Map<String, dynamic> scanResult) async {
    if (!mounted) return;
    Navigator.of(context).pop(); // Close scanner
    
    if (scanResult['success']) {
      if (currentAttendance == null) {
        // Check in
        await _performCheckIn(scanResult);
      } else {
        () {
        // Check out confirmation
        _showCheckOutConfirmation(scanResult);
      }
    
      }} else {
      () {
      _showErrorDialog(scanResult['error']);
    }
  
    }}

  Future<void> _performCheckIn(Map<String, dynamic> scanResult) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final result = await _attendanceService.checkIn(
        qrData: scanResult['qrData'],
        locationLat: scanResult['locationLat'],
        locationLng: scanResult['locationLng'],
      );

      if (!mounted) return;
      if (result['success']) {
        await _loadAttendanceData();
        if (mounted) _showSuccessDialog('Đã check-in thành công!', result['message']);
      } else {
        () {
        if (mounted) _showErrorDialog(result['error']);
      }
    
      }} catch (e) {
      if (mounted) _showErrorDialog('Lỗi check-in: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showCheckOutConfirmation(Map<String, dynamic> scanResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận kết thúc ca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có muốn kết thúc ca làm việc?'),
            SizedBox(height: 12),
            Text('Club: ${scanResult['club_name']}', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performCheckOut(scanResult);
            },
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCheckOut() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final result = await _attendanceService.checkOut();

      if (!mounted) return;
      if (result['success']) {
        await _loadAttendanceData();
        if (mounted) _showSuccessDialog('Đã check-out thành công!', 'Tổng thời gian làm việc: ${result['work_hours']} giờ');
      } else {
        () {
        if (mounted) _showErrorDialog(result['error']);
      }
    
      }} catch (e) {
      if (mounted) _showErrorDialog('Lỗi check-out: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _startBreak(String breakType) async {
    if (currentAttendance == null) return;

    try {
      final result = await _attendanceService.startBreak(
        currentAttendance!['id'],
        breakType,
      );

      if (result['success']) {
        setState(() {
          activeBreakId = result['break_id'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      } else {
        () {
        _showErrorDialog(result['error']);
      }
    
      }} catch (e) {
      _showErrorDialog('Lỗi bắt đầu nghỉ: $e');
    }
  }

  Future<void> _endBreak() async {
    if (activeBreakId == null || !mounted) return;

    try {
      final result = await _attendanceService.endBreak(activeBreakId!);

      if (!mounted) return;
      if (result['success']) {
        setState(() {
          activeBreakId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['message']} (${result['break_duration']} phút)')),
        );
      } else {
        () {
        _showErrorDialog(result['error']);
      }
    
      }} catch (e) {
      if (mounted) _showErrorDialog('Lỗi kết thúc nghỉ: $e');
    }
  }

  void _showSuccessDialog(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(staffInfo != null 
          ? 'Chấm công - ${staffInfo!['clubs']['name"]}" 
          : 'Chấm công'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (userRole != null)
            Chip(
              label: Text(
                _getRoleDisplayName(userRole!),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getRoleColor(userRole!),
            ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAttendanceData,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorView()
              : staffInfo == null
                  ? _buildNoAccessView()
                  : RefreshIndicator(
                      onRefresh: _loadAttendanceData,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStaffInfoCard(),
                            SizedBox(height: 16),
                            _buildCurrentStatusCard(),
                            SizedBox(height: 16),
                            _buildTodayShiftsCard(),
                            SizedBox(height: 16),
                            _buildQuickActionsCard(),
                            SizedBox(height: 16),
                            _buildAttendanceHistoryCard(),
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQRScanner,
        icon: Icon(Icons.qr_code_scanner),
        label: Text(currentAttendance == null ? "Chấm công" : 'Kết thúc ca'),
        backgroundColor: currentAttendance == null ? Colors.green : Colors.orange,
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
            onPressed: _loadAttendanceData,
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  currentAttendance != null ? Icons.work : Icons.work_off,
                  color: currentAttendance != null ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'Trạng thái hiện tại',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (currentAttendance != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Đang làm việc',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Club: ${currentAttendance!['staff_shifts']['club_staff']['clubs']['name']}'),
                    Text('Check-in: ${DateFormat('HH:mm dd/MM/yyyy').format(DateTime.parse(currentAttendance!['check_in_time']))}'),
                    if (currentAttendance!['late_minutes'] > 0)
                      Text(
                        'Đi muộn: ${currentAttendance!['late_minutes']} phút',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.work_off, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Chưa chấm công hôm nay',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodayShiftsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Ca làm hôm nay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (todayShifts.isEmpty) ...[
              Text(
                'Không có ca làm việc hôm nay',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ] else ...[
              ...todayShifts.map((shift) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift['club_staff']['clubs']['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${shift['scheduled_start_time']} - ${shift['scheduled_end_time']}'),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(shift['shift_status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(shift['shift_status']),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thao tác nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showQRScanner,
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text(currentAttendance == null ? "Chấm công" : 'Kết thúc ca'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentAttendance == null ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (currentAttendance != null) ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: activeBreakId == null
                        ? ElevatedButton.icon(
                            onPressed: () => _startBreak('rest'),
                            icon: Icon(Icons.coffee),
                            label: Text('Nghỉ giải lao'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _endBreak,
                            icon: Icon(Icons.play_arrow),
                            label: Text('Kết thúc nghỉ'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceHistoryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Lịch sử 7 ngày',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (attendanceHistory.isEmpty) ...[
              Text(
                'Chưa có lịch sử chấm công',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ] else ...[
              ...attendanceHistory.take(5).map((record) => Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          record['staff_shifts']['club_staff']['clubs']['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd/MM').format(DateTime.parse(record['check_in_time'])),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${DateFormat('HH:mm').format(DateTime.parse(record['check_in_time']))} - ${record['check_out_time'] != null ? DateFormat('HH:mm').format(DateTime.parse(record['check_out_time'])) : '...'}'),
                        Text('${record['total_hours_worked']?.toStringAsFixed(1) ?? '...'} giờ'),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.grey;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scheduled':
        return 'Chờ';
      case 'in_progress':
        return 'Đang làm';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Hủy';
      default:
        return status;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'Chủ CLB';
      case 'manager':
        return 'Quản lý';
      case 'staff':
        return 'Nhân viên';
      case 'trainee':
        return 'Thực tập';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'manager':
        return Colors.indigo;
      case 'staff':
        return Colors.blue;
      case 'trainee':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNoAccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, color: Colors.red, size: 64),
          SizedBox(height: 16),
          Text(
            'Không có quyền truy cập',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Bạn cần được cấp quyền nhân viên tại câu lạc bộ để sử dụng chức năng chấm công.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffInfoCard() {
    if (staffInfo == null) return SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Thông tin nhân viên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getRoleColor(userRole!).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getRoleColor(userRole!).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: _getRoleColor(userRole!)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          staffInfo!['clubs']['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, color: _getRoleColor(userRole!)),
                      SizedBox(width: 8),
                      Text(
                        'Chức vụ: ${_getRoleDisplayName(userRole!)}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Đang hoạt động',
                        style: TextStyle(color: Colors.green[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

