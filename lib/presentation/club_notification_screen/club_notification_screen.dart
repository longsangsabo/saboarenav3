import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';

class ClubNotificationScreen extends StatefulWidget {
  const ClubNotificationScreen({super.key});

} 
  final String? clubId;

  const ClubNotificationScreen({
    super.key,
    this.clubId,
  });

  @override
  _ClubNotificationScreenState createState() => _ClubNotificationScreenState();
}

class _ClubNotificationScreenState extends State<ClubNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  // Form State
  String _notificationType = 'general';
  String _targetAudience = 'all_members';
  bool _isUrgent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gửi thông báo',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _sendNotification,
            child: Text(
              'Gửi',
              style: TextStyle(
                color: AppTheme.primaryLight,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageSection(),
                    SizedBox(height: 24.h),
                    _buildSettingsSection(),
                    SizedBox(height: 24.h),
                    _buildPreviewSection(),
                    SizedBox(height: 32.h),
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nội dung thông báo',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'VD: Thông báo quan trọng',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Vui lòng nhập tiêu đề';
              }
              return null;
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Message
          TextFormField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Nội dung',
              hintText: 'Nhập nội dung thông báo...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Vui lòng nhập nội dung thông báo';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt gửi',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Notification Type
          DropdownButtonFormField<String>(
            initialValue: _notificationType,
            decoration: InputDecoration(
              labelText: 'Loại thông báo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(
                value: 'general',
                child: Text('Thông báo chung'),
              ),
              DropdownMenuItem(
                value: 'tournament',
                child: Text('Thông báo giải đấu'),
              ),
              DropdownMenuItem(
                value: 'event',
                child: Text('Thông báo sự kiện'),
              ),
              DropdownMenuItem(
                value: 'maintenance',
                child: Text('Bảo trì/Nghỉ lễ'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _notificationType = value!;
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Target Audience
          DropdownButtonFormField<String>(
            initialValue: _targetAudience,
            decoration: InputDecoration(
              labelText: 'Đối tượng nhận',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.people),
            ),
            items: const [
              DropdownMenuItem(
                value: 'all_members',
                child: Text('Tất cả thành viên'),
              ),
              DropdownMenuItem(
                value: 'active_members',
                child: Text('Thành viên hoạt động'),
              ),
              DropdownMenuItem(
                value: 'premium_members',
                child: Text('Thành viên VIP'),
              ),
              DropdownMenuItem(
                value: 'admins',
                child: Text('Chỉ quản trị viên'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _targetAudience = value!;
              });
            },
          ),
          
          SizedBox(height: 16.h),
          
          // Urgent Toggle
          SwitchListTile(
            title: Text('Thông báo khẩn cấp'),
            subtitle: Text(
              _isUrgent 
                  ? "Thông báo sẽ được ưu tiên hiển thị"
                  : 'Thông báo thường',
              style: TextStyle(fontSize: 12.sp),
            ),
            value: _isUrgent,
            onChanged: (value) {
              setState(() {
                _isUrgent = value;
              });
            },
            activeThumbColor: AppTheme.errorLight,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: AppTheme.primaryLight),
              SizedBox(width: 8.w),
              Text(
                'Xem trước',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          // Preview Card
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _isUrgent ? Colors.red.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isUrgent ? Colors.red.shade200 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications,
                      color: _isUrgent ? Colors.red : AppTheme.primaryLight,
                      size: 20,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _titleController.text.isNotEmpty 
                            ? _titleController.text 
                            : 'Tiêu đề thông báo',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    if (_isUrgent)
                      Container(
                        padding:  EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'KHẨN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _messageController.text.isNotEmpty 
                      ? _messageController.text 
                      : 'Nội dung thông báo sẽ hiển thị ở đây...',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Gửi đến: ${_getAudienceText()}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _sendNotification,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isUrgent ? Colors.red : AppTheme.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.send, color: Colors.white),
        label: Text(
          _isLoading ? "Đang gửi..." : 'Gửi thông báo',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getAudienceText() {
    switch (_targetAudience) {
      case 'all_members':
        return 'Tất cả thành viên';
      case 'active_members':
        return 'Thành viên hoạt động';
      case 'premium_members':
        return 'Thành viên VIP';
      case 'admins':
        return 'Quản trị viên';
      default:
        return 'Tất cả thành viên';
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement notification sending API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi thông báo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
