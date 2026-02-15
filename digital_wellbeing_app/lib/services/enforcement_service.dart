import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnforcementService {
  static const MethodChannel _channel = MethodChannel('digital_wellbeing/enforcement');

  /// Start the enforcement service
  Future<bool> startEnforcement(List<String> allowedApps, String startTime, String endTime) async {
    try {
      await _channel.invokeMethod('startEnforcement', {
        'allowedApps': allowedApps,
        'startTime': startTime,
        'endTime': endTime,
      });
      return true;
    } on PlatformException catch (e) {
      debugPrint('Failed to start enforcement: ${e.message}');
      return false;
    }
  }

  /// Stop the enforcement service
  Future<bool> stopEnforcement() async {
    try {
      await _channel.invokeMethod('stopEnforcement');
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
