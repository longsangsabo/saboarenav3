import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/services/integrated_qr_service.dart';
import '../routes/app_routes.dart';
import '../core/utils/rank_migration_helper.dart';

class QRScannerWidget extends StatefulWidget {
  const QRScannerWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final Function(Map<String, dynamic>)? onUserFound;
  final VoidCallback? onCancel;

  const QRScannerWidget({
    
    super.key,
    this.onUserFound,
    this.onCancel,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool isScanning = true;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Quét QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel ?? () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(cameraController.torchEnabled ? Icons.flash_off : Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return _buildErrorView(error.toString());
            },
          ),

          // Overlay with scanning frame
          _buildScanningOverlay(),

          // Instructions
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: _buildInstructions(),
          ),

          // Error message
          if (errorMessage != null)
            Positioned(
              bottom: 8.h,
              left: 4.w,
              right: 4.w,
              child: _buildErrorMessage(),
            ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return CustomPaint(
      painter: QRScannerOverlayPainter(),
      child: Container(),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 8.w,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Đưa QR code vào khung để quét',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'QR code sẽ được quét tự động',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.red[600],
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => errorMessage = null),
            child: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 20.w,
              color: Colors.white54,
            ),
            SizedBox(height: 3.h),
            Text(
              'Không thể truy cập camera',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Vui lòng cho phép truy cập camera để quét QR code',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    if (barcode.rawValue == null) return;

    setState(() => isScanning = false);
    _processQRCode(barcode.rawValue!);
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      debugPrint('🔍 Processing QR code: $qrData');
      
      // Use IntegratedQRService to scan and validate
      final scanResult = await IntegratedQRService.scanIntegratedQR(qrData);
      
      if (scanResult != null && scanResult['success'] == true) {
        final qrType = scanResult['type'];
        final userProfile = scanResult['user_profile'];
        
        if (qrType == 'integrated_profile') {
          // Show integrated profile view with referral option
          _showIntegratedProfileDialog(scanResult);
        } else {
          () {
          // Legacy QR code, show normal user info
          if (widget.onUserFound != null) {
            widget.onUserFound!(userProfile ?? {});
          } else {
            () {
            _showUserFoundDialog(userProfile ?? {});
          }
        
          }}
      
        }} else {
        () {
        // QR invalid or user not found
        setState(() {
          errorMessage = scanResult?['error'] ?? 'QR code không hợp lệ';
          isScanning = true;
        });
      }
    
      }} catch (e) {
      debugPrint('❌ Error processing QR: $e');
      setState(() {
        errorMessage = 'Lỗi xử lý QR: $e';
        isScanning = true;
      });
    }
  }

  void _showIntegratedProfileDialog(Map<String, dynamic> scanResult) {
    final userProfile = scanResult['user_profile'];
    final userCode = scanResult['user_code'];
    final referralCode = scanResult['referral_code'];
    final actions = scanResult['actions'] as List<dynamic>? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.blue),
            SizedBox(width: 2.w),
            Text('QR Profile + Referral'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            if (userProfile != null) ...[
              if (userProfile['avatar_url'] != null)
                Center(
                  child: CircleAvatar(
                    radius: 8.w,
                    backgroundImage: NetworkImage(userProfile['avatar_url']),
                    backgroundColor: Colors.grey[300],
                  ),
                ),
              SizedBox(height: 2.h),
              Text(
                userProfile['full_name'] ?? 'Unknown User',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userProfile['bio'] != null) ...[
                SizedBox(height: 1.h),
                Text(userProfile['bio']),
              ],
              SizedBox(height: 2.h),
              _buildUserStat('User Code', userCode ?? 'N/A'),
              _buildUserStat('ELO Rating', '${userProfile['elo_rating'] ?? 1200}'),
              _buildUserStat('Rank', RankMigrationHelper.getNewDisplayName(userProfile['rank'] as String?)),
            ] else ...[
              Text(
                'User Code: $userCode',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text('Profile không tìm thấy, nhưng có thể dùng referral code'),
            ],
            
            // Referral Section
            if (referralCode != null) ...[
              Divider(height: 3.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, color: Colors.green, size: 5.w),
                        SizedBox(width: 2.w),
                        Text(
                          'Referral Bonus',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Code: $referralCode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Đăng ký qua QR này để nhận 50 SPA!',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: Text('Quét tiếp'),
          ),
          if (actions.contains('view_profile'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                // TODO: Navigate to user profile
              },
              child: Text('Xem Profile'),
            ),
          if (actions.contains('apply_referral'))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                // Navigate to registration with pre-filled referral
                Navigator.pushNamed(
                  context, 
                  AppRoutes.registerScreen,
                  arguments: {'referralCode': referralCode},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text('Đăng ký + Referral'),
            ),
        ],
      ),
    );
  }

  void _showUserFoundDialog(Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_pin_circle, color: Colors.green),
            SizedBox(width: 2.w),
            Text('Tìm thấy người chơi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (userData['avatar_url'] != null)
              Center(
                child: CircleAvatar(
                  radius: 8.w,
                  backgroundImage: NetworkImage(userData['avatar_url']),
                  backgroundColor: Colors.grey[300],
                ),
              ),
            SizedBox(height: 2.h),
            Text(
              userData['full_name'] ?? 'Unknown User',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (userData['bio'] != null) ...[
              SizedBox(height: 1.h),
              Text(userData['bio']),
            ],
            SizedBox(height: 2.h),
            _buildUserStat('ELO Rating', '${userData['elo_rating'] ?? 1200}'),
            _buildUserStat('Rank', RankMigrationHelper.getNewDisplayName(userData['rank'] as String?)),
            _buildUserStat('Thắng/Thua', '${userData['total_wins'] ?? 0}/${userData['total_losses'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: Text('Quét tiếp'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              // TODO: Navigate to user profile or challenge screen
            },
            child: Text('Xem hồ sơ'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStat(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class QRScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Background overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Scanner frame
    final scannerSize = size.width * 0.7;
    final scannerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scannerSize,
      height: scannerSize,
    );

    // Cut out the scanner area
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
    canvas.drawRect(scannerRect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    // Scanner border
    canvas.drawRect(scannerRect, borderPaint);

    // Corner indicators
    final cornerLength = 30.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top),
      Offset(scannerRect.left + cornerLength, scannerRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top),
      Offset(scannerRect.left, scannerRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.top),
      Offset(scannerRect.right - cornerLength, scannerRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom),
      Offset(scannerRect.left + cornerLength, scannerRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom),
      Offset(scannerRect.left, scannerRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.bottom),
      Offset(scannerRect.right - cornerLength, scannerRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.bottom),
      Offset(scannerRect.right, scannerRect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Helper widget to launch QR scanner
class QRScannerModal {
  static void show(BuildContext context, {Function(Map<String, dynamic>)? onUserFound}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(onUserFound: onUserFound),
        fullscreenDialog: true,
      ),
    );
  }
}