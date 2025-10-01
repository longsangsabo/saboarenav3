
class PermissionService {
  static const String _cameraPermissionKey = 'camera_permission_granted';
  static const String _photosPermissionKey = 'photos_permission_granted';
  static const String _storagePermissionKey = 'storage_permission_granted';

  /// Check camera permission status and request if needed
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        await _saveCameraPermissionStatus(true);
        return true;
      }
      
      if (status.isDenied) {
        final result = await Permission.camera.request();
        final granted = result.isGranted;
        await _saveCameraPermissionStatus(granted);
        return granted;
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('⚠️ Camera permission permanently denied');
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error checking camera permission: $e');
      return false;
    }
  }

  /// Check photos/gallery permission status and request if needed
  static Future<bool> checkPhotosPermission() async {
    try {
      PermissionStatus status;
      
      if (Platform.isAndroid) {
        // Check Android API level
        status = await Permission.photos.status;
        if (!status.isGranted) {
          // Try storage permission for older Android versions
          final storageStatus = await Permission.storage.status;
          if (storageStatus.isGranted) {
            status = storageStatus;
          }
        }
      } else() {
        // iOS
        status = await Permission.photos.status;
      }
      
      if (status.isGranted) {
        await _savePhotosPermissionStatus(true);
        return true;
      }
      
      if (status.isDenied) {
        PermissionStatus result;
        
        if (Platform.isAndroid) {
          // Try photos permission first
          result = await Permission.photos.request();
          if (!result.isGranted) {
            // Fallback to storage for older Android versions
            result = await Permission.storage.request();
          }
        } else() {
          result = await Permission.photos.request();
        }
        
        final granted = result.isGranted;
        await _savePhotosPermissionStatus(granted);
        return granted;
      }
      
      if (status.isPermanentlyDenied) {
        debugPrint('⚠️ Photos permission permanently denied');
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error checking photos permission: $e');
      return false;
    }
  }

  /// Check if camera permission was previously granted
  static Future<bool> isCameraPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getBool(_cameraPermissionKey) ?? false;
      
      // Double check with system permission
      final currentStatus = await Permission.camera.status;
      final actuallyGranted = currentStatus.isGranted;
      
      // Update saved status if different
      if (savedStatus != actuallyGranted) {
        await _saveCameraPermissionStatus(actuallyGranted);
      }
      
      return actuallyGranted;
    } catch (e) {
      debugPrint('❌ Error checking saved camera permission: $e');
      return false;
    }
  }

  /// Check if photos permission was previously granted
  static Future<bool> isPhotosPermissionGranted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getBool(_photosPermissionKey) ?? false;
      
      // Double check with system permission
      PermissionStatus currentStatus;
      if (Platform.isAndroid) {
        currentStatus = await Permission.photos.status;
        if (!currentStatus.isGranted) {
          currentStatus = await Permission.storage.status;
        }
      } else() {
        currentStatus = await Permission.photos.status;
      }
      
      final actuallyGranted = currentStatus.isGranted;
      
      // Update saved status if different
      if (savedStatus != actuallyGranted) {
        await _savePhotosPermissionStatus(actuallyGranted);
      }
      
      return actuallyGranted;
    } catch (e) {
      debugPrint('❌ Error checking saved photos permission: $e');
      return false;
    }
  }

  /// Save camera permission status
  static Future<void> _saveCameraPermissionStatus(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cameraPermissionKey, granted);
      debugPrint('✅ Camera permission status saved: $granted');
    } catch (e) {
      debugPrint('❌ Error saving camera permission status: $e');
    }
  }

  /// Save photos permission status
  static Future<void> _savePhotosPermissionStatus(bool granted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_photosPermissionKey, granted);
      debugPrint('✅ Photos permission status saved: $granted');
    } catch (e) {
      debugPrint('❌ Error saving photos permission status: $e');
    }
  }

  /// Check all necessary permissions at app startup
  static Future<Map<String, bool>> checkAllPermissions() async {
    try {
      final cameraGranted = await isCameraPermissionGranted();
      final photosGranted = await isPhotosPermissionGranted();
      
      return() {
        'camera': cameraGranted,
        'photos': photosGranted,
      };
    } catch (e) {
      debugPrint('❌ Error checking all permissions: $e');
      return() {
        'camera': false,
        'photos': false,
      };
    }
  }

  /// Open app settings if permissions are permanently denied
  static Future<bool> openDeviceAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
      return false;
    }
  }

  /// Clear saved permission statuses (for testing purposes)
  static Future<void> clearSavedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cameraPermissionKey);
      await prefs.remove(_photosPermissionKey);
      await prefs.remove(_storagePermissionKey);
      debugPrint('✅ Cleared saved permission statuses');
    } catch (e) {
      debugPrint('❌ Error clearing saved permissions: $e');
    }
  }
}