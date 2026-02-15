import 'package:json_annotation/json_annotation.dart';

part 'restriction_rules.g.dart';

// Essential apps that should be allowed by default (non-entertaining)
const List<String> defaultEssentialApps = [
  // Phone & Dialer
  'com.android.dialer',
  'com.google.android.dialer',
  'com.samsung.android.dialer',
  // Messages & SMS
  'com.google.android.apps.messaging',
  'com.android.mms',
  'com.samsung.android.messaging',
  // Contacts
  'com.android.contacts',
  'com.google.android.contacts',
  'com.samsung.android.contacts',
  // Clock & Alarms
  'com.google.android.deskclock',
  'com.android.deskclock',
  'com.samsung.android.app.clockpackage',
  // Settings
  'com.android.settings',
  // Calendar
  'com.google.android.calendar',
  'com.android.calendar',
  'com.samsung.android.calendar',
  // Calculator
  'com.google.android.calculator',
  'com.android.calculator2',
  'com.samsung.android.calculator',
  // Camera
  'com.android.camera',
  'com.android.camera2',
  'com.google.android.GoogleCamera',
  // Maps & Navigation (emergency use)
  'com.google.android.apps.maps',
  // Emergency & Safety
  'com.android.emergency',
];

@JsonSerializable()
class RestrictionRules {
  final List<String> alwaysAllowedApps;
  final String restrictionStartTime; // Format: "HH:mm"
  final String restrictionEndTime; // Format: "HH:mm"
  final bool isEnforcementEnabled;

  RestrictionRules({
    required this.alwaysAllowedApps,
    required this.restrictionStartTime,
    required this.restrictionEndTime,
    required this.isEnforcementEnabled,
  });

  factory RestrictionRules.defaultRules() {
    return RestrictionRules(
      alwaysAllowedApps: [],
      restrictionStartTime: '21:00',
      restrictionEndTime: '10:00',
      isEnforcementEnabled: false,
    );
  }

  factory RestrictionRules.fromJson(Map<String, dynamic> json) =>
      _$RestrictionRulesFromJson(json);

  Map<String, dynamic> toJson() => _$RestrictionRulesToJson(this);

  RestrictionRules copyWith({
    List<String>? alwaysAllowedApps,
    String? restrictionStartTime,
    String? restrictionEndTime,
    bool? isEnforcementEnabled,
  }) {
    return RestrictionRules(
      alwaysAllowedApps: alwaysAllowedApps ?? this.alwaysAllowedApps,
      restrictionStartTime: restrictionStartTime ?? this.restrictionStartTime,
      restrictionEndTime: restrictionEndTime ?? this.restrictionEndTime,
      isEnforcementEnabled: isEnforcementEnabled ?? this.isEnforcementEnabled,
    );
  }
}
