import 'package:flutter/material.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';

class ClubNotificationScreenSimple extends StatefulWidget() {
  final String? clubId;

  const ClubNotificationScreenSimple({
    super.key,
    this.clubId,
  });

  @override
  State<ClubNotificationScreenSimple> createState() => _ClubNotificationScreenSimpleState();
}

class _ClubNotificationScreenSimpleState extends State<ClubNotificationScreenSimple> {
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
      appBar: CustomAppBar(title: 'Gửi thông báo'),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageSection(),
                    const SizedBox(height: 24),
                    _buildTargetSection(),
                    const SizedBox(height: 24),
                    _buildOptionsSection(),
                    const SizedBox(height: 32),
                    _buildSendButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMessageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội dung thông báo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề',
              hintText: 'Nhập tiêu đề thông báo',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tiêu đề';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Nội dung',
              hintText: 'Nhập nội dung thông báo',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập nội dung';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đối tượng nhận thông báo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...['all_members', 'active_members', 'vip_members', 'new_members'].map(
            (audience) => RadioListTile<String>(
              title: Text(_getAudienceLabel(audience)),
              value: audience,
              groupValue: _targetAudience,
              onChanged: (value) {
                setState(() {
                  _targetAudience = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tùy chọn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Notification Type
          const Text(
            'Loại thông báo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildTypeChip('general', 'Thông báo chung'),
              _buildTypeChip('event', 'Sự kiện'),
              _buildTypeChip('promotion', 'Khuyến mãi'),
              _buildTypeChip('system', 'Hệ thống'),
            ],
          ),
          const SizedBox(height: 16),
          // Urgent flag
          SwitchListTile(
            title: const Text('Thông báo khẩn cấp'),
            subtitle: const Text('Ưu tiên hiển thị và gửi push notification'),
            value: _isUrgent,
            onChanged: (value) {
              setState(() {
                _isUrgent = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _notificationType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _notificationType = value;
        });
      },
      selectedColor: AppTheme.primaryLight.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryLight,
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendNotification,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Gửi thông báo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  String _getAudienceLabel(String audience) {
    switch (audience) {
      case 'all_members':
        return 'Tất cả thành viên';
      case 'active_members':
        return 'Thành viên hoạt động';
      case 'vip_members':
        return 'Thành viên VIP';
      case 'new_members':
        return 'Thành viên mới';
      default:
        return 'Không xác định';
    }
  }

  Future<void> _sendNotification() async() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try() {
      // TODO: Implement actual notification sending
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi thông báo thành công!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi thông báo: $e')),
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
}