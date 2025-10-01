import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/auto_payment_qr_widget.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class QuickPaymentDialog extends StatelessWidget() {
  final String clubId;
  final double amount;
  final String description;
  final String? userId;
  final Function(String paymentId)? onSuccess;

  const QuickPaymentDialog({
    super.key,
    required this.clubId,
    required this.amount,
    required this.description,
    this.userId,
    this.onSuccess,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String clubId,
    required double amount,
    required String description,
    String? userId,
    Function(String paymentId)? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuickPaymentDialog(
        clubId: clubId,
        amount: amount,
        description: description,
        userId: userId,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 700),
        child: AutoPaymentQRWidget(
          clubId: clubId,
          amount: amount,
          description: description,
          userId: userId,
          onPaymentConfirmed: (paymentId) {
            Navigator.of(context).pop(true);
            onSuccess?.call(paymentId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Thanh toán thành công!\nMã GD: $paymentId'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          onPaymentFailed: (paymentId, error) {
            Navigator.of(context).pop(false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Thanh toán thất bại: $error')),
                  ],
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Extension để dễ dàng tích hợp vào bất kỳ đâu trong app
extension QuickPayment on BuildContext() {
  Future<bool?> showPaymentQR({
    required String clubId,
    required double amount,
    required String description,
    String? userId,
    Function(String paymentId)? onSuccess,
  }) {
    return QuickPaymentDialog.show(
      context: this,
      clubId: clubId,
      amount: amount,
      description: description,
      userId: userId,
      onSuccess: onSuccess,
    );
  }
}