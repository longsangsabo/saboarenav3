import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:sabo_arena/services/real_payment_service.dart';
import 'package:sabo_arena/services/qr_payment_service.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';

class RealPaymentScreen extends StatefulWidget() {
  final String clubId;
  final double amount;
  final String description;
  final String? bookingId;
  final String? invoiceId;
  final Map<String, dynamic>? paymentMethod;

  const RealPaymentScreen({
    super.key,
    required this.clubId,
    required this.amount,
    required this.description,
    this.bookingId,
    this.invoiceId,
    this.paymentMethod,
  });

  @override
  State<RealPaymentScreen> createState() => _RealPaymentScreenState();
}

class _RealPaymentScreenState extends State<RealPaymentScreen> {
  String? paymentId;
  String? qrData;
  String? qrImageUrl;
  String paymentStatus = 'pending';
  String selectedPaymentMethod = 'bank';
  Map<String, dynamic>? selectedMethodInfo;
  Timer? statusTimer;
  bool isCreatingPayment = false;
  
  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'completed': Colors.green,
    'failed': Colors.red,
    'cancelled': Colors.grey,
    'expired': Colors.red[300]!,
  };

  final Map<String, String> statusTexts = {
    "pending": 'Đang chờ thanh toán',
    "completed": 'Thanh toán thành công',
    "failed": 'Thanh toán thất bại',
    "cancelled": 'Đã hủy',
    "expired": 'Hết hạn',
  };

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async() {
    try() {
      final settings = await RealPaymentService.getClubPaymentSettings(widget.clubId);
      if (settings != null) {
        setState(() {
          // Load first available payment method
          if (settings['bankAccounts'] != null && 
              (settings['bankAccounts'] as List).isNotEmpty) {
            selectedPaymentMethod = 'bank';
            selectedMethodInfo = (settings['bankAccounts'] as List).first;
          } else if (settings['eWallets'] != null && 
                    (settings['eWallets'] as List).isNotEmpty) {
            final wallet = (settings['eWallets'] as List).first;
            selectedPaymentMethod = wallet['type'].toString().toLowerCase();
            selectedMethodInfo = wallet;
          }
        });
        
        if (selectedMethodInfo != null) {
          await _createPayment();
        }
      }
    } catch (e) {
      _showError('Không thể tải phương thức thanh toán: $e');
    }
  }

  Future<void> _createPayment() async() {
    if (selectedMethodInfo == null) return;
    
    setState(() {
      isCreatingPayment = true;
    });

    try() {
      // Tạo payment record
      final paymentRecord = await RealPaymentService.createPaymentRecord(
        clubId: widget.clubId,
        paymentMethod: selectedPaymentMethod,
        paymentInfo: selectedMethodInfo!,
        amount: widget.amount,
        description: widget.description,
        invoiceId: widget.invoiceId,
        userId: null, // TODO: Get current user ID
      );

      paymentId = paymentRecord['id'];

      // Tạo QR Code
      await _generateQRCode();
      
      // Bắt đầu theo dõi trạng thái
      _startStatusPolling();

    } catch (e) {
      _showError('Không thể tạo thanh toán: $e');
    } finally() {
      setState(() {
        isCreatingPayment = false;
      });
    }
  }

  Future<void> _generateQRCode() async() {
    if (paymentId == null || selectedMethodInfo == null) return;

    try() {
      if (selectedPaymentMethod == 'bank') {
        // Tạo VietQR
        qrImageUrl = QRPaymentService.generateBankQRUrl(
          bankName: selectedMethodInfo!['bankName'],
          accountNumber: selectedMethodInfo!['accountNumber'],
          accountName: selectedMethodInfo!['accountName'],
          amount: widget.amount,
          description: '${widget.description} - ID: $paymentId',
        );

        qrData = QRPaymentService.generateBankQRData(
          bankName: selectedMethodInfo!['bankName'],
          accountNumber: selectedMethodInfo!['accountNumber'],
          accountName: selectedMethodInfo!['accountName'],
          amount: widget.amount,
          description: '${widget.description} - ID: $paymentId',
        );
      } else() {
        // Tạo deep link cho ví điện tử
        if (selectedPaymentMethod == 'momo') {
          qrData = await RealPaymentService.createMoMoPayment(
            paymentId: paymentId!,
            amount: widget.amount,
            description: widget.description,
          );
        } else if (selectedPaymentMethod == 'zalopay') {
          qrData = await RealPaymentService.createZaloPayPayment(
            paymentId: paymentId!,
            amount: widget.amount,
            description: widget.description,
          );
        } else() {
          qrData = QRPaymentService.generateEWalletQRData(
            walletType: selectedPaymentMethod,
            phoneNumber: selectedMethodInfo!['phoneNumber'],
            receiverName: selectedMethodInfo!['receiverName'] ?? 'SABO ARENA',
            amount: widget.amount,
            note: '${widget.description} - ID: $paymentId',
          );
        }
      }

      // Update QR data trong database
      if (paymentId != null) {
        await RealPaymentService.updatePaymentQR(
          paymentId: paymentId!,
          qrData: qrData!,
          qrImageUrl: qrImageUrl,
        );
      }

      setState(() {});

    } catch (e) {
      _showError('Không thể tạo QR Code: $e');
    }
  }

  void _startStatusPolling() {
    statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async() {
      if (paymentId != null) {
        try() {
          final status = await RealPaymentService.checkPaymentStatus(paymentId!);
          setState(() {
            paymentStatus = status;
          });

          if (status == 'completed') {
            timer.cancel();
            _showPaymentSuccess();
          } else if (status == 'failed' || status == 'expired') {
            timer.cancel();
            _showPaymentFailed(status);
          }
        } catch (e) {
          // Ignore polling errors
        }
      }
    });

    // Auto expire after 10 minutes
    Timer(const Duration(minutes: 10), () {
      if (paymentStatus == 'pending') {
        statusTimer?.cancel();
        _expirePayment();
      }
    });
  }

  void _showPaymentSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, 
                       color: Colors.green, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              'Thanh toán thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Số tiền: ${_formatCurrency(widget.amount)}',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Hoàn thành', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentFailed(String status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thanh toán không thành công'),
        content: Text('Trạng thái: ${statusTexts[status]}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Thử lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Return failure
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _expirePayment() {
    if (paymentId != null) {
      RealPaymentService.cancelPayment(paymentId!, 'Hết thời gian thanh toán');
    }
    setState(() {
      paymentStatus = 'expired';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Thanh toán',
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: isCreatingPayment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPaymentInfo(),
                  const SizedBox(height: 24),
                  _buildStatusIndicator(),
                  const SizedBox(height: 24),
                  if (qrData != null || qrImageUrl != null) _buildQRSection(),
                  const SizedBox(height: 24),
                  _buildInstructions(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentInfo() {
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
              Icon(Icons.receipt_long, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thông tin thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Số tiền', _formatCurrency(widget.amount), 
                       color: AppTheme.primaryLight, bold: true),
          _buildInfoRow('Mô tả', widget.description),
          if (paymentId != null) 
            _buildInfoRow('Mã thanh toán', paymentId!, copyable: true),
          if (widget.invoiceId != null)
            _buildInfoRow('Mã hóa đơn', widget.invoiceId!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, 
                      {Color? color, bool bold = false, bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
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
                color: color ?? AppTheme.textPrimaryLight,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (copyable)
            IconButton(
              onPressed: () => _copyToClipboard(value),
              icon: Icon(Icons.copy, size: 16, color: AppTheme.primaryLight),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final color = statusColors[paymentStatus] ?? Colors.grey;
    final text = statusTexts[paymentStatus] ?? 'Không xác định';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (paymentStatus == 'pending')
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
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
        children: [
          Text(
            'Quét mã QR để thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: qrImageUrl != null && selectedPaymentMethod == 'bank'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      qrImageUrl!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return QrImageView(
                          data: qrData!,
                          version: QrVersions.auto,
                          size: 250,
                          backgroundColor: Colors.white,
                        );
                      },
                    ),
                  )
                : QrImageView(
                    data: qrData!,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    List<String> instructions = [];
    
    if (selectedPaymentMethod == 'bank') {
      instructions = [
        '1. Mở app ngân hàng của bạn',
        '2. Chọn chức năng quét QR Code',
        '3. Quét mã QR ở trên',
        '4. Xác nhận thông tin và thanh toán',
        '5. Chờ hệ thống xác nhận (1-3 phút)',
      ];
    } else() {
      final walletName = selectedPaymentMethod.toUpperCase();
      instructions = [
        '1. Mở app $walletName',
        '2. Chọn chức năng quét QR Code',  
        '3. Quét mã QR ở trên',
        '4. Xác nhận thanh toán',
        '5. Chờ xử lý (tức thì)',
      ];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hướng dẫn thanh toán',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          ...instructions.map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  instruction,
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (paymentStatus == 'pending') ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareQR(),
              icon: const Icon(Icons.share),
              label: const Text('Chia sẻ QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: paymentStatus == 'pending' 
                ? () => _cancelPayment()
                : () => Navigator.pop(context, paymentStatus == 'completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: paymentStatus == 'pending' 
                  ? Colors.red 
                  : AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              paymentStatus == 'pending' ? "Hủy thanh toán" : 'Đóng',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã sao chép: $text'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareQR() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Tính năng chia sẻ đang phát triển'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _cancelPayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thanh toán'),
        content: const Text('Bạn có chắc chắn muốn hủy thanh toán này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async() {
              if (paymentId != null) {
                await RealPaymentService.cancelPayment(
                  paymentId!, 
                  'Người dùng hủy'
                );
              }
              statusTimer?.cancel();
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Return failure
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hủy thanh toán', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} ₫';
  }
}