import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/context_rules_service.dart';
import '../services/wifi_service.dart';
import '../services/location_service.dart';
import '../services/enforcement_service.dart';

class ContextRulesState {
  final List<WifiRule> wifiRules;
  final List<LocationRule> locationRules;
  final String? currentSsid;
  final LocationCoords? currentLocation;
  final bool wifiRelaxedActive;
  final bool locationStrictActive;
  final bool isLoading;

  const ContextRulesState({
    this.wifiRules = const [],
    this.locationRules = const [],
    this.currentSsid,
    this.currentLocation,
    this.wifiRelaxedActive = false,
    this.locationStrictActive = false,
    this.isLoading = false,
  });

  ContextRulesState copyWith({
    List<WifiRule>? wifiRules,
    List<LocationRule>? locationRules,
    String? currentSsid,
    LocationCoords? currentLocation,
    bool? wifiRelaxedActive,
    bool? locationStrictActive,
    bool? isLoading,
  }) =>
      ContextRulesState(
        wifiRules: wifiRules ?? this.wifiRules,
        locationRules: locationRules ?? this.locationRules,
        currentSsid: currentSsid ?? this.currentSsid,
        currentLocation: currentLocation ?? this.currentLocation,
        wifiRelaxedActive: wifiRelaxedActive ?? this.wifiRelaxedActive,
        locationStrictActive: locationStrictActive ?? this.locationStrictActive,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ContextRulesNotifier extends StateNotifier<ContextRulesState> {
  final ContextRulesService _svc = ContextRulesService();
  final WifiService _wifi = WifiService();
  final LocationService _loc = LocationService();
  final EnforcementService _enforcement = EnforcementService();

  ContextRulesNotifier() : super(const ContextRulesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final wifiRules = await _svc.getWifiRules();
    final locationRules = await _svc.getLocationRules();
    state = state.copyWith(
      wifiRules: wifiRules,
      locationRules: locationRules,
      isLoading: false,
    );
    await refresh();
  }

  /// Re-reads WiFi SSID + GPS, evaluates active rules, writes flags.
  Future<void> refresh() async {
    String? ssid;
    LocationCoords? location;

    if (await _wifi.hasPermission()) {
      ssid = await _wifi.getCurrentSsid();
    }
    if (await _loc.hasPermission()) {
      location = await _loc.getLastKnownLocation();
    }

    bool wifiRelaxed = false;
    bool locationStrict = false;

    for (final rule in state.wifiRules) {
      if (!rule.isActive) continue;
      if (ssid != null && ssid == rule.ssid) {
        if (rule.isRelaxed) wifiRelaxed = true;
      }
    }

    if (location != null) {
      for (final rule in state.locationRules) {
        if (!rule.isActive) continue;
        final center = LocationCoords(lat: rule.lat, lng: rule.lng);
        final dist = LocationCoords.distanceMeters(location, center);
        if (dist <= rule.radiusMeters) {
          if (rule.isStrict) locationStrict = true;
        }
      }
    }

    state = state.copyWith(
      currentSsid: ssid,
      currentLocation: location,
      wifiRelaxedActive: wifiRelaxed,
      locationStrictActive: locationStrict,
    );

    await _enforcement.updateContextFlags(
      wifiRelaxed: wifiRelaxed,
      locationStrict: locationStrict,
    );
  }

  Future<void> addWifiRule(WifiRule rule) async {
    await _svc.addWifiRule(rule);
    final updated = await _svc.getWifiRules();
    state = state.copyWith(wifiRules: updated);
    await refresh();
  }

  Future<void> deleteWifiRule(int id) async {
    await _svc.deleteWifiRule(id);
    final updated = await _svc.getWifiRules();
    state = state.copyWith(wifiRules: updated);
    await refresh();
  }

  Future<void> toggleWifiRule(int id, bool active) async {
    await _svc.toggleWifiRule(id, active);
    final updated = await _svc.getWifiRules();
    state = state.copyWith(wifiRules: updated);
    await refresh();
  }

  Future<void> addLocationRule(LocationRule rule) async {
    await _svc.addLocationRule(rule);
    final updated = await _svc.getLocationRules();
    state = state.copyWith(locationRules: updated);
    await refresh();
  }

  Future<void> deleteLocationRule(int id) async {
    await _svc.deleteLocationRule(id);
    final updated = await _svc.getLocationRules();
    state = state.copyWith(locationRules: updated);
    await refresh();
  }

  Future<void> toggleLocationRule(int id, bool active) async {
    await _svc.toggleLocationRule(id, active);
    final updated = await _svc.getLocationRules();
    state = state.copyWith(locationRules: updated);
    await refresh();
  }
}

final contextRulesProvider =
    StateNotifierProvider<ContextRulesNotifier, ContextRulesState>(
  (_) => ContextRulesNotifier(),
);
