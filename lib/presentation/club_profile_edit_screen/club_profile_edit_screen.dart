import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'widgets/operating_hours_editor_simple.dart';
import 'widgets/location_picker_simple.dart';
import 'widgets/image_upload_section_simple.dart';
import 'package:flutter/foundation.dart';

class ClubProfileEditScreen extends StatefulWidget() {
  const ClubProfileEditScreen({super.key});

  @override
  _ClubProfileEditScreenState createState() => _ClubProfileEditScreenState();
}

class _ClubProfileEditScreenState extends State<ClubProfileEditScreen>
    with TickerProviderStateMixin() {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _tiktokController = TextEditingController();

  // Form State
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String _coverImageUrl = '';
  String _logoImageUrl = '';
  Map<String, String> _operatingHours = {};
  Map<String, double> _location = {'lat': 0.0, 'lng': 0.0};
  List<String> _selectedFacilities = [];
  List<String> _tableTypes = [];
  int _totalTables = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _initializeFormData();
    _animationController.forward();
  }

  void _initializeFormData() {
    // Load existing club data
    _nameController.text = "SABO Arena Central";
    _usernameController.text = "saboarena_central";
    _descriptionController.text = "Arena bi-a hiện đại với hệ thống thi đấu chuyên nghiệp và không gian rộng rãi.";
    _phoneController.text = "+84 28 3944 5678";
    _emailController.text = "contact@saboarena.vn";
    _websiteController.text = "https://saboarena.vn";
    _addressController.text = "123 Nguyễn Huệ, Quận 1, TP.HCM";
    _minPriceController.text = "80000";
    _maxPriceController.text = "120000";
    _facebookController.text = "saboarena.central";
    _instagramController.text = "saboarena_central";
    _tiktokController.text = "saboarena.official";
    
    _coverImageUrl = 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=400&fit=crop';
    _logoImageUrl = 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=200&h=200&fit=crop';
    
    _operatingHours = {
      "monday": '08:00-24:00',
      "tuesday": '08:00-24:00',
      "wednesday": '08:00-24:00',
      "thursday": '08:00-24:00',
      "friday": '08:00-24:00',
      "saturday": '08:00-24:00',
      "sunday": '08:00-24:00',
    };
    
    _location = {'lat': 10.7769, 'lng': 106.7009};
    _selectedFacilities = ['Bàn 8 bi', 'Bàn 9 bi', 'Cafeteria', 'WiFi miễn phí'];
    _tableTypes = ['Pool', 'Carom', 'Snooker'];
    _totalTables = 20;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    
    // Dispose controllers
    _nameController.dispose();
    _usernameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: appTheme.gray50,
        appBar: _buildAppBar(),
        body: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBasicInfoTab(),
                        _buildContactTab(),
                        _buildBusinessTab(),
                        _buildMediaTab(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomActions(),
        floatingActionButton: _hasUnsavedChanges ? _buildSaveButton() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        "Chỉnh sửa hồ sơ",
        style: TextStyle(
          fontSize: 18.fSize,
          fontWeight: FontWeight.bold,
          color: appTheme.gray900,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.close, color: appTheme.gray700),
        onPressed: _onClosePressed,
      ),
      actions: [
        if (_hasUnsavedChanges)
          TextButton(
            onPressed: _onSavePressed,
            child: Text(
              "Lưu",
              style: TextStyle(
                color: appTheme.blue600,
                fontSize: 16.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(
          height: 1,
          color: appTheme.gray200,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: appTheme.blue600,
        labelColor: appTheme.blue600,
        unselectedLabelColor: appTheme.gray600,
        labelStyle: TextStyle(
          fontSize: 14.fSize,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: "Cơ bản"),
          Tab(text: "Liên hệ"),
          Tab(text: "Kinh doanh"),
          Tab(text: "Media"),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Section
            ImageUploadSection(
              coverImageUrl: _coverImageUrl,
              logoImageUrl: _logoImageUrl,
              onCoverChanged: (url) {
                setState(() {
                  _coverImageUrl = url;
                  _hasUnsavedChanges = true;
                });
              },
              onLogoChanged: (url) {
                setState(() {
                  _logoImageUrl = url;
                  _hasUnsavedChanges = true;
                });
              },
            ),
            
            SizedBox(height: 24.v),
            
            // Basic Information
            _buildSectionTitle("Thông tin cơ bản"),
            SizedBox(height: 16.v),
            
            _buildTextField(
              controller: _nameController,
              label: "Tên câu lạc bộ",
              hint: "Nhập tên câu lạc bộ",
              icon: Icons.business_outlined,
              required: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập tên câu lạc bộ';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.v),
            
            _buildTextField(
              controller: _usernameController,
              label: "Tên người dùng",
              hint: "username_club",
              icon: Icons.alternate_email_outlined,
              required: true,
              prefix: "@",
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập tên người dùng';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value!)) {
                  return 'Chỉ được sử dụng chữ, số và dấu _';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16.v),
            
            _buildTextField(
              controller: _descriptionController,
              label: "Mô tả",
              hint: "Mô tả về câu lạc bộ của bạn...",
              icon: Icons.description_outlined,
              maxLines: 4,
              maxLength: 500,
            ),
            
            SizedBox(height: 24.v),
            
            // Facilities Section
            _buildSectionTitle("Tiện ích"),
            SizedBox(height: 16.v),
            _buildFacilitiesSelector(),
            
            SizedBox(height: 100.v), // Space for floating button
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Thông tin liên hệ"),
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _phoneController,
            label: "Số điện thoại",
            hint: "+84 xxx xxx xxx",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isNotEmpty ?? false) {
                if (!RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(value!)) {
                  return 'Số điện thoại không hợp lệ';
                }
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _emailController,
            label: "Email",
            hint: "contact@club.com",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isNotEmpty ?? false) {
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Email không hợp lệ';
                }
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _websiteController,
            label: "Website",
            hint: "https://website.com",
            icon: Icons.language_outlined,
            keyboardType: TextInputType.url,
          ),
          
          SizedBox(height: 24.v),
          
          _buildSectionTitle("Địa chỉ"),
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _addressController,
            label: "Địa chỉ",
            hint: "Nhập địa chỉ câu lạc bộ",
            icon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          
          SizedBox(height: 16.v),
          
          // Location Picker
          LocationPicker(
            initialLocation: _location,
            onLocationChanged: (location) {
              setState(() {
                _location = location;
                _hasUnsavedChanges = true;
              });
            },
          ),
          
          SizedBox(height: 100.v),
        ],
      ),
    );
  }

  Widget _buildBusinessTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Giờ hoạt động"),
          SizedBox(height: 16.v),
          
          OperatingHoursEditor(
            initialHours: _operatingHours,
            onHoursChanged: (hours) {
              setState(() {
                _operatingHours = hours;
                _hasUnsavedChanges = true;
              });
            },
          ),
          
          SizedBox(height: 24.v),
          
          _buildSectionTitle("Thông tin bàn chơi"),
          SizedBox(height: 16.v),
          
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _minPriceController,
                  label: "Giá từ (VND)",
                  hint: "80000",
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              SizedBox(width: 16.h),
              Expanded(
                child: _buildTextField(
                  controller: _maxPriceController,
                  label: "Giá đến (VND)",
                  hint: "120000",
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.v),
          
          _buildTableTypesSelector(),
          
          SizedBox(height: 16.v),
          
          _buildNumberSelector(
            title: "Tổng số bàn",
            value: _totalTables,
            onChanged: (value) {
              setState(() {
                _totalTables = value;
                _hasUnsavedChanges = true;
              });
            },
          ),
          
          SizedBox(height: 100.v),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle("Mạng xã hội"),
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _facebookController,
            label: "Facebook",
            hint: "facebook_username",
            icon: Icons.facebook,
            prefix: "facebook.com/",
          ),
          
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _instagramController,
            label: "Instagram",
            hint: "instagram_username",
            icon: Icons.camera_alt_outlined,
            prefix: "@",
          ),
          
          SizedBox(height: 16.v),
          
          _buildTextField(
            controller: _tiktokController,
            label: "TikTok",
            hint: "tiktok_username",
            icon: Icons.music_note,
            prefix: "@",
          ),
          
          SizedBox(height: 24.v),
          
          _buildSectionTitle("Thư viện ảnh"),
          SizedBox(height: 16.v),
          
          _buildGalleryManager(),
          
          SizedBox(height: 100.v),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.bold,
        color: appTheme.gray900,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    int maxLines = 1,
    int? maxLength,
    bool required = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: (value) {
          setState(() {
            _hasUnsavedChanges = true;
          });
        },
        decoration: InputDecoration(
          labelText: required ? "$label *" : label,
          hintText: hint,
          prefixIcon: Icon(icon, color: appTheme.gray600),
          prefixText: prefix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.h),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
          labelStyle: TextStyle(color: appTheme.gray600),
          hintStyle: TextStyle(color: appTheme.gray400),
        ),
      ),
    );
  }

  Widget _buildFacilitiesSelector() {
    final allFacilities = [
      "Bàn 8 bi", "Bàn 9 bi", "Bàn Carom", "Bàn Snooker",
      "Cafeteria", "Bãi đỗ xe", "WiFi miễn phí", "Điều hòa",
      "Âm thanh chất lượng", "Livestream", "VIP Rooms", "Tủ đồ"
    ];

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chọn tiện ích có sẵn",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 12.v),
          Wrap(
            spacing: 8.h,
            runSpacing: 8.v,
            children: allFacilities.map((facility) {
              final isSelected = _selectedFacilities.contains(facility);
              return FilterChip(
                label: Text(facility),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFacilities.add(facility);
                    } else() {
                      _selectedFacilities.remove(facility);
                    }
                    _hasUnsavedChanges = true;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: appTheme.blue50,
                checkmarkColor: appTheme.blue600,
                labelStyle: TextStyle(
                  color: isSelected ? appTheme.blue600 : appTheme.gray700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? appTheme.blue600 : appTheme.gray300,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableTypesSelector() {
    final allTypes = ["Pool", "Carom", "Snooker", "3-Cushion", "English"];

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Loại bàn bi-a",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 12.v),
          Wrap(
            spacing: 8.h,
            runSpacing: 8.v,
            children: allTypes.map((type) {
              final isSelected = _tableTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _tableTypes.add(type);
                    } else() {
                      _tableTypes.remove(type);
                    }
                    _hasUnsavedChanges = true;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: appTheme.green50,
                checkmarkColor: appTheme.green600,
                labelStyle: TextStyle(
                  color: isSelected ? appTheme.green600 : appTheme.gray700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? appTheme.green600 : appTheme.gray300,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberSelector({
    required String title,
    required int value,
    required Function(int) onChanged,
    int min = 1,
    int max = 100,
  }) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.gray200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(Icons.remove_circle_outline),
                color: value > min ? appTheme.blue600 : appTheme.gray400,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
                decoration: BoxDecoration(
                  color: appTheme.blue50,
                  borderRadius: BorderRadius.circular(8.h),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18.fSize,
                    fontWeight: FontWeight.bold,
                    color: appTheme.blue600,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(Icons.add_circle_outline),
                color: value < max ? appTheme.blue600 : appTheme.gray400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryManager() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.gray200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ảnh hiện tại",
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray700,
                ),
              ),
              TextButton.icon(
                onPressed: _onAddPhotos,
                icon: Icon(Icons.add_photo_alternate_outlined, size: 20.adaptSize),
                label: Text("Thêm ảnh"),
                style: TextButton.styleFrom(
                  foregroundColor: appTheme.blue600,
                  textStyle: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.v),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.h,
              mainAxisSpacing: 8.v,
            ),
            itemCount: 6, // Mock data
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.h),
                  color: appTheme.gray100,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.h),
                      child: Image.network(
                        'https://images.unsplash.com/photo-${1571019613454 + index}?w=200&h=200&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: appTheme.gray200,
                          child: Icon(Icons.image, color: appTheme.gray600),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4.v,
                      right: 4.h,
                      child: GestureDetector(
                        onTap: () => _onRemovePhoto(index),
                        child: Container(
                          padding: EdgeInsets.all(4.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12.h),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16.adaptSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: appTheme.gray200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _onPreviewPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.v),
                side: BorderSide(color: appTheme.blue600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.h),
                ),
              ),
              child: Text(
                "Xem trước",
                style: TextStyle(
                  color: appTheme.blue600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onResetPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: appTheme.gray600,
                padding: EdgeInsets.symmetric(vertical: 12.v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.h),
                ),
              ),
              child: Text(
                "Đặt lại",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return FloatingActionButton.extended(
      onPressed: _isLoading ? null : _onSavePressed,
      backgroundColor: appTheme.green600,
      label: _isLoading
          ? SizedBox(
              width: 20.adaptSize,
              height: 20.adaptSize,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              "Lưu thay đổi",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
      icon: _isLoading
          ? null
          : Icon(Icons.save_outlined, color: Colors.white),
    );
  }

  // Event Handlers
  Future<bool> _onWillPop() async() {
    if (_hasUnsavedChanges) {
      return await _showUnsavedDialog() ?? false;
    }
    return true;
  }

  Future<bool?> _showUnsavedDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Thay đổi chưa được lưu"),
        content: Text("Bạn có muốn thoát mà không lưu thay đổi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Ở lại"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Thoát"),
          ),
        ],
      ),
    );
  }

  void _onClosePressed() async() {
    if (await _onWillPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onSavePressed() async() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đã lưu thành công!"),
          backgroundColor: appTheme.green600,
        ),
      );
    }
  }

  void _onPreviewPressed() {
    // Navigate to preview screen
    debugPrint("Preview pressed");
  }

  void _onResetPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Đặt lại thông tin"),
        content: Text("Bạn có chắc chắn muốn đặt lại tất cả thông tin về mặc định?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeFormData();
              setState(() {
                _hasUnsavedChanges = false;
              });
            },
            child: Text("Đặt lại"),
          ),
        ],
      ),
    );
  }

  void _onAddPhotos() {
    debugPrint("Add photos pressed");
  }

  void _onRemovePhoto(int index) {
    debugPrint("Remove photo at index $index");
  }
}