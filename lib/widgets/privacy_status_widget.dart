import 'package:flutter/material.dart';
import 'package:sabo_arena/helpers/privacy_helper.dart';
import 'package:sabo_arena/services/user_privacy_service.dart';

class PrivacyStatusWidget extends StatefulWidget {
  const PrivacyStatusWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final String userId;
  final bool isOwnProfile;
  final VoidCallback? onPrivacyTap;

  const PrivacyStatusWidget({
    Key? key,
    required this.userId,
    this.isOwnProfile = false,
    this.onPrivacyTap,
  }) : super(key: key);

  @override
  State<PrivacyStatusWidget> createState() => _PrivacyStatusWidgetState();
}

class _PrivacyStatusWidgetState extends State<PrivacyStatusWidget> {
  Map<String, dynamic>? _privacySettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await UserPrivacyService.getUserPrivacySettings(widget.userId);
      setState(() {
        _privacySettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_privacySettings == null) {
      return const SizedBox.shrink();
    }

    final privacyLevel = PrivacyHelper.getPrivacyLevel(_privacySettings!);
    final privacyText = PrivacyHelper.getPrivacyStatusText(_privacySettings!);
    final privacyIcon = PrivacyHelper.getPrivacyIcon(privacyLevel);

    return InkWell(
      onTap: widget.isOwnProfile ? widget.onPrivacyTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getPrivacyColor(privacyLevel).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getPrivacyColor(privacyLevel).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              privacyIcon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              privacyText,
              style: TextStyle(
                color: _getPrivacyColor(privacyLevel),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.isOwnProfile) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: _getPrivacyColor(privacyLevel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPrivacyColor(String level) {
    switch (level) {
      case 'open':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'private':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class PrivacyQuickSettingsWidget extends StatefulWidget {
  const PrivacyQuickSettingsWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final String userId;
  final VoidCallback? onSettingsChanged;

  const PrivacyQuickSettingsWidget({
    Key? key,
    required this.userId,
    this.onSettingsChanged,
  }) : super(key: key);

  @override
  State<PrivacyQuickSettingsWidget> createState() => _PrivacyQuickSettingsWidgetState();
}

class _PrivacyQuickSettingsWidgetState extends State<PrivacyQuickSettingsWidget> {
  Map<String, dynamic>? _currentSettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      final settings = await UserPrivacyService.getUserPrivacySettings(widget.userId);
      setState(() {
        _currentSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyPreset(String presetKey) async {
    setState(() {
      _isSaving = true;
    });

    try {
      final presets = PrivacyHelper.getQuickPrivacyPresets();
      final preset = presets[presetKey];
      
      if (preset != null) {
        final settings = preset['settings'] as Map<String, dynamic>;
        await UserPrivacyService.saveUserPrivacySettings(widget.userId, settings);
        
        setState(() {
          _currentSettings = settings;
        });

        widget.onSettingsChanged?.call();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã áp dụng cài đặt "${preset['name']}"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Có lỗi khi áp dụng cài đặt'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final presets = PrivacyHelper.getQuickPrivacyPresets();
    final currentLevel = _currentSettings != null 
        ? PrivacyHelper.getPrivacyLevel(_currentSettings!)
        : 'moderate';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt nhanh',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...presets.entries.map((entry) {
          final presetKey = entry.key;
          final preset = entry.value;
          final isSelected = _getPresetLevel(preset['settings']) == currentLevel;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving ? null : () => _applyPreset(presetKey),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        preset['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              preset['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected 
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preset['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                        )
                      else if (_isSaving)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getPresetLevel(Map<String, dynamic> settings) {
    return PrivacyHelper.getPrivacyLevel(settings);
  }
}

class PrivacyInfoDialog extends StatelessWidget {
  const PrivacyInfoDialog({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const PrivacyInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.privacy_tip, color: Colors.blue),
          SizedBox(width: 8),
          Text('Thông tin riêng tư'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cài đặt riêng tư cho phép bạn kiểm soát:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _InfoItem(
              icon: '🌍',
              title: 'Hiển thị công khai',
              description: 'Ai có thể thấy thông tin và hoạt động của bạn trong app',
            ),
            _InfoItem(
              icon: '🎯',
              title: 'Thách đấu & Tournament',
              description: 'Ai có thể mời bạn thách đấu hoặc tham gia tournament',
            ),
            _InfoItem(
              icon: '👤',
              title: 'Thông tin cá nhân',
              description: 'Thông tin nào được hiển thị trong profile của bạn',
            ),
            _InfoItem(
              icon: '🔔',
              title: 'Thông báo',
              description: 'Khi nào bạn muốn nhận thông báo từ hệ thống',
            ),
            SizedBox(height: 16),
            Text(
              'Bạn có thể thay đổi cài đặt bất kỳ lúc nào trong phần Cài đặt riêng tư.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đã hiểu'),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String icon;
  final String title;
  final String description;

  const _InfoItem({
    
    required this.icon,
    required this.title,
    required this.description,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}