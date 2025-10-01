import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sabo_arena/services/qr_payment_service.dart';
import 'package:sabo_arena/services/real_payment_service.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class AutoPaymentQRWidget extends StatefulWidget {
  const AutoPaymentQRWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final String clubId;
  final double amount;
  final String description;
  final String? userId;
  final Function(String paymentId)? onPaymentConfirmed;
  final Function(String paymentId, String error)? onPaymentFailed;

  const AutoPaymentQRWidget({
    
    super.key,
    required this.clubId,
    required this.amount,
    required this.description,
    this.userId,
    this.onPaymentConfirmed,
    this.onPaymentFailed,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  State<AutoPaymentQRWidget> createState() => _AutoPaymentQRWidgetState();
}

class _AutoPaymentQRWidgetState extends State<AutoPaymentQRWidget>
    with TickerProviderStateMixin {
  Map<String, dynamic>? clubSettings;
  List<PaymentMethod> availableMethods = [];
  PaymentMethod? selectedMethod;
  String? qrData;
  String? paymentId;
  String status = 'loading';
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPaymentMethods();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _loadPaymentMethods() async {
    try {
      // Load club payment settings
      clubSettings = await RealPaymentService.getClubPaymentSettings(widget.clubId);
      
      if (clubSettings == null) {
        setState(() => status = 'no_setup');
        return;
      }

      // Build available payment methods
      availableMethods.clear();

      // Cash
      if (clubSettings!['cash_enabled'] == true) {
        availableMethods.add(PaymentMethod(
          id: 'cash',
          name: 'Tiền mặt',
          icon: Icons.money,
          color: Colors.green,
          description: 'Thanh toán trực tiếp tại quầy',
        ));
      }

      // Bank transfer
      if (clubSettings!['bank_enabled'] == true && clubSettings!['bank_info'] != null) {
        final bankInfo = clubSettings!['bank_info'];
        availableMethods.add(PaymentMethod(
          id: 'bank',
          name: 'Chuyển khoản ${bankInfo['bankName']}',
          icon: Icons.account_balance,
          color: Colors.blue,
          description: 'QR VietQR tự động',
          data: bankInfo,
        ));
      }

      // MoMo
      if (clubSettings!['ewallet_enabled'] == true && 
          clubSettings!['ewallet_info'] != null &&
          clubSettings!['ewallet_info']['momo_phone']?.isNotEmpty == true) {
        final ewalletInfo = clubSettings!['ewallet_info'];
        availableMethods.add(PaymentMethod(
          id: 'momo',
          name: 'MoMo',
          icon: Icons.phone_android,
          color: const Color(0xFFD82D8B),
          description: 'Quét mã QR MoMo',
          data: ewalletInfo,
        ));
      }

      // ZaloPay
      if (clubSettings!['ewallet_enabled'] == true && 
          clubSettings!['ewallet_info'] != null &&
          clubSettings!['ewallet_info']['zalopay_phone']?.isNotEmpty == true) {
        final ewalletInfo = clubSettings!['ewallet_info'];
        availableMethods.add(PaymentMethod(
          id: 'zalopay',
          name: 'ZaloPay',
          icon: Icons.payment,
          color: const Color(0xFF0068FF),
          description: 'Quét mã QR ZaloPay',
          data: ewalletInfo,
        ));
      }

      if (availableMethods.isEmpty) {
        setState(() => status = 'no_methods');
        return;
      }

      // Auto select first method
      selectedMethod = availableMethods.first;
      await _generateQRCode();
      
      _slideController.forward();
      setState(() => status = 'ready');

    } catch (e) {
      setState(() => status = 'error');
    }
  }

  Future<void> _generateQRCode() async {
    if (selectedMethod == null) return;

    try {
      setState(() => status = 'generating');

      // Create payment record first
      paymentId = await RealPaymentService.createPaymentRecord(
        clubId: widget.clubId,
        amount: widget.amount,
        description: widget.description,
        paymentMethod: selectedMethod!.id,
        userId: widget.userId,
      );

      String? generatedQRData;

      if (selectedMethod!.id == 'cash') {
        // Cash doesn't need QR, just show payment ID
        generatedQRData = 'CASH_PAYMENT_$paymentId';
      } else if (selectedMethod!.id == 'bank') {
        // Generate VietQR
        final bankInfo = selectedMethod!.data;
        generatedQRData = await QRPaymentService.generateBankQRData(
          bankInfo: {
            'bankName': bankInfo['bankName'],
            'accountNumber': bankInfo['accountNumber'],
            'accountName': bankInfo['accountName'],
          },
          amount: widget.amount,
          description: '${widget.description}_$paymentId',
        );
      } else if (selectedMethod!.id == 'momo') {
        // Generate MoMo QR
        final ewalletInfo = selectedMethod!.data;
        generatedQRData = QRPaymentService.generateEWalletQRData(
          walletType: 'momo',
          phoneNumber: ewalletInfo['momo_phone'],
          receiverName: ewalletInfo['owner_name'],
          amount: widget.amount,
          description: '${widget.description}_$paymentId',
        );
      } else if (selectedMethod!.id == 'zalopay') {
        // Generate ZaloPay QR
        final ewalletInfo = selectedMethod!.data;
        generatedQRData = QRPaymentService.generateEWalletQRData(
          walletType: 'zalopay',
          phoneNumber: ewalletInfo['zalopay_phone'],
          receiverName: ewalletInfo['owner_name'],
          amount: widget.amount,
          description: '${widget.description}_$paymentId',
        );
      }

      setState(() {
        qrData = generatedQRData;
        status = 'ready';
      });

      // Start monitoring payment
      _startPaymentMonitoring();

    } catch (e) {
      setState(() => status = 'error');
      widget.onPaymentFailed?.call(paymentId ?? '', e.toString());
    }
  }

  void _startPaymentMonitoring() {
    if (paymentId == null) return;

    // Check payment status every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted || status == 'confirmed' || status == 'failed') {
        timer.cancel();
        return;
      }

      try {
        final paymentStatus = await RealPaymentService.getPaymentStatus(paymentId!);
        if (paymentStatus == 'confirmed') {
          timer.cancel();
          setState(() => status = 'confirmed');
          widget.onPaymentConfirmed?.call(paymentId!);
        } else if (paymentStatus == 'failed' || paymentStatus == 'expired') {
          timer.cancel();
          setState(() => status = 'failed');
          widget.onPaymentFailed?.call(paymentId!, 'Payment $paymentStatus');
        }
      } catch (e) {
        // Continue monitoring
      }
    });

    // Auto expire after 10 minutes
    Timer(const Duration(minutes: 10), () {
      if (mounted && status == 'ready') {
        setState(() => status = 'expired');
        widget.onPaymentFailed?.call(paymentId!, 'Payment expired');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildContent(),
          const SizedBox(height: 20),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.qr_code_scanner,
            color: AppTheme.primaryLight,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thanh toán QR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '${_formatCurrency(widget.amount)} VNĐ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (status) {
      case 'loading':
        return _buildLoading();
      case 'no_setup':
        return _buildNoSetup();
      case 'no_methods':
        return _buildNoMethods();
      case 'generating':
        return _buildGenerating();
      case 'ready':
        return _buildQRCode();
      case 'confirmed':
        return _buildSuccess();
      case 'failed':
      case 'expired':
        return _buildFailed();
      case 'error':
      default:
        return _buildError();
    }
  }

  Widget _buildLoading() {
    return Column(
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Đang tải phương thức thanh toán...',
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildNoSetup() {
    return Column(
      children: [
        Icon(Icons.settings, size: 64, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          'Chưa thiết lập thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng liên hệ quản lý CLB để thiết lập thanh toán QR',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildNoMethods() {
    return Column(
      children: [
        Icon(Icons.money_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          'Không có phương thức thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng liên hệ quản lý CLB',
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildGenerating() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Icon(
                selectedMethod?.icon ?? Icons.qr_code,
                size: 64,
                color: selectedMethod?.color ?? AppTheme.primaryLight,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Đang tạo mã QR...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // Payment method selector
          if (availableMethods.length > 1) ...[
            _buildMethodSelector(),
            const SizedBox(height: 20),
          ],

          // QR Code
          if (selectedMethod?.id != 'cash') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: QrImageView(
                data: qrData ?? '',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quét mã QR để thanh toán',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedMethod?.description ?? '',
              style: TextStyle(color: AppTheme.textSecondaryLight),
            ),
          ] else ...[
            // Cash payment
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.money, size: 64, color: Colors.green[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Thanh toán tiền mặt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vui lòng thanh toán ${_formatCurrency(widget.amount)} VNĐ tại quầy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.green[600]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Text(
                      'Mã thanh toán: $paymentId',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          _buildPaymentDetails(),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: availableMethods.length,
        itemBuilder: (context, index) {
          final method = availableMethods[index];
          final isSelected = selectedMethod?.id == method.id;

          return GestureDetector(
            onTap: () async {
              if (selectedMethod?.id != method.id) {
                setState(() => selectedMethod = method);
                await _generateQRCode();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? method.color.withValues(alpha: 0.12) : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected ? method.color : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    method.icon,
                    color: isSelected ? method.color : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method.name,
                    style: TextStyle(
                      color: isSelected ? method.color : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDetailRow('Số tiền:', '${_formatCurrency(widget.amount)} VNĐ'),
          _buildDetailRow('Nội dung:', widget.description),
          if (paymentId != null)
            _buildDetailRow('Mã giao dịch:', paymentId!),
          _buildDetailRow('Trạng thái:', 'Chờ thanh toán'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: Colors.green, size: 80),
        ),
        const SizedBox(height: 20),
        Text(
          'Thanh toán thành công!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_formatCurrency(widget.amount)} VNĐ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Text(
            'Mã giao dịch: $paymentId',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed() {
    return Column(
      children: [
        Icon(Icons.error, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          status == 'expired' ? "Hết thời gian thanh toán" : 'Thanh toán thất bại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng thử lại hoặc chọn phương thức khác',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Có lỗi xảy ra',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng thử lại sau',
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (status == 'ready' && selectedMethod?.id != 'cash') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareQRCode(),
              icon: const Icon(Icons.share),
              label: const Text('Chia sẻ'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _copyQRData(),
              icon: const Icon(Icons.copy),
              label: const Text('Sao chép'),
            ),
          ),
        ],
      );
    } else if (status == 'failed' || status == 'expired' || status == 'error') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _loadPaymentMethods(),
          icon: const Icon(Icons.refresh),
          label: const Text('Thử lại'),
        ),
      );
    } else if (status == 'confirmed') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.check),
          label: const Text('Hoàn thành'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _shareQRCode() {
    if (qrData != null) {
      Share.share(
        'Thanh toán ${_formatCurrency(widget.amount)} VNĐ\n'
        'Nội dung: ${widget.description}\n'
        'Mã QR: $qrData',
        subject: 'Thanh toán QR Code',
      );
    }
  }

  void _copyQRData() {
    if (qrData != null) {
      Clipboard.setData(ClipboardData(text: qrData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép mã QR')),
      );
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final Map<String, dynamic>? data;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    this.data,
  });
}