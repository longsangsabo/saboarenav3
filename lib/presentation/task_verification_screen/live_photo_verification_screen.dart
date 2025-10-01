import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../models/task_models.dart';
import '../../services/live_photo_verification_service.dart';

class LivePhotoVerificationScreen extends StatefulWidget() {
  final StaffTask task;

  const LivePhotoVerificationScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<LivePhotoVerificationScreen> createState() => _LivePhotoVerificationScreenState();
}

class _LivePhotoVerificationScreenState extends State<LivePhotoVerificationScreen>
    with WidgetsBindingObserver() {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  
  Position? _currentLocation;
  bool _locationPermissionGranted = false;
  double? _distanceFromRequired;
  
  final LivePhotoService _photoService = LivePhotoService();
  
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async() {
    try() {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'Không tìm thấy camera trên thiết bị';
        });
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khởi tạo camera: $e';
      });
    }
  }

  Future<void> _getCurrentLocation() async() {
    try() {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Dịch vụ định vị chưa được bật';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Quyền truy cập vị trí bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Quyền truy cập vị trí bị từ chối vĩnh viễn';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = position;
        _locationPermissionGranted = true;
      });

      _calculateDistanceFromRequired();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi lấy vị trí: $e';
      });
    }
  }

  void _calculateDistanceFromRequired() {
    if (_currentLocation == null || widget.task.requiredLocation == null) return;

    final requiredLat = widget.task.requiredLocation!['lat'] as double;
    final requiredLng = widget.task.requiredLocation!['lng'] as double;

    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      requiredLat,
      requiredLng,
    );

    setState(() {
      _distanceFromRequired = distance;
    });
  }

  Future<void> _capturePhoto() async() {
    if (!_isCameraInitialized || _isCapturing || _controller == null) return;

    if (_currentLocation == null) {
      _showErrorDialog('Vui lòng bật GPS và cho phép truy cập vị trí');
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try() {
      final XFile photo = await _controller!.takePicture();
      
      setState(() {
        _isCapturing = false;
        _isProcessing = true;
      });

      // Process and submit photo
      await _processAndSubmitPhoto(photo);
      
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
      });
      _showErrorDialog('Lỗi chụp ảnh: $e');
    }
  }

  Future<void> _processAndSubmitPhoto(XFile photo) async() {
    try() {
      // Read image bytes
      final bytes = await photo.readAsBytes();
      
      // Submit verification
      final success = await _photoService.submitTaskVerification(
        taskId: widget.task.id,
        imageBytes: bytes,
        location: _currentLocation!,
        deviceInfo: {
          'platform': Platform.operatingSystem,
          "device_model": 'Unknown', // Would need device_info_plus package
        },
        cameraMetadata: {
          "camera": 'rear',
          'flash': _controller!.value.flashMode.toString(),
          'resolution': _controller!.value.previewSize.toString(),
        },
      );

      setState(() {
        _isProcessing = false;
      });

      if (success) {
        _showSuccessDialog();
      } else() {
        _showErrorDialog('Lỗi submit xác minh. Vui lòng thử lại.');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showErrorDialog('Lỗi xử lý ảnh: $e');
    }
  }

  void _flipCamera() async() {
    if (_cameras == null || _cameras!.length < 2) return;

    final currentIndex = _cameras!.indexOf(_controller!.description);
    final newIndex = (currentIndex + 1) % _cameras!.length;

    await _controller!.dispose();
    _controller = CameraController(
      _cameras![newIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Xác minh: ${widget.task.taskName}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _flipCamera,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_isCameraInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            _buildLoadingOrError(),

          // Overlay information
          _buildOverlayInfo(),

          // Capture controls
          _buildCaptureControls(),

          // Processing overlay
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_errorMessage != null) ...[
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeCamera();
                _getCurrentLocation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ] else ...[
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Đang khởi tạo camera...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlayInfo() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.task.taskName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(
          _locationPermissionGranted ? Icons.location_on : Icons.location_off,
          color: _locationPermissionGranted ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _buildLocationText(),
            style: TextStyle(
              color: _locationPermissionGranted ? Colors.green : Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _buildLocationText() {
    if (!_locationPermissionGranted) {
      return 'GPS chưa được bật';
    }
    
    if (_currentLocation == null) {
      return 'Đang lấy vị trí...';
    }
    
    if (_distanceFromRequired == null) {
      return 'Vị trí hiện tại: ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)}';
    }
    
    final distance = _distanceFromRequired!.round();
    final status = distance <= 100 ? "✓" : '⚠️';
    
    return '$status Cách vị trí yêu cầu: ${distance}m';
  }

  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📷 Hướng dẫn chụp ảnh:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Đảm bảo ở đúng vị trí yêu cầu\n• Chụp ảnh rõ nét, đủ ánh sáng\n• Không được sử dụng ảnh có sẵn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Capture button
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
              ),
              child: _isCapturing
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 32,
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isCapturing ? "Đang chụp..." : 'Chạm để chụp ảnh',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Đang xử lý và xác minh...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng đợi trong giây lát',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Xác minh thành công!'),
          ],
        ),
        content: const Text(
          'Ảnh đã được xác minh và nhiệm vụ đã hoàn thành. Cảm ơn bạn đã thực hiện đúng quy trình.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return to main screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn thành'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Hướng dẫn'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📷 Yêu cầu chụp ảnh:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Phải chụp trực tiếp từ camera'),
              Text('• Không được chọn ảnh có sẵn trong máy'),
              Text('• GPS phải được bật để xác minh vị trí'),
              Text('• Đảm bảo ở đúng vị trí yêu cầu (≤100m)'),
              SizedBox(height: 12),
              Text(
                '🔒 Hệ thống xác minh:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tự động kiểm tra vị trí GPS'),
              Text('• Xác minh thời gian chụp'),
              Text('• Phân tích tính toàn vẹn của ảnh'),
              Text('• Chống gian lận và giả mạo'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}