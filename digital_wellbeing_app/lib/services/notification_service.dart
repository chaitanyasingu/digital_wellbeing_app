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
