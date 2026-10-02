import 'package:flutter/services.dart';

class WifiService {
  static const _channel = MethodChannel('digital_wellbeing/wifi');

  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  Future<String?> getCurrentSsid() async =>
      await _channel.invokeMethod<String?>('getCurrentSsid');

  Future<bool> isWifiEnabled() async =>
      await _channel.invokeMethod<bool>('isWifiEnabled') ?? false;
}
