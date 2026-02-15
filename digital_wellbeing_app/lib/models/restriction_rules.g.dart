// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restriction_rules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestrictionRules _$RestrictionRulesFromJson(Map<String, dynamic> json) =>
    RestrictionRules(
      alwaysAllowedApps: (json['alwaysAllowedApps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      restrictionStartTime: json['restrictionStartTime'] as String,
      restrictionEndTime: json['restrictionEndTime'] as String,
      isEnforcementEnabled: json['isEnforcementEnabled'] as bool,
    );

Map<String, dynamic> _$RestrictionRulesToJson(RestrictionRules instance) =>
    <String, dynamic>{
      'alwaysAllowedApps': instance.alwaysAllowedApps,
      'restrictionStartTime': instance.restrictionStartTime,
      'restrictionEndTime': instance.restrictionEndTime,
      'isEnforcementEnabled': instance.isEnforcementEnabled,
    };
