import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';
import 'package:kidsphonics/data/alphabet_picture_data.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/data/game_instruction_scripts.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/data/home_narration.dart';
import 'package:kidsphonics/data/adventure_narration.dart';
import 'package:kidsphonics/data/lesson_instruction_scripts.dart';
import 'package:kidsphonics/data/lesson_example_data.dart';
import 'package:kidsphonics/data/rhyming_jar_data.dart';
import 'package:kidsphonics/data/updated_scene.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/day_cycle_background.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/loading_screen_art.dart';

String _path(File file) => file.path.replaceAll('\\', '/');

/// Follow local imports/exports from the application's real entry point.
Set<String> runtimeSources() {
  final pending = ['lib/main.dart'];
  final sources = <String>{};
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (!sources.add(path)) continue;
    final text = File(path).readAsStringSync();
    for (final match in RegExp(r'''(?:import|export|part)\s+['"]([^'"]+)['"]''')
        .allMatches(text)) {
      final target = match[1]!;
      if (target.startsWith('dart:')) continue;
      final resolved = target.startsWith('package:kidsphonics/')
          ? 'lib/${target.substring('package:kidsphonics/'.length)}'
          : target.startsWith('package:')
              ? null
              : Uri.file(path).resolve(target).toFilePath(windows: false);
      if (resolved != null && File(resolved).existsSync()) {
        pending.add(resolved);
      }
    }
  }
  return sources;
}

/// These are demonstrably superseded, even though old constants/tests still
/// mention them. Review their consumers before changing this list.
const supersededAssets = {
  'assets/images/games_menu/games_card_frame.png':
      'GameZoneCard paints the compact glossy cards; only a legacy constant and artwork test use this frame.',
};

/// Literal image/bundle loads are requirements even when their files are absent.
/// Unused historical constants in imported files are not executable loads.
Set<String> literalAssetLoads(String source) => RegExp(
        r'''(?:Image\.asset|(?:Exact)?AssetImage|rootBundle\.load(?:String|StructuredData)?)\s*\(\s*['"](assets/[^'"\$\r\n]+)['"]''')
    .allMatches(source)
    .map((match) => match[1]!)
    .toSet();

Set<String> evaluatedRuntimeAssets(
    {Map<String, String> sourceOverrides = const {}}) {
  final paths = <String>{};
  void audio(String? value) {
    if (value != null) paths.add('assets/$value');
  }

  for (final source in runtimeSources()) {
    final text = (sourceOverrides[source] ?? File(source).readAsStringSync())
        .replaceAll(r'$sceneAssets', sceneAssets)
        .replaceAll(r'$lessonHeaderAssets', 'assets/images/lesson_header');
    paths.addAll(literalAssetLoads(text));
    for (final match
        in RegExp(r'''['"](assets/[^'"\$\r\n]+)['"]''').allMatches(text)) {
      if (File(match[1]!).existsSync()) paths.add(match[1]!);
    }
    for (final match in RegExp(r'''['"]([^'"\r\n]+)['"]''').allMatches(text)) {
      audio(PhonicsAudioService.assetForPhrase(match[1]!));
    }
  }
  for (final picture in alphabetPictures) {
    paths.addAll(picture.frames);
    audio(alphabetPictureRecordings[picture.letter]);
  }
  for (final word in gameWords) {
    paths.addAll(word.frames);
    audio(word.audioAsset);
  }
  for (final example in practiceExamples) {
    paths.addAll(example.frames);
    for (final phrase in [
      example.letterAudioKey,
      example.soundAudioKey,
      example.wordAudioKey
    ]) {
      audio(PhonicsAudioService.assetForPhrase(phrase));
    }
  }
  for (final word in [...cvcLessonWords, ...blendingLessonWords]) {
    if (word.imageAsset != null) paths.add(word.imageAsset!);
    audio(PhonicsAudioService.assetForPhrase(word.wordAudio));
    audio(PhonicsAudioService.assetForPhrase(word.praiseAudio));
  }
  for (final intro in lessonInstructionScripts.keys) {
    for (var part = 1; part <= 2; part++) {
      audio(PhonicsAudioService.assetForPhrase('$intro-$part'));
    }
  }
  for (final script in gameInstructionScripts.values) {
    audio(PhonicsAudioService.assetForPhrase('game-instruction-${script.key}'));
  }
  for (final family in rhymingFamilies) {
    audio(PhonicsAudioService.assetForPhrase(family.praiseKey));
    for (final word in family.words) {
      audio(PhonicsAudioService.assetForPhrase(rhymeWordKey(word)));
    }
  }
  final mapping = File('lib/services/phonics_audio_service.dart')
      .readAsStringSync()
      .split('static const Map<String, String> _phraseMap = {')[1]
      .split('};')[0];
  for (final match in RegExp(r"'([^']+)'\s*:").allMatches(mapping)) {
    // Resolve precedence: the new game/lesson recording may shadow this map.
    audio(PhonicsAudioService.assetForPhrase(match[1]!));
  }
  paths.addAll([
    ...homeNarrationAssets.values.map((v) => 'assets/$v'),
    ...adventureNarrationAssets.values.map((v) => 'assets/$v'),
    ...KidsNavigationArt.assets,
    ...loadingScreenFrames,
    ...mascotTalkingFrames(false),
    ...mascotTalkingFrames(true),
    for (final category in ['home', 'lesson', 'games', 'progress', 'parent'])
      ...DayCycleBackground.framesFor(category),
    for (final character in ['boy', 'girl']) ...[
      for (var i = 1; i <= 10; i++) '$sceneAssets/${character}_$i.png',
      '$sceneAssets/profile_frame_$character.png',
      'assets/images/school_home/${character}_wave.png',
      'assets/images/lesson_header/${character}_profile.png',
      'assets/images/lesson_header/instructions_dialogue_$character.png',
    ],
    for (var i = 1; i <= 4; i++) '$sceneAssets/dialogue_box_$i.png',
    for (var code = 97; code <= 122; code++)
      'assets/images/letters/${String.fromCharCode(code)}.webp',
    for (final name in ['next', 'previous', 'sound'])
      for (var i = 1; i <= (name == 'previous' ? 2 : 3); i++)
        'assets/images/button_designs/${name}_button_$i.webp',
    for (var i = 1; i <= 4; i++) 'assets/images/answer_choices/frame-$i.webp',
    for (final name in [
      'frame_alphabet_milstone',
      'frame_mybadge',
      'frame_rewards_contain',
      'frame_mytreasure'
    ])
      'assets/images/progress_collection/$name.png',
    'assets/images/app_icon.png',
    for (final name in [
      'win.mp3',
      'flip.mp3',
      'correct.mp3',
      'wrong.mp3',
      'tap.mp3',
      'button_click.wav',
      'backgroundtheme.mp3'
    ])
      'assets/audio/$name',
  ]);
  final yaml = File('pubspec.yaml').readAsStringSync();
  paths.addAll(RegExp(r'asset: (assets/fonts/[^\s]+)')
      .allMatches(yaml)
      .map((m) => m[1]!));
  paths.addAll(Directory('assets/fonts')
      .listSync()
      .whereType<File>()
      .where((file) =>
          file.path.endsWith('-OFL.txt') || file.path.endsWith('.ttf'))
      .map(_path));
  // A retained, tested compatibility screen still loads this illustration.
  paths.add('assets/images/lesson_logos/tricky_letters.webp');
  paths.removeAll(supersededAssets.keys);
  return paths;
}

Map<String, dynamic> currentAssetInventory() {
  final required = evaluatedRuntimeAssets();
  final actual =
      Directory('assets').listSync(recursive: true).whereType<File>().toList();
  final candidates = [
    for (final file in actual)
      if (!required.contains(_path(file)))
        {
          'path': _path(file),
          'bytes': file.lengthSync(),
          'sha256':
              sha256.convert(file.readAsBytesSync()).toString().toUpperCase(),
          'reason': supersededAssets[_path(file)] ??
              'No active entry-point reference or evaluated dynamic image/audio mapping.',
        }
  ];
  return {
    'runtimeSources': runtimeSources().toList()..sort(),
    'required': required.where((p) => File(p).existsSync()).toList()..sort(),
    'preexistingMissing': required.where((p) => !File(p).existsSync()).toList()
      ..sort(),
    'unusedCandidates': candidates,
    'unusedBytes':
        candidates.fold<int>(0, (n, item) => n + (item['bytes'] as int)),
  };
}

void main() {
  test('review runtime media and verify cleanup preserves every retained byte',
      () {
    final report = currentAssetInventory();
    if (const bool.fromEnvironment('AUDIT_CLEANUP')) {
      File('build/runtime_asset_cleanup_audit.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(report));
      return;
    }
    final manifest = File('tools/runtime_asset_cleanup.json');
    expect(manifest.existsSync(), isTrue,
        reason: 'Run the read-only audit before deleting anything.');
    final reviewed = jsonDecode(manifest.readAsStringSync()) as Map;
    expect(report['unusedCandidates'], isEmpty);
    expect(report['preexistingMissing'], isEmpty,
        reason:
            'Every evaluated runtime path must exist; historical missing paths are no longer an allowance.');
    final required = (report['required'] as List).cast<String>().toSet();
    // The launcher icon was explicitly replaced after the cleanup. Keep the
    // original cleanup record and require the exact approved replacement hash.
    final iconReplacement =
        jsonDecode(File('tools/app_icon_import.json').readAsStringSync())
            as Map;
    expect(iconReplacement['path'], 'assets/images/app_icon.png');
    final backgroundFix = jsonDecode(
        File('tools/icon_lock_background_fix.json').readAsStringSync()) as Map;
    final lockReplacement = (backgroundFix['assets'] as List).singleWhere(
        (item) => item['path'] == 'assets/images/games_locl.png') as Map;
    final loadingImport =
        jsonDecode(File('tools/loading_screen_import.json').readAsStringSync())
            as Map;
    final quizIntro = (jsonDecode(
                File('tools/phonics_quiz_audio_import.json').readAsStringSync())
            as List)
        .singleWhere((item) =>
            item['path'] ==
            'assets/audio/game_instructions/phonics_quiz.mp3') as Map;
    final retiredLoading = {
      for (final item in loadingImport['retired'] as List)
        item['path'] as String: item['sha256'],
    };
    expect(
        retiredLoading.keys,
        unorderedEquals([
          'assets/images/app_mascot.png',
          'assets/images/app_mascot.gif',
        ]));
    for (final item in reviewed['retained'] as List) {
      final path = item['path'] as String;
      if (retiredLoading.containsKey(path)) {
        expect(retiredLoading[path], item['sha256']);
        expect(File(path).existsSync(), isFalse);
        continue;
      }
      expect(required, contains(path));
      var expectedHash = item['sha256'];
      if (path == iconReplacement['path']) {
        expect(iconReplacement['previousSha256'], expectedHash);
        expectedHash = iconReplacement['sha256'];
      }
      if (path == lockReplacement['path']) {
        expect(lockReplacement['previousSha256'], expectedHash);
        expectedHash = lockReplacement['sha256'];
      }
      if (path == quizIntro['path']) {
        expect(quizIntro['previousSha256'], expectedHash);
        expectedHash = quizIntro['sha256'];
      }
      expect(
          sha256.convert(File(path).readAsBytesSync()).toString().toUpperCase(),
          expectedHash,
          reason:
              'An active image, font or recording must not change during unused-file cleanup: $path');
    }
    for (final item in reviewed['removed'] as List) {
      expect(File(item['path'] as String).existsSync(), isFalse);
    }
    for (final item in loadingImport['frames'] as List) {
      final file = File(item['path'] as String);
      expect(required, contains(item['path']));
      expect(sha256.convert(file.readAsBytesSync()).toString().toUpperCase(),
          item['sha256'],
          reason: 'Preserve the supplied loading frame bytes.');
    }
  });
}
