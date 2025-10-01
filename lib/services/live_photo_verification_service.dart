import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:typed_data';

// Task Verification Models
class TaskVerification {
  final String id;
  final String taskId;
  final String staffId;
  final String clubId;
  final String taskType; // 'cleaning', 'maintenance', 'setup', 'closing'
  final String description;
  final String photoUrl;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final VerificationStatus status;

  TaskVerification({
    required this.id,
    required this.taskId,
    required this.staffId,
    required this.clubId,
    required this.taskType,
    required this.description,
    required this.photoUrl,
    required this.metadata,
    required this.createdAt,
    required this.status,
  });
}

enum VerificationStatus { pending, verified, rejected }

// Live Photo Capture Service
class LivePhotoService {
  static final LivePhotoService _instance = LivePhotoService._internal();
  factory LivePhotoService() => _instance;
  LivePhotoService._internal();

  // Capture photo with live verification
  Future<TaskVerification?> captureTaskVerification({
    required String taskId,
    required String taskType,
    required String description,
    required String clubId,
  }) async {
    try {
      // 1. Check permissions
      if (!await _checkPermissions()) {
        throw Exception('Camera và GPS permissions required');
      }

      // 2. Get current location
      Position position = await _getCurrentLocation();
      
      // 3. Initialize camera
      List<CameraDescription> cameras = await availableCameras();
      CameraDescription camera = cameras.first;
      
      // 4. Open live camera capture screen
      String? photoPath = await Navigator.push(
        NavigationService.navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => LiveCaptureScreen(
            camera: camera,
            taskType: taskType,
            taskDescription: description,
          ),
        ),
      );

      if (photoPath == null) return null;

      // 5. Process photo with metadata
      String processedPhotoUrl = await _processPhotoWithMetadata(
        photoPath: photoPath,
        position: position,
        taskId: taskId,
        taskType: taskType,
      );

      // 6. Create verification record
      TaskVerification verification = TaskVerification(
        id: generateId(),
        taskId: taskId,
        staffId: getCurrentUserId(),
        clubId: clubId,
        taskType: taskType,
        description: description,
        photoUrl: processedPhotoUrl,
        metadata: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'deviceId': await getDeviceId(),
          'appVersion': await getAppVersion(),
          'photoHash': await calculatePhotoHash(photoPath),
        },
        createdAt: DateTime.now(),
        status: VerificationStatus.pending,
      );

      // 7. Upload to backend
      await _uploadVerification(verification);

      return verification;

    } catch (e) {
      print('Error capturing verification: $e');
      return null;
    }
  }

  // Check required permissions
  Future<bool> _checkPermissions() async {
    LocationPermission locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    return locationPermission == LocationPermission.whileInUse ||
           locationPermission == LocationPermission.always;
  }

  // Get current accurate location
  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );
  }

  // Process photo with watermark and metadata
  Future<String> _processPhotoWithMetadata({
    required String photoPath,
    required Position position,
    required String taskId,
    required String taskType,
  }) async {
    // Read image
    File imageFile = File(photoPath);
    Uint8List imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) throw Exception('Cannot process image');

    // Add watermark with metadata
    String watermarkText = '''
SABO ARENA - TASK VERIFICATION
${taskType.toUpperCase()}
${DateTime.now().toString()}
ID: $taskId
GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}
LIVE CAPTURE - VERIFIED
''';

    // Draw watermark (simplified - you can use more advanced libraries)
    img.Image watermarkedImage = _addWatermark(image, watermarkText);

    // Save processed image
    String processedPath = photoPath.replaceAll('.jpg', '_verified.jpg');
    File processedFile = File(processedPath);
    await processedFile.writeAsBytes(img.encodeJpg(watermarkedImage));

    // Upload to cloud storage and return URL
    return await uploadToCloudStorage(processedPath);
  }

  // Add watermark to image
  img.Image _addWatermark(img.Image image, String text) {
    // This is simplified - in production use proper text rendering
    // You can use packages like 'flutter_image_utilities' for better text rendering
    
    // For now, return image as-is (implement proper watermarking)
    return image;
  }

  // Calculate photo hash for integrity verification
  Future<String> calculatePhotoHash(String photoPath) async {
    File file = File(photoPath);
    List<int> bytes = await file.readAsBytes();
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Upload verification to backend
  Future<void> _uploadVerification(TaskVerification verification) async {
    // Upload to Supabase
    await SupabaseService.client
        .from('task_verifications')
        .insert(verification.toJson());
  }
}

// Live Camera Capture Screen  
class LiveCaptureScreen extends StatefulWidget {
  const LiveCaptureScreen({super.key});

} 
  final CameraDescription camera;
  final String taskType;
  final String taskDescription;

  const LiveCaptureScreen({
    Key? key,
    required this.camera,
    required this.taskType,
    required this.taskDescription,
  }) : super(key: key);

  @override
  State<LiveCaptureScreen> createState() => _LiveCaptureScreenState();
}

class _LiveCaptureScreenState extends State<LiveCaptureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false, // No audio needed for verification photos
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Xác minh: ${widget.taskType}',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Task description
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade900,
            child: Text(
              widget.taskDescription,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Camera preview
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      // Camera preview
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CameraPreview(_controller),
                      ),
                      
                      // Overlay guidelines
                      _buildCameraOverlay(),
                      
                      // Live timestamp
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: StreamBuilder(
                            stream: Stream.periodic(Duration(seconds: 1)),
                            builder: (context, snapshot) {
                              return Text(
                                'LIVE • ${DateTime.now().toString().substring(11, 19)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  () {
                  return Center(child: CircularProgressIndicator());
                }
              
                }},
            ),
          ),
          
          // Capture controls
          Container(
            height: 120,
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Cancel button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                ),
                
                // Capture button
                GestureDetector(
                  onTap: _isProcessing ? null : _capturePhoto,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? Colors.grey : Colors.red,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: _isProcessing 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Icon(Icons.camera_alt, color: Colors.white, size: 35),
                  ),
                ),
                
                // Info button
                IconButton(
                  onPressed: _showCaptureInfo,
                  icon: Icon(Icons.info_outline, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: CameraOverlayPainter(),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      await initializeControllerFuture;
      
      // Capture image
      XFile photo = await _controller.takePicture();
      
      // Return photo path
      Navigator.pop(context, photo.path);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp ảnh: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showCaptureInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hướng dẫn chụp ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Chụp ảnh rõ nét, đầy đủ khu vực'),
            Text('• Đảm bảo ánh sáng đủ'),
            Text('• Ảnh sẽ được đánh dấu thời gian và vị trí'),
            Text('• Không thể sử dụng ảnh có sẵn'),
            Text('• Ảnh sẽ được xác minh tự động'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

// Custom painter for camera overlay
class CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw guide lines
    double centerX = size.width / 2;
    double centerY = size.height / 2;
    
    // Vertical line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );
    
    // Corner brackets
    double bracketSize = 30;
    Paint bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Top-left
    canvas.drawLine(Offset(20, 20), Offset(20 + bracketSize, 20), bracketPaint);
    canvas.drawLine(Offset(20, 20), Offset(20, 20 + bracketSize), bracketPaint);
    
    // Top-right
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20 - bracketSize, 20), bracketPaint);
    canvas.drawLine(Offset(size.width - 20, 20), Offset(size.width - 20, 20 + bracketSize), bracketPaint);
    
    // Bottom-left
    canvas.drawLine(Offset(20, size.height - 20), Offset(20 + bracketSize, size.height - 20), bracketPaint);
    canvas.drawLine(Offset(20, size.height - 20), Offset(20, size.height - 20 - bracketSize), bracketPaint);
    
    // Bottom-right
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20 - bracketSize, size.height - 20), bracketPaint);
    canvas.drawLine(Offset(size.width - 20, size.height - 20), Offset(size.width - 20, size.height - 20 - bracketSize), bracketPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}