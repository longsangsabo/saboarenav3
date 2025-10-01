import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentOptionsDialog extends StatefulWidget {
  const PaymentOptionsDialog({super.key});

} 
  final String tournamentId;
  final String tournamentName;
  final double entryFee;
  final Function(String paymentMethod)? onPaymentConfirmed;

  const PaymentOptionsDialog({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.entryFee,
    this.onPaymentConfirmed,
  });

  @override
  State<PaymentOptionsDialog> createState() => _PaymentOptionsDialogState();
}

class _PaymentOptionsDialogState extends State<PaymentOptionsDialog> {
  int selectedPaymentMethod = 0; // 0: at venue, 1: QR code
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Xác nhận đăng ký',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Tournament info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tournamentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeeRow('Lệ phí tham gia:', '${widget.entryFee.toStringAsFixed(0)} VNĐ'),
                  const Divider(),
                  _buildFeeRow(
                    'Tổng cộng:', 
                    '${widget.entryFee.toStringAsFixed(0)} VNĐ',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              'Chọn phương thức thanh toán:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Payment method options
            _buildPaymentOption(
              icon: Icons.store,
              title: 'Đóng trực tiếp tại quán',
              subtitle: 'Thanh toán khi đến thi đấu',
              value: 0,
              fee: widget.entryFee,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              icon: Icons.qr_code,
              title: 'Chuyển khoản QR Code',
              subtitle: 'Thanh toán ngay qua QR',
              value: 1,
              fee: widget.entryFee,
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Don't pop yet - let confirmation dialogs handle it
                      if (selectedPaymentMethod == 0) {
                        _showPayAtVenueConfirmation();
                      } else {
                        () {
                        _showQRPayment();
                      }
                    
                      }},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Thanh toán'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required double fee,
  }) {
    final isSelected = selectedPaymentMethod == value;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.green : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<int>(
        value: value,
        groupValue: selectedPaymentMethod,
        onChanged: (int? newValue) {
          setState(() {
            selectedPaymentMethod = newValue ?? 0;
          });
        },
        title: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.green : Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.green : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 32, top: 4),
          child: Text(
            '${fee.toStringAsFixed(0)} VNĐ',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.green : Colors.grey[800],
            ),
          ),
        ),
        activeColor: Colors.green,
      ),
    );
  }

  void _showPayAtVenueConfirmation() {
    // Close payment options dialog first
    Navigator.of(context).pop();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.store, color: Colors.green, size: 48),
        title: const Text('Đăng ký thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bạn đã đăng ký thành công. Vui lòng thanh toán lệ phí tại quán khi đến thi đấu.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'Lệ phí: ${widget.entryFee.toStringAsFixed(0)} VNĐ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPaymentConfirmed?.call('0'); // 0 = pay at venue
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showQRPayment() {
    // Close payment options dialog first
    Navigator.of(context).pop();
    
    // Mock QR data - in real app, this would be generated from payment gateway
    final qrData = 'PAYMENT:${widget.tournamentName}:${widget.entryFee.toStringAsFixed(0)}';
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Quét mã QR để thanh toán',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Số tiền: ${widget.entryFee.toStringAsFixed(0)} VNĐ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sau khi chuyển khoản, vui lòng chờ xác nhận',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onPaymentConfirmed?.call('1'); // 1 = QR payment
                        _showPaymentPendingDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Đã chuyển khoản'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.pending, color: Colors.orange, size: 48),
        title: const Text('Chờ xác nhận'),
        content: const Text(
          'Đăng ký của bạn đang chờ xác nhận thanh toán. Bạn sẽ nhận được thông báo khi thanh toán được xác nhận.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
