import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/models/club.dart';

class ClubLogoSettingsScreen extends StatefulWidget() {
  final String clubId;

  const ClubLogoSettingsScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubLogoSettingsScreen> createState() => _ClubLogoSettingsScreenState();
}

class _ClubLogoSettingsScreenState extends State<ClubLogoSettingsScreen> {
  final ClubService _clubService = ClubService.instance;
  final ImagePicker _picker = ImagePicker();
  
  Club? _club;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  Future<void> _loadClubData() async() {
    try() {
      setState(() => _isLoading = true);
      final club = await _clubService.getClubById(widget.clubId);
      setState(() {
        _club = club;
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải thông tin CLB: $error')),
        );
      }
    }
  }

  Future<void> _pickAndUploadLogo() async() {
    try() {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();
      
      // Upload to Supabase and update club
      final updatedClub = await _clubService.uploadAndUpdateClubLogo(
        widget.clubId, 
        imageBytes, 
        image.name,
      );

      setState(() {
        _club = updatedClub;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logo đã được cập nhật thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi upload logo: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeLogo() async() {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa logo'),
        content: const Text('Bạn có chắc chắn muốn xóa logo hiện tại không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try() {
      setState(() => _isUploading = true);

      final updatedClub = await _clubService.removeClubLogo(widget.clubId);

      setState(() {
        _club = updatedClub;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logo đã được xóa thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi xóa logo: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Logo câu lạc bộ'),
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentLogoSection(),
                  const SizedBox(height: 32),
                  _buildActionSection(),
                  const SizedBox(height: 32),
                  _buildInstructionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentLogoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Logo hiện tại',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight.withOpacity(0.1),
              border: Border.all(
                color: AppTheme.primaryLight.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _club?.logoUrl != null
                ? ClipOval(
                    child: Image.network(
                      _club!.logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.sports_tennis,
                          size: 50,
                          color: AppTheme.primaryLight,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.sports_tennis,
                    size: 50,
                    color: AppTheme.primaryLight,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            _club?.logoUrl != null ? "Logo đã được thiết lập" : 'Chưa có logo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.upload, color: AppTheme.primaryLight, size: 24),
                ),
                title: Text(
                  'Tải lên logo mới',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Chọn ảnh từ thư viện',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                trailing: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondaryLight,
                        size: 20,
                      ),
                onTap: _isUploading ? null : _pickAndUploadLogo,
              ),
              if (_club?.logoUrl != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red, size: 24),
                  ),
                  title: Text(
                    'Xóa logo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Xóa logo và sử dụng icon mặc định',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  trailing: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondaryLight,
                          size: 20,
                        ),
                  onTap: _isUploading ? null : _removeLogo,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryLight,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hướng dẫn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Logo sẽ hiển thị trên dashboard và giao diện CLB\n'
            '• Kích thước tốt nhất: 512x512 pixels\n'
            '• Định dạng hỗ trợ: PNG, JPG, JPEG\n'
            '• Kích thước file tối đa: 2MB\n'
            '• Nên sử dụng ảnh có nền trong suốt (PNG)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}