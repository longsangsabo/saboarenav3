# 🎨 SABO ARENA - CURRENT LAYOUT ANALYSIS

## 📱 Overview
Sabo Arena là một app mạng xã hội billiards sử dụng **Flutter** với **Material Design 3** và **5-tab bottom navigation** architecture.

## 🏗️ App Architecture

### Navigation Flow
```
SplashScreen (2s) 
    ↓
OnboardingScreen (role selection: Player/Club Owner)
    ↓  
LoginScreen (email/password authentication)
    ↓
Main App (5-tab navigation)
```

### Main Layout Structure

#### **📋 1. HomeFeedScreen** (Primary Home)
- **Layout**: Standard Scaffold với custom app bar
- **Components**:
  - `CustomAppBar.homeFeed`: "Billiards Social" + Search/Notifications
  - `FeedTabWidget`: 2 tabs ("Gần đây" / "Đang theo dõi")
  - `Content Area`: Scrollable ListView của posts
  - `FloatingActionButton`: Tạo bài viết mới
  - `BottomNavigationBar`: 5 tabs navigation

#### **👤 2. UserProfileScreen** (Profile Management)
- **Layout**: Scrollable profile với editable elements
- **Components**:
  - `ProfileHeaderWidget`: Avatar + Cover photo (both editable)
  - `StatisticsCardsWidget`: Match stats, ELO rating
  - `AchievementsSection`: User achievements
  - `SocialFeaturesWidget`: Friends, QR code
  - `SettingsMenuWidget`: App settings

#### **🔄 3. Other Main Screens**
- **FindOpponentsScreen**: Player discovery với map/list view
- **TournamentListScreen**: Tournament cards với registration
- **ClubProfileScreen**: Club management interface

## 🎨 UI/UX Design Patterns

### **Color Scheme**
- **Primary**: Green theme cho billiards branding
- **Accent**: White backgrounds với subtle shadows
- **Text**: Dark on light, proper contrast ratios

### **Navigation Patterns**
```
Bottom Navigation (5 tabs):
├── 🏠 Trang chủ (HomeFeedScreen)
├── 👥 Đối thủ (FindOpponentsScreen)  
├── 🏆 Giải đấu (TournamentListScreen)
├── 🏢 Câu lạc bộ (ClubProfileScreen)
└── 👤 Cá nhân (UserProfileScreen)
```

### **Content Patterns**
- **Cards**: Rounded corners, elevation shadows
- **Lists**: Infinite scroll với pull-to-refresh
- **Images**: Circular avatars, rectangular covers
- **Buttons**: Material Design 3 style

## 📊 Screen Dimensions & Responsive Design

### **Using Sizer Package**
- **Responsive units**: `w` (width %), `h` (height %), `sp` (text size)
- **Breakpoints**: Mobile-first design
- **Orientation**: Portrait-only (locked in main.dart)

### **Key Measurements**
```dart
// Common spacing patterns found in code:
- Padding: 4.w, 2.h (horizontal/vertical)
- Card margins: 2.w, 1.h  
- Avatar sizes: 6.w, 12.w (small/large)
- Text sizes: 12.sp, 14.sp, 16.sp, 18.sp, 20.sp
```

## 🔧 Technical Implementation

### **State Management**
- **StatefulWidget** với local state management
- **Services**: Singleton pattern cho business logic
- **Models**: Data classes với JSON serialization

### **Key Services**
```dart
AuthService.instance      // Authentication
UserService.instance      // User data
StorageService           // File uploads (Supabase)
PermissionService        // Camera/Photos permissions
```

### **Widget Architecture**
```
Screens/
├── Main Screen (Scaffold)
├── Custom AppBar (PreferredSizeWidget)
├── Content Body (Column/ListView)
├── FloatingActionButton (Optional)
└── BottomNavigationBar (Fixed 5 tabs)
```

## 🎯 Current Issues & Opportunities

### **Issues Identified**
1. **Authentication Flow**: App runs as anonymous → RLS policies block uploads
2. **Image Persistence**: Files upload to Storage but DB updates fail
3. **Permission Caching**: Implemented but needs authentication context

### **Layout Strengths**
✅ **Consistent Navigation**: 5-tab bottom nav across all screens
✅ **Responsive Design**: Sizer package ensures proper scaling  
✅ **Material Design**: Following MD3 guidelines
✅ **Custom Components**: Reusable CustomAppBar, widgets
✅ **Billiards Branding**: Green theme, appropriate iconography

### **Potential Improvements**
🔄 **Deep Linking**: Add route-based navigation
🔄 **State Management**: Consider Provider/Bloc for complex state
🔄 **Offline Support**: Cache critical data locally
🔄 **Accessibility**: Add semantic labels, screen reader support

## 📱 Current User Journey

```
App Launch → Splash → Onboarding → Login → Home Feed
                                          ↓
┌─────────────────────────────────────────┴─────────────────────────────────────────┐
│  Main App (Bottom Navigation)                                                      │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────────────────────┤
│    Home     │  Opponents  │ Tournaments │    Clubs    │        Profile          │
│   Feed      │   Finding   │    List     │   Profile   │      Management         │
│ (Primary)   │             │             │             │   (Image uploads)       │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────────────────┘
```

## 🎨 Visual Hierarchy

### **Content Priority**
1. **Primary**: Home Feed (social content)
2. **Secondary**: Profile Management (user data)  
3. **Tertiary**: Discovery features (opponents, tournaments, clubs)

### **Interaction Patterns**
- **Tap**: Navigation, simple actions
- **Swipe**: Tab switching, refresh
- **Long Press**: Context menus, bulk actions
- **Pinch/Zoom**: Image viewing (planned)

---

**📊 Summary**: Sabo Arena có layout structure vững chắc với Material Design 3, 5-tab navigation, và responsive design. Vấn đề chính hiện tại là authentication flow chứ không phải UI/UX layout.