import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum SpeechMicrophonePermission { granted, denied, settingsRequired }

/// Device boundary kept injectable for permission and late-callback tests.
abstract class SpeechPracticeService {
  Future<SpeechMicrophonePermission> requestPermission();
  Future<bool> initialize(
      {required void Function(String) onStatus,
      required void Function(String) onError});
  Future<List<String>> locales();
  Future<void> listen(
      {required void Function(String, bool) onResult,
      required String localeId});
  Future<void> stop();
  Future<bool> openSettings();
}

class DeviceSpeechPracticeService implements SpeechPracticeService {
  final _speech = stt.SpeechToText();
  @override
  Future<SpeechMicrophonePermission> requestPermission() async {
    final permission = await Permission.microphone.request();
    if (permission.isGranted) return SpeechMicrophonePermission.granted;
    return permission.isPermanentlyDenied || permission.isRestricted
        ? SpeechMicrophonePermission.settingsRequired
        : SpeechMicrophonePermission.denied;
  }

  @override
  Future<bool> initialize(
          {required void Function(String) onStatus,
          required void Function(String) onError}) =>
      _speech.initialize(
          onStatus: onStatus, onError: (error) => onError(error.errorMsg));
  @override
  Future<List<String>> locales() async =>
      (await _speech.locales()).map((locale) => locale.localeId).toList();
  @override
  Future<void> listen(
          {required void Function(String, bool) onResult,
          required String localeId}) =>
      _speech.listen(
          onResult: (result) =>
              onResult(result.recognizedWords, result.finalResult),
          listenOptions: stt.SpeechListenOptions(
              listenFor: const Duration(seconds: 5),
              pauseFor: const Duration(seconds: 2),
              localeId: localeId));
  @override
  Future<void> stop() => _speech.stop();
  @override
  Future<bool> openSettings() => openAppSettings();
}

/// Match complete recognized words, never a substring or a different spelling.
/// Easier tiers accept the target within a phrase; Hard requires that word alone.
bool matchesSpokenWord(String target, String recognized,
    {required bool strict}) {
  List<String> words(String value) => RegExp(r"[a-z]+(?:'[a-z]+)?")
      .allMatches(value.toLowerCase())
      .map((m) => m[0]!)
      .toList();
  final expected = words(target);
  final heard = words(recognized);
  if (expected.isEmpty || heard.isEmpty) return false;
  if (strict) return expected.join(' ') == heard.join(' ');
  for (var i = 0; i <= heard.length - expected.length; i++) {
    if (heard.sublist(i, i + expected.length).join(' ') == expected.join(' ')) {
      return true;
    }
  }
  return false;
}

String? englishSpeechLocale(List<String> locales) {
  for (final preferred in ['en_US', 'en_PH', 'en_GB']) {
    for (final locale in locales) {
      if (locale.replaceAll('-', '_').toLowerCase() ==
          preferred.toLowerCase()) {
        return locale;
      }
    }
  }
  for (final locale in locales) {
    if (locale.toLowerCase() == 'en' ||
        locale.toLowerCase().startsWith('en_') ||
        locale.toLowerCase().startsWith('en-')) {
      return locale;
    }
  }
  return null;
}
