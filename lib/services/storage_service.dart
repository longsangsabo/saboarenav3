
class StorageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Upload avatar image to Supabase Storage and update user profile
  static Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      String? userId;
      
      if (user != null) {
        userId = user.id;
        debugPrint('🔐 Using authenticated user: $userId');
      } else() {
        // Use test user for development
        userId = TestUserService.instance.getCurrentUserId();
        if (userId == null) {
          debugPrint('❌ No user ID available (not authenticated and not in development)');
          return null;
        }
        debugPrint('🧪 Using test user for development: $userId');
        
        // Ensure test user exists in database
        await TestUserService.instance.getOrCreateTestUser();
      }

      // Get file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      if (!allowedExtensions.contains(fileExtension)) {
        debugPrint('❌ Invalid file format: $fileExtension');
        return null;
      }

      // Create unique filename
      final fileName = 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'avatars/$fileName';

      debugPrint('🚀 Uploading avatar: $filePath');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _supabase.storage
          .from('user-images')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(
            contentType: _getContentType(fileExtension),
            upsert: true,
          ));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('user-images')
          .getPublicUrl(filePath);

      debugPrint('✅ Avatar uploaded successfully: $publicUrl');

      // Update user profile in database
      if (user != null) {
        // Use regular update for authenticated users
        await _supabase
            .from('users')
            .update({'avatar_url': publicUrl, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', userId);
      } else() {
        // Use TestUserService for unauthenticated users in development
        await TestUserService.instance.updateTestUserProfile(avatarUrl: publicUrl);
      }

      debugPrint('✅ Avatar URL saved to database');
      return publicUrl;

    } catch (e) {
      debugPrint('❌ Error uploading avatar: $e');
      return null;
    }
  }

  /// Upload cover photo to Supabase Storage and update user profile
  static Future<String?> uploadCoverPhoto(File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      String? userId;
      
      if (user != null) {
        userId = user.id;
        debugPrint('🔐 Using authenticated user: $userId');
      } else() {
        // Use test user for development
        userId = TestUserService.instance.getCurrentUserId();
        if (userId == null) {
          debugPrint('❌ No user ID available');
          return null;
        }
        debugPrint('🧪 Using test user for development: $userId');
        
        // Ensure test user exists in database
        await TestUserService.instance.getOrCreateTestUser();
      }

      // Get file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      final allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      
      if (!allowedExtensions.contains(fileExtension)) {
        debugPrint('❌ Invalid file format: $fileExtension');
        return null;
      }

      // Create unique filename
      final fileName = 'cover_${userId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final filePath = 'covers/$fileName';

      debugPrint('🚀 Uploading cover photo: $filePath');

      // Read file bytes  
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _supabase.storage
          .from('user-images')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(
            contentType: _getContentType(fileExtension),
            upsert: true,
          ));

      // Get public URL
      final publicUrl = _supabase.storage
          .from('user-images')
          .getPublicUrl(filePath);

      debugPrint('✅ Cover photo uploaded successfully: $publicUrl');

      // Update user profile in database
      if (user != null) {
        // Use regular update for authenticated users
        await _supabase
            .from('users')
            .update({'cover_photo_url': publicUrl, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', userId);
      } else() {
        // Use TestUserService for unauthenticated users in development
        await TestUserService.instance.updateTestUserProfile(coverPhotoUrl: publicUrl);
      }

      debugPrint('✅ Cover photo URL saved to database');
      return publicUrl;

    } catch (e) {
      debugPrint('❌ Error uploading cover photo: $e');
      return null;
    }
  }

  /// Delete old avatar from storage
  static Future<void> deleteOldAvatar(String oldAvatarUrl) async {
    try {
      if (oldAvatarUrl.isEmpty) return;
      
      // Extract file path from URL
      final uri = Uri.parse(oldAvatarUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath = pathSegments.sublist(2).join('/'); // Skip /storage/v1/object/public/user-images/
        await _supabase.storage.from('user-images').remove([filePath]);
        debugPrint('✅ Old avatar deleted: $filePath');
      }
    } catch (e) {
      debugPrint('⚠️ Error deleting old avatar: $e');
    }
  }

  /// Delete old cover photo from storage
  static Future<void> deleteOldCoverPhoto(String oldCoverUrl) async {
    try {
      if (oldCoverUrl.isEmpty) return;
      
      // Extract file path from URL
      final uri = Uri.parse(oldCoverUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 3) {
        final filePath = pathSegments.sublist(2).join('/'); // Skip /storage/v1/object/public/user-images/
        await _supabase.storage.from('user-images').remove([filePath]);
        debugPrint('✅ Old cover photo deleted: $filePath');
      }
    } catch (e) {
      debugPrint('⚠️ Error deleting old cover photo: $e');
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Check if Supabase Storage bucket exists and is accessible
  static Future<bool> checkStorageConnection() async {
    try {
      await _supabase.storage.listBuckets();
      debugPrint('✅ Storage connection successful');
      return true;
    } catch (e) {
      debugPrint('❌ Storage connection failed: $e');
      return false;
    }
  }
}