import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../member_management_screen/member_management_screen.dart';

class MemberProfileEditScreen extends StatefulWidget {
  const MemberProfileEditScreen({super.key});

} 
  final MemberData memberData;

  const MemberProfileEditScreen({
    super.key,
    required this.memberData,
  });

  @override
  _MemberProfileEditScreenState createState() => _MemberProfileEditScreenState();
}

class _MemberProfileEditScreenState extends State<MemberProfileEditScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Form controllers
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _bioController;
  late TextEditingController _instagramController;
  late TextEditingController _facebookController;

  // Profile data
  String? _selectedAvatarUrl;
  MembershipType _selectedMembershipType = MembershipType.regular;
  MemberStatus _selectedStatus = MemberStatus.active;
  RankType _selectedRank = RankType.beginner;
  bool _isPublicProfile = true;
  bool _allowMessages = true;
  bool _allowInvitations = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeFormData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _initializeFormData() {
    final user = widget.memberData.user;
    final membership = widget.memberData.membershipInfo;

    _displayNameController = TextEditingController(text: user.displayName);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _locationController = TextEditingController(text: user.location ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _instagramController = TextEditingController(text: user.socialLinks?.instagram ?? '');
    _facebookController = TextEditingController(text: user.socialLinks?.facebook ?? '');

    _selectedAvatarUrl = user.avatar;
    _selectedMembershipType = membership.type;
    _selectedStatus = membership.status;
    _selectedRank = user.rank;

    // Add change listeners to detect modifications
    _displayNameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
    _bioController.addListener(_onFormChanged);
    _instagramController.addListener(_onFormChanged);
    _facebookController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      title: 'Chỉnh sửa thành viên',
      leading: IconButton(
        icon: Icon(Icons.close),
        onPressed: _handleBackPress,
      ),
      actions: [
        if (_hasChanges)
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Lưu',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatarSection(),
            SizedBox(height: 32),
            _buildBasicInfoSection(),
            SizedBox(height: 24),
            _buildContactInfoSection(),
            SizedBox(height: 24),
            _buildMembershipSection(),
            SizedBox(height: 24),
            _buildSocialLinksSection(),
            SizedBox(height: 24),
            _buildPrivacySection(),
            SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Ảnh đại diện',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getMembershipColor().withOpacity(0.5),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getMembershipColor().withOpacity(0.3),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundImage: NetworkImage(_selectedAvatarUrl ?? ''),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _changeAvatar,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Nhấn vào camera để thay đổi ảnh',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Thông tin cơ bản',
      icon: Icons.person,
      children: [
        _buildTextField(
          controller: _displayNameController,
          label: 'Tên hiển thị',
          icon: Icons.badge,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên hiển thị';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Giới thiệu',
          icon: Icons.description,
          maxLines: 3,
          maxLength: 200,
        ),
        SizedBox(height: 16),
        _buildDropdownField<RankType>(
          value: _selectedRank,
          label: 'Trình độ',
          icon: Icons.star,
          items: RankType.values,
          itemBuilder: (rank) => Text(_getRankLabel(rank)),
          onChanged: (rank) {
            if (rank != null) {
              setState(() {
                _selectedRank = rank;
                _hasChanges = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      title: 'Thông tin liên hệ',
      icon: Icons.contact_phone,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Số điện thoại',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _locationController,
          label: 'Địa chỉ',
          icon: Icons.location_on,
        ),
      ],
    );
  }

  Widget _buildMembershipSection() {
    return _buildSection(
      title: 'Thông tin thành viên',
      icon: Icons.card_membership,
      children: [
        _buildDropdownField<MembershipType>(
          value: _selectedMembershipType,
          label: 'Loại thành viên',
          icon: Icons.workspace_premium,
          items: MembershipType.values,
          itemBuilder: (type) => Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getMembershipColorForType(type),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(_getMembershipTypeLabel(type)),
            ],
          ),
          onChanged: (type) {
            if (type != null) {
              setState(() {
                _selectedMembershipType = type;
                _hasChanges = true;
              });
            }
          },
        ),
        SizedBox(height: 16),
        _buildDropdownField<MemberStatus>(
          value: _selectedStatus,
          label: 'Trạng thái',
          icon: Icons.circle,
          items: MemberStatus.values,
          itemBuilder: (status) => Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColorForType(status),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(_getMemberStatusLabel(status)),
            ],
          ),
          onChanged: (status) {
            if (status != null) {
              setState(() {
                _selectedStatus = status;
                _hasChanges = true;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection() {
    return _buildSection(
      title: 'Mạng xã hội',
      icon: Icons.share,
      children: [
        _buildTextField(
          controller: _instagramController,
          label: 'Instagram',
          icon: Icons.camera_alt,
          prefixText: '@',
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _facebookController,
          label: 'Facebook',
          icon: Icons.facebook,
          prefixText: 'facebook.com/',
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Quyền riêng tư',
      icon: Icons.privacy_tip,
      children: [
        _buildSwitchTile(
          title: 'Hồ sơ công khai',
          subtitle: 'Cho phép thành viên khác xem hồ sơ',
          value: _isPublicProfile,
          onChanged: (value) {
            setState(() {
              _isPublicProfile = value;
              _hasChanges = true;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Nhận tin nhắn',
          subtitle: 'Cho phép thành viên khác gửi tin nhắn',
          value: _allowMessages,
          onChanged: (value) {
            setState(() {
              _allowMessages = value;
              _hasChanges = true;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Nhận lời mời',
          subtitle: 'Cho phép nhận lời mời tham gia giải đấu',
          value: _allowInvitations,
          onChanged: (value) {
            setState(() {
              _allowInvitations = value;
              _hasChanges = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _hasChanges && !_isLoading ? _saveChanges : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Đang lưu...'),
                    ],
                  )
                : Text(
                    'Lưu thay đổi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : _resetForm,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Khôi phục ban đầu',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  Color _getMembershipColor() {
    return _getMembershipColorForType(_selectedMembershipType);
  }

  Color _getMembershipColorForType(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return Colors.grey;
      case MembershipType.vip:
        return Colors.amber;
      case MembershipType.premium:
        return Colors.purple;
    }
  }

  Color _getStatusColorForType(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return Colors.green;
      case MemberStatus.inactive:
        return Colors.grey;
      case MemberStatus.suspended:
        return Colors.orange;
      case MemberStatus.pending:
        return Colors.blue;
    }
  }

  String _getMembershipTypeLabel(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return 'Thường';
      case MembershipType.vip:
        return 'VIP';
      case MembershipType.premium:
        return 'Premium';
    }
  }

  String _getMemberStatusLabel(MemberStatus status) {
    switch (status) {
      case MemberStatus.active:
        return 'Hoạt động';
      case MemberStatus.inactive:
        return 'Không hoạt động';
      case MemberStatus.suspended:
        return 'Tạm khóa';
      case MemberStatus.pending:
        return 'Chờ duyệt';
    }
  }

  String _getRankLabel(RankType rank) {
    switch (rank) {
      case RankType.beginner:
        return 'Mới bắt đầu';
      case RankType.intermediate:
        return 'Trung bình';
      case RankType.advanced:
        return 'Nâng cao';
      case RankType.professional:
        return 'Chuyên nghiệp';
    }
  }

  // Event handlers
  Future<bool> _handleBackPress() async {
    if (_hasChanges) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thay đổi chưa được lưu'),
          content: Text('Bạn có muốn lưu thay đổi trước khi thoát?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Bỏ qua'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Lưu'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _saveChanges();
      }
    }
    return true;
  }

  void _changeAvatar() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thay đổi ảnh đại diện',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.link),
              title: Text('Sử dụng URL'),
              onTap: () {
                Navigator.pop(context);
                _enterImageUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _takePicture() {
    // Implementation for taking picture
  }

  void _pickFromGallery() {
    // Implementation for picking from gallery
  }

  void _enterImageUrl() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Nhập URL ảnh'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'URL ảnh',
              hintText: 'https://example.com/image.jpg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _selectedAvatarUrl = controller.text;
                    _hasChanges = true;
                  });
                }
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thông tin thành viên đã được cập nhật'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _hasChanges = false;
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Khôi phục thông tin'),
        content: Text('Bạn có chắc muốn khôi phục về thông tin ban đầu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeFormData();
              setState(() {
                _hasChanges = false;
              });
            },
            child: Text('Khôi phục'),
          ),
        ],
      ),
    );
  }
}
