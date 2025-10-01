# SPA Club Management System

## Tổng quan
Hệ thống quản lý SPA (Spa Point Awards) thay thế hoàn toàn cơ chế "cược" bằng hệ thống điểm thưởng tích cực. Users nhận SPA từ thách đấu, clubs tạo phần thưởng, admin phân bổ ngân sách.

## Kiến trúc hệ thống

### Database Schema (`supabase/migrations/20250926000000_create_spa_club_system.sql`)
- **club_spa_balances**: Ngân sách SPA của mỗi club
- **spa_rewards**: Danh sách phần thưởng mà clubs tạo ra
- **user_spa_balances**: Số dư SPA của từng user  
- **spa_transactions**: Lịch sử giao dịch SPA
- **Functions**: `award_spa_bonus()`, `add_spa_to_club()`

### Services (`lib/services/club_spa_service.dart`)
Core service cung cấp tất cả logic SPA:

#### User Methods
- `getUserSpaBalance()`: Lấy số dư SPA của user
- `getAvailableRewards()`: Danh sách phần thưởng có thể đổi  
- `redeemReward()`: Đổi phần thưởng bằng SPA
- `getUserSpaTransactions()`: Lịch sử giao dịch SPA

#### Club Owner Methods  
- `getClubSpaBalance()`: Ngân sách SPA của club
- `getClubRewards()`: Phần thưởng mà club đã tạo
- `createReward()`: Tạo phần thưởng mới
- `getClubSpaTransactions()`: Giao dịch SPA của club

#### Admin Methods
- `getAllClubsWithSpaBalance()`: Tất cả clubs và ngân sách
- `getAllSpaTransactions()`: Toàn bộ giao dịch hệ thống
- `getSystemSpaStats()`: Thống kê tổng quan
- `allocateSpaToClub()`: Cấp ngân sách SPA cho club

### User Interface

#### 1. User SPA Rewards (`lib/presentation/spa_management/spa_reward_screen.dart`)
- **Tab 1: Số dư**: Hiển thị số dư SPA hiện tại
- **Tab 2: Phần thưởng**: Browse và đổi rewards
- **Tab 3: Lịch sử**: Xem giao dịch SPA

#### 2. Club Management (`lib/presentation/spa_management/club_spa_management_screen.dart`)  
- **Tab 1: Tổng quan**: Ngân sách và hoạt động
- **Tab 2: Phần thưởng**: Quản lý rewards  
- **Tab 3: Thống kê**: Analytics và insights

#### 3. Admin Management (`lib/presentation/spa_management/admin_spa_management_screen.dart`)
- **Tab 1: Câu lạc bộ**: Cấp ngân sách cho clubs
- **Tab 2: Thống kê**: Overview toàn hệ thống
- **Tab 3: Lịch sử**: Tất cả giao dịch

### Navigation Helper (`lib/utils/spa_navigation_helper.dart`)
Utilities để tích hợp SPA vào app:
- `navigateToUserSpaRewards()`: Mở màn hình SPA user
- `navigateToClubSpaManagement()`: Mở quản lý SPA club  
- `navigateToAdminSpaManagement()`: Mở quản lý admin
- `showSpaBalanceBottomSheet()`: Hiển thị số dư SPA
- `showSpaBonusEarnedSnackBar()`: Thông báo nhận SPA
- `buildSpaBalanceChip()`: Widget hiển thị số dư
- `buildFloatingSpaButton()`: Floating button SPA

## Quy trình hoạt động

### 1. Admin cấp ngân sách
```dart
await spaService.allocateSpaToClub(
  clubId: 'club123',
  spaAmount: 10000,
  description: 'Ngân sách tháng 9',
);
```

### 2. Club tạo phần thưởng
```dart  
await spaService.createReward(
  clubId: 'club123',
  rewardName: 'Áo thun câu lạc bộ',
  spaCost: 500,
  rewardValue: 'Áo thun cotton size M',
  quantityAvailable: 20,
);
```

### 3. User nhận SPA từ thách đấu
```dart
await spaService.awardSpaBonus(
  userId: 'user456', 
  clubId: 'club123',
  spaAmount: 100,
  activityType: 'challenge_win',
  description: 'Thắng thách đấu vs Player X',
);
```

### 4. User đổi thưởng
```dart
await spaService.redeemReward(
  userId: 'user456',
  rewardId: 'reward789',
);
```

## Tích hợp vào Challenge System

### Cập nhật logic thách đấu
Thay thế tất cả `spaBet` bằng `spaBonus`:

```dart
// Cũ (cược)
final spaBet = _calculateSpaBet(playerLevel);

// Mới (thưởng)  
final spaBonus = _calculateSpaBonus(playerLevel);
```

### Award SPA khi hoàn thành match
```dart
if (matchResult == 'win') {
  await spaService.awardSpaBonus(
    userId: currentUser.id,
    clubId: selectedClub.id, 
    spaAmount: spaBonus,
    activityType: 'challenge_win',
  );
  
  // Hiển thị thông báo
  SpaNavigationHelper.showSpaBonusEarnedSnackBar(
    context,
    spaAmount: spaBonus,
    activity: 'thách đấu',
    clubId: selectedClub.id,
    clubName: selectedClub.name,
  );
}
```

## UI Integration Examples

### Hiển thị số dư SPA trong profile
```dart
SpaNavigationHelper.buildSpaBalanceChip(
  balance: userSpaBalance,
  onTap: () => SpaNavigationHelper.navigateToUserSpaRewards(
    context,
    clubId: currentClub.id,
    clubName: currentClub.name,
  ),
)
```

### Floating SPA button  
```dart
SpaNavigationHelper.buildFloatingSpaButton(
  context: context,
  balance: userSpaBalance,
  clubId: currentClub.id,
  clubName: currentClub.name,
)
```

### Quick SPA balance view
```dart
SpaNavigationHelper.showSpaBalanceBottomSheet(
  context,
  spaBalance: userSpaBalance,
  clubId: currentClub.id, 
  clubName: currentClub.name,
)
```

## Security & Permissions

### Row Level Security (RLS)
- Users: Chỉ xem SPA balance và transactions của mình
- Club owners: Quản lý SPA của club mình  
- Admins: Full access toàn hệ thống

### Database Functions
- `award_spa_bonus()`: Tự động cập nhật balances và tạo transactions
- `add_spa_to_club()`: Admin-only function để cấp ngân sách

## Testing

### Test user SPA flow
1. Tạo thách đấu và thắng → Nhận SPA
2. Browse danh sách phần thưởng 
3. Đổi thưởng bằng SPA
4. Xem lịch sử giao dịch

### Test club management
1. Login as club owner
2. Tạo phần thưởng mới
3. Xem thống kê redemptions
4. Quản lý inventory

### Test admin features  
1. Login as admin
2. Cấp ngân sách cho clubs
3. Xem system-wide analytics
4. Monitor all transactions

## Deployment Notes

1. **Chạy migration**: Apply `20250926000000_create_spa_club_system.sql`
2. **Cập nhật permissions**: Verify RLS policies 
3. **Test functions**: Ensure `award_spa_bonus()` và `add_spa_to_club()` work
4. **UI integration**: Add SPA components vào existing screens
5. **Replace terminology**: Transform all "cược" → "bonus" references

Hệ thống SPA đã hoàn toàn thay thế cơ chế cược bằng positive reward system, tạo ra trải nghiệm gaming tích cực và thu hút users tham gia nhiều hơn!