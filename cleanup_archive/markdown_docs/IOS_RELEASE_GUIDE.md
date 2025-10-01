# iOS Release Setup Guide

## Prerequisites
1. **Apple Developer Account** ($99/year)
   - Individual or Organization account
   - Access to Apple Developer Portal
   - Access to App Store Connect

2. **Mac với Xcode** (Required)
   - Xcode 15+ recommended
   - iOS SDK 17+
   - Command Line Tools installed

## Step 1: Apple Developer Account Setup

### 1.1 Create App Identifier
1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (Add new)
4. Select **App IDs** → **App**
5. Fill in details:
   - **Description**: Sabo Arena
   - **Bundle ID**: `com.saboarena.app` (reverse domain notation)
   - **Capabilities**: Select required capabilities:
     - Camera
     - Location Services (Background Modes)
     - Maps
     - Network Extensions

### 1.2 Create iOS Distribution Certificate
1. In Apple Developer Portal → **Certificates**
2. Click **+** (Add new)
3. Select **iOS Distribution (App Store and Ad Hoc)**
4. Generate Certificate Signing Request (CSR):
   - Open **Keychain Access** on Mac
   - **Keychain Access** → **Certificate Assistant** → **Request Certificate from CA**
   - Enter your email and name
   - Select **Saved to disk**
5. Upload CSR and download certificate
6. Double-click to install in Keychain

### 1.3 Create Provisioning Profile
1. In Apple Developer Portal → **Profiles**
2. Click **+** (Add new)
3. Select **App Store** distribution
4. Choose your App ID
5. Select your Distribution Certificate
6. Download and double-click to install

## Step 2: Xcode Configuration

### 2.1 Open iOS project in Xcode
```bash
open ios/Runner.xcworkspace
```

### 2.2 Configure Bundle Identifier
1. Select **Runner** project in navigator
2. Select **Runner** target
3. In **General** tab:
   - **Bundle Identifier**: `com.saboarena.app`
   - **Version**: `1.0.0`
   - **Build**: `1`

### 2.3 Configure Signing & Capabilities
1. In **Signing & Capabilities** tab:
   - **Team**: Select your Apple Developer Team
   - **Provisioning Profile**: Select your App Store profile
   - **Signing Certificate**: iOS Distribution
2. Add required capabilities:
   - Camera
   - Location (When In Use)
   - Maps

### 2.4 Update Info.plist
Add usage descriptions:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your position on the map</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to show your position on the map</string>
```

## Step 3: Build iOS App

### 3.1 Build Release IPA
```bash
# Clean build
flutter clean
flutter pub get

# Build iOS archive
flutter build ipa --release --dart-define=SUPABASE_URL=https://mogjjvscxjwvhtpkrlqr.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ
```

The IPA file will be created at: `build/ios/ipa/sabo_arena.ipa`

## Step 4: App Store Connect Setup

### 4.1 Create App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in details:
   - **Platform**: iOS
   - **Name**: Sabo Arena
   - **Primary Language**: Vietnamese
   - **Bundle ID**: `com.saboarena.app`
   - **SKU**: `sabo-arena-v1`

### 4.2 App Information
1. **Category**: Games → Sports
2. **Content Rights**: Your content
3. **Age Rating**: Complete questionnaire
4. **App Review Information**:
   - Contact information
   - Demo account (if needed)
   - Notes for reviewer

### 4.3 Upload App Binary
Using Xcode:
1. Open **Xcode** → **Window** → **Organizer**
2. Select your archive
3. Click **Distribute App**
4. Select **App Store Connect**
5. Follow upload wizard

Or using Application Loader:
```bash
# Install Transporter from Mac App Store
# Drag and drop IPA file to upload
```

### 4.4 Complete App Store Listing
1. **App Store** tab:
   - App Name: "Sabo Arena"
   - Subtitle: "Sport Arena Management"
   - Promotional Text
   - Description (use prepared content from store_assets/)
   - Keywords
   - Support URL
   - Marketing URL
   - Privacy Policy URL

2. **Screenshots** (Required):
   - 6.7" iPhone: 1290×2796 (3 required)
   - 6.5" iPhone: 1284×2778 (3 required)
   - 5.5" iPhone: 1242×2208 (3 required)
   - iPad Pro (6th Gen): 2048×2732 (3 required)
   - iPad Pro (2nd Gen): 2048×2732 (3 required)

3. **App Preview** (Optional):
   - Video previews for each device size

## Step 5: Submit for Review

### 5.1 Final Checklist
- [ ] App binary uploaded and processed
- [ ] App Store listing complete
- [ ] Screenshots uploaded for all required sizes
- [ ] App Review Information complete
- [ ] Pricing and Availability set
- [ ] Export Compliance questionnaire complete

### 5.2 Submit
1. In App Store Connect → **Version** tab
2. Click **Submit for Review**
3. Review process typically takes 1-7 days

## Troubleshooting

### Common Issues:
1. **Provisioning Profile errors**: Regenerate profiles
2. **Certificate expired**: Renew certificates
3. **Build errors**: Check Xcode version and iOS deployment target
4. **App Store rejection**: Follow App Store Review Guidelines

### Useful Commands:
```bash
# Check iOS setup
flutter doctor

# List iOS devices
flutter devices

# Build for iOS simulator
flutter build ios --simulator

# Build for iOS device
flutter build ios --release
```

## Next Steps After Approval
1. App will be available on App Store
2. Monitor crash reports in App Store Connect
3. Prepare app updates following same process
4. Consider implementing App Store optimization (ASO)

## Resources
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)