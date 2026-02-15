# Digital Wellbeing App

**Android-only** digital wellbeing application that reduces screen time by enforcing strict, time-based app access rules.

## 🎯 Project Status

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 1** | ✅ **COMPLETE** | Core MVP - App blocking, time config, local storage |
| **Phase 2** | ✅ **COMPLETE** | Enforcement hardening - Reboot persistence, foreground service |
| **Phase 3** | ⏳ Pending | Settings lock UX & polish |
| **Phase 4** | ⏳ Pending | Anti-tamper enhancements |
| **Phase 5** | ⏳ Pending | Optional backend sync |

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.10+
- Android SDK with API 21+ (Android 5.0+)
- Android device or emulator

### Run the App
```bash
# Install dependencies
flutter pub get

# Generate JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device
flutter run
```

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

### Future Phases
- Settings can be changed outside restriction window (Phase 3)
- No tamper detection warnings (Phase 4)
- No cloud backup (Phase 5)

## 📞 Support & Issues

This is a production-grade implementation following the specification in the project root. All features match the requirements document.

For issues, check:
1. Accessibility service is enabled
2. All permissions granted
3. Device is not rooted
4. Android version is 5.0+

## 📄 License

Private project - not for public distribution.
