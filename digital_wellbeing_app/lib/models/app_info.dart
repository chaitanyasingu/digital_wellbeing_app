import 'package:json_annotation/json_annotation.dart';

part 'app_info.g.dart';

@JsonSerializable()
class AppInfo {
  final String packageName;
  final String appName;
  final bool isSystemApp;

  AppInfo({
    required this.packageName,
    required this.appName,
    required this.isSystemApp,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) =>
      _$AppInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AppInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppInfo &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}
