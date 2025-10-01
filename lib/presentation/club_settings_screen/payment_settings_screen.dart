import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/presentation/payment/payment_setup_screen.dart';
import 'package:sabo_arena/services/real_payment_service.dart';
import 'package:sabo_arena/widgets/auto_payment_qr_widget.dart';

class PaymentSettingsScreen extends StatefulWidget() {
  final String clubId;

  const PaymentSettingsScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? currentSettings;
  bool hasSettings = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentSettings();
  }

  Future<void> _loadPaymentSettings() async() {
    try() {
      final settings = await RealPaymentService.getClubPaymentSettings(widget.clubId);
      setState(() {
        currentSettings = settings;
        hasSettings = settings != null;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasSettings = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Phương thức thanh toán'),
      backgroundColor: AppTheme.backgroundLight,
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (hasSettings) ...[
                    _buildCurrentSettings(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildPaymentHistory(),
                  ] else ...[
                    _buildSetupPrompt(),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withOpacity(0.1),
            AppTheme.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasSettings ? Colors.green : AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasSettings ? Icons.check_circle : Icons.payment, 
              color: Colors.white, 
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSettings ? "Thanh toán đã kích hoạt" : 'Thiết lập thanh toán QR',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSettings 
                    ? "Khách hàng có thể thanh toán qua QR Code"
                    : 'Nhập thông tin 1 lần, tự động tạo QR cho mọi giao dịch',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (hasSettings)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Text(
                'HOẠT ĐỘNG',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                'Cài đặt hiện tại',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Payment methods
          if (currentSettings!['cash_enabled'] == true)
            _buildMethodRow(Icons.money, 'Tiền mặt', 'Thanh toán tại quầy'),
          
          if (currentSettings!['bank_enabled'] == true && currentSettings!['bank_info'] != null)
            _buildMethodRow(
              Icons.account_balance, 
              'Chuyển khoản ${currentSettings!['bank_info']['bankName']}',
              'STK: ${currentSettings!['bank_info']['accountNumber']}'
            ),
          
          if (currentSettings!['ewallet_enabled'] == true && currentSettings!['ewallet_info'] != null) ...[
            if (currentSettings!['ewallet_info']['momo_phone']?.isNotEmpty == true)
              _buildMethodRow(Icons.phone_android, 'MoMo', currentSettings!['ewallet_info']['momo_phone']),
            if (currentSettings!['ewallet_info']['zalopay_phone']?.isNotEmpty == true)
              _buildMethodRow(Icons.payment, 'ZaloPay', currentSettings!['ewallet_info']['zalopay_phone']),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thao tác nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit,
                  title: 'Chỉnh sửa',
                  subtitle: 'Cập nhật thông tin',
                  color: Colors.blue,
                  onTap: _editSettings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_scanner,
                  title: 'Test QR',
                  subtitle: 'Thử nghiệm',
                  color: Colors.green,
                  onTap: _testPayment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                'Giao dịch gần đây',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mock recent payments
          _buildPaymentHistoryItem(
            'Thanh toán sân 1',
            'Chuyển khoản Vietcombank',
            '100,000 VNĐ',
            '5 phút trước',
            Icons.account_balance,
            Colors.green,
          ),
          _buildPaymentHistoryItem(
            'Nạp tiền tài khoản',
            'MoMo QR Code',
            '200,000 VNĐ',
            '1 giờ trước',
            Icons.phone_android,
            Colors.green,
          ),
          _buildPaymentHistoryItem(
            'Thanh toán đồ uống',
            'Tiền mặt',
            '50,000 VNĐ',
            '2 giờ trước',
            Icons.money,
            Colors.green,
          ),
          
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng xem tất cả đang được phát triển')),
                );
              },
              child: Text(
                'Xem tất cả giao dịch',
                style: TextStyle(color: AppTheme.primaryLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem(
    String title, 
    String method, 
    String amount, 
    String time,
    IconData icon,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  method,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.blue[25]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_scanner, color: Colors.blue[600], size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa thiết lập thanh toán QR',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khách hàng chưa thể thanh toán qua QR Code.\nHãy thiết lập ngay để tăng doanh thu!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 20),
          
          // Benefits
          _buildBenefitRow('Tự động tạo QR cho mọi giao dịch'),
          _buildBenefitRow('Hỗ trợ 23+ ngân hàng Việt Nam'),
          _buildBenefitRow('MoMo, ZaloPay, ViettelPay...'),
          _buildBenefitRow('Theo dõi giao dịch realtime'),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.rocket_launch, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Thiết lập ngay (5 phút)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _startSetup() async() {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSetupScreen(clubId: widget.clubId),
      ),
    );
    
    if (result == true) {
      // Reload settings after setup
      _loadPaymentSettings();
    }
  }

  void _editSettings() async() {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSetupScreen(clubId: widget.clubId),
      ),
    );
    
    if (result == true) {
      _loadPaymentSettings();
    }
  }

  void _testPayment() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
          child: AutoPaymentQRWidget(
            clubId: widget.clubId,
            amount: 50000,
            description: 'Test thanh toán QR Code',
            onPaymentConfirmed: (paymentId) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Test thành công! Payment ID: $paymentId'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onPaymentFailed: (paymentId, error) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Test thất bại: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}