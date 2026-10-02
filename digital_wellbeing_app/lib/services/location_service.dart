import 'package:flutter/services.dart';

class LocationCoords {
  final double lat;
  final double lng;
  final double accuracy;

  const LocationCoords({
    required this.lat,
    required this.lng,
    required this.accuracy,
  });

  static double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const earthR = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = _sin2(dLat / 2) +
        _cos(_toRad(lat1)) * _cos(_toRad(lat2)) * _sin2(dLng / 2);
    final c = 2 * _asin(_sqrt(a));
    return earthR * c;
  }

  static double _toRad(double deg) => deg * 3.14159265358979 / 180;
  static double _sin2(double x) => _sin(x) * _sin(x);

  static double _sin(double x) {
    double result = x;
    double term = x;
    for (int i = 1; i < 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(x + 3.14159265358979 / 2);
  static double _asin(double x) => x + x * x * x / 6;
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double r = x;
    for (int i = 0; i < 20; i++) { r = (r + x / r) / 2; }
    return r;
  }
}

class LocationService {
  static const _channel = MethodChannel('digital_wellbeing/location');

  Future<bool> hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPermission') ?? false;

  Future<bool> hasBackgroundPermission() async =>
      await _channel.invokeMethod<bool>('hasBackgroundPermission') ?? false;

  Future<bool> requestPermission() async =>
      await _channel.invokeMethod<bool>('requestPermission') ?? false;

  Future<LocationCoords?> getLastKnownLocation() async {
    final result =
        await _channel.invokeMapMethod<String, dynamic>('getLastKnownLocation');
    if (result == null) return null;
    return LocationCoords(
      lat: (result['lat'] as num).toDouble(),
      lng: (result['lng'] as num).toDouble(),
      accuracy: (result['accuracy'] as num).toDouble(),
    );
  }
}
