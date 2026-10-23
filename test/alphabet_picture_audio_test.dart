import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/alphabet_picture_data.dart';
import 'package:kidsphonics/data/lesson_instruction_scripts.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/alphabet_pictures_screen.dart';
import 'package:kidsphonics/widgets/lesson_control_button.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    mockProgressAudio();
    audio = QuizAudioHarness()..install();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  String suffix(String letter) => '/${alphabetPictureRecordings[letter]}';
  int starts(String letter) =>
      audio.starts.where((s) => s.endsWith(suffix(letter))).length;
  Finder speaker() => find.descendant(
      of: find.byKey(const ValueKey('alphabet-picture-sound')),
      matching: find.byType(OutlinedButton));
  bool speakerReady(WidgetTester t) =>
      t
          .widget<LessonControlButton>(
              find.byKey(const ValueKey('alphabet-picture-sound')))
          .onPressed !=
      null;
  Future<void> waitFor(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
    expect(ready(), true, reason: 'Started recordings: ${audio.starts}');
  }

  Future<void> drain(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
  }

  Future<void> tap(WidgetTester t, Finder target) async {
    await t.ensureVisible(target);
    await t.pump(const Duration(milliseconds: 350));
    await t.tap(target);
    await t.pump();
  }

  const intro = 'lesson-instruction-alphabet-pictures';
  String instruction(WidgetTester t) => t
      .widget<Text>(find.byKey(const ValueKey('lesson-instruction-text')))
      .data!;
  Future<void> finishIntro(WidgetTester t, {bool verify = false}) async {
    for (var part = 0; part < 2; part++) {
      final file = lessonInstructionRecordings[intro]![part];
      await waitFor(t, () => audio.starts.any((s) => s.endsWith('/$file')));
      expect(instruction(t), lessonInstructionScripts[intro]![part]);
      expect(starts('A'), 0);
      if (verify) {
        // Exceed the recording's duration without delivering completion.
        await t.pump(const Duration(seconds: 6));
        expect(instruction(t), lessonInstructionScripts[intro]![part]);
        expect(starts('A'), 0);
      }
      await t.runAsync(() => audio.completeSource('/$file'));
    }
    await waitFor(t, () => starts('A') == 1);
    expect(instruction(t), lessonInstructionDefaults[intro]);
  }

  test('both instruction recordings are bundled unchanged', () async {
    final report = jsonDecode(
        File('tools/alphabet_picture_instruction_import.json')
            .readAsStringSync()) as Map;
    expect(report['recordings'], 2);
    expect(report['mpegFramesValidated'], true);
    for (final item in report['files'] as List) {
      final bytes = await rootBundle.load(item['path'] as String);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          item['sha256']);
      expect(item['mpegFrames'], greaterThan(0));
    }
  });

  test(
      'all 26 sentence recordings are bundled byte-for-byte including lowercase k',
      () async {
    final report = jsonDecode(
            File('tools/alphabet_picture_audio_import.json').readAsStringSync())
        as Map;
    expect(report['recordings'], 26);
    expect(report['mpegFramesValidated'], true);
    expect(alphabetPictureRecordings.keys.join(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    for (final item in report['files'] as List) {
      final letter = item['letter'] as String;
      final bytes = await rootBundle.load(item['path'] as String);
      expect(alphabetPictureRecordings[letter],
          (item['path'] as String).substring(7));
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          item['sha256']);
      expect(item['mpegFrames'], greaterThan(0));
    }
    expect(alphabetPictureRecordings['K'], 'audio/alphabet_pictures/k.mp3');
    expect(alphabetPictureAudioAsset('alphabet-picture-AA'), isNull);
  });

  testWidgets('every A-Z picture autoplays its sentence and Sound repeats Z',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final boundary = GlobalKey();
    final p = await mount(t,
        RepaintBoundary(key: boundary, child: const AlphabetPicturesScreen()));
    await finishIntro(t, verify: true);
    expect(p.getLetterProgress('A').viewCount, 1);
    for (final entry in alphabetPictures) {
      await waitFor(t, () => starts(entry.letter) == 1);
      expect(find.text(entry.sentence), findsOneWidget);
      expect(find.byKey(ValueKey('alphabet-picture-${entry.letter}')),
          findsOneWidget);
      expect(p.getLetterProgress(entry.letter).wordListens, 0);
      await t.runAsync(() => audio.completeSource(suffix(entry.letter)));
      await waitFor(t, () => speakerReady(t));
      expect(p.getLetterProgress(entry.letter).wordListens, 1);
      if (entry.letter == 'B') {
        await capture(t, boundary, 'alphabet_pictures_audio_390');
      }
      if (entry.letter != 'Z') {
        await tap(t, find.widgetWithText(OutlinedButton, 'Next'));
      }
    }
    expect(
        t
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Next'))
            .onPressed,
        isNull);
    await tap(t, speaker());
    await waitFor(t, () => starts('Z') == 2);
    await t.runAsync(() => audio.completeSource(suffix('Z')));
    await waitFor(t, () => speakerReady(t));
    expect(p.getLetterProgress('Z').wordListens, 2);
    expect(p.quickCheckLetters.where((l) => l.wordListens > 0).length, 26);
    expect((p.xp, p.stars, p.overallMasteredCount, p.streak), (0, 0, 0, 0));
    expect(p.practicedLessonCount, 1);
    final restored = AppProvider();
    await t.runAsync(() => restored.ready);
    expect(restored.getLetterProgress('Z').wordListens, 2);
    restored.dispose();
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets(
      'rapid Next cancels old sentences and counts only completed playback',
      (t) async {
    final p = await mount(t, const AlphabetPicturesScreen());
    await finishIntro(t);
    await waitFor(t, () => starts('A') == 1);
    await tap(t, find.widgetWithText(OutlinedButton, 'Next'));
    await waitFor(t, () => starts('B') == 1);
    await tap(t, find.widgetWithText(OutlinedButton, 'Next'));
    await waitFor(t, () => starts('C') == 1);
    expect(p.getLetterProgress('A').wordListens, 0);
    expect(p.getLetterProgress('B').wordListens, 0);
    await t.runAsync(() => audio.completeSource(suffix('C')));
    await waitFor(t, () => speakerReady(t));
    expect(p.getLetterProgress('C').wordListens, 1);
    expect(audio.calls.where((call) => call.startsWith('stop:')).length,
        greaterThanOrEqualTo(2));
    await close(t, p);
  });

  testWidgets('the alphabet picker stops playback then autoplays the chosen Z',
      (t) async {
    final p = await mount(t, const AlphabetPicturesScreen());
    await finishIntro(t);
    await waitFor(t, () => starts('A') == 1);
    await tap(t, find.text('A\u2013Z Grid'));
    await t.pump(const Duration(milliseconds: 350));
    expect(p.phonicsAudio.currentPhrase, isNull);
    final z = find.byKey(const ValueKey('pick-letter-Z'));
    await t.scrollUntilVisible(z, 120,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('alphabet-pictures-grid')),
            matching: find.byType(Scrollable)));
    await t.pump(const Duration(milliseconds: 350));
    await t.ensureVisible(z);
    await t.pump(const Duration(milliseconds: 350));
    await t.tap(z);
    await t.pump(const Duration(milliseconds: 350));
    await waitFor(t, () => starts('Z') == 1);
    expect(find.text('Z is for zebra.'), findsOneWidget);
    expect(p.getLetterProgress('A').wordListens, 0);
    await t.runAsync(() => audio.completeSource(suffix('Z')));
    await waitFor(t, () => speakerReady(t));
    expect(p.getLetterProgress('Z').wordListens, 1);
    await close(t, p);
  });

  testWidgets('Voice Off and backgrounding stop speech without counting it',
      (t) async {
    final p = await mount(t, const AlphabetPicturesScreen());
    await finishIntro(t);
    await waitFor(t, () => starts('A') == 1);
    unawaited(p.toggleVoice());
    await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
    await t.runAsync(() => audio.completeSource(suffix('A')));
    await drain(t);
    expect(p.getLetterProgress('A').wordListens, 0);
    unawaited(p.toggleVoice());
    await waitFor(t, () => p.voiceEnabled && speakerReady(t));
    await t.pump();
    await tap(t, speaker());
    await waitFor(t, () => starts('A') == 2);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
    await t.runAsync(() => audio.completeSource(suffix('A')));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await drain(t);
    expect(starts('A'), 2);
    expect(p.getLetterProgress('A').wordListens, 0);
    await close(t, p);
  });

  for (final action in [
    'Next',
    'Sound',
    'Grid',
    'Voice Off',
    'Background',
    'Cover',
    'Dispose'
  ]) {
    testWidgets('$action interrupts the intro without later autoplay',
        (t) async {
      final p = await mount(t, const AlphabetPicturesScreen());
      final first = lessonInstructionRecordings[intro]!.first;
      await waitFor(t, () => audio.starts.any((s) => s.endsWith('/$first')));
      expect(p.getLetterProgress('A').viewCount, 1);
      switch (action) {
        case 'Next':
          await tap(t, find.widgetWithText(OutlinedButton, 'Next'));
          await waitFor(t, () => starts('B') == 1);
        case 'Sound':
          await tap(t, speaker());
          await waitFor(t, () => starts('A') == 1);
        case 'Grid':
          await tap(t, find.text('A\u2013Z Grid'));
          await t.pump(const Duration(milliseconds: 350));
          await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
          Navigator.of(t.element(
                  find.byKey(const ValueKey('alphabet-pictures-grid'))))
              .pop();
          await t.pump(const Duration(milliseconds: 350));
        case 'Voice Off':
          unawaited(p.toggleVoice());
          await waitFor(
              t, () => !p.voiceEnabled && p.phonicsAudio.currentPhrase == null);
        case 'Background':
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
          await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        case 'Cover':
          final nav =
              Navigator.of(t.element(find.byType(AlphabetPicturesScreen)));
          nav.push(MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Other page'))));
          await t.pump(const Duration(milliseconds: 350));
          await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
          nav.pop();
          await t.pump(const Duration(milliseconds: 350));
        case 'Dispose':
          await close(t, p);
      }
      await drain(t);
      await t.pump(const Duration(seconds: 12));
      await drain(t);
      expect(audio.starts.where((s) => s.endsWith('/alphabet_picture_2.mp3')),
          isEmpty);
      expect(starts('A'), action == 'Sound' ? 1 : 0);
      expect(starts('B'), action == 'Next' ? 1 : 0);
      if (action != 'Dispose') {
        expect(p.quickCheckLetters.where((l) => l.wordListens > 0), isEmpty);
        expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
        await close(t, p);
      }
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('covering or leaving the lesson cancels its pending sentence',
      (t) async {
    final p = await mount(t, const AlphabetPicturesScreen());
    await finishIntro(t);
    await waitFor(t, () => starts('A') == 1);
    final navigator =
        Navigator.of(t.element(find.byType(AlphabetPicturesScreen)));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Other page'))));
    await t.pump(const Duration(milliseconds: 350));
    await waitFor(t, () => p.phonicsAudio.currentPhrase == null);
    await t.runAsync(() => audio.completeSource(suffix('A')));
    await drain(t);
    expect(p.getLetterProgress('A').wordListens, 0);
    navigator.pop();
    await t.pump(const Duration(milliseconds: 350));
    expect(starts('A'), 1);
    await tap(t, speaker());
    await waitFor(t, () => starts('A') == 2);
    await close(t, p);
    expect(p.phonicsAudio.currentPhrase, isNull);
    expect(t.takeException(), isNull);
  });
}
