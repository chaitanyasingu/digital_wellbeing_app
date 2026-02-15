import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for detecting and tracking bypass attempts
class TamperDetectionService {
  static const String _keyForceCloseCount = 'force_close_count';
  static const String _keyLastForceCloseTime = 'last_force_close_time';
  static const String _keyAccessibilityDisabledCount =
      'accessibility_disabled_count';
  static const String _keyLastAccessibilityCheck = 'last_accessibility_check';

  static const int maxForceClosesInWindow = 3;
  static const Duration forceCloseWindow = Duration(minutes: 5);

  /// Track an app force-close event
  Future<bool> trackForceClose() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    final lastTime = prefs.getInt(_keyLastForceCloseTime) ?? 0;

    // Reset count if outside the window
    if (now - lastTime > forceCloseWindow.inMilliseconds) {
      await prefs.setInt(_keyForceCloseCount, 1);
      await prefs.setInt(_keyLastForceCloseTime, now);
      print('[TamperDetection] Force-close tracked (1 in window)');
      return false; // Not suspicious yet
    }

    // Increment count within window
    final count = (prefs.getInt(_keyForceCloseCount) ?? 0) + 1;
    await prefs.setInt(_keyForceCloseCount, count);
    await prefs.setInt(_keyLastForceCloseTime, now);

    print(
      '[TamperDetection] Force-close tracked ($count in ${forceCloseWindow.inMinutes} minutes)',
    );

    // Check if suspicious
    if (count >= maxForceClosesInWindow) {
      print('[TamperDetection] ⚠️ SUSPICIOUS: $count force-closes detected');
      return true; // Trigger warning
    }

    return false;
  }

  /// Get current force-close count in window
  Future<int> getForceCloseCount() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastTime = prefs.getInt(_keyLastForceCloseTime) ?? 0;

    // Return 0 if outside window
    if (now - lastTime > forceCloseWindow.inMilliseconds) {
      return 0;
    }

    return prefs.getInt(_keyForceCloseCount) ?? 0;
  }

  /// Reset force-close tracking
  Future<void> resetForceCloseTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForceCloseCount);
    await prefs.remove(_keyLastForceCloseTime);
    print('[TamperDetection] Force-close tracking reset');
  }

  /// Track accessibility service disabled event
  Future<void> trackAccessibilityDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyAccessibilityDisabledCount) ?? 0) + 1;
    await prefs.setInt(_keyAccessibilityDisabledCount, count);
    await prefs.setInt(
      _keyLastAccessibilityCheck,
      DateTime.now().millisecondsSinceEpoch,
    );
    print(
      '[TamperDetection] Accessibility disabled event tracked (total: $count)',
    );
  }

  /// Get total accessibility disabled count
  Future<int> getAccessibilityDisabledCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAccessibilityDisabledCount) ?? 0;
  }

  /// Check if we should show tamper warning
  Future<bool> shouldShowTamperWarning() async {
    final forceCloseCount = await getForceCloseCount();
    return forceCloseCount >= maxForceClosesInWindow;
  }

  /// Reset all tamper detection data
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyForceCloseCount);
    await prefs.remove(_keyLastForceCloseTime);
    await prefs.remove(_keyAccessibilityDisabledCount);
    await prefs.remove(_keyLastAccessibilityCheck);
    print('[TamperDetection] All tracking data reset');
  }
}
