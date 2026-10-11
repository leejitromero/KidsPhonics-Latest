import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/data/adventure_narration.dart';
import 'package:kidsphonics/data/home_narration.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';

import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/data/rhyming_jar_data.dart';
import 'package:kidsphonics/data/lesson_example_data.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

/// Evaluates dynamic getters and audio precedence before proposing removals.
/// The report is read-only; deletion is a separate reviewed step.
Set<String> requiredAssets() {
  final paths = <String>{};
  void audio(String? path) {
    if (path != null) paths.add('assets/$path');
  }

  for (final path in [
    ...homeNarrationAssets.values,
    ...adventureNarrationAssets.values,
  ]) {
    audio(path);
  }

  for (final source
      in Directory('lib').listSync(recursive: true).whereType<File>()) {
    if (!source.path.endsWith('.dart')) continue;
    final text = source.readAsStringSync();
    // Resolve literal phrases too: retry prompts are outside the word catalog.
    for (final match in RegExp(r'''['"]([^'"\r\n]+)['"]''').allMatches(text)) {
      audio(PhonicsAudioService.assetForPhrase(match[1]!));
    }
    for (final match
        in RegExp(r'''['"](assets/[^'"\$\r\n]+)['"]''').allMatches(text)) {
      if (File(match[1]!).existsSync()) paths.add(match[1]!);
    }
  }
  for (final w in gameWords) {
    paths.addAll(w.frames);
    audio(w.audioAsset);
  }
  for (final e in practiceExamples) {
    paths.addAll(e.frames);
    audio(PhonicsAudioService.assetForPhrase(e.letterAudioKey));
    audio(PhonicsAudioService.assetForPhrase(e.soundAudioKey));
    audio(PhonicsAudioService.assetForPhrase(e.wordAudioKey));
  }
  for (final w in [...cvcLessonWords, ...blendingLessonWords]) {
    if (w.imageAsset != null) paths.add(w.imageAsset!);
    audio(PhonicsAudioService.assetForPhrase(w.wordAudio));
    audio(PhonicsAudioService.assetForPhrase(w.praiseAudio));
  }
  for (final intro in ['cvc-intro', 'blend-intro']) {
    audio(PhonicsAudioService.assetForPhrase(intro));
  }
  audio(PhonicsAudioService.assetForPhrase('rhyme-intro'));
  for (final family in rhymingFamilies) {
    audio(PhonicsAudioService.assetForPhrase(family.praiseKey));
    for (final word in family.words) {
      audio(PhonicsAudioService.assetForPhrase(rhymeWordKey(word)));
    }
  }
  final service =
      File('lib/services/phonics_audio_service.dart').readAsStringSync();
  final mapping = service
      .split('static const Map<String, String> _phraseMap = {')[1]
      .split('};')[0];
  for (final m in RegExp(r"'([^']+)'\s*:").allMatches(mapping)) {
    audio(PhonicsAudioService.assetForPhrase(m[1]!));
  }
  for (var code = 97; code <= 122; code++) {
    paths.add('assets/images/letters/${String.fromCharCode(code)}.webp');
  }
  for (final name in ['wigloo', 'boopli', 'zoplet', 'jitjit']) {
    paths.addAll(
        ['assets/images/mascot_$name.webp', 'assets/images/mascot_$name.gif']);
  }
  for (final name in ['next', 'sound', 'previous']) {
    for (var i = 1; i <= (name == 'previous' ? 2 : 3); i++) {
      paths.add('assets/images/button_designs/${name}_button_$i.webp');
    }
  }
  for (var i = 1; i <= 4; i++) {
    paths.add('assets/images/answer_choices/frame-$i.webp');
  }
  for (final asset
      in Directory('assets/images/game_logos').listSync().whereType<File>()) {
    if (asset.path.endsWith('.webp')) {
      paths.add(asset.path.replaceAll('\\', '/'));
    }
  }
  paths.addAll([
    'assets/images/lesson_logos/letter_sounds.webp',
    'assets/images/lesson_logos/vowel_sounds.webp',
    'assets/images/app_icon.png'
  ]);
  for (final asset in Directory('assets/fonts').listSync().whereType<File>()) {
    if (asset.path.endsWith('.ttf') || asset.path.endsWith('-OFL.txt')) {
      paths.add(asset.path.replaceAll('\\', '/'));
    }
  }
  for (final name in [
    'win.mp3',
    'flip.mp3',
    'correct.mp3',
    'wrong.mp3',
    'tap.mp3',
    'button_click.wav',
    'backgroundtheme.mp3'
  ]) {
    paths.add('assets/audio/$name');
  }
  return paths;
}

void main() {
  test('reviewed cleanup files are absent and no unused media remain', () {
    final removed =
        jsonDecode(File('tools/removed_unused_assets.json').readAsStringSync())
            as List;
    for (final item in removed) {
      expect(File(item['path'] as String).existsSync(), isFalse,
          reason: 'Retired file: ${item['path']}');
    }
    final required = requiredAssets();
    final actual = Directory('assets')
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.replaceAll('\\', '/'))
        .toSet();
    expect(actual.difference(required), isEmpty,
        reason: 'New assets need an evaluated runtime usage before bundling.');
  });
  test('dynamic lesson, game, mascot and audio assets exist and remain bundled',
      () async {
    final needed = requiredAssets();
    final yaml = File('pubspec.yaml').readAsStringSync();
    final declared = RegExp(r'^\s+- (assets/[^\r\n]+)', multiLine: true)
        .allMatches(yaml)
        .map((m) => m[1]!.trim())
        .toList();
    for (final path in needed) {
      expect(File(path).existsSync(), isTrue, reason: path);
      expect(
          declared.any((d) =>
              path == d ||
              (d.endsWith('/') &&
                  path.substring(0, path.lastIndexOf('/') + 1) == d)),
          isTrue,
          reason: '$path must be declared');
    }
    if (const bool.fromEnvironment('AUDIT_ASSETS')) {
      final files =
          Directory('assets').listSync(recursive: true).whereType<File>();
      final unused = [
        for (final f in files)
          if (!needed.contains(f.path.replaceAll('\\', '/')))
            {
              'path': f.path.replaceAll('\\', '/'),
              'bytes': f.lengthSync(),
            }
      ];
      final report = {
        'required': needed.toList()..sort(),
        'unusedCandidates': unused,
        'unusedBytes': unused.fold<int>(0, (n, a) => n + (a['bytes'] as int)),
      };
      File('tools/asset_usage_audit.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(report));
    }
  });
}
