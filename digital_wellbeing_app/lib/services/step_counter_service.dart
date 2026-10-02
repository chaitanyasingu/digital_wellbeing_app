import 'package:flutter/services.dart';

class StepCounterService {
  static const _channel = MethodChannel('digital_wellbeing/steps');

  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      return await _channel.invokeMethod<bool>('hasPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  // Returns steps since midnight, or -1 if sensor unavailable / timed out.
  Future<int> getStepsToday() async {
    try {
      return await _channel.invokeMethod<int>('getStepsToday') ?? -1;
    } catch (_) {
      return -1;
    }
  }
}
