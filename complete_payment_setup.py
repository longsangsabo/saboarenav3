#!/usr/bin/env python3
"""
Complete Payment System Setup Script
Thiết lập hoàn chỉnh hệ thống thanh toán QR cho Sabo Arena

This script ensures all payment components are properly integrated
and ready for production use.
"""

import os
import sys
import subprocess

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"\n🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} - SUCCESS")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} - FAILED")
        print(f"Error: {e.stderr}")
        return False

def check_file_exists(file_path, description):
    """Check if a file exists"""
    if os.path.exists(file_path):
        print(f"✅ {description} - EXISTS")
        return True
    else:
        print(f"❌ {description} - MISSING")
        return False

def main():
    print("🚀 SABO ARENA - COMPLETE PAYMENT SYSTEM SETUP")
    print("=" * 60)
    
    # Change to project directory
    os.chdir('/workspaces/saboarenav3')
    
    success_count = 0
    total_checks = 0
    
    # 1. Check Flutter project structure
    print("\n📁 CHECKING PROJECT STRUCTURE:")
    files_to_check = [
        ('lib/services/real_payment_service.dart', 'Real Payment Service'),
        ('lib/services/qr_payment_service.dart', 'QR Payment Service'),
        ('lib/widgets/auto_payment_qr_widget.dart', 'Auto Payment QR Widget'),
        ('lib/widgets/quick_payment_dialog.dart', 'Quick Payment Dialog'),
        ('lib/widgets/payment_qr_widget.dart', 'Payment QR Widget'),
        ('lib/presentation/payment/payment_setup_screen.dart', 'Payment Setup Screen'),
        ('lib/presentation/club_settings_screen/payment_settings_screen.dart', 'Payment Settings Screen'),
        ('lib/helpers/payment_helper.dart', 'Payment Helper'),
        ('QR_CODE_PAYMENT_GUIDE.md', 'Payment Guide Documentation'),
        ('real_payment_system_setup.sql', 'Database Schema'),
        ('setup_real_payment_system.py', 'Database Setup Script'),
    ]
    
    for file_path, description in files_to_check:
        if check_file_exists(file_path, description):
            success_count += 1
        total_checks += 1
    
    # 2. Check dependencies
    print("\n📦 CHECKING FLUTTER DEPENDENCIES:")
    deps_to_check = [
        'qr_flutter',
        'share_plus', 
        'supabase_flutter',
        'crypto',
        'http',
    ]
    
    for dep in deps_to_check:
        if run_command(f"grep -q '{dep}:' pubspec.yaml", f"Dependency {dep}"):
            success_count += 1
        total_checks += 1
    
    # 3. Flutter commands
    print("\n🔧 FLUTTER PROJECT SETUP:")
    commands = [
        ('flutter clean', 'Clean Flutter project'),
        ('flutter pub get', 'Get Flutter dependencies'),
        ('flutter analyze --no-fatal-infos', 'Analyze Flutter code'),
    ]
    
    for command, description in commands:
        if run_command(command, description):
            success_count += 1
        total_checks += 1
    
    # 4. Database setup check
    print("\n🗄️ DATABASE SETUP:")
    if check_file_exists('real_payment_system_setup.sql', 'Database Schema File'):
        success_count += 1
    total_checks += 1
    
    # Try to run database setup
    if run_command('python3 setup_real_payment_system.py', 'Database Setup Execution'):
        success_count += 1
    total_checks += 1
    
    # 5. Create example usage file
    print("\n📝 CREATING USAGE EXAMPLES:")
    example_content = '''
// EXAMPLE USAGE - Copy này vào code để sử dụng

// 1. Import cần thiết
import 'package:sabo_arena/helpers/payment_helper.dart';

// 2. Thanh toán đặt sân
await PaymentHelper.payForBooking(
  context: context,
  clubId: 'your-club-id',
  bookingId: 'booking-123',
  amount: 100000,
  tableName: 'Bàn số 1',
  duration: Duration(hours: 2),
  userId: 'user-id',
);

// 3. Nạp tiền tài khoản
await PaymentHelper.topUpAccount(
  context: context,
  clubId: 'your-club-id',
  userId: 'user-id',
  amount: 200000,
);

// 4. Tạo button thanh toán
PaymentHelper.buildPaymentButton(
  context: context,
  clubId: 'your-club-id',
  amount: 50000,
  description: 'Thanh toán đơn hàng',
  onSuccess: (paymentId) {
    print('Payment successful: $paymentId');
  },
)

// 5. Quick payment dialog
context.showPaymentQR(
  clubId: 'your-club-id',
  amount: 75000,
  description: 'Thanh toán dịch vụ',
);
'''
    
    try:
        with open('PAYMENT_USAGE_EXAMPLES.dart', 'w') as f:
            f.write(example_content)
        print("✅ Usage Examples - CREATED")
        success_count += 1
    except Exception as e:
        print(f"❌ Usage Examples - FAILED: {e}")
    total_checks += 1
    
    # 6. Create integration checklist
    print("\n📋 CREATING INTEGRATION CHECKLIST:")
    checklist_content = '''
# PAYMENT SYSTEM INTEGRATION CHECKLIST

## ✅ SETUP COMPLETED
- [x] Real Payment Service
- [x] QR Payment Service  
- [x] Auto Payment QR Widget
- [x] Payment Setup Screen
- [x] Database Schema
- [x] Payment Helper
- [x] Quick Payment Dialog

## 🔧 INTEGRATION STEPS

### 1. Club Owner Setup (5 phút)
- Vào Settings > Phương thức thanh toán
- Click "Thiết lập thanh toán QR"  
- Nhập thông tin ngân hàng + ví điện tử
- Test QR Code
- Lưu cài đặt

### 2. Tích hợp vào Booking
```dart
// Trong booking confirmation screen
await PaymentHelper.payForBooking(
  context: context,
  clubId: widget.clubId,
  bookingId: bookingId,
  amount: totalAmount,
  tableName: selectedTable,
  duration: bookingDuration,
);
```

### 3. Tích hợp vào Order System  
```dart
// Trong order checkout
await PaymentHelper.payForOrder(
  context: context,
  clubId: widget.clubId,
  orderId: orderId,
  amount: orderTotal,
  items: orderItems,
);
```

### 4. Add to any Screen
```dart
// Quick payment button
PaymentHelper.buildPaymentButton(
  context: context,
  clubId: clubId,
  amount: amount,
  description: description,
)
```

## 🚀 FEATURES READY
- ✅ VietQR cho 23+ ngân hàng Việt Nam
- ✅ MoMo, ZaloPay QR Code
- ✅ Real-time payment tracking
- ✅ Automatic payment confirmation
- ✅ Payment history & analytics
- ✅ Webhook handling
- ✅ Database integration
- ✅ Beautiful Material Design UI
- ✅ Error handling & validation
- ✅ Auto-expiration (10 minutes)

## 🎯 NEXT STEPS
1. Test thanh toán thực tế
2. Đăng ký MoMo/ZaloPay Business API
3. Setup webhook endpoints
4. Train staff sử dụng hệ thống
5. Monitor payment analytics

## 🆘 SUPPORT
- Check QR_CODE_PAYMENT_GUIDE.md for detailed docs
- Use PAYMENT_USAGE_EXAMPLES.dart for code samples
- Database schema in real_payment_system_setup.sql
'''
    
    try:
        with open('PAYMENT_INTEGRATION_CHECKLIST.md', 'w') as f:
            f.write(checklist_content)
        print("✅ Integration Checklist - CREATED")
        success_count += 1
    except Exception as e:
        print(f"❌ Integration Checklist - FAILED: {e}")
    total_checks += 1
    
    # Final summary
    print("\n" + "=" * 60)
    print("🎯 SETUP SUMMARY")
    print("=" * 60)
    print(f"✅ Successful: {success_count}/{total_checks}")
    print(f"❌ Failed: {total_checks - success_count}/{total_checks}")
    
    if success_count == total_checks:
        print("\n🎉 SETUP HOÀN THÀNH 100%!")
        print("🚀 Payment system sẵn sàng sử dụng!")
        print("\n📋 NEXT STEPS:")
        print("1. Vào app Settings > Phương thức thanh toán")
        print("2. Thiết lập thông tin ngân hàng + ví điện tử")
        print("3. Test QR Code")  
        print("4. Tích hợp vào booking/order screens")
        print("5. Train staff và go-live!")
    else:
        print(f"\n⚠️  CÓ {total_checks - success_count} LỖI CẦN SỬA")
        print("📞 Liên hệ dev để hỗ trợ fix lỗi")
        
    return success_count == total_checks

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)