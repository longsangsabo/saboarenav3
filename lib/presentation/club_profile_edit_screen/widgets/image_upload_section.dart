import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';

class ImageUploadSection extends StatefulWidget() {
  final String coverImageUrl;
  final String logoImageUrl;
  final Function(String) onCoverChanged;
  final Function(String) onLogoChanged;

  const ImageUploadSection({
    super.key,
    required this.coverImageUrl,
    required this.logoImageUrl,
    required this.onCoverChanged,
    required this.onLogoChanged,
  });

  @override
  _ImageUploadSectionState createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends State<ImageUploadSection>
    with TickerProviderStateMixin() {
  late AnimationController _uploadController;
  late Animation<double> _uploadProgress;
  
  bool _isCoverUploading = false;
  bool _isLogoUploading = false;
  double _coverUploadProgress = 0.0;
  double _logoUploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    _uploadController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _uploadProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uploadController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _uploadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[600] ?? Colors.grey /*appTheme.*/black900.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCoverImageSection(),
          SizedBox(height: 16.sp),
          _buildLogoImageSection(),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return Container(
      height: 180.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.sp),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Cover image
          ClipRRect(
            borderRadius: BorderRadius.circular(12.sp),
            child: SizedBox(
              width: double.infinity,
              height: 180.h,
              child: widget.coverImageUrl.isNotEmpty
                  ? CustomImageWidget(
                      imagePath: widget.coverImageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray500,
                            size: 48.sp,
                          ),
                          SizedBox(height: 8.sp),
                          Text(
                            "Ảnh bìa",
                            style: TextStyle(
                              color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray600,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Upload overlay
          if (_isCoverUploading)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.sp),
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 60.sp,
                        height: 60.sp,
                        child: Stack(
                          children: [
                            Center(
                              child: SizedBox(
                                width: 40.sp,
                                height: 40.sp,
                                child: CircularProgressIndicator(
                                  value: _coverUploadProgress,
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.sp),
                      Text(
                        "Đang tải lên... ${(_coverUploadProgress * 100).toInt()}%",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Edit buttons
          if (!_isCoverUploading) ...[
            Positioned(
              top: 12.h,
              right: 12.h,
              child: Row(
                children: [
                  _buildImageActionButton(
                    icon: Icons.camera_alt_outlined,
                    tooltip: "Chụp ảnh",
                    onPressed: () => _onCameraTapped(true),
                    backgroundColor: Colors.black.withOpacity(0.6),
                  ),
                  SizedBox(width: 8.sp),
                  _buildImageActionButton(
                    icon: Icons.photo_library_outlined,
                    tooltip: "Chọn từ thư viện",
                    onPressed: () => _onGalleryTapped(true),
                    backgroundColor: Colors.black.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            
            // Info overlay
            Positioned(
              bottom: 12.h,
              left: 12.h,
              right: 12.h,
              child: Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.sp),
                    Expanded(
                      child: Text(
                        "Kích thước khuyến nghị: 1200x400px",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoImageSection() {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray200),
      ),
      child: Row(
        children: [
          // Logo preview
          Container(
            width: 80.sp,
            height: 80.sp,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray300, width: 2),
              color: Colors.white,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.sp),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: widget.logoImageUrl.isNotEmpty
                        ? CustomImageWidget(
                            imagePath: widget.logoImageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray100,
                            child: Icon(
                              Icons.business_outlined,
                              color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray500,
                              size: 32.sp,
                            ),
                          ),
                  ),
                ),
                
                // Upload overlay for logo
                if (_isLogoUploading)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.sp),
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: SizedBox(
                          width: 30.sp,
                          height: 30.sp,
                          child: Stack(
                            children: [
                              Center(
                                child: SizedBox(
                                  width: 24.sp,
                                  height: 24.sp,
                                  child: CircularProgressIndicator(
                                    value: _logoUploadProgress,
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              Center(
                                child: Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(width: 16.sp),
          
          // Logo info and actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Logo câu lạc bộ",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray900,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  "Kích thước khuyến nghị: 400x400px",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray600,
                  ),
                ),
                SizedBox(height: 12.sp),
                
                if (!_isLogoUploading) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onCameraTapped(false),
                          icon: Icon(Icons.camera_alt_outlined, size: 18.sp),
                          label: Text("Chụp"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600] ?? Colors.grey /*appTheme.*/blue600,
                            side: BorderSide(color: Colors.grey[600] ?? Colors.grey /*appTheme.*/blue600),
                            padding: EdgeInsets.symmetric(vertical: 8.sp),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onGalleryTapped(false),
                          icon: Icon(Icons.photo_library_outlined, size: 18.sp),
                          label: Text("Thư viện"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600] ?? Colors.grey /*appTheme.*/green600,
                            side: BorderSide(color: Colors.grey[600] ?? Colors.grey /*appTheme.*/green600),
                            padding: EdgeInsets.symmetric(vertical: 8.sp),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.sp),
                    decoration: BoxDecoration(
                      color: Colors.grey[600] ?? Colors.grey /*appTheme.*/blue50,
                      borderRadius: BorderRadius.circular(16.sp),
                    ),
                    child: Text(
                      "Đang tải lên... ${(_logoUploadProgress * 100).toInt()}%",
                      style: TextStyle(
                        color: Colors.grey[600] ?? Colors.grey /*appTheme.*/blue600,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.sp),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20.sp),
          child: Container(
            padding: EdgeInsets.all(8.sp),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  void _onCameraTapped(bool isCover) {
    _showImageSourceDialog(isCover, ImageSource.camera);
  }

  void _onGalleryTapped(bool isCover) {
    _showImageSourceDialog(isCover, ImageSource.gallery);
  }

  void _showImageSourceDialog(bool isCover, ImageSource source) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.h,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray300,
                  borderRadius: BorderRadius.circular(2.sp),
                ),
              ),
              SizedBox(height: 20.sp),
              
              Text(
                isCover ? "Chọn ảnh bìa" : "Chọn logo",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray900,
                ),
              ),
              
              SizedBox(height: 20.sp),
              
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt_outlined,
                      title: "Máy ảnh",
                      subtitle: "Chụp ảnh mới",
                      onTap: () {
                        Navigator.pop(context);
                        _simulateImageUpload(isCover, "camera");
                      },
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.photo_library_outlined,
                      title: "Thư viện",
                      subtitle: "Chọn từ thư viện",
                      onTap: () {
                        Navigator.pop(context);
                        _simulateImageUpload(isCover, "gallery");
                      },
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20.sp),
              
              if (isCover ? widget.coverImageUrl.isNotEmpty : widget.logoImageUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _removeImage(isCover);
                  },
                  icon: Icon(Icons.delete_outline, color: Colors.grey[600] ?? Colors.grey /*appTheme.*/red600),
                  label: Text(
                    "Xóa ảnh hiện tại",
                    style: TextStyle(color: Colors.grey[600] ?? Colors.grey /*appTheme.*/red600),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.sp),
      child: Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray200),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: Colors.grey[600] ?? Colors.grey /*appTheme.*/blue50,
                borderRadius: BorderRadius.circular(12.sp),
              ),
              child: Icon(
                icon,
                color: Colors.grey[600] ?? Colors.grey /*appTheme.*/blue600,
                size: 32.sp,
              ),
            ),
            SizedBox(height: 12.sp),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray900,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600] ?? Colors.grey /*appTheme.*/gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateImageUpload(bool isCover, String source) async() {
    setState(() {
      if (isCover) {
        _isCoverUploading = true;
        _coverUploadProgress = 0.0;
      } else() {
        _isLogoUploading = true;
        _logoUploadProgress = 0.0;
      }
    });

    // Simulate upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(Duration(milliseconds: 150));
      if (mounted) {
        setState(() {
          if (isCover) {
            _coverUploadProgress = i / 100;
          } else() {
            _logoUploadProgress = i / 100;
          }
        });
      }
    }

    if (mounted) {
      setState(() {
        if (isCover) {
          _isCoverUploading = false;
        } else() {
          _isLogoUploading = false;
        }
      });

      // Simulate new image URL
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newImageUrl = isCover
          ? "https://images.unsplash.com/photo-$timestamp?w=1200&h=400&fit=crop"
          : 'https://images.unsplash.com/photo-$timestamp?w=400&h=400&fit=crop';

      if (isCover) {
        widget.onCoverChanged(newImageUrl);
      } else() {
        widget.onLogoChanged(newImageUrl);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCover ? "Đã tải lên ảnh bìa thành công" : "Đã tải lên logo thành công"
          ),
          backgroundColor: Colors.grey[600] ?? Colors.grey /*appTheme.*/green600,
        ),
      );
    }
  }

  void _removeImage(bool isCover) {
    if (isCover) {
      widget.onCoverChanged('');
    } else() {
      widget.onLogoChanged('');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCover ? "Đã xóa ảnh bìa" : "Đã xóa logo"
        ),
        backgroundColor: Colors.grey[600] ?? Colors.grey /*appTheme.*/orange600,
      ),
    );
  }
}

enum ImageSource { camera, gallery }
