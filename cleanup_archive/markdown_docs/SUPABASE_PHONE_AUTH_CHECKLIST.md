# 📱 SUPABASE PHONE AUTH CONFIGURATION CHECKLIST

## ✅ KIỂM TRA TRÊN SUPABASE DASHBOARD

### 1. 🔐 Authentication Settings
Truy cập: **Supabase Dashboard > Authentication > Settings**

- [ ] **Enable Phone Authentication**
  - Bật "Enable phone confirmations" 
  - Bật "Enable phone sign-ups"
  
- [ ] **Configure Phone Providers**
  - Chọn SMS provider: Twilio (recommended) hoặc MessageBird
  - Nhập credentials của SMS provider

### 2. 📞 SMS Provider Setup (Twilio Recommended)

#### A. Tạo Twilio Account
- [ ] Đăng ký tài khoản tại: https://www.twilio.com
- [ ] Verify phone number của bạn
- [ ] Mua Twilio phone number cho SMS

#### B. Configure trong Supabase
- [ ] Twilio Account SID
- [ ] Twilio Auth Token  
- [ ] Twilio Phone Number (From number)

### 3. 🌍 Phone Number Configuration

- [ ] **Country Code Settings**
  - Default country: Vietnam (+84)
  - Allowed countries: Thêm các quốc gia cần thiết

- [ ] **Phone Number Format**
  - Validation rules cho Việt Nam: `^(\+84|84|0)[0-9]{9,10}$`
  - Test với: 0901234567, +84901234567, 84901234567

### 4. 🔧 OTP Settings

- [ ] **OTP Configuration**
  - OTP length: 6 digits (recommended)
  - OTP expiry: 5-10 minutes
  - Rate limiting: 1 OTP per minute per phone

- [ ] **SMS Template**
```
Your verification code is: {{.Code}}
This code expires in 10 minutes.
```

### 5. 🛡️ Security Settings

- [ ] **Rate Limiting**
  - Max OTP requests per hour: 5-10
  - Max login attempts: 5 per 15 minutes
  
- [ ] **Captcha (Optional)**
  - Enable reCAPTCHA cho registration form

### 6. 🧪 Testing Checklist

#### A. Registration Flow Test
- [ ] Nhập số điện thoại Việt Nam (0901234567)
- [ ] Nhận được SMS OTP
- [ ] Verify OTP thành công
- [ ] User account được tạo trong Auth table
- [ ] Profile data được lưu vào user_profiles table

#### B. Login Flow Test  
- [ ] Đăng nhập bằng phone + password
- [ ] Redirect đúng route (user/admin dashboard)
- [ ] Session được maintain

#### C. Error Scenarios
- [ ] OTP sai → Error message hiển thị
- [ ] OTP hết hạn → Cho phép resend
- [ ] Phone number đã tồn tại → Error appropriate  
- [ ] SMS delivery failed → Retry mechanism

### 7. 📊 Monitoring & Analytics

- [ ] **Supabase Auth Logs**
  - Monitor auth events trong Dashboard
  - Track success/failure rates
  
- [ ] **SMS Delivery Monitoring**
  - Check Twilio console để xem delivery status
  - Monitor SMS costs

### 8. 🚀 Production Deployment

- [ ] **Environment Variables**
```bash
SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co
SUPABASE_ANON_KEY=your_anon_key
```

- [ ] **Flutter App Build**
```bash
flutter run --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co \
           --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

### 9. 💰 Cost Optimization

- [ ] **SMS Cost Management**
  - Monitor Twilio usage dashboard
  - Set up billing alerts
  - Implement OTP retry limits
  
- [ ] **Supabase Usage**
  - Monitor auth MAU (Monthly Active Users)
  - Check database read/write operations

## 🔍 DEBUG COMMANDS

```bash
# Test phone number normalization
echo "0901234567" → "+84901234567"
echo "+84901234567" → "+84901234567"

# Check Supabase connection
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Monitor auth events
# Check Supabase Dashboard > Authentication > Users
```

## ⚠️ COMMON ISSUES

1. **SMS không gửi được**
   - Check Twilio credentials
   - Verify Twilio phone number status
   - Check rate limits

2. **OTP verification fails**  
   - Check OTP expiry time
   - Verify phone number format consistency
   - Check network connectivity

3. **User creation fails**
   - Check RLS policies cho user_profiles table
   - Verify database permissions
   - Check unique constraints

## 📞 SUPPORT CONTACTS

- Supabase Support: support@supabase.io
- Twilio Support: help.twilio.com  
- Flutter Integration: pub.dev/packages/supabase_flutter