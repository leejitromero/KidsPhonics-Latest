import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/lesson_instruction_scripts.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/vowel_sounds_screen.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUpAll(() async {
    final fonts = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      fonts.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await fonts.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    mockProgressAudio();
    audio = QuizAudioHarness()..install();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  String text(WidgetTester t) => t
      .widget<Text>(find.byKey(const ValueKey('lesson-instruction-text')))
      .data!;
  Future<void> drain(WidgetTester t) async {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }

  Future<void> until(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await drain(t);
    }
    expect(ready(), isTrue, reason: 'Started recordings: ${audio.starts}');
  }

  Future<void> finish(WidgetTester t, AppProvider p) async {
    await close(t, p);
    await t.runAsync(() async {
      PhonicsAudioService().dispose();
      AudioService().dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await t.pump();
  }

  test('all ten supplied recordings are bundled unchanged; old intros removed',
      () async {
    final imports = jsonDecode(
        File('tools/lesson_instruction_audio_import.json')
            .readAsStringSync()) as List;
    expect(imports, hasLength(10));
    for (final entry in imports) {
      final asset = 'assets/audio/lesson_instructions/${entry['file']}';
      final bytes = await rootBundle.load(asset);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          entry['sha256']);
    }
    for (final entry in lessonInstructionRecordings.entries) {
      expect(entry.value, hasLength(2));
      expect(lessonInstructionScripts[entry.key], hasLength(2));
      for (var part = 1; part <= 2; part++) {
        expect(PhonicsAudioService.assetForPhrase('${entry.key}-$part'),
            'audio/lesson_instructions/${entry.value[part - 1]}');
      }
      expect(PhonicsAudioService.assetForPhrase(entry.key), isNull);
    }
    final removed = jsonDecode(
        File('tools/lesson_instruction_removed_audio.json')
            .readAsStringSync()) as List;
    expect(removed, hasLength(5));
    final bundledAssets =
        (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets();
    for (final entry in removed) {
      expect(File(entry['path'] as String).existsSync(), isFalse);
      expect(bundledAssets, isNot(contains(entry['path'])));
    }
    expect(
        Directory('assets/audio/lesson_instructions')
            .listSync()
            .whereType<File>(),
        hasLength(lessonInstructionRecordings.values
            .fold<int>(0, (total, files) => total + files.length)));
  });

  for (final scenario in [
    (
      page: const LetterRecognitionScreen(),
      key: 'lesson-instruction-recognition'
    ),
    (page: const LetterSoundsScreen(), key: 'lesson-instruction-sounds'),
    (page: const VowelSoundsScreen(), key: 'lesson-instruction-vowels'),
    (page: const CvcWordsScreen(), key: 'cvc-intro'),
    (page: const BlendingSoundsScreen(), key: 'blend-intro'),
  ]) {
    testWidgets(
        '${scenario.key}: sentence advances only on matching MP3 completion',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, scenario.page);
      final recordings = lessonInstructionRecordings[scenario.key]!;
      final scripts = lessonInstructionScripts[scenario.key]!;
      final hint = lessonInstructionDefaults[scenario.key]!;
      for (var part = 0; part < 2; part++) {
        await until(
            t, () => audio.starts.any((s) => s.endsWith(recordings[part])));
        expect(text(t), scripts[part]);
        expect(audio.starts.where((s) => s.contains('/lesson_instructions/')),
            hasLength(part + 1));
        final ink =
            t.getRect(find.byKey(const ValueKey('lesson-instruction-text')));
        final opening =
            t.getRect(find.byKey(const ValueKey('lesson-dialogue-content')));
        expect(opening.inflate(.01).contains(ink.topLeft), isTrue);
        expect(opening.inflate(.01).contains(ink.bottomRight), isTrue);
        // Longer than a reading timer: the text must stay on the playing clip.
        await t.pump(const Duration(seconds: 10));
        expect(text(t), scripts[part]);
        expect(audio.starts.where((s) => s.contains('/lesson_instructions/')),
            hasLength(part + 1));
        await t.runAsync(() => audio.completeSource(recordings[part]));
      }
      await until(t, () => text(t) == hint);
      await t.pump(const Duration(seconds: 10));
      expect(text(t), hint);
      expect(audio.starts.where((s) => s.contains('/lesson_instructions/')),
          hasLength(2));
      expect((p.xp, p.stars), (0, 0));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    testWidgets(
        '${scenario.key}: voice off keeps both full sentences readable then defaults',
        (t) async {
      SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final p = await mount(t, scenario.page);
      final scripts = lessonInstructionScripts[scenario.key]!;
      final hint = lessonInstructionDefaults[scenario.key]!;
      await drain(t);
      expect(text(t), scripts.first);
      for (var i = 0; i < 15 && text(t) != scripts.last; i++) {
        await drain(t);
        await t.pump(const Duration(seconds: 1));
      }
      expect(text(t), scripts.last);
      for (var i = 0; i < 15 && text(t) != hint; i++) {
        await drain(t);
        await t.pump(const Duration(seconds: 1));
      }
      expect(text(t), hint);
      expect(audio.starts, isEmpty);
      expect(t.takeException(), isNull);
      await finish(t, p);
    });
  }
}
