import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/attendance_service.dart';

class QRAttendanceScanner extends StatefulWidget {
  const QRAttendanceScanner({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final Function(Map<String, dynamic>) onScanResult;
  
  const QRAttendanceScanner({
    
    super.key,
    required this.onScanResult,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  State<QRAttendanceScanner> createState() => _QRAttendanceScannerState();
}

class _QRAttendanceScannerState extends State<QRAttendanceScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final AttendanceService _attendanceService = AttendanceService();
  
  bool isScanning = true;
  bool isProcessing = false;
  String? errorMessage;
  
  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (isScanning && !isProcessing && scanData.code != null) {
        _handleScanResult(scanData.code!);
      }
    });
  }

  Future<void> _handleScanResult(String qrData) async {
    if (isProcessing) return;
    
    setState(() {
      isProcessing = true;
      isScanning = false;
      errorMessage = null;
    });

    try {
      // Verify QR code
      final verificationResult = await _attendanceService.verifyAttendanceQR(qrData);
      
      if (verificationResult['success']) {
        // Stop scanning and return result
        await controller?.pauseCamera();
        widget.onScanResult(verificationResult);
      } else {
        () {
        setState(() {
          errorMessage = verificationResult['error'];
          isProcessing = false;
        });
        
        // Resume scanning after 3 seconds
        await Future.delayed(Duration(seconds: 3));
        setState(() {
          isScanning = true;
          errorMessage = null;
        });
      }
    
      }} catch (e) {
      setState(() {
        errorMessage = 'Lỗi quét QR: $e';
        isProcessing = false;
      });
      
      // Resume scanning after 3 seconds
      await Future.delayed(Duration(seconds: 3));
      setState(() {
        isScanning = true;
        errorMessage = null;
      });
    }
  }

  void _toggleFlash() async {
    await controller?.toggleFlash();
    setState(() {});
  }

  void _flipCamera() async {
    await controller?.flipCamera();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Quét mã chấm công'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // QR Scanner View
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: isProcessing ? Colors.orange : Colors.green,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
          
          // Instructions overlay
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Đưa camera về phía mã QR chấm công',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mã QR sẽ được quét tự động',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Processing overlay
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Đang xác thực QR code...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Error message
          if (errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: Colors.white,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
          // Bottom controls
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.flash_on,
                  label: 'Đèn flash',
                  onPressed: _toggleFlash,
                ),
                _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  label: 'Đổi camera',
                  onPressed: _flipCamera,
                ),
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Quét lại',
                  onPressed: () {
                    setState(() {
                      isScanning = true;
                      isProcessing = false;
                      errorMessage = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}