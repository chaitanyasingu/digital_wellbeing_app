import 'package:flutter/services.dart';

class DeviceAdminService {
  static const _channel = MethodChannel('digital_wellbeing/device_admin');

  Future<bool> isAdminActive() async =>
      await _channel.invokeMethod<bool>('isAdminActive') ?? false;

  /// Opens the system Device Admin activation dialog.
  /// Returns true if admin was activated.
  Future<bool> activateAdmin() async =>
      await _channel.invokeMethod<bool>('activateAdmin') ?? false;

  Future<void> deactivateAdmin() async =>
      await _channel.invokeMethod('deactivateAdmin');
}
