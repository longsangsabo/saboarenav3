
// EXAMPLE USAGE - Copy này vào code để sử dụng

// 1. Import cần thiết
import 'package:sabo_arena/helpers/payment_helper.dart';

// 2. Thanh toán đặt sân
await PaymentHelper.payForBooking(
  context = context,
  clubId = 'your-club-id',
  bookingId = 'booking-123',
  amount = 100000,
  tableName = 'Bàn số 1',
  duration = Duration(hours: 2),
  userId = 'user-id',
);

// 3. Nạp tiền tài khoản
await PaymentHelper.topUpAccount(
  context = context,
  clubId = 'your-club-id',
  userId = 'user-id',
  amount = 200000,
);

// 4. Tạo button thanh toán
PaymentHelper.buildPaymentButton(
  context = context,
  clubId = 'your-club-id',
  amount = 50000,
  description = 'Thanh toán đơn hàng',
  onSuccess = (paymentId) {
    print('Payment successful: $paymentId');
  },
)

// 5. Quick payment dialog
context.showPaymentQR(
  clubId = 'your-club-id',
  amount = 75000,
  description = 'Thanh toán dịch vụ',
);
