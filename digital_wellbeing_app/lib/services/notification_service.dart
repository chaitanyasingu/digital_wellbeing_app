import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel(
    'digital_wellbeing/notifications',
  );

  /// Request notification permission (Android 13+)
  Future<bool> requestNotificationPermission() async {
    try {
      final bool granted = await _channel.invokeMethod(
        'requestNotificationPermission',
      );
      debugPrint('Notification permission granted: $granted');
      return granted;
    } on PlatformException catch (e) {
      debugPrint('Failed to request notification permission: ${e.message}');
      return false;
    }
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod(
        'hasNotificationPermission',
      );
      return hasPermission;
    } on PlatformException catch (e) {
      debugPrint('Failed to check notification permission: ${e.message}');
      return false;
    }
  }

  /// Show a test notification to verify it works
  Future<void> showTestNotification() async {
    try {
      await _channel.invokeMethod('showTestNotification');
    } on PlatformException catch (e) {
      debugPrint('Failed to show test notification: ${e.message}');
    }
  }

  /// Show tamper warning notification (accessibility disabled, force-closes)
  Future<void> showTamperWarning({
    required String title,
    required String message,
  }) async {
    try {
      await _channel.invokeMethod('showTamperWarning', {
        'title': title,
        'message': message,
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to show tamper warning: ${e.message}');
    }
  }

  /// Show persistent app blocking notification during restriction period
  /// This notification persists until the restriction period ends
  Future<void> showAppBlockingNotification({
    required String endTime,
  }) async {
    try {
      debugPrint('[NotificationService] [NOTIFICATION] Calling Android showAppBlockingNotification with endTime=$endTime');
      await _channel.invokeMethod('showAppBlockingNotification', {
        'endTime': endTime,
      });
      debugPrint('[NotificationService] [NOTIFICATION] ✓ showAppBlockingNotification method call completed');
    } on PlatformException catch (e) {
      debugPrint('[NotificationService] [NOTIFICATION] ✗ Failed to show app blocking notification: ${e.message}');
    }
  }

  /// Dismiss the app blocking notification
  Future<void> dismissAppBlockingNotification() async {
    try {
      debugPrint('[NotificationService] [NOTIFICATION] Calling Android dismissAppBlockingNotification');
      await _channel.invokeMethod('dismissAppBlockingNotification');
      debugPrint('[NotificationService] [NOTIFICATION] ✓ dismissAppBlockingNotification method call completed');
    } on PlatformException catch (e) {
      debugPrint('[NotificationService] [NOTIFICATION] ✗ Failed to dismiss app blocking notification: ${e.message}');
    }
  }

  /// Get logs from accessibility service for debugging
  Future<List<String>> getAccessibilityLogs() async {
    try {
      final List<dynamic> logs = await _channel.invokeMethod(
        'getAccessibilityLogs',
      );
      return logs.cast<String>();
    } on PlatformException catch (e) {
      debugPrint('Failed to get accessibility logs: ${e.message}');
      return [];
    }
  }
}
