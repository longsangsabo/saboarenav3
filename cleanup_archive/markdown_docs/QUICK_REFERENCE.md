# 🚀 SABO ARENA - Tournament System Quick Reference
*Hướng dẫn nhanh cho Developer*

---

## ⚡ **QUICK START**

### 📦 **Dependencies**
```yaml
dependencies:
  supabase_flutter: ^2.0.0
  fl_chart: ^0.60.0
  sizer: ^2.0.15
```

### 🔑 **Core Services**
```dart
// Import các services chính
import '../services/tournament_service.dart';
import '../services/tournament_template_service.dart';
import '../services/tournament_automation_service.dart';
import '../services/realtime_tournament_service.dart';
import '../services/tournament_statistics_service.dart';
```

---

## 🎯 **TOURNAMENT FORMATS**

| Format | Code | Use Case |
|--------|------|----------|
| Single Elimination | `TournamentFormats.singleElimination` | Quick tournaments |
| SABO DE16 | `TournamentFormats.saboDoubleElimination` | 16-player championships |
| SABO DE32 | `TournamentFormats.saboDoubleElimination32` | 32-player championships |
| Round Robin | `TournamentFormats.roundRobin` | Small groups, leagues |
| Swiss System | `TournamentFormats.swiss` | Rated competitions |
| Ladder | `TournamentFormats.ladder` | Ongoing rankings |
| Winner Takes All | `TournamentFormats.winnerTakesAll` | High-stakes events |

---

## 🏗️ **BASIC IMPLEMENTATION**

### 1️⃣ **Create Tournament từ Template**
```dart
// Show template picker
showModalBottomSheet(
  context: context,
  builder: (context) => TournamentTemplateSelectionWidget(
    onTemplateSelected: (templateId, config) async {
      final tournamentId = await TournamentTemplateService.instance
          .createTournamentFromTemplate(
        templateId: templateId,
        title: 'My Tournament',
        clubId: clubId,
        organizerId: organizerId,
        startDate: DateTime.now().add(Duration(hours: 6)),
      );
    },
  ),
);
```

### 2️⃣ **Setup Real-time Updates**
```dart
void _setupRealtime() {
  RealTimeTournamentService.instance
      .subscribeToTournamentUpdates(tournamentId)
      .listen((update) {
    switch (update['type']) {
      case 'participant_joined':
        _refreshParticipants();
        break;
      case 'match_completed':
        _refreshBrackets();
        break;
    }
  });
}
```

### 3️⃣ **Start Automation**
```dart
// Enable full automation
await TournamentAutomationService.instance
    .startTournamentAutomation(tournamentId);
```

---

## 🎨 **UI COMPONENTS**

### 📊 **Main Widgets**
```dart
// Management Screen
TournamentManagementScreen(tournament: tournament)

// Status Panel  
TournamentStatusPanel(tournament: tournament)

// Analytics Dashboard
TournamentAnalyticsDashboard(tournament: tournament)

// Bracket Visualization
VisualTournamentBracketWidget(tournament: tournament)

// Automation Control
TournamentAutomationControlPanel(tournament: tournament)
```

### 🔧 **Utility Widgets**
```dart
// Template Selection
TournamentTemplateSelectionWidget(onTemplateSelected: callback)

// Match Entry
MatchResultEntryWidget(match: match, onResult: callback)

// Rankings Display
TournamentRankingsWidget(tournament: tournament)
```

---

## 📱 **BUILT-IN TEMPLATES**

| Template | ID | Description |
|----------|----|---------| 
| Quick 8-Ball | `builtin_quick_8_ball` | Fast 16-player single elimination |
| SABO DE16 | `builtin_sabo_de16` | Official championship format |
| Round Robin League | `builtin_round_robin_league` | Everyone plays everyone |
| Swiss Rated | `builtin_swiss_rated` | ELO-based competitive |
| Mega Championship | `builtin_mega_championship` | 32-player DE format |
| Winner Takes All | `builtin_winner_takes_all` | High-stakes showdown |

---

## ⚙️ **AUTOMATION FEATURES**

### 🤖 **Auto Functions**
- ✅ Registration open/close
- ✅ Tournament start
- ✅ Match pairing
- ✅ Bracket progression
- ✅ Notifications
- ✅ Completion handling

### 🎛️ **Control Methods**
```dart
final automation = TournamentAutomationService.instance;

// Start/Stop
await automation.startTournamentAutomation(tournamentId);
await automation.stopTournamentAutomation(tournamentId);
```

---

## 📊 **ANALYTICS**

### 📈 **Basic Stats**
```dart
final stats = TournamentStatisticsService();
final analytics = await stats.getTournamentAnalytics(tournamentId);

// Available data:
// - participant_count
// - total_matches  
// - completion_rate
// - average_match_duration
// - elo_distribution
// - performance_trends
```

### 📱 **Dashboard Tabs**
1. **Overview**: Key metrics & progress
2. **Participants**: Player statistics  
3. **Matches**: Match analytics
4. **Performance**: Trends & charts

---

## 🔍 **DEBUGGING**

### 🐛 **Common Checks**
```dart
// Supabase connection
final isConnected = Supabase.instance.client.realtime.isConnected;

// Service initialization  
final templateService = TournamentTemplateService.instance;
final automationService = TournamentAutomationService.instance;

// Error handling
try {
  await tournamentService.createTournament(data);
} catch (e) {
  print('❌ Error: $e');
}
```

### 📝 **Debug Logging**
```dart
// Enable in services
print('🔍 Service: ${this.runtimeType}');
print('📊 Data: $data');
print('✅ Success: $result');
```

---

## 🚨 **ERROR HANDLING**

### ⚠️ **Common Errors**
```dart
// Authentication
if (Supabase.instance.client.auth.currentUser == null) {
  throw Exception('User not authenticated');
}

// Permission check
final userRole = await getUserRole();
if (userRole != 'club_admin') {
  throw Exception('Insufficient permissions');
}

// Tournament status
if (tournament.status == TournamentStatus.completed) {
  throw Exception('Tournament already completed');
}
```

---

## 🔄 **STATE MANAGEMENT**

### 📱 **Widget State Updates**
```dart
class TournamentScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  void _refreshUI() {
    if (mounted) {
      setState(() {
        // Update UI state
      });
    }
  }

  @override
  void dispose() {
    // Clean up subscriptions
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## 🎉 **PRODUCTION TIPS**

### ⚡ **Performance**
- Use `ListView.builder` cho large lists
- Implement pagination cho tournaments
- Cache template data
- Optimize real-time subscriptions

### 🔒 **Security**
- Validate user permissions
- Sanitize input data
- Use RLS policies
- Implement rate limiting

### 📱 **UX Best Practices**
- Show loading states
- Handle offline scenarios
- Provide error feedback
- Use optimistic updates

---

## 🆘 **EMERGENCY COMMANDS**

```dart
// Stop all automation
await TournamentAutomationService.instance.dispose();

// Clear real-time subscriptions
RealTimeTournamentService.instance.dispose();

// Force tournament completion
await TournamentCompletionService().forceCompleteTournament(tournamentId);

// Reset tournament to previous state
await TournamentService().resetTournamentState(tournamentId, previousState);
```

---

## 📞 **QUICK CONTACTS**

- **Issues**: GitHub Issues
- **Docs**: `/TOURNAMENT_SYSTEM_USER_GUIDE.md`
- **Schema**: Check database migration files
- **Templates**: Built-in templates in `TournamentTemplateService`

---

*Keep this guide handy! 🔖*  
*Updated: Sep 25, 2025*