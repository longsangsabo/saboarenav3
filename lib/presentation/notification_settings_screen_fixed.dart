import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../models/notification_models.dart';

/// Simplified Notification Settings Screen
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

@override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _pushEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _quietHoursEnabled = false;
  
  // Individual notification type settings
  final Map<NotificationType, bool> _typeSettings = {
    for (var type in NotificationType.values) type: true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 1,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGeneralSettings(),
            SizedBox(height: 3.h),
            _buildNotificationTypes(),
            SizedBox(height: 3.h),
            _buildAdvancedSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Settings',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Turn all notifications on or off'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive push notifications on this device'),
                value: _pushEnabled,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() => _pushEnabled = value);
                } : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Sound'),
                subtitle: const Text('Play sound for notifications'),
                value: _soundEnabled,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() => _soundEnabled = value);
                } : null,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Vibration'),
                subtitle: const Text('Vibrate for notifications'),
                value: _vibrationEnabled,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() => _vibrationEnabled = value);
                } : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Types',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Column(
            children: NotificationType.values.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value;
              final isEnabled = _typeSettings[type] ?? true;
              
              return Column(
                children: [
                  SwitchListTile(
                    title: Text(type.displayName),
                    subtitle: Text(type.description),
                    value: isEnabled,
                    onChanged: _notificationsEnabled ? (value) {
                      setState(() => _typeSettings[type] = value);
                    } : null,
                  ),
                  if (index < NotificationType.values.length - 1)
                    const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Settings',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Quiet Hours'),
                subtitle: const Text('Disable notifications during specific hours'),
                value: _quietHoursEnabled,
                onChanged: _notificationsEnabled ? (value) {
                  setState(() => _quietHoursEnabled = value);
                } : null,
              ),
              if (_quietHoursEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: const Text('22:00'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () {
                    // TODO: Implement time picker
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: const Text('07:00'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () {
                    // TODO: Implement time picker
                  },
                ),
              ],
              const Divider(height: 1),
              ListTile(
                title: const Text('Notification Sound'),
                subtitle: const Text('Default'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Implement sound picker
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Test Notification'),
                subtitle: const Text('Send a test notification'),
                trailing: const Icon(Icons.send),
                onTap: () {
                  _sendTestNotification();
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 3.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ),
      ],
    );
  }

  void _sendTestNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveSettings() {
    // TODO: Implement save functionality with NotificationPreferencesService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

