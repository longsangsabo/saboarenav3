# Sabo Arena - Hướng dẫn Setup Supabase Backend

## 📋 Tổng quan

**Sabo Arena** là ứng dụng mạng xã hội cho cộng đồng billiards với backend Supabase đã được thiết kế hoàn chỉnh bao gồm:

### ✅ Đã triển khai:
- 🎯 **Database Schema**: Hoàn chỉnh với 10+ tables, relationships, indexes
- 🔐 **Authentication**: Email/password với Row Level Security (RLS)
- 📱 **Data Models**: User, Tournament, Club, Match, Post models với JSON serialization
- 🛠️ **Service Layer**: SupabaseService với auth, CRUD, real-time, storage
- 📊 **Repository Pattern**: UserRepository cho data operations
- 🎨 **UI Screens**: 6 screens đã có giao diện hoàn chỉnh

### 🚀 Cần setup:
1. Tạo Supabase project
2. Chạy SQL schema
3. Cập nhật credentials
4. Test kết nối

---

## 🏗️ Bước 1: Setup Supabase Project

### 1.1 Tạo Project mới
```bash
1. Truy cập https://supabase.com
2. Đăng ký/Đăng nhập tài khoản
3. Click "New Project" 
4. Chọn Organization
5. Điền thông tin:
   - Name: sabo-arena
   - Database Password: [password mạnh]
   - Region: Southeast Asia (Singapore)
6. Click "Create new project"
7. Đợi 2-3 phút để setup hoàn tất
```

### 1.2 Lấy Project Credentials
```bash
1. Vào project dashboard
2. Click Settings (⚙️) → API
3. Copy 2 thông tin quan trọng:
   - Project URL
   - anon/public key
```

---

## 🗄️ Bước 2: Tạo Database Schema

### 2.1 Chạy SQL Schema
```sql
1. Vào project dashboard
2. Click "SQL Editor" (bên trái)
3. Click "New query"
4. Copy toàn bộ nội dung file `supabase_schema.sql` 
5. Paste vào editor và click "Run"
6. Đợi script chạy hoàn tất (~ 30 giây)
```

### 2.2 Verify Database
Sau khi chạy schema thành công, bạn sẽ có:
```
✅ 15 tables: users, clubs, tournaments, matches, posts, etc.
✅ Indexes cho performance  
✅ RLS policies cho security
✅ Triggers cho updated_at
✅ Helper functions (get_nearby_players, etc.)
✅ Sample achievements data
```

---

## 🔧 Bước 3: Cấu hình App

### 3.1 Cập nhật Supabase Credentials
```dart
// File: lib/core/supabase_config.dart
class SupabaseConfig {
  static const String url = 'https://your-project-id.supabase.co'; // ← Thay đổi
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // ← Thay đổi
  
  // Giữ nguyên phần còn lại...
}
```

### 3.2 Test Connection
```bash
flutter run
# Check console output cho "Supabase initialized successfully"
```

---

## 🧪 Bước 4: Test Features

### 4.1 Test Authentication (Trong app)
```dart
// Có thể test qua debug console
final authResponse = await SupabaseService.instance.signUpWithEmail(
  email: 'test@example.com',
  password: 'password123',
);
```

### 4.2 Test Database Operations
```dart
// Có thể test qua UserRepository
final userRepo = UserRepository();
final currentUser = await userRepo.getCurrentUser();
```

---

## 📊 Database Schema Overview

### Core Tables:
```sql
users           -- Player profiles, stats, rankings
clubs           -- Billiards club information  
tournaments     -- Tournament management
matches         -- Individual games/matches
posts           -- Social feed posts
comments        -- Post interactions
friendships     -- Social connections
notifications   -- Real-time alerts
```

### Key Features:
- **Authentication**: Built-in Supabase auth với RLS
- **Real-time**: Live tournament updates, chat
- **Geolocation**: Find nearby players
- **File Storage**: Avatar, tournament images
- **Performance**: Optimized indexes và queries

---

## 🎯 Next Steps - Kế hoạch phát triển

### Phase 1: Core Integration ✅
- [x] Setup Supabase project  
- [x] Create database schema
- [x] Implement service layer
- [x] Create data models

### Phase 2: Screen Integration 🔄
- [ ] Replace mock data với real API calls
- [ ] Implement authentication screens
- [ ] Connect user profile với Supabase
- [ ] Connect tournament list với database

### Phase 3: Advanced Features 📋
- [ ] Real-time tournament updates
- [ ] File upload cho avatars
- [ ] Push notifications
- [ ] Offline sync
- [ ] Admin dashboard

---

## 🚨 Production Checklist

### Security:
- [ ] Enable RLS trên tất cả tables
- [ ] Review và test RLS policies
- [ ] Setup proper CORS settings
- [ ] Enable 2FA cho Supabase account

### Performance:
- [ ] Add additional indexes if needed
- [ ] Setup CDN cho images
- [ ] Monitor database performance
- [ ] Optimize queries

### Backup:
- [ ] Enable automatic backups
- [ ] Test restore process
- [ ] Setup monitoring alerts

---

## 📚 Useful Resources

- **Supabase Docs**: https://supabase.com/docs
- **Flutter Supabase Package**: https://pub.dev/packages/supabase_flutter
- **RLS Guide**: https://supabase.com/docs/guides/auth/row-level-security
- **Real-time Guide**: https://supabase.com/docs/guides/realtime

---

## 🐛 Troubleshooting

### Common Issues:

**1. "Failed to initialize Supabase"**
```
- Kiểm tra URL và anon key
- Đảm bảo project đã setup xong
- Check network connection
```

**2. "Row Level Security policy violation"**  
```
- Review RLS policies trong SQL Editor
- Đảm bảo user đã authenticate
- Check table permissions
```

**3. "JSON serialization error"**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

---

## 👥 Support

Nếu gặp vấn đề trong quá trình setup:

1. **Check console logs** cho error details
2. **Review Supabase dashboard** logs
3. **Test từng component** riêng biệt
4. **Verify database schema** đã chạy đúng

---

**🎉 Chúc mừng! Bạn đã setup thành công Supabase backend cho Sabo Arena!**

Tiếp theo, chúng ta sẽ integrate các screens với real data và implement các features advanced như real-time updates và file uploads.