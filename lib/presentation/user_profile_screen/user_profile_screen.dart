import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_export.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/storage_service.dart';
import '../../services/permission_service.dart';
import '../../services/share_service.dart';
import '../../services/club_service.dart';
import '../../services/messaging_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_privacy_service.dart';
import '../../helpers/privacy_helper.dart';
import '../club_dashboard_screen/club_dashboard_screen_simple.dart';
import '../club_registration_screen/club_registration_screen.dart';
import '../privacy_settings_screen/privacy_settings_screen.dart';
import '../../widgets/shared_bottom_navigation.dart';
import '../../widgets/privacy_status_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './widgets/achievements_section_widget.dart';
import './widgets/edit_profile_modal.dart';
import './widgets/profile_header_widget.dart';
import './widgets/qr_code_widget.dart';
import './widgets/social_features_widget.dart';
import './widgets/statistics_cards_widget.dart';

class UserProfileScreen extends StatefulWidget() {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin() {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool _isLoading = true;

  // Services
  final UserService _userService = UserService.instance;
  final AuthService _authService = AuthService.instance;
  final MessagingService _messagingService = MessagingService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  // Dynamic data from backend
  UserProfile? _userProfile;
  Map<String, dynamic> _socialData = {};
  
  // Temporary image states for immediate UI update
  String? _tempCoverPhotoPath;
  String? _tempAvatarPath;

  // Messaging state
  int _unreadMessageCount = 0;

  // Notification state
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUnreadMessageCount();
    _loadUnreadNotificationCount();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async() {
    try() {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      debugPrint('🚀 Profile: Loading user data from backend...');
      final currentUser = _authService.currentUser;

      if (currentUser != null) {
        final userProfile = await _userService.getUserProfileById(currentUser.id);

        if (mounted) {
          setState(() {
            _userProfile = userProfile;
          });
        }

        await _loadProfileData(userProfile.id);
      } else() {
        debugPrint('⚠️ Profile: No authenticated user.');
      }

      debugPrint('✅ Profile: User data loaded successfully');
    } catch (e) {
      debugPrint('❌ Profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải hồ sơ người dùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProfileData(String userId) async() {
    try() {
      debugPrint('🚀 Profile: Loading social data...');

      final friends = await _userService.getUserFollowers(userId);
      // final recentChallenges = await _socialService.fetchRecentChallenges(userId); // This method doesn't exist
      final userStats = await _userService.getUserStats(userId);

      if (mounted) {
        setState(() {
          _socialData = {
            "friendsCount": friends.length,
            "challengesCount": 0, // Placeholder
            "tournamentsCount": userStats['total_tournaments'] ?? 0,
            "recentFriends": friends.take(5).toList(),
            "recentChallenges": [], // Placeholder
          };
        });
      }
      debugPrint('✅ Profile: Additional data loaded successfully');
    } catch (e) {
      debugPrint('❌ Profile data error: $e');
    }
  }

  Future<void> _loadUnreadMessageCount() async() {
    try() {
      final count = await _messagingService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading unread message count: $e');
    }
  }

  Future<void> _loadUnreadNotificationCount() async() {
    try() {
      final count = await _notificationService.getUnreadNotificationCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading unread notification count: $e');
    }
  }

  Future<void> _refreshProfile() async() {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    HapticFeedback.lightImpact();
    await _loadUserProfile();
    await _loadUnreadMessageCount();
    await _loadUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã cập nhật thông tin profile'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }
  }

  void _navigateToMessaging() {
    Navigator.pushNamed(context, AppRoutes.messagingScreen).then((_) {
      // Refresh unread count when returning from messaging
      _loadUnreadMessageCount();
    });
  }

  void _navigateToNotifications() {
    // Show notifications modal since no dedicated screen exists
    _showNotificationsModal();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 2.h),
              Text('Không thể tải hồ sơ', style: AppTheme.lightTheme.textTheme.titleLarge),
              SizedBox(height: 1.h),
              Text('Vui lòng đăng nhập hoặc thử lại.', style: AppTheme.lightTheme.textTheme.bodyMedium),
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.loginScreen),
                child: Text('Đăng nhập'),
              )
            ],
          ),
        ),
      );
    }

    final userDataMap = _userProfile!.toJson();
    
    // Merge with temporary images for immediate UI update
    final displayUserData = Map<String, dynamic>.from(userDataMap);
    
    // Map database fields to widget expected keys
    displayUserData['avatar'] = _tempAvatarPath ?? _userProfile!.avatarUrl;
    displayUserData['coverPhoto'] = _tempCoverPhotoPath ?? _userProfile!.coverPhotoUrl;
    displayUserData['displayName'] = _userProfile!.fullName;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeaderWidget(
                    userData: displayUserData,
                    onEditProfile: _showEditProfileModal,
                    onCoverPhotoTap: _changeCoverPhoto,
                    onAvatarTap: _changeAvatar,
                  ),
                  SizedBox(height: 3.h),
                  StatisticsCardsWidget(userId: _userProfile!.id),
                  SizedBox(height: 4.h),
                  AchievementsSectionWidget(
                    userId: _userProfile!.id,
                    onViewAll: _viewAllAchievements,
                  ),
                  SizedBox(height: 4.h),
                  SocialFeaturesWidget(
                    socialData: _socialData,
                    onFriendsListTap: _viewFriendsList,
                    onRecentChallengesTap: _viewRecentChallenges,
                    onTournamentHistoryTap: _viewTournamentHistory,
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SharedBottomNavigation(
        currentIndex: 4, // Profile tab
        onNavigate: (route) {
          if (route != AppRoutes.userProfileScreen) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      elevation: 0,
      title: Text('Hồ sơ cá nhân', style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        // Messaging button with notification badge
        Stack(
          children: [
            IconButton(
              onPressed: _navigateToMessaging,
              icon: Icon(Icons.message_outlined, color: AppTheme.lightTheme.colorScheme.primary),
              tooltip: 'Tin nhắn',
            ),
            if (_unreadMessageCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _unreadMessageCount > 99 ? '99+' : _unreadMessageCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // Notification button with notification badge
        Stack(
          children: [
            IconButton(
              onPressed: _navigateToNotifications,
              icon: Icon(Icons.notifications_outlined, color: AppTheme.lightTheme.colorScheme.primary),
              tooltip: 'Thông báo',
            ),
            if (_unreadNotificationCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        // Hiển thị nút chuyển sang giao diện club nếu user có role "clb" hoặc "club_owner"
        if (_userProfile?.role == 'clb' || _userProfile?.role == 'club_owner')
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: ElevatedButton.icon(
              onPressed: _switchToClubInterface,
              icon: Icon(Icons.sports_soccer, size: 16),
              label: Text('CLB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        IconButton(
          onPressed: _showQRCode,
          icon: CustomIconWidget(iconName: 'qr_code', color: AppTheme.lightTheme.colorScheme.primary),
          tooltip: 'Mã QR',
        ),
        IconButton(
          onPressed: _showMoreOptions,
          icon: CustomIconWidget(iconName: 'more_vert'),
          tooltip: 'Tùy chọn khác',
        ),
      ],
    );
  }

  void _showEditProfileModal() {
    if (_userProfile == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(
        userProfile: _userProfile!,
        onSave: (updatedProfile) async() {
          try() {
            // Cập nhật profile qua API
            await _userService.updateUserProfile(
              fullName: updatedProfile.fullName,
              displayName: updatedProfile.displayName,
              bio: updatedProfile.bio,
              phone: updatedProfile.phone,
              location: updatedProfile.location,
              avatarUrl: updatedProfile.avatarUrl,
            );
            
            // Refresh local data
            await _loadUserProfile();
            
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Cập nhật hồ sơ thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Lỗi cập nhật hồ sơ: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _changeCoverPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Thay đổi ảnh bìa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: () => _pickCoverPhotoFromCamera(),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Chọn ảnh',
                  onTap: () => _pickCoverPhotoFromGallery(),
                ),
              ],
            ),
            SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Thay đổi ảnh đại diện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Chụp ảnh',
                  onTap: () => _pickAvatarFromCamera(),
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Chọn ảnh',
                  onTap: () => _pickAvatarFromGallery(),
                ),
                if (_userProfile?.avatarUrl != null)
                  _buildImageSourceOption(
                    icon: Icons.delete,
                    label: 'Xóa ảnh',
                    onTap: () => _removeAvatar(),
                    color: Colors.red,
                  ),
              ],
            ),
            SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Cover Photo Functions
  Future<void> _pickCoverPhotoFromCamera() async() {
    Navigator.pop(context); // Đóng bottom sheet
    
    try() {
      // Kiểm tra quyền camera
      final cameraGranted = await PermissionService.checkCameraPermission();
      if (!cameraGranted) {
        _showErrorMessage('Cần cấp quyền truy cập camera để chụp ảnh');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _tempCoverPhotoPath = image.path;
        });
        _showSuccessMessage('✅ Đã chọn ảnh bìa từ camera');
        // TODO: Upload to Supabase and update user profile
        _uploadCoverPhoto(image.path);
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _pickCoverPhotoFromGallery() async() {
    Navigator.pop(context); // Đóng bottom sheet
    
    try() {
      // Kiểm tra quyền truy cập thư viện ảnh
      final photosGranted = await PermissionService.checkPhotosPermission();
      if (!photosGranted) {
        _showPermissionDialog();
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _tempCoverPhotoPath = image.path;
        });
        _showSuccessMessage('✅ Đã chọn ảnh bìa từ thư viện');
        // TODO: Upload to Supabase and update user profile
        _uploadCoverPhoto(image.path);
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chọn ảnh: $e');
    }
  }

  // Avatar Functions
  Future<void> _pickAvatarFromCamera() async() {
    Navigator.pop(context); // Đóng bottom sheet
    
    try() {
      // Kiểm tra quyền camera
      final cameraGranted = await PermissionService.checkCameraPermission();
      if (!cameraGranted) {
        _showErrorMessage('Cần cấp quyền truy cập camera để chụp ảnh');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _tempAvatarPath = image.path;
        });
        _showSuccessMessage('✅ Đã chọn ảnh đại diện từ camera');
        // TODO: Upload to Supabase and update user profile
        _uploadAvatar(image.path);
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _pickAvatarFromGallery() async() {
    Navigator.pop(context); // Đóng bottom sheet
    
    try() {
      // Kiểm tra quyền truy cập thư viện ảnh
      final photosGranted = await PermissionService.checkPhotosPermission();
      if (!photosGranted) {
        _showPermissionDialog();
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _tempAvatarPath = image.path;
        });
        _showSuccessMessage('✅ Đã chọn ảnh đại diện từ thư viện');
        // TODO: Upload to Supabase and update user profile
        _uploadAvatar(image.path);
      }
    } catch (e) {
      _showErrorMessage('Lỗi khi chọn ảnh: $e');
    }
  }

  void _removeAvatar() {
    Navigator.pop(context); // Đóng bottom sheet
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ảnh đại diện'),
        content: Text('Bạn có chắc chắn muốn xóa ảnh đại diện không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _tempAvatarPath = null;
              });
              _showSuccessMessage('✅ Đã xóa ảnh đại diện');
              // TODO: Remove from Supabase and update user profile
              _removeAvatarFromServer();
            },
            child: Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // Upload functions
  Future<void> _uploadCoverPhoto(String imagePath) async() {
    try() {
      debugPrint('🚀 Uploading cover photo: $imagePath');
      
      // Get old cover photo URL to delete later
      final oldCoverUrl = _userProfile?.coverPhotoUrl ?? '';
      
      // Upload to Supabase Storage and update database
      final newCoverUrl = await StorageService.uploadCoverPhoto(File(imagePath));
      
      if (newCoverUrl != null) {
        // Delete old cover photo if exists
        if (oldCoverUrl.isNotEmpty) {
          StorageService.deleteOldCoverPhoto(oldCoverUrl);
        }
        
        // Update local state with new URL
        setState(() {
          _tempCoverPhotoPath = null; // Clear temp path
          if (_userProfile != null) {
            _userProfile = _userProfile!.copyWith(coverPhotoUrl: newCoverUrl);
          }
        });
        
        _showSuccessMessage('✅ Ảnh bìa đã được lưu thành công!');
      } else() {
        _showErrorMessage('❌ Không thể tải lên ảnh bìa. Vui lòng thử lại.');
      }
    } catch (e) {
      debugPrint('❌ Cover photo upload error: $e');
      _showErrorMessage('Lỗi khi tải ảnh bìa: $e');
    }
  }

  Future<void> _uploadAvatar(String imagePath) async() {
    try() {
      debugPrint('🚀 Uploading avatar: $imagePath');
      
      // Get old avatar URL to delete later
      final oldAvatarUrl = _userProfile?.avatarUrl ?? '';
      
      // Upload to Supabase Storage and update database
      final newAvatarUrl = await StorageService.uploadAvatar(File(imagePath));
      
      if (newAvatarUrl != null) {
        // Delete old avatar if exists
        if (oldAvatarUrl.isNotEmpty) {
          StorageService.deleteOldAvatar(oldAvatarUrl);
        }
        
        // Update local state with new URL
        setState(() {
          _tempAvatarPath = null; // Clear temp path
          if (_userProfile != null) {
            _userProfile = _userProfile!.copyWith(avatarUrl: newAvatarUrl);
          }
        });
        
        _showSuccessMessage('✅ Ảnh đại diện đã được lưu thành công!');
      } else() {
        _showErrorMessage('❌ Không thể tải lên ảnh đại diện. Vui lòng thử lại.');
      }
    } catch (e) {
      debugPrint('❌ Avatar upload error: $e');
      _showErrorMessage('Lỗi khi tải ảnh đại diện: $e');
    }
  }

  Future<void> _removeAvatarFromServer() async() {
    try() {
      debugPrint('🚀 Removing avatar from server');
      
      final oldAvatarUrl = _userProfile?.avatarUrl ?? '';
      
      if (oldAvatarUrl.isNotEmpty) {
        // Delete from storage
        await StorageService.deleteOldAvatar(oldAvatarUrl);
        
        // Update user profile in database to remove avatar URL
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client
              .from('users')
              .update({'avatar_url': null, 'updated_at': DateTime.now().toIso8601String()})
              .eq('id', user.id);
        }
        
        // Update local state
        setState(() {
          _tempAvatarPath = null;
          if (_userProfile != null) {
            _userProfile = _userProfile!.copyWith(avatarUrl: null);
          }
        });
        
        _showSuccessMessage('✅ Đã xóa ảnh đại diện');
      }
    } catch (e) {
      debugPrint('❌ Avatar removal error: $e');
      _showErrorMessage('Lỗi khi xóa ảnh đại diện: $e');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cần cấp quyền truy cập'),
          content: const Text(
            'Ứng dụng cần quyền truy cập thư viện ảnh để bạn có thể chọn ảnh.\n\n'
            'Vui lòng vào:\n'
            'Cài đặt > Ứng dụng > SABO Arena > Quyền\n'
            'và bật quyền "Ảnh và phương tiện"',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                PermissionService.openDeviceAppSettings(); // Mở cài đặt ứng dụng
              },
              child: const Text('Mở cài đặt'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }



  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? Colors.green).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color ?? Colors.green, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _switchToClubInterface() async() {
    if (_userProfile?.role != 'clb' && _userProfile?.role != 'club_owner') {
      _showErrorMessage('Bạn không có quyền truy cập giao diện club');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try() {
      // Tìm club đầu tiên mà user sở hữu hoặc là member
      final club = await ClubService.instance.getFirstClubForUser(_userProfile!.id);
      
      // Close loading dialog
      Navigator.pop(context);

      if (club == null) {
        // Show club creation options for club owner without clubs
        _showClubCreationOptions();
        return;
      }

      // Navigate to club dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClubDashboardScreenSimple(
            clubId: club.id,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      _showErrorMessage('Lỗi khi tải thông tin club: $e');
    }
  }

  void _showQRCode() {
    if (_userProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QRCodeWidget(
        userData: _userProfile!.toJson(),
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _shareProfile() async() {
    if (_userProfile == null) return;
    
    try() {
      await ShareService.shareUserProfile(_userProfile!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ hồ sơ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 24), // Spacer for centering
                  Text(
                    'Tùy chọn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Share & Copy Section
                    _buildOptionItem(
                      icon: Icons.share,
                      title: 'Chia sẻ hồ sơ',
                      subtitle: 'Chia sẻ hồ sơ của bạn với bạn bè',
                      onTap: () {
                        Navigator.pop(context);
                        _shareProfile();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.copy,
                      title: 'Sao chép liên kết',
                      subtitle: 'Sao chép đường dẫn đến hồ sơ',
                      onTap: () {
                        Navigator.pop(context);
                        _copyProfileLink();
                      },
                    ),
                    
                    Divider(height: 30),
                    
                    // Settings Section
                    _buildOptionItem(
                      icon: Icons.person,
                      title: 'Tài khoản',
                      subtitle: 'Thông tin cá nhân, bảo mật',
                      onTap: () {
                        Navigator.pop(context);
                        _openAccountSettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      subtitle: 'Cài đặt thông báo push',
                      onTap: () {
                        Navigator.pop(context);
                        _openNotificationSettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.language,
                      title: 'Ngôn ngữ',
                      subtitle: 'Tiếng Việt, English',
                      onTap: () {
                        Navigator.pop(context);
                        _openLanguageSettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.privacy_tip,
                      title: 'Cài đặt riêng tư',
                      subtitle: 'Kiểm soát thông tin hiển thị',
                      onTap: () {
                        Navigator.pop(context);
                        _openPrivacySettings();
                      },
                    ),
                    _buildOptionItem(
                      icon: Icons.help,
                      title: 'Trợ giúp & Hỗ trợ',
                      subtitle: 'FAQ, liên hệ',
                      onTap: () {
                        Navigator.pop(context);
                        _openHelpSupport();
                      },
                    ),
                    
                    // Show Club options if user is club owner
                    if (_userProfile?.role == 'club_owner') ...[
                      _buildOptionItem(
                        icon: Icons.add_business,
                        title: 'Đăng ký CLB',
                        subtitle: 'Tạo câu lạc bộ mới',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToClubRegistration();
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.business,
                        title: 'Quản lý CLB',
                        subtitle: 'Điều hành câu lạc bộ',
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToClubManagement();
                        },
                      ),
                    ],
                    
                    Divider(height: 30),
                    
                    // Logout
                    _buildOptionItem(
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      subtitle: 'Thoát tài khoản hiện tại',
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      isDestructive: true,
                    ),
                    
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDestructive = false,
  }) {
    final effectiveIconColor = isDestructive ? Colors.red : (iconColor ?? Colors.blue);
    final effectiveTitleColor = isDestructive ? Colors.red : null;
    
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: effectiveIconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: effectiveIconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: effectiveTitleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _copyProfileLink() {
    // In a real app, you would use Clipboard.setData()
    // Clipboard.setData(ClipboardData(text: 'https://saboarena.com/profile/${_userProfile?.id}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Đã sao chép liên kết hồ sơ'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewAllAchievements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAchievementsModal(),
    );
  }

  Widget _buildAchievementsModal() {
    // Mock data for achievements
    final achievements = [
      {"title": 'Người mới', "description": 'Hoàn thành 5 trận đấu đầu tiên', "icon": '🏆', 'completed': true},
      {"title": 'Chiến thắng đầu tiên', "description": 'Thắng trận đấu đầu tiên', "icon": '🥇', 'completed': true},
      {"title": 'Streak Master', "description": 'Thắng liên tiếp 5 trận', "icon": '🔥', 'completed': true},
      {"title": 'Tournament Player', "description": 'Tham gia 10 giải đấu', "icon": '🏟️', 'completed': false},
      {"title": 'Social Player', "description": 'Kết bạn với 50 người chơi', "icon": '👥', 'completed': false},
      {"title": 'Champion', "description": 'Thắng một giải đấu', "icon": '👑', 'completed': false},
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                Text(
                  'Thành tích của tôi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Achievements List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                final isCompleted = achievement['completed'] as bool;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green.shade100 : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            achievement['icon'] as String,
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCompleted ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              achievement['description'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: isCompleted ? Colors.green.shade600 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isCompleted)
                        Icon(Icons.check_circle, color: Colors.green, size: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewFriendsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFriendsListModal(),
    );
  }

  Widget _buildFriendsListModal() {
    // Mock data for friends list
    final friends = List.generate(15, (index) => {
      "id": 'friend_$index',
      "name": 'Người chơi ${index + 1}',
      'avatar': null,
      'status': index % 3 == 0 ? 'online' : (index % 3 == 1 ? "offline" : 'in_game'),
      "level": 'Trung bình',
      'lastSeen': index % 3 == 0 ? "Đang online" : '${index + 1} phút trước',
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.people, color: Colors.blue, size: 24),
                Text(
                  'Bạn bè (${friends.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bạn bè...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          
          // Friends List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                final status = friend['status'] as String;
                Color statusColor = status == 'online' ? Colors.green : 
                                  status == 'in_game' ? Colors.orange : Colors.grey;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey.shade300,
                            child: Icon(Icons.person, color: Colors.white, size: 30),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend['name'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              friend['level'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              friend['lastSeen'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: Colors.grey),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'message',
                            child: Row(
                              children: [
                                Icon(Icons.message, size: 18),
                                SizedBox(width: 8),
                                Text('Nhắn tin'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'challenge',
                            child: Row(
                              children: [
                                Icon(Icons.sports_esports, size: 18),
                                SizedBox(width: 8),
                                Text('Thách đấu'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 18),
                                SizedBox(width: 8),
                                Text('Xem hồ sơ'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          String action = '';
                          switch (value) {
                            case 'message':
                              action = 'Nhắn tin với ${friend['name']}';
                              break;
                            case 'challenge':
                              action = 'Thách đấu với ${friend['name']}';
                              break;
                            case 'profile':
                              action = 'Xem hồ sơ ${friend['name']}';
                              break;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(action)),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _viewRecentChallenges() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChallengesHistoryModal(),
    );
  }

  void _viewTournamentHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTournamentHistoryModal(),
    );
  }

  Widget _buildChallengesHistoryModal() {
    // Mock data for challenges
    final challenges = List.generate(10, (index) => {
      "id": 'challenge_$index',
      "opponent": 'Đối thủ ${index + 1}',
      'result': index % 3 == 0 ? 'won' : (index % 3 == 1 ? "lost" : 'draw'),
      "score": '${(index % 3) + 1}-${(index % 2) + 1}',
      'date': DateTime.now().subtract(Duration(days: index)),
      "duration": '${15 + (index * 2)} phút',
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.sports_esports, color: Colors.purple, size: 24),
                Text(
                  'Lịch sử thách đấu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Statistics
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Thắng', challenges.where((c) => c['result'] == 'won').length.toString(), Colors.green),
                _buildStatItem('Hòa', challenges.where((c) => c['result'] == 'draw').length.toString(), Colors.orange),
                _buildStatItem('Thua', challenges.where((c) => c['result'] == 'lost').length.toString(), Colors.red),
              ],
            ),
          ),
          
          // Challenges List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final result = challenge['result'] as String;
                final date = challenge['date'] as DateTime;
                
                Color resultColor = result == 'won' ? Colors.green : 
                                   result == 'lost' ? Colors.red : Colors.orange;
                IconData resultIcon = result == 'won' ? Icons.trending_up : 
                                     result == 'lost' ? Icons.trending_down : Icons.trending_flat;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: resultColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(resultIcon, color: resultColor, size: 20),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'vs ${challenge['opponent']}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tỷ số: ${challenge['score']} • ${challenge['duration']}',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: resultColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          result == 'won' ? 'Thắng' : result == 'lost' ? "Thua" : 'Hòa',
                          style: TextStyle(
                            color: resultColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentHistoryModal() {
    // Mock data for tournaments
    final tournaments = List.generate(8, (index) => {
      "id": 'tournament_$index',
      "name": 'Giải đấu ${index + 1}',
      'position': index % 4 + 1,
      'participants': (index + 1) * 8,
      'date': DateTime.now().subtract(Duration(days: index * 7)),
      'prize': index == 0 ? '1.000.000 VND' : index == 1 ? '500.000 VND' : index == 2 ? '250.000 VND' : null,
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                Text(
                  'Lịch sử giải đấu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Tournaments List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: tournaments.length,
              itemBuilder: (context, index) {
                final tournament = tournaments[index];
                final position = tournament['position'] as int;
                final date = tournament['date'] as DateTime;
                final prize = tournament['prize'] as String?;
                
                Color positionColor = position == 1 ? Colors.amber : 
                                     position == 2 ? Colors.grey : 
                                     position == 3 ? Colors.brown : 
                                     Colors.grey.shade400;
                IconData positionIcon = position <= 3 ? Icons.emoji_events : Icons.sports_esports;
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: positionColor.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: positionColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(positionIcon, color: positionColor, size: 20),
                            Text(
                              '#$position',
                              style: TextStyle(
                                color: positionColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament['name'] as String,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${tournament['participants']} người tham gia',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            Text(
                              '${date.day}/${date.month}/${date.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            if (prize != null)
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Giải thưởng: $prize',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _openAccountSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mở cài đặt tài khoản'))
    );
  }

  void _openNotificationSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mở cài đặt thông báo'))
    );
  }

  void _openLanguageSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildLanguageSelector(),
    );
  }

  void _navigateToClubManagement() async() {
    try() {
      // Get current user ID
      final currentUserId = _authService.currentUser?.id;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập lại')),
        );
        return;
      }

      // Find club owned by current user
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('clubs')
          .select('id, name')
          .eq('owner_id', currentUserId)
          .eq('approval_status', 'approved')
          .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn chưa có club nào được phê duyệt')),
        );
        return;
      }

      // Navigate with actual club ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClubDashboardScreenSimple(
            clubId: response['id'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  void _openPrivacySettings() {
    if (_userProfile == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivacySettingsScreen(userId: _userProfile!.id),
      ),
    );
  }

  void _openHelpSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mở trợ giúp & hỗ trợ'))
    );
  }

  Widget _buildLanguageSelector() {
    final languages = [
      {"code": 'vi', "name": 'Tiếng Việt', "flag": '🇻🇳'},
      {"code": 'en', "name": 'English', "flag": '🇺🇸'},
      {"code": 'ko', "name": '한국어', "flag": '🇰🇷'},
      {"code": 'ja', "name": '日本語', "flag": '🇯🇵'},
    ];

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chọn ngôn ngữ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ...languages.map((lang) => ListTile(
            leading: Text(lang['flag']!, style: TextStyle(fontSize: 24)),
            title: Text(lang['name']!),
            trailing: lang['code'] == 'vi' ? Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Đã chuyển sang ${lang['name']}')),
              );
            },
          )),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  void _handleLogout() async() {
    HapticFeedback.mediumImpact();
    try() {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.loginScreen, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildNotificationsModal(),
    );
  }

  Widget _buildNotificationsModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Thông báo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_unreadNotificationCount > 0)
                      TextButton(
                        onPressed: _markAllNotificationsAsRead,
                        child: Text(
                          'Đánh dấu tất cả',
                          style: TextStyle(
                            color: AppTheme.lightTheme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Notifications List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _notificationService.getUserNotifications(limit: 50),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Lỗi tải thông báo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Vui lòng thử lại sau',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có thông báo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Thông báo mới sẽ hiển thị ở đây',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final type = notification['type'] ?? 'default';
    final createdAt = DateTime.tryParse(notification['created_at'] ?? '') ?? DateTime.now();
    final timeAgo = _getTimeAgo(createdAt);

    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'tournament_invitation':
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case 'match_result':
        iconData = Icons.sports_soccer;
        iconColor = Colors.green;
        break;
      case 'club_announcement':
        iconData = Icons.business;
        iconColor = Colors.blue;
        break;
      case 'rank_update':
        iconData = Icons.trending_up;
        iconColor = Colors.purple;
        break;
      case 'friend_request':
        iconData = Icons.person_add;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade300 : Colors.blue.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? 'Thông báo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            color: isRead ? Colors.grey.shade800 : Colors.black,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: isRead ? Colors.grey.shade600 : Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else() {
      return 'Vừa xong';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read if not already read
    if (!(notification['is_read'] ?? false)) {
      _notificationService.markNotificationAsRead(notification['id']);
      setState(() {
        _unreadNotificationCount = (_unreadNotificationCount - 1).clamp(0, 999);
      });
    }

    // Handle different notification types
    final type = notification['type'] ?? '';
    final actionData = notification['action_data'] ?? {};

    switch (type) {
      case 'tournament_invitation':
        // Navigate to tournament details
        if (actionData['tournament_id'] != null) {
          Navigator.pop(context); // Close modal
          Navigator.pushNamed(context, AppRoutes.tournamentDetailScreen, arguments: actionData['tournament_id']);
        }
        break;
      case 'match_result':
        // Navigate to match details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xem chi tiết kết quả trận đấu')),
        );
        break;
      case 'club_announcement':
        // Navigate to club screen
        Navigator.pop(context); // Close modal
        Navigator.pushNamed(context, AppRoutes.clubMainScreen);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xem thông báo: ${notification['title']}')),
        );
    }
  }

  void _markAllNotificationsAsRead() async() {
    try() {
      await _notificationService.markAllNotificationsAsRead();
      setState(() {
        _unreadNotificationCount = 0;
      });
      Navigator.pop(context); // Close modal
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã đánh dấu tất cả thông báo là đã đọc'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi đánh dấu thông báo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showClubCreationOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.sports_soccer,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 28,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Quản lý CLB',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn chưa có câu lạc bộ nào để quản lý.',
              style: TextStyle(fontSize: 14.sp, height: 1.4),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo CLB mới:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '🏢 Đăng ký thông tin CLB của bạn\n'
                    '⏳ Chờ admin phê duyệt (24-48 giờ)\n'
                    '🎯 Bắt đầu quản lý và tổ chức giải đấu\n'
                    '👥 Thu hút thành viên và người chơi',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Đóng',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClubRegistrationScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            ),
            child: Text(
              'Đăng ký CLB',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToClubRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClubRegistrationScreen(),
      ),
    );
  }
}