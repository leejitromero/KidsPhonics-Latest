import 'package:flutter/services.dart';

/// Reads the installed package, displaying only its public major/minor version.
class AppBuildInfo {
  const AppBuildInfo({this.version, this.build});
  final String? version, build;
  String get label {
    final installed = version;
    if (installed == null) return 'Version information unavailable';
    final publicVersion =
        installed.split('+').first.split('.').take(2).join('.');
    return 'Version $publicVersion';
  }

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
