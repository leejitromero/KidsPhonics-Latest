import 'package:flutter/services.dart';

/// Reads the installed package so About matches the actual Android APK.
class AppBuildInfo {
  const AppBuildInfo({this.version, this.build});
  final String? version, build;
  String get label => version == null
      ? 'Version information unavailable'
      : 'Version $version${build == null ? '' : ' (build $build)'}';

  static Future<AppBuildInfo> load() async {
    try {
      final info = await const MethodChannel('kidsphonics/app_info')
          .invokeMapMethod<String, dynamic>('getInfo');
      String? value(String key) {
        final text = info?[key];
        return text is String && text.trim().isNotEmpty ? text.trim() : null;
      }

      return AppBuildInfo(version: value('version'), build: value('build'));
    } on MissingPluginException {
      return const AppBuildInfo();
    } on PlatformException {
      return const AppBuildInfo();
    }
  }
}
