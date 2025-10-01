# SABO Arena - Release Build Instructions

## 🔥 **READY TO USE FILES:**

### ✅ **Android Signing Setup:**
- `android/key.properties` - Template keystore config
- `android/app/build.gradle` - Updated with signing config
- `android/app/proguard-rules.pro` - Optimized for release
- `create_keystore.bat` - Script to create keystore
- `build_android_release.bat` - Build AAB for Play Store

### ✅ **iOS Build Setup:**
- `build_ios_release.bat` - Build script for iOS
- Updated .gitignore to protect sensitive files

### ✅ **Store Assets:**  
- `store_assets/app_description.md` - Complete store listing
- `store_assets/privacy_policy.md` - Privacy policy template

---

## 🚀 **NEXT STEPS (BẠN CẦN LÀM):**

### **1. Create Android Keystore:**
```bash
# Run this command:
./create_keystore.bat

# Remember your passwords! You'll need them forever.
```

### **2. Update key.properties:**
```properties
# Edit android/key.properties with your real passwords:
storePassword=YOUR_ACTUAL_PASSWORD
keyPassword=YOUR_ACTUAL_PASSWORD  
keyAlias=upload
storeFile=../upload-keystore.jks
```

### **3. Test Production Build:**
```bash
# Build Android AAB:
./build_android_release.bat

# Build iOS (need Mac + Xcode):
./build_ios_release.bat
```

### **4. Create App Icons:**
- Design 1024x1024 master icon
- Use online tools to generate all sizes
- Replace files in android/app/src/main/res/mipmap-*
- Replace iOS icons in ios/Runner/Assets.xcassets

### **5. Store Setup:**
- Google Play Console: $25 one-time fee
- Apple Developer: $99/year
- Upload your built AAB/IPA files

---

## ⚠️ **IMPORTANT SECURITY:**
- NEVER commit keystore files to git
- Keep backup of keystore + passwords safe
- Test builds on real devices before submitting

## 🎯 **ESTIMATED TIMELINE:**
- Keystore creation: 5 minutes
- Icon design: 2-4 hours  
- Store setup: 1-2 hours
- Review process: 1-7 days

**You're 80% ready for store submission! 🚀**