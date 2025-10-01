# 🎯 GIẢI PHÁP TÍCH HỢP QR + REFERRAL CODE

## 🚀 **CONCEPT: MỘT QR CODE - HAI TÍNH NĂNG**

```
📱 QR Code của User
├── 👀 Quét QR → Hiển thị Profile
├── 🔗 Link → Profile Page  
└── 🎁 Đăng ký mới → Auto áp dụng Referral Code
```

---

## 🎯 **ARCHITECTURE MỚI**

### URL Structure:
```
https://saboarena.com/user/SABO123456?ref=SABO-LONGSANG
                        ↑                    ↑
                   User Code            Referral Code
```

### QR Data Format:
```json
{
  "user_code": "SABO123456",
  "user_id": "uuid-here", 
  "referral_code": "SABO-LONGSANG",
  "profile_url": "https://saboarena.com/user/SABO123456?ref=SABO-LONGSANG"
}
```

---

## 🔧 **IMPLEMENTATION**

### 1. **Enhanced QR Data Generation**
```dart
class IntegratedQRService {
  static String generateIntegratedQRData({
    required String userId,
    required String userCode,
    required String referralCode,
  }) {
    // Tạo URL có cả profile và referral
    final baseUrl = 'https://saboarena.com';
    return '$baseUrl/user/$userCode?ref=$referralCode';
  }
  
  static Map<String, dynamic> generateQRDataWithReferral(UserProfile user) {
    final userCode = ShareService.generateUserCode(user.id);
    final referralCode = 'SABO-${user.username?.toUpperCase() ?? "USER"}';
    final profileUrl = generateIntegratedQRData(
      userId: user.id,
      userCode: userCode, 
      referralCode: referralCode,
    );
    
    return {
      'user_code': userCode,
      'user_id': user.id,
      'referral_code': referralCode,
      'profile_url': profileUrl,
      'qr_data': profileUrl, // QR chứa URL này
    };
  }
}
```

### 2. **Enhanced QR Scan Service**
```dart
class IntegratedQRScanService {
  static Future<Map<String, dynamic>?> scanIntegratedQR(String qrData) async {
    try {
      print('🔍 Scanning integrated QR: $qrData');
      
      // Parse URL: https://saboarena.com/user/SABO123456?ref=SABO-LONGSANG
      final uri = Uri.parse(qrData);
      
      if (uri.host == 'saboarena.com' && uri.pathSegments.length >= 2) {
        final userCode = uri.pathSegments[1]; // SABO123456
        final referralCode = uri.queryParameters['ref']; // SABO-LONGSANG
        
        // Tìm user theo user_code
        final userProfile = await _findUserByCode(userCode);
        
        if (userProfile != null) {
          return {
            'type': 'integrated_profile',
            'user_profile': userProfile,
            'user_code': userCode,
            'referral_code': referralCode,
            'profile_url': qrData,
            'actions': [
              'view_profile',      // Xem profile
              'open_app',         // Mở app
              'apply_referral'    // Áp dụng referral nếu đăng ký mới
            ]
          };
        }
      }
      
      // Fallback: try old QR formats
      return await QRScanService.scanQRCode(qrData);
      
    } catch (e) {
      print('❌ Error scanning integrated QR: $e');
      return null;
    }
  }
  
  static Future<Map<String, dynamic>?> _findUserByCode(String userCode) async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .eq('user_code', userCode)
          .single();
      
      return response;
    } catch (e) {
      print('❌ User not found by code: $userCode');
      return null;
    }
  }
}
```

### 3. **Registration with Auto Referral**
```dart
class IntegratedRegistrationService {
  static Future<Map<String, dynamic>> registerWithQRReferral({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? scannedQRData, // QR data từ scan trước đó
  }) async {
    try {
      // 1. Đăng ký user account
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      final newUserId = authResponse.user!.id;
      
      // 2. Parse referral từ QR data
      String? referralCodeToApply;
      if (scannedQRData != null) {
        final uri = Uri.parse(scannedQRData);
        referralCodeToApply = uri.queryParameters['ref'];
      }
      
      // 3. Tạo profile với QR system
      await RegistrationQRService.completeRegistrationWithQR(
        userId: newUserId,
        email: email,
        fullName: fullName,
        username: username,
      );
      
      // 4. Tạo referral code cho user mới
      final newUserReferralCode = 'SABO-${username?.toUpperCase() ?? "USER"}';
      await BasicReferralService.createReferralCode(
        userId: newUserId,
        code: newUserReferralCode,
      );
      
      // 5. Áp dụng referral code nếu có
      Map<String, dynamic>? referralResult;
      if (referralCodeToApply != null) {
        referralResult = await BasicReferralService.applyReferralCode(
          code: referralCodeToApply,
          newUserId: newUserId,
        );
      }
      
      return {
        'success': true,
        'user_id': newUserId,
        'my_referral_code': newUserReferralCode,
        'applied_referral': referralResult,
        'message': referralResult?['success'] == true 
            ? 'Đăng ký thành công! Bạn đã nhận ${referralResult!['referred_reward']} SPA từ referral code!'
            : 'Đăng ký thành công!'
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
```

### 4. **Auto Generate User's Integrated QR**
```dart
class UserQRManager {
  static Future<String> generateUserIntegratedQR(String userId) async {
    try {
      // 1. Lấy thông tin user
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) throw Exception('User not found');
      
      // 2. Đảm bảo user có user_code
      String userCode = userProfile['user_code'];
      if (userCode == null) {
        userCode = await UserCodeService.generateUniqueUserCode(userId);
        await _updateUserCode(userId, userCode);
      }
      
      // 3. Đảm bảo user có referral_code
      String referralCode = await _ensureUserHasReferralCode(userId, userProfile);
      
      // 4. Tạo integrated QR data
      final qrData = IntegratedQRService.generateIntegratedQRData(
        userId: userId,
        userCode: userCode,
        referralCode: referralCode,
      );
      
      // 5. Update QR data trong database
      await _updateUserQRData(userId, qrData);
      
      return qrData;
      
    } catch (e) {
      print('❌ Error generating integrated QR: $e');
      rethrow;
    }
  }
  
  static Future<String> _ensureUserHasReferralCode(String userId, Map<String, dynamic> userProfile) async {
    // Kiểm tra xem user đã có referral code chưa
    final existingCode = await BasicReferralService.getUserReferralCode(userId);
    if (existingCode != null) return existingCode;
    
    // Tạo mới nếu chưa có
    final username = userProfile['username'] ?? 'USER';
    final newReferralCode = 'SABO-${username.toString().toUpperCase()}';
    
    await BasicReferralService.createReferralCode(
      userId: userId,
      code: newReferralCode,
    );
    
    return newReferralCode;
  }
}
```

---

## 🎯 **USER EXPERIENCE FLOW**

### Scenario 1: User A chia sẻ QR
```
👤 User A 
├── 📱 Mở app → Profile → QR Code
├── 🔄 QR chứa: https://saboarena.com/user/SABO123456?ref=SABO-USERA
└── 📤 Share QR (image hoặc link)
```

### Scenario 2: User B quét QR (đã có app)
```
👤 User B (có app)
├── 📱 Scan QR → https://saboarena.com/user/SABO123456?ref=SABO-USERA
├── 👀 Hiển thị Profile của User A
├── 🔗 Button "Thách đấu" / "Kết bạn"
└── ✅ Không áp dụng referral (đã có tài khoản)
```

### Scenario 3: User C quét QR (chưa có app)
```
👤 User C (chưa có app)
├── 📱 Scan QR → Redirect đến web/app store
├── 💾 Lưu referral code: SABO-USERA
├── 📥 Download app
├── 📝 Đăng ký tài khoản
├── 🎁 Auto áp dụng SABO-USERA
├── 💰 User A +100 SPA, User C +50 SPA
└── ✅ Cả hai đều có lợi!
```

---

## 🚀 **IMPLEMENT NGAY**

Bạn có muốn tôi:

1. ✅ **Tạo IntegratedQRService** - Tích hợp QR + Referral
2. ✅ **Update QR Scanner** - Detect tích hợp format  
3. ✅ **Auto-generate** - User tự động có integrated QR
4. ✅ **Update Registration** - Auto áp dụng referral từ QR
5. ✅ **Test complete flow** - Từ share QR đến nhận SPA

Như vậy **MỘT QR CODE** sẽ làm được **TẤT CẢ**:
- ✅ Hiển thị profile
- ✅ Link dẫn trang web
- ✅ Auto referral cho user mới

**Perfect solution** cho ý tưởng của bạn! 🎯