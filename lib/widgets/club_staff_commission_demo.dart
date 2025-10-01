import 'package:flutter/material.dart';
import '../services/club_staff_service.dart';
import '../services/commission_service.dart';

/// Demo app để test Club Staff Commission System
class ClubStaffCommissionDemo extends StatefulWidget {
  const ClubStaffCommissionDemo({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const ClubStaffCommissionDemo({Key? key}) : super(key: key);

  @override
  State<ClubStaffCommissionDemo> createState() => _ClubStaffCommissionDemoState();
}

class _ClubStaffCommissionDemoState extends State<ClubStaffCommissionDemo> {
  final _scrollController = ScrollController();
  final List<String> _logs = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Staff Commission Demo'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? null : _runFullDemo,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Chạy Demo Đầy Đủ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear),
                  label: const Text('Xóa Log'),
                ),
                const Spacer(),
                if (_isRunning)
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Đang chạy...'),
                    ],
                  ),
              ],
            ),
          ),
          
          // Logs Display
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.white;
                  
                  if (log.startsWith('✅')) {
                    textColor = Colors.green;
                  } else if (log.startsWith('❌')) {
                    textColor = Colors.red;
                  } else if (log.startsWith('🚀') || log.startsWith('📋')) {
                    textColor = Colors.blue;
                  } else if (log.startsWith('💰')) {
                    textColor = Colors.yellow;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'test1',
            onPressed: _isRunning ? null : _testStaffManagement,
            tooltip: 'Test Staff Management',
            child: const Icon(Icons.people),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'test2',
            onPressed: _isRunning ? null : _testCommissionSystem,
            tooltip: 'Test Commission System',
            child: const Icon(Icons.monetization_on),
          ),
        ],
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
    });
    
    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  Future<void> _runFullDemo() async {
    setState(() => _isRunning = true);
    
    _addLog('🚀 Bắt đầu Demo Hệ Thống Club Staff Commission');
    _addLog('================================================');
    
    await _testStaffManagement();
    await Future.delayed(const Duration(seconds: 2));
    await _testCommissionSystem();
    await Future.delayed(const Duration(seconds: 2));
    await _testAnalytics();
    
    _addLog('================================================');
    _addLog('✅ Demo hoàn tất! Hệ thống hoạt động tốt.');
    
    setState(() => _isRunning = false);
  }

  Future<void> _testStaffManagement() async {
    _addLog('📋 TEST 1: Staff Management System');
    _addLog('-----------------------------------');
    
    try {
      // Test 1: Add staff to club
      _addLog('🔹 Testing: Thêm nhân viên vào club...');
      
      final addResult = await ClubStaffService.assignUserAsStaff(
        clubId: 'demo-club-id',
        userId: 'demo-user-id',
        staffRole: 'staff',
        commissionRate: 5.0,
        canEnterScores: true,
        canManageTournaments: false,
        canViewReports: false,
      );
      
      if (addResult['success']) {
        _addLog('✅ Thêm nhân viên thành công! Staff ID: ${addResult['staff_id']}');
      } else {
        () {
        _addLog('❌ Lỗi thêm nhân viên: ${addResult['message']}');
      }
      
      
      }await Future.delayed(const Duration(milliseconds: 500));
      
      // Test 2: Get club staff list
      _addLog('🔹 Testing: Lấy danh sách nhân viên...');
      
      final staffList = await ClubStaffService.getClubStaff('demo-club-id');
      _addLog('✅ Tìm thấy ${staffList.length} nhân viên trong club');
      
      for (int i = 0; i < staffList.length && i < 3; i++) {
        final staff = staffList[i];
        final userName = staff['users']?['full_name'] ?? 'Unknown';
        final role = staff['staff_role'] ?? 'staff';
        _addLog('   📋 $userName - $role (${staff['commission_rate']}% HH)');
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Test 3: Check user staff info
      _addLog('🔹 Testing: Kiểm tra thông tin staff của user...');
      
      final staffInfo = await ClubStaffService.getUserStaffInfo('demo-user-id');
      if (staffInfo != null) {
        _addLog('✅ User là staff tại club: ${staffInfo['clubs']?['name'] ?? 'Unknown'}');
      } else {
        () {
        _addLog('ℹ️ User chưa là staff tại club nào');
      }
      
    
      }} catch (e) {
      _addLog('❌ Lỗi test Staff Management: $e');
    }
  }

  Future<void> _testCommissionSystem() async {
    _addLog('');
    _addLog('💰 TEST 2: Commission System');
    _addLog('------------------------------');
    
    try {
      // Test 1: Apply staff referral
      _addLog('🔹 Testing: Áp dụng mã giới thiệu staff...');
      
      final referralResult = await ClubStaffService.applyStaffReferral(
        referralCode: 'STAFF-DEMO123',
        newCustomerId: 'demo-customer-id',
      );
      
      if (referralResult['success']) {
        _addLog('✅ Áp dụng mã giới thiệu thành công!');
        _addLog('   💎 Khách hàng nhận: ${referralResult['referred_reward']} SPA');
        _addLog('   💰 Staff nhận: ${referralResult['referrer_reward']} SPA');
      } else {
        () {
        _addLog('❌ Lỗi áp dụng mã giới thiệu: ${referralResult['message']}');
      }
      
      
      }await Future.delayed(const Duration(milliseconds: 500));
      
      // Test 2: Record customer transaction
      _addLog('🔹 Testing: Ghi nhận giao dịch khách hàng...');
      
      final transactionResult = await ClubStaffService.recordCustomerTransaction(
        customerId: 'demo-customer-id',
        clubId: 'demo-club-id',
        transactionType: 'tournament_fee',
        amount: 50000,
        description: 'Phí tham gia giải đấu tuần',
        paymentMethod: 'cash',
      );
      
      if (transactionResult['success']) {
        _addLog('✅ Ghi nhận giao dịch thành công!');
        _addLog('   💵 Số tiền: 50,000 VND');
        _addLog('   💰 Hoa hồng tự động: ${transactionResult['commission_amount']} VND');
      } else {
        () {
        _addLog('❌ Lỗi ghi nhận giao dịch: ${transactionResult['message']}');
      }
      
      
      }await Future.delayed(const Duration(milliseconds: 500));
      
      // Test 3: Calculate commission
      _addLog('🔹 Testing: Tính toán hoa hồng...');
      
      final commissionResult = await CommissionService.calculateCommission(
        transactionId: transactionResult['transaction_id'] ?? 'demo-transaction-id',
      );
      
      if (commissionResult['success']) {
        _addLog('✅ Tính hoa hồng thành công!');
        _addLog('   💰 Hoa hồng: ${commissionResult['commission_amount']} VND');
        _addLog('   📊 Tỷ lệ: ${commissionResult['commission_rate']}%');
      } else {
        () {
        _addLog('ℹ️ ${commissionResult['message']}');
      }
      
      
      }await Future.delayed(const Duration(milliseconds: 500));
      
      // Test 4: Get pending commissions
      _addLog('🔹 Testing: Lấy danh sách hoa hồng chờ thanh toán...');
      
      final pendingCommissions = await CommissionService.getPendingCommissions();
      _addLog('✅ Tìm thấy ${pendingCommissions.length} hoa hồng chờ thanh toán');
      
      double totalPending = 0;
      for (int i = 0; i < pendingCommissions.length && i < 5; i++) {
        final commission = pendingCommissions[i];
        final amount = (commission['commission_amount'] as num).toDouble();
        totalPending += amount;
        _addLog('   💰 ${amount.toStringAsFixed(0)} VND - ${commission['commission_type']}');
      }
      
      if (totalPending > 0) {
        _addLog('   📊 Tổng chờ thanh toán: ${totalPending.toStringAsFixed(0)} VND');
      }
      
    } catch (e) {
      _addLog('❌ Lỗi test Commission System: $e');
    }
  }

  Future<void> _testAnalytics() async {
    _addLog('');
    _addLog('📊 TEST 3: Analytics & Reports');
    _addLog('-------------------------------');
    
    try {
      // Test 1: Staff earnings summary
      _addLog('🔹 Testing: Tổng hợp thu nhập staff...');
      
      final earnings = await ClubStaffService.getStaffEarnings('demo-staff-id');
      
      if (earnings['success']) {
        _addLog('✅ Lấy thu nhập staff thành công!');
        _addLog('   💰 Tổng hoa hồng: ${earnings['total_commissions']?.toStringAsFixed(0) ?? '0'} VND');
        _addLog('   📅 Tháng này: ${earnings['this_month_commissions']?.toStringAsFixed(0) ?? '0'} VND');
        _addLog('   👥 Khách hàng active: ${earnings['active_referrals'] ?? 0}');
        _addLog('   💵 Doanh thu khách: ${earnings['total_customer_spending']?.toStringAsFixed(0) ?? '0'} VND');
      } else {
        () {
        _addLog('ℹ️ ${earnings['message']}');
      }
      
      
      }await Future.delayed(const Duration(milliseconds: 500));
      
      // Test 2: Club commission analytics
      _addLog('🔹 Testing: Phân tích hoa hồng club...');
      
      final analytics = await CommissionService.getClubCommissionAnalytics(
        clubId: 'demo-club-id',
      );
      
      if (analytics['success']) {
        final summary = analytics['summary'] ?? {};
        _addLog('✅ Phân tích club thành công!');
        _addLog('   💰 Tổng HH đã trả: ${summary['total_commissions_paid']?.toStringAsFixed(0) ?? '0'} VND');
        _addLog('   📈 Doanh thu tạo ra: ${summary['total_revenue_generated']?.toStringAsFixed(0) ?? '0'} VND');
        _addLog('   📊 Tỷ lệ HH TB: ${summary['commission_rate_avg']?.toStringAsFixed(1) ?? '0'}%');
        _addLog('   🧾 Tổng giao dịch: ${summary['total_transactions'] ?? 0}');
        
        final staffPerformance = analytics['staff_performance'] ?? {};
        if (staffPerformance.isNotEmpty) {
          _addLog('   👥 Top staff performers:');
          int count = 0;
          for (var staffName in staffPerformance.keys) {
            if (count >= 3) break;
            final performance = staffPerformance[staffName];
            final commissions = performance['total_commissions']?.toStringAsFixed(0) ?? '0';
            final customers = performance['unique_customers'] ?? 0;
            _addLog('      🏆 $staffName: $commissions VND ($customers khách)');
            count++;
          }
        }
      } else {
        () {
        _addLog('ℹ️ ${analytics['message']}');
      }
      
      
      }await Future.delayed(const Duration(milliseconds, 500));
      
      // Test 3: Commission report generation
      _addLog('🔹 Testing: Tạo báo cáo hoa hồng...');
      
      final report = await CommissionService.generateCommissionReport(
        clubId: 'demo-club-id',
        reportType: 'summary',
      );
      
      if (report['success']) {
        _addLog('✅ Tạo báo cáo thành công!');
        _addLog('   📋 Loại báo cáo: ${report['report_type']}');
        _addLog('   📅 Kỳ báo cáo: ${report['period']}');
        
        if (report['summary'] != null) {
          final summary = report['summary'];
          _addLog('   💰 Tổng HH: ${summary['total_commissions']?.toStringAsFixed(0) ?? '0'} VND');
          _addLog('   📈 Tổng doanh thu: ${summary['total_revenue']?.toStringAsFixed(0) ?? '0'} VND');
        }
      } else {
        () {
        _addLog('ℹ️ ${report['message']}');
      }
      
    
      }} catch (e) {
      _addLog('❌ Lỗi test Analytics: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}