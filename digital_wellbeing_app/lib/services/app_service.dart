import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_info.dart';

class AppService {
  static const MethodChannel _channel = MethodChannel('digital_wellbeing/apps');

  /// Fetch all installed apps from Android
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      debugPrint('Calling getInstalledApps via method channel...');
      final List<dynamic> apps = await _channel
          .invokeMethod('getInstalledApps')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('getInstalledApps method channel timed out after 30s');
              return <dynamic>[];
            },
          );
      debugPrint('Received ${apps.length} apps from native side');
      return apps
          .map((app) => AppInfo.fromJson(Map<String, dynamic>.from(app)))
          .toList();
    } on PlatformException catch (e) {
      debugPrint('PlatformException in getInstalledApps: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error in getInstalledApps: $e');
      return [];
    }
  }

  /// Get the current foreground app package name
  Future<String?> getCurrentApp() async {
    try {
      return await _channel.invokeMethod('getCurrentApp');
    } on PlatformException catch (e) {
      debugPrint('Failed to get current app: ${e.message}');
      return null;
    }
  }
}
