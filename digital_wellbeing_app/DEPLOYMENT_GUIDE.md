# Deployment Guide - Digital Mindfulness

This guide covers two deployment scenarios:
1. **Testing on Physical Phone** - For development and personal testing
2. **Publishing to Google Play Store** - For public release

---

## Part 1: Deploy to Physical Phone for Testing

### Prerequisites
- Android phone with USB debugging enabled
- USB cable
- Windows computer with Flutter SDK installed
- Android device running Android 5.0+ (API 21+)

---

### Step 1: Enable Developer Options on Your Phone

1. **Open Settings** on your Android phone
2. Go to **About Phone**
3. Find **Build Number** (usually under Software Information)
4. **Tap Build Number 7 times** rapidly
5. You'll see "You are now a developer!" message
6. Go back to Settings → **Developer Options** (now visible)
7. Enable **USB Debugging**
8. Enable **Stay Awake** (optional, keeps screen on while plugged in)

---

### Step 2: Connect Phone to Computer

1. **Connect phone via USB cable** to your computer
2. Phone will show **"Allow USB Debugging"** popup
3. Check **"Always allow from this computer"**
4. Tap **Allow**

---

### Step 3: Verify Device Connection

```powershell
# Open PowerShell in the app directory
cd C:\ProjectsV2\futtler_app\digital_wellbeing_app

# Check if device is detected
flutter devices
```

**Expected Output:**
```
Found 1 connected device:
  SM G996B (mobile) • R5CR1234ABC • android-arm64 • Android 14 (API 34)
```

If you see "No devices found":
- Try different USB cable (must support data, not just charging)
- Re-enable USB debugging
- Install phone's USB drivers (usually auto-installs)
- Try different USB port

---

### Step 4: Build and Install Debug APK

#### Option A: Direct Run (Recommended for Testing)

```powershell
# Navigate to project directory
cd C:\ProjectsV2\futtler_app\digital_wellbeing_app

# Run app in debug mode
flutter run
```

This will:
- Build debug APK
- Install on phone
- Launch automatically
- Show logs in terminal

**To reload changes without restarting:**
- Press `r` in terminal for hot reload
- Press `R` for hot restart
- Press `q` to quit

#### Option B: Build APK File (For Sharing/Manual Install)

```powershell
# Build debug APK
flutter build apk --debug

# APK location:
# build/app/outputs/flutter-apk/app-debug.apk
```

**Install APK manually:**
1. Copy APK to phone (via USB, email, or cloud)
2. Open file manager on phone
3. Tap on APK file
4. Allow "Install from unknown sources" if prompted
5. Tap Install

---

### Step 5: Grant Required Permissions

After installation, the app needs permissions:

1. **Launch the app** on your phone
2. **Notification Permission** (Android 13+)
   - App will request on first launch
   - Tap "Allow"

3. **Accessibility Permission**
   - When you enable enforcement, app will guide you
   - Settings → Accessibility → Digital Mindfulness
   - Toggle ON
   - Confirm

4. **Other Permissions** (granted automatically)
   - RECEIVE_BOOT_COMPLETED
   - FOREGROUND_SERVICE
   - SCHEDULE_EXACT_ALARM

---

### Step 6: Test Core Features

#### Quick Test Checklist:

1. **✅ Basic UI**
   - App opens without crashes
   - Purple theme visible
   - Navigation works

2. **✅ App Selection**
   - "Allowed Apps" screen loads
   - Can select/deselect apps
   - Save works

3. **✅ Time Configuration**
   - Set restriction times
   - Save works
   - Times display correctly

4. **✅ Enforcement**
   - Toggle enforcement ON
   - Grant accessibility permission
   - Notification appears

5. **✅ Blocking** (Set restriction to NOW)
   - Set start time to current time
   - Try opening non-allowed app
   - Blocking screen appears
   - "GO BACK" button works

6. **✅ Persistence**
   - Force-close app
   - Reopen app
   - Settings preserved
   - Enforcement still active

---

### Step 7: Debug Issues

#### View Logs in Real-Time

```powershell
# While app is running
flutter run

# Or use ADB directly
adb logcat | Select-String "flutter"
```

#### Common Issues:

**Issue:** App crashes on launch
- Check terminal for error messages
- Run `flutter doctor` to verify setup
- Try `flutter clean` then rebuild

**Issue:** Blocking doesn't work
- Verify accessibility service enabled
- Check restriction times include current time
- Ensure blocked app NOT in allowed list

**Issue:** Notifications don't appear
- Grant notification permission
- Check phone's Do Not Disturb is off
- Test with "Show Test Notification" in settings

---

### Step 8: Iterate and Test

**Development Cycle:**

1. Make code changes in VS Code
2. Save files
3. In terminal, press `r` (hot reload) or `R` (hot restart)
4. Test changes on phone
5. Repeat

**For major changes (native code, dependencies):**
```powershell
flutter run --device-id <device-id>
```

---

## Part 2: Publish to Google Play Store

### Overview Timeline
- **Setup:** 1-2 hours (one-time)
- **First Review:** 3-7 days
- **Updates:** 1-3 days per release

---

### Prerequisites

1. **Google Account** with payment method
2. **$25 one-time registration fee** for Google Play Console
3. **App ready for production**
   - All features working
   - Tested thoroughly
   - No critical bugs
4. **Required Assets**
   - App icon (512x512 PNG)
   - Feature graphic (1024x500)
   - Screenshots (2-8 images)
   - Privacy policy URL

---

### Phase 1: Prepare App for Release

#### Step 1.1: Create Keystore (App Signing)

**Create signing key:**

```powershell
# Navigate to Android folder
cd C:\ProjectsV2\futtler_app\digital_wellbeing_app\android

# Generate keystore (RUN ONCE ONLY)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Enter password (SAVE THIS SECURELY!)
# Enter your details when prompted
```

**CRITICAL:** Store keystore password securely! If lost, you CANNOT update your app.

#### Step 1.2: Configure Signing

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

**Add to `.gitignore`:**
```
# Add these lines to .gitignore
android/key.properties
android/upload-keystore.jks
```

#### Step 1.3: Update `android/app/build.gradle.kts`

Before `android {` block, add:

```kotlin
// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android {` block, replace `buildTypes {` section:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

#### Step 1.4: Update Version Numbers

Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
# For updates, increment: 1.0.1+2, 1.0.2+3, etc.
```

#### Step 1.5: Review AndroidManifest.xml

Ensure these are set correctly in `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <!-- Check app name -->
    <application
        android:label="Digital Mindfulness"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Ensure no debuggable flags -->
        <!-- android:debuggable should NOT be present in release -->
    </application>
</manifest>
```

#### Step 1.6: Create App Icon

**Generate adaptive icons:**

1. Use Android Studio:
   - Right-click `android/app/src/main/res`
   - New → Image Asset
   - Icon Type: Launcher Icons (Adaptive and Legacy)
   - Path: Select your 512x512 icon
   - Generate

2. Or use online tool: https://romannurik.github.io/AndroidAssetStudio/

---

### Phase 2: Build Release APK/AAB

#### Step 2.1: Build Android App Bundle (Recommended)

```powershell
# Navigate to project root
cd C:\ProjectsV2\futtler_app\digital_wellbeing_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build App Bundle (AAB) - Recommended for Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

**Why AAB?** Google Play generates optimized APKs for each device configuration.

#### Step 2.2: Build APK (Alternative)

```powershell
# Build universal APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

#### Step 2.3: Verify Build

**Check file size:**
- AAB should be ~15-30 MB
- APK should be ~20-40 MB

**Test release build on phone:**

```powershell
# Install release APK
flutter install --release

# Or manually:
# Copy app-release.apk to phone and install
```

**Test thoroughly:** Release builds are optimized and may behave differently than debug builds.

---

### Phase 3: Create Google Play Console Account

#### Step 3.1: Register Developer Account

1. Go to https://play.google.com/console
2. Sign in with Google Account
3. Click **Create Developer Account**
4. **Pay $25 registration fee** (one-time)
5. Fill in developer profile:
   - Developer name (shown to users)
   - Email address
   - Website (optional but recommended)
6. Accept agreements
7. Wait for verification (usually instant, max 48 hours)

#### Step 3.2: Create App Entry

1. In Play Console, click **Create app**
2. Fill in details:
   - **App name:** Digital Mindfulness
   - **Default language:** English (US)
   - **App or game:** App
   - **Free or paid:** Free
3. Declarations:
   - Developer Program Policies: Yes
   - US export laws: Yes
4. Click **Create app**

---

### Phase 4: Complete Store Listing

#### Step 4.1: Main Store Listing

Go to **Store presence → Main store listing**

**App name:**
```
Digital Mindfulness - Focus & Screen Time Control
```

**Short description (80 chars max):**
```
Reduce screen time with mindful app blocking. Focus on what matters.
```

**Full description (4000 chars max):**
```
🧘 Digital Mindfulness - Take Control of Your Screen Time

Digital Mindfulness helps you build healthier phone habits through scheduled app restrictions and mindful awareness.

✨ KEY FEATURES

🔒 Scheduled App Blocking
Set custom time windows (like 9pm-7am) when distracting apps are restricted. Only your essential apps remain accessible during mindful periods.

🧘 Mindful Design
Beautiful purple theme with encouraging messages. No punishment, just gentle reminders to stay focused.

🛡️ Robust Enforcement
• Survives app force-closes
• Persists after device reboots
• Detects bypass attempts
• Accessibility-powered blocking

⚙️ Easy Setup
1. Choose apps to keep accessible (like Phone, Messages)
2. Set your mindful hours
3. Enable enforcement
4. Stay focused!

🔔 Smart Notifications
Non-dismissible during restrictions to keep you accountable. See exactly when your mindful period ends.

🔐 Settings Lock
Can't change settings during restricted hours - helping you stick to your goals.

📊 Transparent Tracking
See force-close attempts and accessibility changes. Full transparency about what's monitored.

💚 Built for You
Created for personal digital wellbeing, not parental control. You're in charge of your own mindfulness journey.

WHY DIGITAL MINDFULNESS?

Modern smartphones are designed to be addictive. Digital Mindfulness gives you the tools to reclaim your time and attention. Perfect for:

• Reducing late-night phone use
• Improving sleep quality
• Increasing productivity
• Better work-life balance
• Mindful living

REQUIREMENTS

• Android 5.0+ (API 21+)
• Accessibility service permission (for blocking)
• Notification permission (Android 13+)

PRIVACY

• All data stored locally on your device
• No account required
• No personal data collected
• No ads, no trackers
• Open source

SUPPORT

Questions? Email: support@digitalmindfulness.app
GitHub: github.com/yourname/digital-mindfulness

Start your mindful journey today! 🌟
```

#### Step 4.2: Graphics Assets

**App icon (512x512 PNG):**
- Already have from app development
- Upload in PNG format
- Must be 512x512px exactly

**Feature graphic (1024x500 PNG):**
Create with:
- Purple gradient background
- 🧘 meditation emoji or icon
- "Digital Mindfulness" text
- Tagline: "Focus on What Matters"

**Screenshots (minimum 2, recommended 8):**

Take screenshots showing:
1. Home screen with purple theme
2. Time configuration screen
3. App selection screen
4. Active restriction notification
5. Blocking screen ("Mindful Moment")
6. Settings lock indicator
7. Analytics/stats (if available)
8. Accessibility setup guide

**Screenshot specifications:**
- 16:9 or 9:16 aspect ratio
- Minimum dimension: 320px
- Maximum dimension: 3840px
- PNG or JPEG

#### Step 4.3: Categorization

- **App category:** Productivity
- **Tags:** productivity, mindfulness, focus, screen time, digital wellbeing
- **Content rating:** Complete questionnaire → Likely "Everyone"

#### Step 4.4: Contact Details

- **Email:** your-email@domain.com (visible to users)
- **Website:** Optional but recommended
- **Privacy policy URL:** **REQUIRED** (see below)

---

### Phase 5: Privacy Policy

**You MUST have a privacy policy URL.** Here's a template:

#### Option A: Host on GitHub Pages

Create `PRIVACY_POLICY.md`:

```markdown
# Privacy Policy - Digital Mindfulness

Last updated: February 16, 2026

## Data Collection

Digital Mindfulness does NOT collect, store, or transmit any personal data.

## What We Store Locally

All data remains on your device:
- Selected restriction times
- Allowed apps list
- Force-close attempt counts
- Accessibility service status

## Permissions Used

- **Accessibility Service**: Required to detect and block app launches
- **Notifications**: Shows enforcement status
- **Boot Completed**: Restores enforcement after reboot
- **Foreground Service**: Keeps enforcement active

## Third-Party Services

We do not use:
- Analytics
- Crash reporting
- Ad networks
- Cloud storage

## Data Security

All data stored using Android's encrypted SharedPreferences and SQLite database.

## Children's Privacy

Suitable for all ages. No data collection from anyone.

## Changes

Policy updates published at this URL.

## Contact

Questions: support@digitalmindfulness.app
```

**Host it:**
1. Create GitHub repo (can be private)
2. Enable GitHub Pages
3. URL: `https://yourusername.github.io/digital-mindfulness/privacy`

#### Option B: Use Free Policy Generator

- https://app-privacy-policy-generator.firebaseapp.com/
- https://www.freeprivacypolicy.com/

---

### Phase 6: Content Rating

1. Go to **Policy → App content**
2. Click **Content rating → Start questionnaire**
3. Select all relevant categories:
   - **Violence:** None
   - **Sexuality:** None
   - **Language:** None
   - etc.
4. Submit for rating (instant)
5. Likely result: **Everyone** or **PEGI 3**

---

### Phase 7: Upload App Bundle

#### Step 7.1: Create Release

1. Go to **Release → Production**
2. Click **Create new release**
3. Click **Upload** and select `app-release.aab`
4. Wait for upload and processing (2-5 minutes)

#### Step 7.2: Release Notes

**What's new in this version:**

```
🎉 Welcome to Digital Mindfulness v1.0!

✨ Features:
• Scheduled app blocking with custom time windows
• Beautiful mindful design with purple theme
• Robust enforcement that survives reboots
• Smart notifications during restrictions
• Settings lock for accountability
• Anti-tamper detection

Start your mindfulness journey today! 🧘
```

#### Step 7.3: Complete Release Setup

**Countries/Regions:**
- Select "All countries" or specific markets

**Rollout percentage:**
- Start with 20% for first release (staged rollout)
- Monitor for issues
- Increase to 100% after 1-2 days

---

### Phase 8: Pre-Launch Testing (Recommended)

Google offers free automated testing:

1. Go to **Release → Testing → Pre-launch report**
2. Google tests on various devices automatically
3. Review results (crashes, compatibility issues)
4. Fix issues before production launch

---

### Phase 9: Complete Remaining Requirements

Before you can publish, complete:

1. **✅ Store listing** - Done above
2. **✅ App content rating** - Done above
3. **✅ Privacy policy** - Done above
4. **✅ Target audience**
   - Age: 13+ (or appropriate age)
   - Designed for children: No
5. **✅ News app declaration**
   - Is this a news app: No
6. **✅ COVID-19 contact tracing**
   - Does app offer: No
7. **✅ Data safety**
   - Fill out questionnaire (no data collected)
8. **✅ Advertising ID**
   - Uses advertising ID: No
9. **✅ Government apps**
   - Is government app: No

---

### Phase 10: Submit for Review

#### Step 10.1: Review Dashboard

1. Check all sections have green checkmarks
2. Go to **Publishing overview**
3. Review summary

#### Step 10.2: Submit

1. Click **Send for review**
2. Confirm submission
3. Wait for review (typically 3-7 days)

#### Step 10.3: During Review

**Status tracking:**
- **In review**: Google is reviewing
- **Approved**: Ready to publish
- **Rejected**: See reason, fix, resubmit

**Common rejection reasons:**
- Missing privacy policy
- Policy violations (usually false positives)
- Broken functionality
- Missing required permissions

---

### Phase 11: Publish!

Once approved:

1. Go to **Publishing overview**
2. Click **Publish**
3. App goes live in **1-3 hours**

**Check your listing:**
- Search "Digital Mindfulness" on Play Store
- Your app should appear!
- Share the link: `https://play.google.com/store/apps/details?id=com.digitalwellbeing.digital_wellbeing_app`

---

## Part 3: Post-Launch

### Monitor Performance

**Key metrics in Play Console:**
- **Installs**: Total downloads
- **Uninstalls**: Track retention
- **Crashes**: Android vitals
- **Ratings**: User satisfaction
- **Reviews**: User feedback

### Respond to Reviews

- Reply to all reviews (especially negative)
- Thank users for positive feedback
- Help users with issues
- Shows you care about users

### Release Updates

**Typical update cycle:**

1. Fix bugs based on user feedback
2. Add requested features
3. Update version in `pubspec.yaml` (e.g., 1.0.1+2)
4. Build new AAB
5. Create new release in Play Console
6. Upload AAB
7. Add release notes
8. Submit for review (faster than initial: 1-2 days)

### Promote Your App

**Organic growth:**
- Share on Reddit (r/digitalminimalism, r/productivity)
- Product Hunt launch
- Tweet about it
- Write blog post
- Create demo video

**ASO (App Store Optimization):**
- Optimize title and description with keywords
- Encourage satisfied users to leave reviews
- Update screenshots with best features
- A/B test different graphics

---

## Troubleshooting

### Build Issues

**Error: "Keystore was tampered with"**
```powershell
# Recreate keystore (ONLY if you haven't published yet)
# DO NOT do this after publishing!
```

**Error: "Android license not accepted"**
```powershell
flutter doctor --android-licenses
# Accept all licenses
```

**Error: "Gradle build failed"**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter build appbundle --release
```

### Play Console Issues

**"App Bundle not signed correctly"**
- Check `key.properties` file exists and is correct
- Verify signing config in `build.gradle.kts`
- Rebuild app bundle

**"Missing required sections"**
- Go through all sections in Play Console
- Ensure all have green checkmarks
- Common missing: Privacy policy, content rating, data safety

**"Upload failed"**
- Check AAB file size (max 150 MB)
- Ensure version code incremented
- Try uploading different file

---

## Checklist Summary

### Before Deployment to Phone
- [ ] USB debugging enabled on phone
- [ ] Phone connected and detected (`flutter devices`)
- [ ] App runs in debug mode
- [ ] All permissions granted
- [ ] Core features tested

### Before Play Store Submission
- [ ] Keystore created and backed up
- [ ] Signing configured in `build.gradle.kts`
- [ ] Version number updated
- [ ] Release AAB built and tested
- [ ] App icon 512x512 created
- [ ] Feature graphic 1024x500 created
- [ ] 2-8 screenshots taken
- [ ] Privacy policy published
- [ ] Google Play Console account created ($25 paid)
- [ ] Store listing completed
- [ ] Content rating obtained
- [ ] All app content sections filled

### After Submission
- [ ] Monitor review status daily
- [ ] Prepare for user feedback
- [ ] Set up email for support requests
- [ ] Plan first update (v1.0.1)
- [ ] Celebrate launch! 🎉

---

## Cost Summary

### One-Time Costs
- Google Play Developer Account: **$25**
- Domain for privacy policy (optional): **$10-15/year**

### Ongoing Costs (v1.0 - Free Version)
- **$0** - No backend costs yet!

### Future Costs (v2.0 - Premium)
- Backend hosting: ~$70/month
- Break-even: 15 paid users
- Expected: $500+/month after 6 months

---

## Support Resources

### Documentation
- Flutter Deployment: https://docs.flutter.dev/deployment/android
- Play Console Help: https://support.google.com/googleplay/android-developer
- App Signing: https://developer.android.com/studio/publish/app-signing

### Community
- Stack Overflow: Tag `flutter` and `android`
- Reddit: r/FlutterDev
- Discord: Flutter Community

### Professional Help
If stuck, consider hiring:
- Flutter consultant: $50-150/hour
- Play Store submission service: $100-300
- ASO expert: $500-2000

---

**Good luck with your launch! 🚀**

Questions? Check the troubleshooting section or reach out for help.
