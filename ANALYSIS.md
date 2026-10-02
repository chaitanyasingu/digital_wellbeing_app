# Digital Wellbeing App — Code Analysis

**Analyzed:** 2026-10-02  
**Version:** 1.0.3+4  
**Stack:** Flutter (Dart) + Kotlin (Android-only)

---

## Overview

A focus-enforcement app that blocks user-defined apps during configurable daily restriction windows. Built on Android's AccessibilityService API to intercept window events and inject fullscreen blocking overlays.

---

## Pros

### Architecture & Design

- **Clean layer separation** — `models/`, `providers/`, `screens/`, `services/` are logically distinct with no cross-cutting concerns bleeding between them.
- **Repository pattern** — `AppsRepository` decouples the UI from both the SQLite cache (`DatabaseService`) and the live device query (`AppService`), making future data-source swaps straightforward.
- **Riverpod state management** — Used correctly and consistently. `StateNotifierProvider` + immutable models with `copyWith` is a solid pattern; no god-object providers.
- **Midnight-spanning restriction windows** — Both the Dart `TimeService` and Kotlin `AppBlockingService` correctly handle overnight windows (e.g., 21:00–10:00). A common edge case that is handled right.
- **Three MethodChannel bridge** — Clean separation of concern at the Flutter/Android boundary: one channel each for apps, enforcement, and notifications.

### Core Enforcement Logic

- **Debounced overlay** — A 1-second global debounce plus a per-package in-progress set prevents duplicate overlays from rapid `TYPE_WINDOW_STATE_CHANGED` events. This is a common pitfall in AccessibilityService apps and is properly handled.
- **System whitelist** — Hardcoded `SYSTEM_WHITELIST` (launchers, SystemUI, Settings, Dialer) prevents the user from being locked out of the device entirely.
- **Settings lock is genuinely enforced** — Both the UI layer (greyed-out controls, `onTap: null`) and the state layer (exception thrown on programmatic mutation during a restriction window) enforce the lock. It is not just cosmetic.
- **Reboot persistence** — `BootCompletedReceiver` + `START_STICKY` + `SharedPreferences.commit()` (synchronous write) cover the most common bypass paths: device restart, app kill, and race conditions between Flutter writes and Kotlin reads.
- **Tamper detection scaffolding** — `TamperDetectionService` tracks force-close events in a 5-minute sliding window, and `TimeChangeReceiver` detects backward system-clock jumps. The intent is right.

### Developer Experience

- **Extensive labeled debug logging** — `[EnforcementService]`, `[OVERLAY]`, `[DECISION]` prefixes throughout Kotlin make on-device debugging with `logcat` practical.
- **PowerShell deploy helpers** — `deploy-to-phone.ps1` and `test-on-phone.ps1` reduce friction for physical device testing.
- **JSON code generation** — `json_annotation` + `json_serializable` + `build_runner` keeps serialization boilerplate out of the model classes.

---

## Cons

### Testing

- **Zero test coverage** — `test/` is entirely empty. No unit, widget, or integration tests for any Dart code. No Kotlin tests either. For an app that can actively restrict access to other apps, this is a material risk: a regression could lock a user out of apps without recourse.

### Reliability & Correctness Risks

- **Duplicated time restriction logic** — `isCurrentTimeRestricted` is implemented identically in three places: `TimeService.dart`, `AppBlockingService.kt`, and `EnforcementForegroundService.kt`. The duplication is architecturally forced (native services cannot call Dart), but there is no shared test to guarantee they stay in sync. A future change to one will silently diverge from the others.
- **Incomplete tamper response** — `TimeChangeReceiver` detects backward clock changes but takes no enforcement action — it only logs. A user who rolls back the system clock by more than 5 minutes during a restriction window will bypass enforcement, since the service will re-evaluate the current time and may no longer consider it a restricted period.
- **No database error handling** — `DatabaseService` has a lazily initialized singleton `_database` with no handling for corruption or migration failures. A corrupted SQLite file will throw at runtime with no recovery path.
- **WorkManager disabled** — `BackgroundJobService` is entirely stubbed out with a TODO ("compatibility issue"). The daily app-list sync never runs automatically. The app DB silently goes stale without a manual sync tap by the user.

### Code Quality

- **`print()` in production code** — `main.dart`, `home_screen.dart`, `rules_provider.dart`, and others use bare `print()` calls instead of a logging framework or `kDebugMode` guard. These emit to release builds, leaking implementation details.
- **`test_screen.dart` compiled into production** — The developer debug screen is in `lib/screens/` and compiled into every build, though not reachable from normal navigation. It should be removed or gated behind a build flag.
- **`BlockingActivity.kt` appears to be dead code** — An alternative blocking implementation (`BlockingActivity`) exists as a file but is not referenced by the current overlay approach. Its status (legacy, in-progress, fallback) is undocumented.
- **No public API documentation** — No `///` Dart docstrings on service or provider public methods. Method names are clear enough that this is minor, but it raises the onboarding cost for a new contributor.

### Platform & Scalability

- **Android-only despite Flutter** — The project uses `flutter create` but is Android-only by design. The cross-platform capability of Flutter provides no benefit here and adds a dependency layer (MethodChannel boilerplate, `pubspec.yaml` overhead) that a pure Kotlin app would avoid.
- **Hardcoded app seed data** — `DatabaseService.seedCommonApps()` contains ~30 hardcoded package names (Facebook, Instagram, etc.) as a fallback. This list will drift out of date and varies by region/device.
- **AccessibilityService single point of failure** — If the user disables the accessibility service (intentionally or by a device optimizer), enforcement stops with no recovery other than a manual re-prompt. There is no watchdog mechanism to detect and alert on this state in real time.
- **Settings lock polling interval** — `SettingsLockNotifier` recalculates lock state every 10 seconds via a timer. Acceptable for battery, but means the UI can be up to 10 seconds late to reflect that a restriction window has started or ended.

---

## Summary Table

| Area | Rating | Notes |
|---|---|---|
| Core enforcement logic | Good | Debouncing, whitelist, persistence all handled |
| Architecture / structure | Good | Clean separation, solid Riverpod usage |
| Time window handling | Good | Overnight spans handled correctly in both layers |
| Test coverage | Poor | Zero tests — highest risk area |
| Tamper resistance | Partial | Detected but not acted on for clock tampering |
| Code hygiene | Fair | `print()` in prod, dead code, no docstrings |
| Reliability | Fair | Duplicated logic, no DB error handling |
| Platform fit | Fair | Flutter overhead for an Android-only app |
