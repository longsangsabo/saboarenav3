# Notification System Integration Guide

Complete notification system đã được implement cho SABO Arena app với các tính năng:

## ✅ Implemented Features

### 1. Enhanced Notification Service (`enhanced_notification_service.dart`)
- **Local Notifications**: Flutter local notifications với customizable sounds, vibrations
- **Real-time Updates**: Supabase real-time subscriptions cho instant notifications
- **Background Processing**: WorkManager để xử lý notifications khi app đóng
- **Bulk Operations**: Mark multiple notifications as read, batch processing
- **Action Handling**: Support notification action buttons (Accept/Decline/etc.)

### 2. Notification Preferences System (`notification_preferences_service.dart`)
- **Per-type Settings**: Enable/disable cho từng loại notification
- **Quiet Hours**: Tự động disable notifications trong khung giờ nhất định
- **Sound & Vibration**: Customizable audio và haptic feedback
- **Server Sync**: Sync preferences với Supabase backend
- **Granular Control**: Push, local, sound, vibration settings riêng biệt

### 3. Rich UI Components
- **Notification List Screen**: Swipe actions, filtering, pagination, real-time updates
- **Settings Screen**: Beautiful UI cho notification preferences với expandable cards
- **Admin Dashboard**: Complete analytics dashboard với charts và broadcast functionality

### 4. Comprehensive Analytics (`notification_analytics_service.dart`)
- **Delivery Tracking**: Monitor notification delivery rates
- **Read Rates**: Track user engagement với notifications
- **Click-through Rates**: Monitor notification effectiveness
- **Type Performance**: Analytics per notification type
- **User Engagement**: Individual user behavior metrics
- **Export Functionality**: Export analytics data for reporting

### 5. Data Models (`notification_models.dart`)
- **NotificationModel**: Complete data structure với priorities, actions, metadata
- **NotificationTemplates**: Pre-built templates cho common notifications
- **Analytics Models**: Structured analytics data models
- **Preferences Models**: Type-safe preference configurations

## 🚀 How to Integrate

### 1. Add to Your Main App

```dart
// main.dart
import 'package:your_app/services/notification_system_integration.dart';
import 'package:your_app/services/notification_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase first
  await Supabase.initialize(/* your config */);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SABO Arena',
      routes: {
        // Your existing routes
        ...NotificationRoutes.getRoutes(), // Add notification routes
      },
      home: AuthWrapper(), // Your auth wrapper
    );
  }
}
```

### 2. Wrap Your Authenticated App

```dart
// After user logs in, wrap your main screen with notification system
class AuthenticatedApp extends StatelessWidget {
  final String userId;
  
  const AuthenticatedApp({required this.userId});

  @override
  Widget build(BuildContext context) {
    return NotificationSystemWrapper(
      userId: userId,
      enableAnalytics: true,
      child: MainScreen(), // Your main app screen
    );
  }
}
```

### 3. Add Notification Bell to AppBar

```dart
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SABO Arena'),
        actions: [
          // Notification bell with badge
          NotificationSystemIntegration.instance.buildNotificationBell(
            onTap: () => NotificationRoutes.toNotificationList(context),
            iconColor: Colors.white,
          ),
        ],
      ),
      body: YourMainContent(),
    );
  }
}
```

### 4. Send Notifications

```dart
// Send notification to specific user
await NotificationSystemIntegration.instance.sendNotificationToUser(
  userId: 'target_user_id',
  type: NotificationType.tournamentInvitation,
  title: 'Tournament Invitation',
  body: 'You\'re invited to join Summer Championship!',
  actionUrl: '/tournaments/123',
  data: {'tournament_id': '123'},
);

// Send using template
await NotificationSystemIntegration.instance.sendTemplateNotification(
  userId: 'user_id',
  type: NotificationType.matchResult,
  variables: {
    'opponent_name': 'John Doe',
    'result': 'You won!',
    'match_id': '456',
  },
);

// Broadcast to multiple users
await NotificationSystemIntegration.instance.sendBroadcastNotification(
  userIds: ['user1', 'user2', 'user3'],
  type: NotificationType.clubAnnouncement,
  title: 'Club Meeting',
  body: 'Monthly club meeting tomorrow at 7 PM',
);
```

### 5. Database Setup

Run the SQL migration để setup analytics tables:

```bash
# Apply notification analytics functions
psql -h your-host -U postgres -d your-db -f notification_analytics_functions.sql
```

### 6. Navigation Integration

```dart
// In your drawer or navigation menu
ListTile(
  leading: NotificationSystemIntegration.instance.buildNotificationBadge(
    child: Icon(Icons.notifications),
  ),
  title: Text('Notifications'),
  onTap: () => NotificationRoutes.toNotificationList(context),
),

// Settings screen
ListTile(
  leading: Icon(Icons.notifications_active),
  title: Text('Notification Settings'),
  onTap: () => NotificationRoutes.toNotificationSettings(context),
),

// Admin only
if (userRole == 'admin')
  ListTile(
    leading: Icon(Icons.dashboard),
    title: Text('Notification Dashboard'),
    onTap: () => NotificationRoutes.toAdminDashboard(context),
  ),
```

## 🔧 Configuration Options

### Notification Types
- `tournament_invitation` - Tournament invites
- `match_result` - Match outcomes  
- `club_announcement` - Club news
- `rank_update` - Ranking changes
- `friend_request` - Friend requests
- `challenge_request` - Game challenges
- `system_notification` - System updates

### Priority Levels
- `low` - Background notifications
- `normal` - Standard notifications (default)
- `high` - Important notifications
- `urgent` - Critical notifications

## 📊 Analytics Available

### Global Metrics
- Total notifications sent
- Read rates by type
- Click-through rates
- Average response times
- Delivery trends over time

### User Metrics  
- Individual read rates
- Preferred notification types
- Engagement patterns
- Response time analysis

### Admin Dashboard Features
- Send broadcast notifications
- View real-time analytics
- Manage notification templates
- Monitor system health
- Export analytics data

## 🔒 Security & Privacy

- **RLS Policies**: Row Level Security cho user data
- **Permission Based**: Admin functions require proper auth
- **Data Privacy**: User preferences stored securely
- **Analytics Anonymization**: Optional user data anonymization

## 🧪 Testing

```dart
// Send test notification
await NotificationSystemIntegration.instance.sendNotificationToUser(
  userId: 'current_user_id',
  type: NotificationType.general,
  title: 'Test Notification',
  body: 'This is a test notification',
  priority: NotificationPriority.normal,
);
```

## 📝 Customization

### Custom Notification Templates
```dart
final customTemplate = NotificationTemplate(
  type: NotificationType.general,
  titleTemplate: 'Custom: {{title}}',
  bodyTemplate: 'Hello {{user_name}}, {{message}}',
  defaultPriority: NotificationPriority.high,
  actions: [
    NotificationAction(id: 'view', title: 'View Details'),
    NotificationAction(id: 'dismiss', title: 'Dismiss'),
  ],
);
```

### Custom Analytics Events
```dart
await NotificationAnalyticsService.instance.trackCustomEvent(
  eventName: 'custom_user_action',
  userId: userId,
  data: {'action_type': 'button_click', 'screen': 'home'},
);
```

## 🎯 Best Practices

1. **Initialize Early**: Initialize notification system as soon as user authenticates
2. **Handle Permissions**: Request notification permissions appropriately
3. **Batch Operations**: Use bulk operations cho better performance
4. **Analytics**: Track important events để improve engagement
5. **User Control**: Always provide easy settings để users control notifications
6. **Test Thoroughly**: Test với different notification types và scenarios

## 🐛 Troubleshooting

### Common Issues

1. **Notifications not showing**: Check permission settings và initialization
2. **Analytics not working**: Verify Supabase connection và RLS policies  
3. **Background sync failing**: Check WorkManager setup và permissions
4. **Real-time updates slow**: Verify Supabase real-time configuration

### Debug Mode
```dart
// Enable debug logging
await NotificationSystemIntegration.instance.initialize(
  userId: userId,
  enableAnalytics: true,
  config: {'debug_mode': true},
);
```

This complete notification system provides enterprise-grade functionality with comprehensive analytics, user preferences, admin controls, and beautiful UI components. Tất cả đã ready để integrate vào SABO Arena app!