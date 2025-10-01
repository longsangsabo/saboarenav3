import 'package:flutter/material.dart';
import 'package:sabo_arena/services/user_privacy_service.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

@override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool isLoading = true;
  bool isSaving = false;
  Map<String, dynamic> privacySettings = {};
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => isLoading = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final settings = await UserPrivacyService.getUserPrivacySettings(userId);
        setState(() {
          privacySettings = settings ?? {};
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Không thể tải cài đặt riêng tư: $e');
    }
  }

  Future<void> _savePrivacySettings() async {
    setState(() => isSaving = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final success = await UserPrivacyService.saveUserPrivacySettings(
          userId, 
          privacySettings,
        );
        
        if (success) {
          _showSuccess('Đã lưu cài đặt riêng tư');
        } else {
          () {
          _showError('Không thể lưu cài đặt');
        }
      
        }}
    } catch (e) {
      _showError('Lỗi khi lưu cài đặt: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Cài đặt riêng tư'),
      backgroundColor: AppTheme.backgroundLight,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildPrivacySettings(),
                  const SizedBox(height: 32),
                  _buildSaveButton(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo[50]!,
            Colors.indigo[25]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.privacy_tip, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiểm soát riêng tư',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tùy chỉnh thông tin nào được hiển thị công khai và ai có thể tương tác với bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    final categories = UserPrivacyService.getPrivacyCategories();
    
    return Column(
      children: categories.entries.map((entry) {
        final categoryName = entry.key;
        final settings = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: _buildSettingsCategory(categoryName, settings),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsCategory(String title, List<Map<String, String>> settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(title),
                  color: AppTheme.primaryLight,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          
          // Settings items
          ...settings.asMap().entries.map((entry) {
            final index = entry.key;
            final setting = entry.value;
            final isLast = index == settings.length - 1;
            
            return _buildSettingItem(
              setting['key']!,
              setting['title']!,
              setting['description']!,
              isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String key, String title, String description, bool isLast) {
    final currentValue = privacySettings[key] ?? true;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: AppTheme.dividerLight.withOpacity(0.3)))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: currentValue,
            onChanged: (value) {
              setState(() {
                privacySettings[key] = value;
              });
            },
            activeThumbColor: AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSaving ? null : _savePrivacySettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Lưu cài đặt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hiển thị công cộng':
        return Icons.public;
      case 'Thông tin cá nhân':
        return Icons.person;
      case 'Hoạt động và thành tích':
        return Icons.emoji_events;
      case 'Tương tác':
        return Icons.people;
      case 'Tìm kiếm và gợi ý':
        return Icons.search;
      default:
        return Icons.settings;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

