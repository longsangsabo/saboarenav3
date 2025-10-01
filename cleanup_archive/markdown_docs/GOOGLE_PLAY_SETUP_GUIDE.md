# Google Play Console Setup Guide

## Prerequisites
1. **Google Play Developer Account** ($25 one-time fee)
2. **AAB file** (Already created: `build/app/outputs/bundle/release/app-release.aab`)
3. **Store assets** (Already prepared in `store_assets/` folder)

## Step 1: Create Google Play Developer Account

### 1.1 Sign up for Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google account
3. Pay the $25 registration fee
4. Complete developer profile:
   - Developer name: "Sabo Arena Team" (or your preferred name)
   - Website: Your app website (optional)
   - Contact details

### 1.2 Accept Play Console Developer Program Policies
- Read and accept all policies and agreements
- This may take 1-2 days for account verification

## Step 2: Create New App

### 2.1 Create App in Play Console
1. Click **Create app**
2. Fill in app details:
   - **App name**: "Sabo Arena"
   - **Default language**: Vietnamese (Tiếng Việt)
   - **App or game**: Game
   - **Free or paid**: Free
3. Accept declarations:
   - [ ] Not primarily for children under 13
   - [ ] Follow Google Play Developer Policy
   - [ ] Follow US export laws

### 2.2 Set up your app
The dashboard will show tasks to complete:

## Step 3: App Content and Compliance

### 3.1 Privacy Policy
1. **App content** → **Privacy Policy**
2. Add your privacy policy URL: `https://your-website.com/privacy-policy`
3. Or use the template created in `store_assets/privacy_policy.html`

### 3.2 App Access
1. **App content** → **App access**
2. Select: **All functionality is available without special access**
3. If you have restricted features, provide test credentials

### 3.3 Ads
1. **App content** → **Ads**
2. Select: **No, my app does not contain ads** (if applicable)
3. Or: **Yes, my app contains ads** and provide ad network info

### 3.4 Content Rating
1. **App content** → **Content rating**
2. Complete the content rating questionnaire:
   - **Category**: Game
   - Answer questions about content (violence, mature themes, etc.)
3. This generates IARC ratings for different regions

### 3.5 Target Audience
1. **App content** → **Target audience and content**
2. Select age groups your app targets:
   - **Primary**: Ages 13+ (if sports app)
   - **Secondary**: Ages 18+ (if contains user-generated content)

### 3.6 Data Safety
1. **App content** → **Data safety**
2. Complete data collection and security practices:
   - **Location data**: Approximate/Precise location (for maps)
   - **Personal info**: Name, email (for user accounts)
   - **Device ID**: For analytics
   - **App activity**: In-app actions (for features)
3. Explain how data is used:
   - App functionality
   - Analytics
   - Account management

### 3.7 Government Apps
1. **App content** → **Government apps**
2. Select: **This app is not a government app**

## Step 4: Store Listing

### 4.1 Main Store Listing
1. **Store presence** → **Main store listing**
2. Fill in details:
   - **App name**: "Sabo Arena"
   - **Short description**: Use content from `store_assets/short_description.txt`
   - **Full description**: Use content from `store_assets/full_description.txt`

### 4.2 Graphics
Upload the following (use AI tools or design software):

**App Icon** (Already generated):
- 512 x 512 px (use `assets/images/app_icon.png` - resize to 512x512)

**Feature Graphic** (Required):
- 1024 x 500 px
- Create a banner showcasing your app

**Phone Screenshots** (Required - at least 2):
- 16:9 ratio (1920 x 1080 px recommended)
- Portrait or landscape
- Take screenshots from your app

**7-inch Tablet Screenshots** (Optional):
- 16:10 ratio
- Portrait or landscape

**10-inch Tablet Screenshots** (Optional):
- 16:10 ratio
- Portrait or landscape

### 4.3 Categorization
- **Category**: Sports
- **Tags**: arena, sports, management, booking (choose relevant tags)

### 4.4 Contact Details
- **Website**: Your app website
- **Email**: Support email
- **Phone**: Support phone (optional)

### 4.5 External Marketing
- **Privacy Policy**: Required URL
- **Marketing opt-out**: Let users opt out of marketing emails

## Step 5: Upload App Bundle

### 5.1 Create Release
1. **Release** → **Production**
2. Click **Create new release**

### 5.2 Upload AAB
1. Click **Upload** and select: `build/app/outputs/bundle/release/app-release.aab`
2. The system will analyze your bundle and show:
   - Supported devices
   - APK sizes
   - Permissions

### 5.3 Release Details
- **Release name**: "1.0.0 - Initial Release"
- **Release notes**: Describe what's new
  ```
  🎉 Welcome to Sabo Arena!
  
  ⚽ Book sports venues easily
  🗺️ Find arenas near you
  📱 QR code check-ins
  🏆 Tournament management
  👥 Social features and challenges
  
  This is our initial release. Thank you for using Sabo Arena!
  ```

## Step 6: Review and Publish

### 6.1 Pre-launch Report
- Google Play will run automated tests
- Review the report for any issues
- Fix critical issues if found

### 6.2 Content Policy Review
- Google will review your app for policy compliance
- This usually takes 1-3 days
- You'll receive email notifications about status

### 6.3 Release App
1. **Publishing overview** page
2. Review all sections have green checkmarks
3. Click **Send X changes for review**
4. Choose rollout percentage:
   - Start with 5-10% for initial release
   - Gradually increase to 100%

## Step 7: Post-Release Management

### 7.1 Monitor Release
- **Release** → **Production** → **Manage releases**
- Watch for crashes, ANRs (App Not Responding)
- Monitor user reviews and ratings

### 7.2 Update Release Information
- Add more languages if needed
- Update screenshots with better ones
- A/B test store listing elements

### 7.3 Analytics and Reporting
- **Statistics** → Track installs, crashes, ratings
- **Financial reports** → Revenue (if paid app)
- **User feedback** → Reviews and crash reports

## Step 8: App Updates

### 8.1 For Future Updates
1. Update version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # version+build
   ```
2. Build new AAB:
   ```bash
   flutter build appbundle --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
   ```
3. Upload to **Production** → **Create new release**
4. Add release notes describing changes

### 8.2 Staged Rollouts
- Start with small percentage (5-20%)
- Monitor for issues
- Gradually increase to 100%
- Can halt rollout if issues found

## Quick Checklist

Before submitting:
- [ ] App content sections all complete (green checkmarks)
- [ ] Store listing filled with descriptions and graphics
- [ ] AAB uploaded and analyzed successfully
- [ ] Privacy policy URL added
- [ ] Content rating completed
- [ ] Data safety form completed
- [ ] Release notes written
- [ ] App tested on multiple devices

## Expected Timeline
- **Account setup**: 1-2 days (verification)
- **App setup**: 2-4 hours (filling forms)
- **Review process**: 1-3 days
- **Total time to publish**: 3-7 days

## Useful Resources
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Play Developer Policy](https://support.google.com/googleplay/android-developer/topic/9858052)
- [App Bundle Documentation](https://developer.android.com/guide/app-bundle)

## Troubleshooting Common Issues

### Upload Issues:
- **Large bundle size**: Check if assets are optimized
- **Missing permissions**: Add required permissions in AndroidManifest.xml
- **Signing issues**: Verify keystore configuration

### Policy Violations:
- **Privacy policy missing**: Add valid URL
- **Content rating incorrect**: Re-complete questionnaire
- **Data safety incomplete**: Provide all required information

### Review Delays:
- **Complex apps**: May take longer to review
- **Policy concerns**: Address any flagged issues
- **Holiday periods**: Reviews may be slower