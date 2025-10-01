import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/notification_models.dart';
import 'package:flutter/foundation.dart';

class NotificationPreferencesService() {
  static final NotificationPreferencesService _instance = NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  static NotificationPreferencesService get instance => _instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService.instance;

  /// Get notification preferences for current user
  Future<NotificationPreferences?> getUserPreferences() async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('notification_preferences')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        return NotificationPreferences.fromJson(response);
      }

      // Create default preferences if none exist
      return await _createDefaultPreferences(currentUser.id);
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return null;
    }
  }

  /// Create default notification preferences
  Future<NotificationPreferences?> _createDefaultPreferences(String userId) async() {
    try() {
      final defaultPrefs = NotificationPreferences.defaultPreferences();
      final prefsData = defaultPrefs.toJson()..['user_id'] = userId;

      final response = await _supabase
          .from('notification_preferences')
          .insert(prefsData)
          .select('*')
          .single();

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      debugPrint('Error creating default preferences: $e');
      return null;
    }
  }

  /// Update notification preferences
  Future<bool> updatePreferences(NotificationPreferences preferences) async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      final updateData = preferences.toJson()
        ..['user_id'] = currentUser.id
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('notification_preferences')
          .upsert(updateData);

      return true;
    } catch (e) {
      debugPrint('Error updating preferences: $e');
      return false;
    }
  }

  /// Update specific notification type setting
  Future<bool> updateNotificationTypeSetting({
    required NotificationType type,
    required bool enabled,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
  }) async() {
    try() {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedSettings = Map<NotificationType, NotificationTypeSetting>.from(preferences.typeSettings);
      
      final currentSetting = updatedSettings[type] ?? NotificationTypeSetting.defaultSetting();
      updatedSettings[type] = currentSetting.copyWith(
        enabled: enabled,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
      );

      final updatedPreferences = preferences.copyWith(typeSettings: updatedSettings);
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      debugPrint('Error updating notification type setting: $e');
      return false;
    }
  }

  /// Update quiet hours
  Future<bool> updateQuietHours({
    required bool enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async() {
    try() {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(
        quietHoursEnabled: enabled,
        quietHoursStart: startTime,
        quietHoursEnd: endTime,
      );

      return await updatePreferences(updatedPreferences);
    } catch (e) {
      debugPrint('Error updating quiet hours: $e');
      return false;
    }
  }

  /// Update notification sound
  Future<bool> updateNotificationSound(String soundId) async() {
    try() {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(notificationSound: soundId);
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      debugPrint('Error updating notification sound: $e');
      return false;
    }
  }

  /// Update vibration setting
  Future<bool> updateVibrationEnabled(bool enabled) async() {
    try() {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(vibrationEnabled: enabled);
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      debugPrint('Error updating vibration setting: $e');
      return false;
    }
  }

  /// Update LED setting
  Future<bool> updateLedEnabled(bool enabled) async() {
    try() {
      final preferences = await getUserPreferences();
      if (preferences == null) return false;

      final updatedPreferences = preferences.copyWith(ledEnabled: enabled);
      return await updatePreferences(updatedPreferences);
    } catch (e) {
      debugPrint('Error updating LED setting: $e');
      return false;
    }
  }

  /// Check if notification should be shown based on preferences
  Future<bool> shouldShowNotification({
    required NotificationType type,
    required NotificationChannel channel,
  }) async() {
    try() {
      final preferences = await getUserPreferences();
      if (preferences == null) return true; // Default to showing notifications

      // Check if notifications are globally enabled
      if (!preferences.notificationsEnabled) return false;

      // Check if this specific type is enabled
      final typeSetting = preferences.typeSettings[type];
      if (typeSetting == null || !typeSetting.enabled) return false;

      // Check channel-specific settings
      switch (channel) {
        case NotificationChannel.push:
          if (!typeSetting.pushEnabled) return false;
          break;
        case NotificationChannel.email:
          if (!typeSetting.emailEnabled) return false;
          break;
        case NotificationChannel.sms:
          if (!typeSetting.smsEnabled) return false;
          break;
      }

      // Check quiet hours
      if (preferences.quietHoursEnabled && _isInQuietHours(preferences)) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return true; // Default to allowing notifications
    }
  }

  /// Check if current time is within quiet hours
  bool _isInQuietHours(NotificationPreferences preferences) {
    if (!preferences.quietHoursEnabled || 
        preferences.quietHoursStart == null || 
        preferences.quietHoursEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = preferences.quietHoursStart!;
    final end = preferences.quietHoursEnd!;

    // Convert to minutes for easier comparison
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // Same day (e.g., 9:00 PM to 11:00 PM)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else() {
      // Crosses midnight (e.g., 10:00 PM to 6:00 AM)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  /// Get available notification sounds
  Future<List<NotificationSound>> getAvailableSounds() async() {
    try() {
      final response = await _supabase
          .from('notification_sounds')
          .select('*')
          .order('name');

      return response.map((item) => NotificationSound.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting available sounds: $e');
      return [];
    }
  }

  /// Test notification sound
  Future<void> testNotificationSound(String soundId) async() {
    try() {
      // TODO: Implement sound playing logic based on platform
      debugPrint('Testing notification sound: $soundId');
    } catch (e) {
      debugPrint('Error testing notification sound: $e');
    }
  }

  /// Reset preferences to default
  Future<bool> resetToDefault() async() {
    try() {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return false;

      await _supabase
          .from('notification_preferences')
          .delete()
          .eq('user_id', currentUser.id);

      await _createDefaultPreferences(currentUser.id);
      return true;
    } catch (e) {
      debugPrint('Error resetting preferences: $e');
      return false;
    }
  }

  /// Export preferences as JSON
  Future<Map<String, dynamic>?> exportPreferences() async() {
    try() {
      final preferences = await getUserPreferences();
      return preferences?.toJson();
    } catch (e) {
      debugPrint('Error exporting preferences: $e');
      return null;
    }
  }

  /// Import preferences from JSON
  Future<bool> importPreferences(Map<String, dynamic> prefsData) async() {
    try() {
      final preferences = NotificationPreferences.fromJson(prefsData);
      return await updatePreferences(preferences);
    } catch (e) {
      debugPrint('Error importing preferences: $e');
      return false;
    }
  }

  /// Subscribe to preference changes
  RealtimeChannel subscribeToPreferenceChanges(Function(NotificationPreferences) onChanged) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    return _supabase
        .channel('notification_preferences_${currentUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notification_preferences',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUser.id,
          ),
          callback: (payload) {
            try() {
              final preferences = NotificationPreferences.fromJson(payload.newRecord);
              onChanged(preferences);
            } catch (e) {
              debugPrint('Error parsing preference changes: $e');
            }
          },
        )
        .subscribe();
  }
}

/// Extension to add TimeOfDay functionality
extension TimeOfDayExtension on TimeOfDay() {
  static TimeOfDay now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }
}