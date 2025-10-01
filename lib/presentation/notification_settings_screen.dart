import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../services/notification_preferences_service.dart';

/// Notification Settings Screen để users tùy chỉnh notification preferences
class NotificationSettingsScreen extends StatefulWidget() {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationPreferencesService _prefsService = 
      NotificationPreferencesService.instance;
  
  NotificationPreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async() {
    try() {
      final prefs = await _prefsService.loadPreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load notification preferences');
    }
  }

  Future<void> _updateGlobalSetting(bool enabled) async() {
    if (_preferences == null) return;
    
    setState(() => _isSaving = true);
    
    try() {
      _preferences!.globalEnabled = enabled;
      await _prefsService.savePreferences(_preferences!);
      setState(() => _isSaving = false);
      _showSuccessSnackBar('Notification settings updated');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to update settings');
    }
  }

  Future<void> _updateTypeSetting(NotificationType type, bool enabled) async() {
    setState(() => _isSaving = true);
    
    try() {
      await _prefsService.updateNotificationTypeSetting(type, enabled);
      await _loadPreferences(); // Refresh
      setState(() => _isSaving = false);
      _showSuccessSnackBar('${type.displayName} updated');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to update ${type.displayName}');
    }
  }

  Future<void> _updatePushSetting(NotificationType type, bool enabled) async() {
    setState(() => _isSaving = true);
    
    try() {
      await _prefsService.updatePushSetting(type, enabled);
      await _loadPreferences(); // Refresh
      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to update push settings');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlobalSection(),
                  SizedBox(height: 3.h),
                  _buildNotificationTypesSection(),
                  SizedBox(height: 3.h),
                  _buildQuietHoursSection(),
                  SizedBox(height: 3.h),
                  _buildAdvancedSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGlobalSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications_active, 
                     color: Colors.green[700], size: 6.w),
                SizedBox(width: 3.w),
                Text(
                  'General Settings',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: const Text(
                'Enable Notifications',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Turn all notifications on or off'
              ),
              value: _preferences?.globalEnabled ?? true,
              onChanged: _isSaving ? null : _updateGlobalSetting,
              thumbColor: Colors.green[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypesSection() {
    if (_preferences == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.green[700], size: 6.w),
                SizedBox(width: 3.w),
                Text(
                  'Notification Types',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ...NotificationType.values.map(
              (type) => _buildNotificationTypeItem(type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeItem(NotificationType type) {
    final setting = _preferences!.typeSettings[type] ?? 
                   NotificationTypeSetting.defaultSetting();

    return ExpansionTile(
      leading: _getTypeIcon(type),
      title: Text(
        type.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        type.description,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12.sp,
        ),
      ),
      trailing: Switch(
        value: setting.enabled && (_preferences!.globalEnabled),
        onChanged: _isSaving || !_preferences!.globalEnabled 
            ? null 
            : (value) => _updateTypeSetting(type, value),
        thumbColor: Colors.green[700],
      ),
      children: [
        if (setting.enabled && _preferences!.globalEnabled)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Show notifications even when app is closed'),
                  value: setting.pushEnabled,
                  onChanged: _isSaving 
                      ? null 
                      : (value) => _updatePushSetting(type, value ?? false),
                  activeColor: Colors.green[700],
                ),
                CheckboxListTile(
                  title: const Text('Sound'),
                  subtitle: const Text('Play sound for notifications'),
                  value: setting.soundEnabled,
                  onChanged: _isSaving 
                      ? null 
                      : (value) {
                          // Update sound setting
                          // TODO: Implement sound setting update
                        },
                  activeColor: Colors.green[700],
                ),
                CheckboxListTile(
                  title: const Text('Vibration'),
                  subtitle: const Text('Vibrate device for notifications'),
                  value: setting.vibrationEnabled,
                  onChanged: _isSaving 
                      ? null 
                      : (value) {
                          // Update vibration setting
                          // TODO: Implement vibration setting update
                        },
                  activeColor: Colors.green[700],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuietHoursSection() {
    if (_preferences == null) return const SizedBox();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: Colors.green[700], size: 6.w),
                SizedBox(width: 3.w),
                Text(
                  'Quiet Hours',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SwitchListTile(
              title: const Text(
                'Enable Quiet Hours',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Disable notifications during specified hours'
              ),
              value: _preferences!.quietHours.enabled,
              onChanged: _isSaving ? null : (value) {
                // TODO: Implement quiet hours toggle
              },
              thumbColor: Colors.green[700],
            ),
            if (_preferences!.quietHours.enabled) ...[
              ListTile(
                title: const Text('Start Time'),
                subtitle: Text(_preferences!.quietHours.startTime.toString()),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(isStartTime: true),
              ),
              ListTile(
                title: const Text('End Time'),
                subtitle: Text(_preferences!.quietHours.endTime.toString()),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(isStartTime: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_applications, 
                     color: Colors.green[700], size: 6.w),
                SizedBox(width: 3.w),
                Text(
                  'Advanced',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ListTile(
              title: const Text('Reset to Defaults'),
              subtitle: const Text('Restore all notification settings to default'),
              leading: const Icon(Icons.restore, color: Colors.orange),
              onTap: _showResetDialog,
            ),
            ListTile(
              title: const Text('Test Notification'),
              subtitle: const Text('Send a test notification'),
              leading: const Icon(Icons.notifications, color: Colors.blue),
              onTap: _sendTestNotification,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTypeIcon(NotificationType type) {
    IconData iconData;
    Color color = Colors.green[700]!;

    switch (type) {
      case NotificationType.tournamentInvitation:
        iconData = Icons.emoji_events;
        break;
      case NotificationType.tournamentRegistration:
        iconData = Icons.app_registration;
        break;
      case NotificationType.matchResult:
        iconData = Icons.sports_score;
        break;
      case NotificationType.clubAnnouncement:
        iconData = Icons.campaign;
        break;
      case NotificationType.rankUpdate:
        iconData = Icons.trending_up;
        break;
      case NotificationType.friendRequest:
        iconData = Icons.person_add;
        break;
      case NotificationType.challengeRequest:
        iconData = Icons.sports_mma;
        break;
      case NotificationType.systemNotification:
        iconData = Icons.system_update;
        color = Colors.blue;
        break;
      case NotificationType.general:
        iconData = Icons.notifications;
        break;
    }

    return Icon(iconData, color: color, size: 6.w);
  }

  Future<void> _selectTime({required bool isStartTime}) async() {
    final currentTime = isStartTime 
        ? _preferences!.quietHours.startTime
        : _preferences!.quietHours.endTime;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentTime.hour, 
        minute: currentTime.minute
      ),
    );

    if (selectedTime != null) {
      final newTime = TimeOfDay(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );

      try() {
        if (isStartTime) {
          await _prefsService.updateQuietHours(
            enabled: _preferences!.quietHours.enabled,
            startTime: newTime,
            endTime: _preferences!.quietHours.endTime,
          );
        } else() {
          await _prefsService.updateQuietHours(
            enabled: _preferences!.quietHours.enabled,
            startTime: _preferences!.quietHours.startTime,
            endTime: newTime,
          );
        }
        
        await _loadPreferences();
        _showSuccessSnackBar('Quiet hours updated');
      } catch (e) {
        _showErrorSnackBar('Failed to update quiet hours');
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all notification settings to default? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async() {
              Navigator.pop(context);
              await _resetToDefaults();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async() {
    setState(() => _isSaving = true);
    
    try() {
      final defaultPrefs = NotificationPreferences.defaultPreferences();
      await _prefsService.savePreferences(defaultPrefs);
      await _loadPreferences();
      setState(() => _isSaving = false);
      _showSuccessSnackBar('Settings reset to default');
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Failed to reset settings');
    }
  }

  void _sendTestNotification() {
    // TODO: Implement test notification
    _showSuccessSnackBar('Test notification sent!');
  }
}