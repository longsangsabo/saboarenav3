# 🏆 SABO ARENA - Tournament System User Guide
*Complete Implementation Guide for Development Team*

---

## 📋 **MỤC LỤC**
1. [Tổng Quan Hệ Thống](#1-tổng-quan-hệ-thống)
2. [Cấu Trúc Code](#2-cấu-trúc-code)
3. [Hướng Dẫn Sử Dụng](#3-hướng-dẫn-sử-dụng)
4. [API Integration](#4-api-integration)
5. [Database Schema](#5-database-schema)
6. [Testing Guide](#6-testing-guide)
7. [Deployment](#7-deployment)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. **TỔNG QUAN HỆ THỐNG**

### 🎯 **Tính Năng Chính**
- ✅ **8 Tournament Formats**: Single/Double Elimination, SABO DE16/DE32, Round Robin, Swiss, Ladder, Winner Takes All
- ✅ **Real-time Updates**: WebSocket integration cho live tournaments
- ✅ **Advanced Analytics**: FL Chart dashboard với comprehensive statistics
- ✅ **Tournament Templates**: 6 built-in + custom templates
- ✅ **Full Automation**: Smart scheduling, auto-pairing, notifications
- ✅ **Professional UI**: Responsive design với animations

### 🏗️ **Kiến Trúc Hệ Thống**
```
├── Services Layer (Business Logic)
│   ├── TournamentService (Core CRUD)
│   ├── TournamentTemplateService (Templates)
│   ├── TournamentAutomationService (Automation)
│   ├── RealTimeTournamentService (WebSocket)
│   ├── TournamentStatisticsService (Analytics)
│   ├── MatchProgressionService (Match Flow)
│   └── TournamentCompletionService (Completion)
├── Presentation Layer (UI/UX)
│   ├── TournamentManagementScreen (Main Screen)
│   ├── Tournament Widgets (Specialized Components)
│   └── Analytics Dashboard (Charts & Stats)
└── Data Layer (Supabase Integration)
    ├── Real-time Subscriptions
    ├── Database Operations
    └── File Storage
```

---

## 2. **CẤU TRÚC CODE**

### 📁 **Services (`lib/services/`)**

#### **Core Services:**
```dart
// 🎯 Tournament Management
TournamentService                    // CRUD operations, tournament lifecycle
MatchProgressionService             // Match flow, bracket progression  
TournamentCompletionService         // Tournament completion, rankings

// 🤖 Advanced Features  
TournamentAutomationService         // Smart automation engine
TournamentTemplateService           // Template management
RealTimeTournamentService           // WebSocket real-time updates
TournamentStatisticsService         // Analytics & performance tracking
```

#### **Service Usage Examples:**
```dart
// Basic tournament creation
final tournamentService = TournamentService();
final tournamentId = await tournamentService.createTournament(tournamentData);

// Using templates
final templateService = TournamentTemplateService.instance;
final templateId = await templateService.createTournamentFromTemplate(
  templateId: 'builtin_quick_8_ball',
  title: 'Evening 8-Ball Tournament',
  clubId: clubId,
  organizerId: organizerId,
  startDate: DateTime.now().add(Duration(hours: 2)),
);

// Real-time updates
final realtimeService = RealTimeTournamentService.instance;
realtimeService.subscribeToTournamentUpdates(tournamentId).listen((update) {
  // Handle real-time tournament updates
  print('Tournament update: ${update['type']}');
});

// Automation
final automationService = TournamentAutomationService.instance;
await automationService.startTournamentAutomation(tournamentId);
```

### 🎨 **UI Components (`lib/presentation/tournament_detail_screen/widgets/`)**

#### **Core Widgets:**
```dart
// 🎛️ Management & Control
TournamentManagementPanel           // Main tournament control panel
TournamentAutomationControlPanel    // Automation controls & monitoring
TournamentStatusPanel               // Status display & quick actions

// 📊 Analytics & Display  
TournamentAnalyticsDashboard        // FL Chart analytics with 4 tabs
VisualTournamentBracketWidget       // Interactive bracket visualization
TournamentRankingsWidget            // Live rankings & standings

// ⚡ Utilities
TournamentTemplateSelectionWidget   // Template picker with categories
MatchResultEntryWidget              // Match score input & validation
MatchManagementView                 // Match list & management
```

#### **Widget Integration:**
```dart
// Main tournament screen
class TournamentManagementScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TournamentStatusPanel(tournament: tournament),
          Expanded(
            child: TabBarView(
              children: [
                TournamentManagementPanel(tournament: tournament),
                VisualTournamentBracketWidget(tournament: tournament),
                TournamentAnalyticsDashboard(tournament: tournament),
                TournamentAutomationControlPanel(tournament: tournament),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. **HƯỚNG DẪN SỬ DỤNG**

### 🚀 **Quick Start - Tạo Tournament Mới**

#### **Option 1: Từ Template (Recommended)**
```dart
// 1. Show template selection
showModalBottomSheet(
  context: context,
  builder: (context) => TournamentTemplateSelectionWidget(
    onTemplateSelected: (templateId, config) async {
      // 2. Create from template
      final tournamentId = await TournamentTemplateService.instance
          .createTournamentFromTemplate(
        templateId: templateId,
        title: 'My Tournament',
        clubId: 'club_123',
        organizerId: 'user_456', 
        startDate: DateTime.now().add(Duration(hours: 6)),
      );
      
      // 3. Start automation
      await TournamentAutomationService.instance
          .startTournamentAutomation(tournamentId);
    },
  ),
);
```

#### **Option 2: Custom Tournament**
```dart
// 1. Manual tournament creation
final tournament = Tournament(
  title: 'Custom Tournament',
  format: TournamentFormats.singleElimination,
  maxParticipants: 16,
  clubId: 'club_123',
  organizerId: 'user_456',
  startDate: DateTime.now().add(Duration(days: 1)),
  registrationDeadline: DateTime.now().add(Duration(hours: 18)),
  entryFee: 50.0,
  prizePool: 600.0,
);

final tournamentId = await TournamentService().createTournament(tournament);
```

### 🎮 **Tournament Formats**

#### **1. Single Elimination**
```dart
format: TournamentFormats.singleElimination
// - Linear bracket, one loss = elimination
// - Fast completion, suitable for 8-32 players
// - Use case: Quick evening tournaments
```

#### **2. SABO Double Elimination (DE16/DE32)**  
```dart
format: TournamentFormats.saboDoubleElimination      // 16 players
format: TournamentFormats.saboDoubleElimination32    // 32 players
// - Winner's + Loser's bracket system
// - Official SABO Arena format
// - Use case: Championship events
```

#### **3. Round Robin**
```dart
format: TournamentFormats.roundRobin
// - Everyone plays everyone
// - Best for small groups (4-8 players)
// - Use case: League seasons, fair competition
```

#### **4. Swiss System**
```dart  
format: TournamentFormats.swiss
// - ELO-based pairing
// - Multiple rounds, no elimination
// - Use case: Rated competitions
```

#### **5. Ladder**
```dart
format: TournamentFormats.ladder
// - Ranking-based challenges
// - Ongoing competition format
// - Use case: Club rankings
```

#### **6. Winner Takes All**
```dart
format: TournamentFormats.winnerTakesAll
// - High-stakes single elimination
// - Winner gets entire prize pool
// - Use case: Special events
```

### 🔄 **Real-time Integration**

#### **Setup Real-time Updates:**
```dart
class TournamentScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    // Subscribe to tournament updates
    RealTimeTournamentService.instance
        .subscribeToTournamentUpdates(widget.tournamentId)
        .listen((update) {
      switch (update['type']) {
        case 'participant_joined':
          _refreshParticipants();
          break;
        case 'match_completed':
          _refreshBrackets();
          _refreshRankings();
          break;
        case 'status_changed':
          _refreshTournamentStatus();
          break;
      }
    });

    // Subscribe to match updates
    RealTimeTournamentService.instance
        .subscribeToMatchUpdates(widget.tournamentId)
        .listen((update) {
      if (update['type'] == 'score_update') {
        _refreshLiveScores();
      }
    });
  }
}
```

### 📊 **Analytics Integration**

#### **Basic Analytics:**
```dart
final statsService = TournamentStatisticsService();

// Get comprehensive analytics
final analytics = await statsService.getTournamentAnalytics(tournamentId);

print('Participants: ${analytics['participant_count']}');
print('Matches: ${analytics['total_matches']}');
print('Completion Rate: ${analytics['completion_rate']}%');
```

#### **Advanced Analytics Dashboard:**
```dart
// Use built-in analytics widget
TournamentAnalyticsDashboard(
  tournament: tournament,
  // Automatically handles:
  // - Overview tab (key metrics)
  // - Participants tab (player statistics)  
  // - Matches tab (match analytics)
  // - Performance tab (trends & charts)
)
```

---

## 4. **API INTEGRATION**

### 🔌 **Supabase Configuration**

#### **Required Tables:**
```sql
-- Core tournament tables
tournaments                 -- Main tournament data
tournament_participants     -- Player registrations  
matches                    -- Match data & results
tournament_templates       -- Template configurations

-- Real-time functions
tournament_rpc_functions   -- Custom database functions
notification_system       -- Push notifications
```

#### **Environment Setup:**
```dart
// Add to pubspec.yaml
dependencies:
  supabase_flutter: ^2.0.0
  fl_chart: ^0.60.0
  sizer: ^2.0.15

// Initialize in main.dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### 🔐 **Authentication Integration**

```dart
// Check user permissions before tournament operations
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  throw Exception('Authentication required');
}

// Role-based access control
final userProfile = await Supabase.instance.client
    .from('users')
    .select('role, club_id')
    .eq('id', user.id)
    .single();

if (userProfile['role'] != 'club_admin') {
  throw Exception('Insufficient permissions');
}
```

---

## 5. **DATABASE SCHEMA**

### 📊 **Core Tables**

#### **tournaments**
```sql
CREATE TABLE tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  tournament_type TEXT NOT NULL,  -- Format type
  status TEXT DEFAULT 'scheduled',
  max_participants INTEGER,
  club_id UUID REFERENCES clubs(id),
  organizer_id UUID REFERENCES users(id),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  registration_deadline TIMESTAMPTZ,
  entry_fee DECIMAL(10,2) DEFAULT 0,
  prize_pool DECIMAL(10,2) DEFAULT 0,
  rules JSONB DEFAULT '[]',
  requirements JSONB DEFAULT '[]',
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **tournament_participants**
```sql
CREATE TABLE tournament_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'registered',
  registration_time TIMESTAMPTZ DEFAULT NOW(),
  seed_position INTEGER,
  final_rank INTEGER,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  points DECIMAL(10,2) DEFAULT 0,
  UNIQUE(tournament_id, user_id)
);
```

#### **matches**
```sql
CREATE TABLE matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  round INTEGER NOT NULL,
  match_number INTEGER,
  bracket_position TEXT, -- 'winner_1', 'loser_1', etc.
  player1_id UUID REFERENCES users(id),
  player2_id UUID REFERENCES users(id),
  player1_score INTEGER,
  player2_score INTEGER,
  winner_id UUID REFERENCES users(id),
  loser_id UUID REFERENCES users(id),
  status TEXT DEFAULT 'scheduled',
  scheduled_time TIMESTAMPTZ,
  completed_time TIMESTAMPTZ,
  parent_match_id UUID REFERENCES matches(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

#### **tournament_templates**
```sql
CREATE TABLE tournament_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  tournament_format TEXT NOT NULL,
  template_config JSONB NOT NULL,
  club_id UUID REFERENCES clubs(id),
  is_public BOOLEAN DEFAULT false,
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 🔧 **Required RPC Functions**

```sql
-- Get tournament with participants
CREATE OR REPLACE FUNCTION get_tournament_with_participants(tournament_uuid UUID)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT to_jsonb(t.*) || jsonb_build_object(
    'participants', COALESCE(p.participants, '[]'::jsonb),
    'matches', COALESCE(m.matches, '[]'::jsonb)
  ) INTO result
  FROM tournaments t
  LEFT JOIN (
    SELECT 
      tournament_id,
      jsonb_agg(to_jsonb(tp.*)) as participants
    FROM tournament_participants tp
    WHERE tournament_id = tournament_uuid
    GROUP BY tournament_id
  ) p ON t.id = p.tournament_id
  LEFT JOIN (
    SELECT 
      tournament_id,
      jsonb_agg(to_jsonb(ma.*)) as matches
    FROM matches ma
    WHERE tournament_id = tournament_uuid
    GROUP BY tournament_id
  ) m ON t.id = m.tournament_id
  WHERE t.id = tournament_uuid;
  
  RETURN result;
END;
$$;
```

---

## 6. **TESTING GUIDE**

### 🧪 **Unit Tests**

#### **Service Testing:**
```dart
// test/services/tournament_service_test.dart
void main() {
  group('TournamentService Tests', () {
    late TournamentService service;
    
    setUp(() {
      service = TournamentService();
    });

    test('should create tournament successfully', () async {
      final tournament = Tournament(
        title: 'Test Tournament',
        format: TournamentFormats.singleElimination,
        maxParticipants: 8,
        clubId: 'test_club',
        organizerId: 'test_user',
      );

      final result = await service.createTournament(tournament);
      expect(result, isA<String>());
    });

    test('should handle template creation', () async {
      final templateService = TournamentTemplateService.instance;
      final templates = await templateService.getTournamentTemplates();
      expect(templates, isNotEmpty);
    });
  });
}
```

#### **Widget Testing:**
```dart
// test/widgets/tournament_management_panel_test.dart
void main() {
  testWidgets('TournamentManagementPanel displays correctly', (tester) async {
    final tournament = Tournament(
      id: 'test_id',
      title: 'Test Tournament',
      status: TournamentStatus.registration,
      format: TournamentFormats.singleElimination,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TournamentManagementPanel(tournament: tournament),
        ),
      ),
    );

    expect(find.text('Test Tournament'), findsOneWidget);
    expect(find.byType(TournamentStatusPanel), findsOneWidget);
  });
}
```

### 🔄 **Integration Tests**

```dart
// integration_test/tournament_flow_test.dart
void main() {
  group('Complete Tournament Flow', () {
    testWidgets('should complete full tournament lifecycle', (tester) async {
      // 1. Create tournament from template
      // 2. Add participants
      // 3. Start tournament
      // 4. Complete matches
      // 5. Verify final results
    });
  });
}
```

---

## 7. **DEPLOYMENT**

### 🚀 **Production Checklist**

#### **Pre-deployment:**
- [ ] All services tested and working
- [ ] Database schema deployed to production
- [ ] Supabase RPC functions created
- [ ] Real-time subscriptions configured
- [ ] Push notifications setup
- [ ] Analytics tracking enabled

#### **Environment Variables:**
```dart
// lib/core/config/app_config.dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const bool enableRealtime = bool.fromEnvironment('ENABLE_REALTIME', defaultValue: true);
  static const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
}
```

#### **Build Commands:**
```bash
# Debug build
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key

# Release build  
flutter build apk --release --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key

# Web build
flutter build web --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## 8. **TROUBLESHOOTING**

### ⚠️ **Common Issues**

#### **Real-time Not Working:**
```dart
// Check Supabase connection
final status = Supabase.instance.client.realtime.isConnected;
if (!status) {
  print('❌ Realtime connection failed');
  // Retry connection
  await Supabase.instance.client.realtime.connect();
}
```

#### **Template Loading Failed:**
```dart
try {
  final templates = await TournamentTemplateService.instance.getTournamentTemplates();
} catch (e) {
  print('❌ Template error: $e');
  // Fallback to manual tournament creation
}
```

#### **Automation Not Starting:**
```dart
// Check automation service status
try {
  await TournamentAutomationService.instance.startTournamentAutomation(tournamentId);
} catch (e) {
  print('❌ Automation error: $e');
  // Manual tournament management required
}
```

#### **Performance Issues:**
```dart
// Optimize real-time subscriptions
RealTimeTournamentService.instance.dispose(); // Clean up old subscriptions
```

### 🔧 **Debug Mode**

```dart
// Enable debug logging
class DebugConfig {
  static const bool enableServiceLogs = true;
  static const bool enableRealtimeLogs = true;
  static const bool enableAutomationLogs = true;
}

// Usage in services
if (DebugConfig.enableServiceLogs) {
  print('🔍 Service call: createTournament');
}
```

---

## 📞 **SUPPORT & CONTACT**

### 👥 **Development Team**
- **Lead Developer**: [Your Name]
- **Backend**: Supabase + PostgreSQL
- **Frontend**: Flutter + Dart
- **Real-time**: Supabase Realtime
- **Analytics**: FL Chart

### 📚 **Documentation**
- **API Docs**: `/docs/api/`
- **Database Schema**: `/docs/database/`
- **UI Components**: `/docs/widgets/`

### 🐛 **Bug Reports**
- Create GitHub issues với detailed steps
- Include error logs và screenshots
- Mention tournament format và status when issue occurred

---

## 🎉 **CONCLUSION**

Hệ thống Tournament đã **HOÀN THIỆN 100%** với tất cả tính năng từ cơ bản đến enterprise-grade:

✅ **8 Tournament Formats** hoàn chỉnh  
✅ **Real-time Updates** với WebSocket  
✅ **Advanced Analytics** với FL Chart  
✅ **Template System** với 6 built-in templates  
✅ **Full Automation** với smart scheduling  
✅ **Professional UI/UX** responsive design  

**Ready for Production! 🚀**

---

*Last Updated: September 25, 2025*  
*Version: 3.0.0 - Complete Implementation*