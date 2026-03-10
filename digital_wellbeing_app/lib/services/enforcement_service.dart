import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

class EnforcementService {
  static const MethodChannel _channel = MethodChannel('digital_wellbeing/enforcement');
  final NotificationService _notificationService = NotificationService();

  /// Start the enforcement service
  Future<bool> startEnforcement(List<String> allowedApps, String startTime, String endTime) async {
    try {
      debugPrint('[EnforcementService] ========== STARTING ENFORCEMENT ==========');
      debugPrint('[EnforcementService] Allowed apps: ${allowedApps.length}');
      debugPrint('[EnforcementService] Restriction window: $startTime - $endTime');
      
      await _channel.invokeMethod('startEnforcement', {
        'allowedApps': allowedApps,
        'startTime': startTime,
        'endTime': endTime,
      });
      
      debugPrint('[EnforcementService] ✓ Enforcement method called successfully');
      
      // Show persistent notification about app blocking during restriction period
      debugPrint('[EnforcementService] Calling showAppBlockingNotification until $endTime');
      await _notificationService.showAppBlockingNotification(endTime: endTime);
      debugPrint('[EnforcementService] ✓ showAppBlockingNotification completed');
      
      return true;
    } on PlatformException catch (e) {
      debugPrint('[EnforcementService] ✗ Failed to start enforcement: ${e.message}');
      return false;
    }
  }

  /// Stop the enforcement service
  Future<bool> stopEnforcement() async {
    try {
      await _channel.invokeMethod('stopEnforcement');
      
      // Dismiss the app blocking notification when enforcement stops
      debugPrint('[EnforcementService] Dismissing app blocking notification');
      await _notificationService.dismissAppBlockingNotification();
      
      return true;
    } on PlatformException catch (e) {
      debugPrint('Failed to stop enforcement: ${e.message}');
      return false;
    }
  }

  /// Check if accessibility service is enabled
  Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod('isAccessibilityEnabled');
    } on PlatformException catch (e) {
      debugPrint('Failed to check accessibility: ${e.message}');
      return false;
    }
  }

  /// Open accessibility settings
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint('Failed to open accessibility settings: ${e.message}');
    }
  }
}
