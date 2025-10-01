# 🏢 CLUB STAFF COMMISSION SYSTEM

Hệ thống quản lý nhân viên và hoa hồng tiên tiến cho SABO Arena - một giải pháp toàn diện để quản lý staff, theo dõi khách hàng, và tự động tính toán hoa hồng.

## 📋 TỔNG QUAN HỆ THỐNG

### 🎯 Mục tiêu chính
- **Quản lý nhân viên**: Thêm, sửa, xóa staff với các quyền hạn linh hoạt
- **Hệ thống giới thiệu**: Staff có mã QR riêng để giới thiệu khách hàng
- **Tính hoa hồng tự động**: Theo dõi chi tiêu khách hàng và tính hoa hồng real-time
- **Analytics & Reports**: Báo cáo hiệu suất làm việc và thu nhập chi tiết
- **Multi-level Management**: Phân quyền từ owner → manager → staff

### 🏗️ Kiến trúc hệ thống

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Club Owner    │────│   Club Manager  │────│   Club Staff    │
│                 │    │                 │    │                 │
│ • Manage all    │    │ • Manage staff  │    │ • Enter scores  │
│ • View reports  │    │ • View reports  │    │ • Refer customers│
│ • Pay commissions│   │ • Assign roles  │    │ • Earn commissions│
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                    ┌─────────────────┐
                    │   Customers     │
                    │                 │
                    │ • Scan QR codes │
                    │ • Make purchases│
                    │ • Generate revenue│
                    └─────────────────┘
```

## 🗄️ CẤU TRÚC DATABASE

### 📊 Tables chính

#### 1. `club_staff` - Quản lý nhân viên
```sql
- id: UUID (Primary Key)
- club_id: UUID (FK to clubs)
- user_id: UUID (FK to users)
- staff_role: VARCHAR (owner, manager, staff, cashier)
- commission_rate: DECIMAL (Tỷ lệ hoa hồng %)
- can_enter_scores: BOOLEAN
- can_manage_tournaments: BOOLEAN
- can_view_reports: BOOLEAN
- can_manage_staff: BOOLEAN
- hired_at, terminated_at, is_active
```

#### 2. `staff_referrals` - Theo dõi khách hàng được giới thiệu
```sql
- id: UUID (Primary Key)
- staff_id: UUID (FK to club_staff)
- customer_id: UUID (FK to users)
- club_id: UUID (FK to clubs)
- referral_code: VARCHAR (Mã giới thiệu)
- initial_bonus_spa: INTEGER
- total_customer_spending: DECIMAL
- total_commission_earned: DECIMAL
```

#### 3. `customer_transactions` - Giao dịch của khách hàng
```sql
- id: UUID (Primary Key)
- customer_id: UUID (FK to users)
- club_id: UUID (FK to clubs)
- staff_referral_id: UUID (FK to staff_referrals)
- transaction_type: VARCHAR (tournament_fee, spa_purchase, etc.)
- amount: DECIMAL
- commission_eligible: BOOLEAN
- commission_amount: DECIMAL
```

#### 4. `staff_commissions` - Hoa hồng của staff
```sql
- id: UUID (Primary Key)
- staff_id: UUID (FK to club_staff)
- customer_transaction_id: UUID (FK to customer_transactions)
- commission_amount: DECIMAL
- is_paid: BOOLEAN
- paid_at: TIMESTAMP
- payment_method: VARCHAR
```

#### 5. `staff_performance` - Hiệu suất làm việc
```sql
- id: UUID (Primary Key)
- staff_id: UUID (FK to club_staff)
- period_start, period_end: DATE
- total_referrals: INTEGER
- total_revenue_generated: DECIMAL
- total_commissions_earned: DECIMAL
- performance_score: DECIMAL
```

### ⚡ Triggers & Functions tự động

#### 1. `calculate_staff_commission()`
- Tự động tính hoa hồng khi có giao dịch mới
- Kiểm tra điều kiện commission_eligible
- Áp dụng tỷ lệ hoa hồng theo staff

#### 2. `update_staff_referral_totals()`
- Cập nhật tổng chi tiêu khách hàng
- Cập nhật tổng hoa hồng kiếm được
- Chạy real-time khi có transaction

#### 3. Row Level Security (RLS)
- Staff chỉ xem được data của mình
- Owner/Manager xem được tất cả
- Customer chỉ xem được transaction của mình

## 🚀 CÁC TÍNH NĂNG CHÍNH

### 👥 Staff Management
- ✅ **Thêm nhân viên**: Assign user làm staff với role và commission rate
- ✅ **Phân quyền linh hoạt**: 4 levels (owner → manager → staff → cashier)
- ✅ **Quản lý permissions**: Nhập điểm, quản lý giải đấu, xem báo cáo
- ✅ **Activate/Deactivate**: Tạm dừng hoặc kết thúc staff

### 🎯 Referral System
- ✅ **Staff QR Codes**: Mỗi staff có mã QR riêng với commission rate cao hơn
- ✅ **Auto Apply**: Tích hợp với hệ thống QR hiện có
- ✅ **Bonus Rewards**: Staff và khách đều nhận SPA bonus
- ✅ **Tracking**: Theo dõi khách hàng được giới thiệu lifetime

### 💰 Commission System
- ✅ **Auto Calculate**: Tự động tính hoa hồng theo % từng staff
- ✅ **Multiple Types**: Tournament fee, SPA purchase, equipment rental, membership
- ✅ **Real-time Tracking**: Cập nhật ngay khi có giao dịch
- ✅ **Payment Management**: Đánh dấu đã thanh toán, lịch sử payments

### 📊 Analytics & Reports
- ✅ **Staff Performance**: Doanh thu, khách hàng, giao dịch, hiệu suất
- ✅ **Club Overview**: Tổng quan hoa hồng, top performers
- ✅ **Commission Reports**: Xuất báo cáo theo kỳ, theo staff
- ✅ **Customer Analysis**: Top customers, spending patterns

## 💻 DART SERVICES

### 🔧 ClubStaffService
```dart
// Quản lý nhân viên
ClubStaffService.assignUserAsStaff()     // Thêm staff
ClubStaffService.removeStaff()           // Xóa staff  
ClubStaffService.getClubStaff()          // Lấy danh sách staff
ClubStaffService.getUserStaffInfo()      // Check user là staff

// Referral system
ClubStaffService.applyStaffReferral()    // Áp dụng mã giới thiệu
ClubStaffService.recordCustomerTransaction() // Ghi nhận giao dịch
ClubStaffService.getStaffEarnings()      // Thu nhập staff
```

### 💳 CommissionService
```dart
// Commission calculation
CommissionService.calculateCommission()  // Tính hoa hồng
CommissionService.getPendingCommissions() // HH chờ thanh toán
CommissionService.markCommissionsAsPaid() // Đánh dấu đã trả

// Analytics
CommissionService.getStaffCommissionAnalytics() // Phân tích staff
CommissionService.getClubCommissionAnalytics()  // Phân tích club
CommissionService.generateCommissionReport()    // Tạo báo cáo
```

## 🎨 UI COMPONENTS

### 📱 StaffDashboard
- **Earnings Overview**: Tổng hoa hồng, tháng này, khách hàng active
- **Quick Actions**: Tạo QR, xem báo cáo, quản lý khách hàng
- **Recent Commissions**: Lịch sử hoa hồng gần đây
- **Performance Metrics**: Charts và số liệu hiệu suất

### 🏢 ClubStaffManager  
- **Staff List**: Danh sách nhân viên với roles và permissions
- **Add/Edit Staff**: Dialog thêm/sửa thông tin staff
- **Analytics Tab**: Phân tích hiệu suất club và staff
- **Commission Management**: Quản lý thanh toán hoa hồng

### 🧪 ClubStaffCommissionDemo
- **Full System Test**: Demo đầy đủ các tính năng
- **Real-time Logs**: Hiển thị kết quả test real-time
- **Error Handling**: Xử lý và hiển thị lỗi rõ ràng

## 📋 WORKFLOW HOẠT ĐỘNG

### 1. Setup Staff (Club Owner)
```
1. Club Owner đăng nhập → ClubStaffManager
2. Nhấn "Thêm nhân viên" → Nhập email user
3. Chọn role, commission rate, permissions
4. System tự tạo staff referral code (STAFF-USERNAME)
5. Staff nhận notification và có thể bắt đầu làm việc
```

### 2. Staff Referral Process
```
1. Staff tạo QR code từ StaffDashboard
2. Customer scan QR → Đăng ký với referral code
3. System tự động:
   - Tạo record trong staff_referrals
   - Áp dụng SPA bonus cho cả 2 bên
   - Link customer với staff lifetime
```

### 3. Commission Earning
```
1. Customer chi tiêu tại club (tournament, spa, rental...)
2. Staff/Cashier ghi nhận transaction
3. System triggers tự động:
   - Tính commission theo rate của staff
   - Insert vào staff_commissions table  
   - Update totals trong staff_referrals
   - Real-time update dashboard
```

### 4. Payment Process
```
1. Club Owner vào Commission Management
2. Xem pending commissions → Select staff
3. Đánh dấu "Đã thanh toán" với method & reference
4. Staff nhận notification về payment
5. Update performance metrics
```

## 🔒 BẢO MẬT & QUYỀN HẠNG

### Row Level Security (RLS)
- **Staff**: Chỉ xem được data của chính mình
- **Manager**: Xem được data của staff trong club
- **Owner**: Xem được tất cả data của club  
- **Customer**: Chỉ xem được transaction của mình

### Permission Matrix
| Action | Customer | Staff | Manager | Owner |
|--------|----------|-------|---------|-------|
| View own earnings | ❌ | ✅ | ✅ | ✅ |
| Enter scores | ❌ | ✅* | ✅ | ✅ |
| Manage tournaments | ❌ | ✅* | ✅ | ✅ |
| Add/Remove staff | ❌ | ❌ | ✅* | ✅ |
| View club reports | ❌ | ✅* | ✅ | ✅ |
| Pay commissions | ❌ | ❌ | ✅ | ✅ |

*Tùy thuộc vào permissions được cấp

## 🚀 SETUP & DEPLOYMENT

### 1. Database Setup
```bash
# 1. Apply schema SQL
psql -d your_db -f club_staff_commission_system_complete.sql

# 2. Verify tables created
SELECT table_name FROM information_schema.tables 
WHERE table_name LIKE '%staff%' OR table_name LIKE '%commission%';
```

### 2. Flutter Integration
```dart
// Add services to pubspec.yaml dependencies
import '../services/club_staff_service.dart';
import '../services/commission_service.dart';

// Add UI widgets
import '../widgets/staff_dashboard.dart';
import '../widgets/club_staff_manager.dart';
```

### 3. Test System
```dart
// Run demo to verify functionality
MaterialApp(
  home: ClubStaffCommissionDemo(),
)
```

## 📊 METRICS & KPIs

### Staff Performance KPIs
- **Total Referrals**: Số khách hàng được giới thiệu
- **Active Customers**: Khách hàng còn hoạt động
- **Revenue Generated**: Doanh thu tạo ra từ referrals
- **Commission Earned**: Tổng hoa hồng kiếm được
- **Conversion Rate**: Tỷ lệ referral → active customer

### Club Performance KPIs  
- **Total Commissions Paid**: Tổng hoa hồng đã trả
- **Staff ROI**: Return on Investment từ staff
- **Customer Retention**: Tỷ lệ giữ chân khách hàng  
- **Revenue per Staff**: Doanh thu trung bình mỗi staff
- **Top Performers**: Ranking staff theo hiệu suất

## 🔄 TÍCH HỢP VỚI HỆ THỐNG CŨ

### QR Code Referral System
- ✅ **Backward Compatible**: Hoạt động với BasicReferralService hiện tại
- ✅ **Enhanced QR**: Staff QR codes có commission rate cao hơn
- ✅ **Unified Database**: Sử dụng chung bảng referral_codes

### Tournament System
- ✅ **Score Entry**: Staff có thể nhập điểm trận đấu
- ✅ **Tournament Fees**: Tự động track phí tham gia → commission
- ✅ **Match Tracking**: Link transactions với matches cụ thể

### SPA System  
- ✅ **Purchase Tracking**: Theo dõi mua SPA → commission
- ✅ **Bonus Integration**: Tích hợp với hệ thống bonus hiện tại

## 🐛 TROUBLESHOOTING

### Lỗi thường gặp

#### 1. "Could not find function exec_sql"
```sql
-- Supabase không có exec_sql function
-- Solution: Execute SQL trực tiếp qua Supabase dashboard
```

#### 2. RLS Policy errors
```sql
-- Check user permissions
SELECT auth.uid(); -- Should return user ID
-- Verify policies applied
SELECT * FROM pg_policies WHERE tablename = 'club_staff';
```

#### 3. Commission not calculating
```sql  
-- Check triggers exist
SELECT * FROM pg_trigger WHERE tgname LIKE '%commission%';
-- Verify staff_referral_id in transactions
SELECT staff_referral_id FROM customer_transactions WHERE id = 'transaction-id';
```

#### 4. Flutter service errors
```dart
// Check Supabase connection
final response = await Supabase.instance.client
  .from('club_staff').select().limit(1);
print('Connection: ${response}');
```

## 📚 TÀI LIỆU THAM KHẢO

### SQL Schema Files
- `club_staff_commission_system.sql` - Original schema
- `club_staff_commission_system_complete.sql` - Complete with RLS & triggers

### Dart Service Files  
- `club_staff_service.dart` - Staff management & referrals
- `commission_service.dart` - Commission calculation & analytics

### UI Widget Files
- `staff_dashboard.dart` - Staff earnings dashboard
- `club_staff_manager.dart` - Owner/manager interface  
- `club_staff_commission_demo.dart` - System testing demo

### Python Setup Scripts
- `apply_club_staff_system.py` - Database setup automation

---

## 🎯 KẾT LUẬN

Hệ thống Club Staff Commission đã được thiết kế và triển khai hoàn chỉnh với:

✅ **Database Schema**: 5 tables + indexes + RLS policies + triggers  
✅ **Dart Services**: ClubStaffService + CommissionService  
✅ **UI Components**: StaffDashboard + ClubStaffManager + Demo  
✅ **Business Logic**: Auto commission calculation + analytics  
✅ **Security**: RLS policies + permission matrix  
✅ **Integration**: Tương thích với QR referral system hiện tại

**Hệ thống sẵn sàng production và có thể scale cho nhiều club!** 🚀

---

*Phát triển bởi SABO Arena Development Team - January 2025*