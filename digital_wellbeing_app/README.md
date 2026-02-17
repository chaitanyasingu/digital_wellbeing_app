# Digital Mindfulness

**Android-only** digital wellbeing application that reduces screen time by enforcing strict, time-based app access rules.

> 🧘 Helping you build healthier phone habits through mindful restrictions.

## 🎯 Project Status

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 1** | ✅ **COMPLETE** | Core MVP - App blocking, time config, local storage |
| **Phase 2** | ✅ **COMPLETE** | Enforcement hardening - Reboot persistence, foreground service |
| **Phase 3** | ✅ **COMPLETE** | Settings lock UX & polish |
| **Phase 4** | ✅ **COMPLETE** | Anti-tamper + UX redesign to "Digital Mindfulness" |
| **Version 2.0** | 📋 **PLANNED** | Premium features - Multiple time windows, cloud sync ([Roadmap](VERSION_2_ROADMAP.md)) |

**Current Version:** v1.0.0 - Ready for testing and Play Store submission! 🚀

## 🚀 Getting Started

### For Developers (Testing)

**Quick Deploy to Your Phone:**
```powershell
# Windows PowerShell helper script
.\deploy-to-phone.ps1

# Or manually:
flutter pub get
flutter run
```

See **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** for complete instructions.

### For End Users

Install from Google Play Store: **Coming Soon!** 🎉

### Prerequisites
- Flutter SDK 3.10+
- Android SDK with API 21+ (Android 5.0+)
- Android device or emulator

## 📋 Core Features (Phase 1 & 2)

### ✅ Always-Allowed Apps
- Select apps accessible 24/7 (phone, messages, payments)
- Search and multi-select interface
- Settings persist across restarts

### ✅ Time-Based Restrictions
- Configure daily restriction window (e.g., 21:00 - 10:00)
- Supports midnight-spanning periods
- All non-allowed apps blocked during window

### ✅ Settings Lock
- Cannot modify settings during active restriction
- Visual lock indicators with countdown timer
- Prevents cheating by changing configuration

### ✅ Persistent Enforcement
- **Survives app force-close** (foreground service)
- **Survives device reboots** (boot receiver)
- **Detects time changes** (prevents bypass)
- Persistent notification when active

### ✅ Accessibility-Based Blocking
- Monitors app launches in real-time
- Immediate blocking overlay for restricted apps
- Auto-redirect to home screen

## 📖 Documentation

- **[PHASE_1_README.md](./PHASE_1_README.md)** - Core MVP implementation + validation tests
- **[PHASE_2_README.md](./PHASE_2_README.md)** - Enforcement hardening + validation tests
- **[Original Spec](../# Android Digital Wellbeing App – P.txt)** - Complete project requirements

## 🧪 Testing

### Phase 1 Validation (10 Tests)
Run all tests in [PHASE_1_README.md](./PHASE_1_README.md#phase-1-validation-tests) to verify:
- App list loading
- Time configuration
- Blocking during restrictions
- Settings lock functionality

### Phase 2 Validation (10 Tests)
Run all tests in [PHASE_2_README.md](./PHASE_2_README.md#phase-2-validation-tests) to verify:
- Reboot persistence
- Foreground service notification
- Time change detection
- Service auto-restart

## 🏗️ Architecture

### Flutter Layer
```
lib/
├── models/          # Data models with JSON serialization
├── services/        # Platform channels & business logic
├── providers/       # Riverpod state management
└── screens/         # UI screens
```

### Android Native Layer
```
android/.../kotlin/
├── MainActivity.kt                    # Platform channel handler
├── AppBlockingService.kt             # Accessibility service
├── BlockingActivity.kt               # Blocking overlay
├── EnforcementForegroundService.kt   # Persistent service
├── BootCompletedReceiver.kt          # Reboot listener
└── TimeChangeReceiver.kt             # Time change detector
```

## 🔐 Permissions Required

- `QUERY_ALL_PACKAGES` - List installed apps
- `BIND_ACCESSIBILITY_SERVICE` - Monitor app launches
- `RECEIVE_BOOT_COMPLETED` - Auto-start on reboot
- `FOREGROUND_SERVICE` - Persistent enforcement
- `POST_NOTIFICATIONS` - Show enforcement notification

## ⚙️ Configuration

### Default Settings
- Start Time: 21:00
- End Time: 10:00
- Always-Allowed Apps: (empty - user configures)
- Enforcement: OFF (user enables)

### Storage
- Local: SharedPreferences (encrypted)
- Backup: Not yet implemented (Phase 5)

## 🎨 UI Design Principles

- **Concise Text**: All labels 1-2 lines max (12-14px font)
- **Clear Status**: Visual indicators for locked/unlocked state
- **No Confusion**: Disabled controls are grayed out
- **Transparent**: Shows exact unlock time during restrictions

## 🐛 Known Limitations

### By Design (Per Spec)
- ❌ No iOS support (Android-only)
- ❌ Does not prevent factory reset
- ❌ Does not work on rooted devices
- ❌ User can uninstall app (no Device Owner mode)

### Free Version (v1.x)
- Only one time window per day (upgrade to Premium v2.x for multiple windows)
- No cloud backup (coming in v2.x Premium)

## 📚 Documentation

### Development Phases
- **[PHASE_1_README.md](PHASE_1_README.md)** - Core MVP implementation details
- **[PHASE_2_README.md](PHASE_2_README.md)** - Enforcement hardening deep dive
- **[PHASE_4_README.md](PHASE_4_README.md)** - Anti-tamper + UX redesign + Testing guide

### Deployment & Publishing
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - 📱 Test on your phone + Publish to Play Store
- **[PLAY_STORE_CHECKLIST.md](PLAY_STORE_CHECKLIST.md)** - 📋 Quick reference for store listing
- **[deploy-to-phone.ps1](deploy-to-phone.ps1)** - 🚀 PowerShell script for quick deployment
- **[test-on-phone.ps1](test-on-phone.ps1)** - ✅ Interactive testing checklist

### Future Planning
- **[VERSION_2_ROADMAP.md](VERSION_2_ROADMAP.md)** - 💎 Premium features (multiple windows, cloud sync, monetization)

## 🚀 Deployment Quick Links

**Test on Your Phone:**
```powershell
.\deploy-to-phone.ps1
# Or follow: DEPLOYMENT_GUIDE.md Part 1
```

**Publish to Play Store:**
```powershell
# 1. Create signing key (one-time)
cd android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Build release
cd ..
flutter build appbundle --release

# 3. Follow: DEPLOYMENT_GUIDE.md Part 2
```

## 📞 Support & Issues

**For Bugs or Feature Requests:**
- Open an issue on GitHub
- Email: [Your email]

**Common Issues:**
1. **Blocking not working?** → Enable accessibility service
2. **Notifications missing?** → Grant notification permission (Android 13+)
3. **Restrictions not persisting?** → Check battery optimization is disabled

**Troubleshooting:** See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) troubleshooting section.

## 🎉 Ready to Launch?

**Checklist:**
- ✅ Phases 1-4 complete
- ✅ App rebranded to "Digital Mindfulness"
- ✅ Purple theme and mindful UX
- ✅ Comprehensive test suite in PHASE_4_README
- ✅ Deployment guide ready
- ✅ Play Store checklist prepared

**Next Steps:**
1. Test on your physical phone using [deploy-to-phone.ps1](deploy-to-phone.ps1)
2. Run through [test-on-phone.ps1](test-on-phone.ps1) checklist
3. Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) to publish

**Start your mindfulness journey today! 🧘**
4. Android version is 5.0+

## 📄 License

Private project - not for public distribution.
