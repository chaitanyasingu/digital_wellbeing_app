// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppInfo _$AppInfoFromJson(Map<String, dynamic> json) => AppInfo(
  packageName: json['packageName'] as String,
  appName: json['appName'] as String,
  isSystemApp: json['isSystemApp'] as bool,
);

Map<String, dynamic> _$AppInfoToJson(AppInfo instance) => <String, dynamic>{
  'packageName': instance.packageName,
  'appName': instance.appName,
  'isSystemApp': instance.isSystemApp,
};
