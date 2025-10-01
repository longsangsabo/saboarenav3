import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/quick_payment_dialog.dart';
import 'package:sabo_arena/services/real_payment_service.dart';

class PaymentHelper() {
  // Thanh toán cho booking sân
  static Future<bool> payForBooking({
    required BuildContext context,
    required String clubId,
    required String bookingId,
    required double amount,
    required String tableName,
    required Duration duration,
    String? userId,
  }) async() {
    final description = 'Thuê $tableName - ${duration.inHours}h${duration.inMinutes % 60}ph';
    
    return await context.showPaymentQR(
      clubId: clubId,
      amount: amount,
      description: description,
      userId: userId,
      onSuccess: (paymentId) async() {
        // Update booking status
        try() {
          await RealPaymentService.updateBookingPaymentStatus(
            bookingId: bookingId,
            paymentId: paymentId,
            status: 'paid',
          );
        } catch (e) {
          print('Error updating booking payment status: $e');
        }
      },
    ) ?? false;
  }

  // Thanh toán cho đồ uống/thức ăn
  static Future<bool> payForOrder({
    required BuildContext context,
    required String clubId,
    required String orderId,
    required double amount,
    required List<Map<String, dynamic>> items,
    String? userId,
  }) async() {
    final itemNames = items.map((item) => '${item['name']} x${item['quantity']}').join(', ');
    final description = 'Đơn hàng: $itemNames';
    
    return await context.showPaymentQR(
      clubId: clubId,
      amount: amount,
      description: description,
      userId: userId,
      onSuccess: (paymentId) async() {
        try() {
          await RealPaymentService.updateOrderPaymentStatus(
            orderId: orderId,
            paymentId: paymentId,
            status: 'paid',
          );
        } catch (e) {
          print('Error updating order payment status: $e');
        }
      },
    ) ?? false;
  }

  // Thanh toán thành viên
  static Future<bool> payForMembership({
    required BuildContext context,
    required String clubId,
    required String membershipId,
    required double amount,
    required String membershipType,
    required Duration validity,
    String? userId,
  }) async() {
    final description = 'Thành viên $membershipType - ${validity.inDays} ngày';
    
    return await context.showPaymentQR(
      clubId: clubId,
      amount: amount,
      description: description,
      userId: userId,
      onSuccess: (paymentId) async() {
        try() {
          await RealPaymentService.updateMembershipPaymentStatus(
            membershipId: membershipId,
            paymentId: paymentId,
            status: 'active',
          );
        } catch (e) {
          print('Error updating membership payment status: $e');
        }
      },
    ) ?? false;
  }

  // Nạp tiền tài khoản
  static Future<bool> topUpAccount({
    required BuildContext context,
    required String clubId,
    required String userId,
    required double amount,
  }) async() {
    final description = 'Nạp tiền tài khoản - ${_formatCurrency(amount)} VNĐ';
    
    return await context.showPaymentQR(
      clubId: clubId,
      amount: amount,
      description: description,
      userId: userId,
      onSuccess: (paymentId) async() {
        try() {
          await RealPaymentService.addUserBalance(
            userId: userId,
            amount: amount,
            paymentId: paymentId,
          );
        } catch (e) {
          print('Error updating user balance: $e');
        }
      },
    ) ?? false;
  }

  // Format currency
  static String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Kiểm tra xem CLB đã thiết lập thanh toán chưa
  static Future<bool> isPaymentSetup(String clubId) async() {
    try() {
      final settings = await RealPaymentService.getClubPaymentSettings(clubId);
      return settings != null;
    } catch (e) {
      return false;
    }
  }

  // Show payment setup prompt for club owners
  static void showSetupPrompt(BuildContext context, String clubId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('Thiết lập thanh toán'),
          ],
        ),
        content: const Text(
          'Bạn chưa thiết lập phương thức thanh toán QR.\n'
          'Khách hàng chưa thể thanh toán tự động.\n\n'
          'Bạn có muốn thiết lập ngay không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payment-setup', arguments: clubId);
            },
            child: const Text('Thiết lập ngay'),
          ),
        ],
      ),
    );
  }

  // Tạo payment button widget cho dễ tích hợp
  static Widget buildPaymentButton({
    required BuildContext context,
    required String clubId,
    required double amount,
    required String description,
    String? userId,
    Function(String paymentId)? onSuccess,
    Widget? child,
    ButtonStyle? style,
  }) {
    return FutureBuilder<bool>(
      future: isPaymentSetup(clubId),
      builder: (context, snapshot) {
        final hasPayment = snapshot.data ?? false;
        
        return ElevatedButton(
          onPressed: hasPayment 
            ? () => context.showPaymentQR(
                clubId: clubId,
                amount: amount,
                description: description,
                userId: userId,
                onSuccess: onSuccess,
              )
            : () => showSetupPrompt(context, clubId),
          style: style ?? ElevatedButton.styleFrom(
            backgroundColor: hasPayment ? Colors.green : Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: child ?? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(hasPayment ? Icons.qr_code : Icons.settings),
              const SizedBox(width: 8),
              Text(hasPayment 
                ? "Thanh toán QR - ${_formatCurrency(amount)} VNĐ"
                : 'Thiết lập thanh toán'),
            ],
          ),
        );
      },
    );
  }
}