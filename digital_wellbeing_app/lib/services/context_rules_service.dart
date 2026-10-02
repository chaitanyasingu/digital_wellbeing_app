import 'database_service.dart';

class WifiRule {
  final int? id;
  final String name;
  final String ssid;
  final bool isRelaxed;
  final bool isActive;

  const WifiRule({
    this.id,
    required this.name,
    required this.ssid,
    this.isRelaxed = true,
    this.isActive = true,
  });

  static WifiRule fromMap(Map<String, dynamic> m) => WifiRule(
        id: m['id'] as int?,
        name: m['name'] as String,
        ssid: m['ssid'] as String,
        isRelaxed: (m['effect'] as String) == 'relaxed',
        isActive: (m['is_active'] as int) == 1,
      );
}

class LocationRule {
  final int? id;
  final String name;
  final double lat;
  final double lng;
  final int radiusMeters;
  final bool isStrict;
  final bool isActive;

  const LocationRule({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.radiusMeters = 200,
    this.isStrict = true,
    this.isActive = true,
  });

  static LocationRule fromMap(Map<String, dynamic> m) => LocationRule(
        id: m['id'] as int?,
        name: m['name'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        radiusMeters: m['radius_meters'] as int,
        isStrict: (m['effect'] as String) == 'strict',
        isActive: (m['is_active'] as int) == 1,
      );
}

class ContextRulesService {
  final _db = DatabaseService.instance;

  // ── WiFi rules ─────────────────────────────────────────────────────────────

  Future<List<WifiRule>> getWifiRules() async {
    final rows = await _db.getContextWifiRules();
    return rows.map(WifiRule.fromMap).toList();
  }

  Future<int> addWifiRule(WifiRule rule) async {
    return _db.insertContextWifiRule({
      'name': rule.name,
      'ssid': rule.ssid,
      'effect': rule.isRelaxed ? 'relaxed' : 'strict',
      'is_active': rule.isActive ? 1 : 0,
    });
  }

  Future<void> deleteWifiRule(int id) => _db.deleteContextWifiRule(id);

  Future<void> toggleWifiRule(int id, bool active) =>
      _db.updateContextWifiRule(id, {'is_active': active ? 1 : 0});

  // ── Location rules ─────────────────────────────────────────────────────────

  Future<List<LocationRule>> getLocationRules() async {
    final rows = await _db.getContextLocationRules();
    return rows.map(LocationRule.fromMap).toList();
  }

  Future<int> addLocationRule(LocationRule rule) async {
    return _db.insertContextLocationRule({
      'name': rule.name,
      'lat': rule.lat,
      'lng': rule.lng,
      'radius_meters': rule.radiusMeters,
      'effect': rule.isStrict ? 'strict' : 'relaxed',
      'is_active': rule.isActive ? 1 : 0,
    });
  }

  Future<void> deleteLocationRule(int id) => _db.deleteContextLocationRule(id);

  Future<void> toggleLocationRule(int id, bool active) =>
      _db.updateContextLocationRule(id, {'is_active': active ? 1 : 0});
}
