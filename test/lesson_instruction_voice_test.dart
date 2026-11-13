import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/letter_recognition_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/vowel_sounds_screen.dart';
import 'package:kidsphonics/services/audio_service.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/lesson_swipe_navigation.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuizAudioHarness audio;
  setUp(() {
    SharedPreferences.setMockInitialValues({'sfx': false});
    mockProgressAudio();
    audio = QuizAudioHarness()..install();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  Future<void> waitFor(WidgetTester t, bool Function() ready) async {
    for (var i = 0; i < 150 && !ready(); i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
    expect(ready(), isTrue, reason: 'Started: ${audio.starts}');
  }

  Future<void> drain(WidgetTester t) async {
    for (var i = 0; i < 5; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)));
      await t.pump();
    }
  }

  Future<void> finish(WidgetTester t, AppProvider provider) async {
    await close(t, provider);
    await t.runAsync(() async {
      PhonicsAudioService().dispose();
      AudioService().dispose();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await t.pump();
  }

  for (final scenario in [
    (
      name: 'Recognition',
      page: const LetterRecognitionScreen(),
      phrase: 'lesson-instruction-recognition-1',
      file: 'letter_recognition_1.mp3',
      manual: 'letter-a.mp3',
      next: 'letter-b.mp3',
      third: 'letter-c.mp3'
    ),
    (
      name: 'Letter Sounds',
      page: const LetterSoundsScreen(),
      phrase: 'lesson-instruction-sounds-1',
      file: 'letter_sounds_1.mp3',
      manual: 'sound-a.mp3',
      next: 'sound-b.mp3',
      third: 'sound-c.mp3'
    ),
    (
      name: 'Short Vowels',
      page: const VowelSoundsScreen(),
      phrase: 'lesson-instruction-vowels-1',
      file: 'short_vowel_1.mp3',
      manual: 'sound-a.mp3',
      next: 'sound-e.mp3',
      third: 'sound-i.mp3'
    ),
  ]) {
    test('${scenario.name} recording is registered and bundled', () async {
      final asset = PhonicsAudioService.assetForPhrase(scenario.phrase);
      expect(asset, 'audio/lesson_instructions/${scenario.file}');
      expect((await rootBundle.load('assets/$asset')).lengthInBytes,
          greaterThan(1000));
    });

    testWidgets('${scenario.name} plays once and speaker interrupts the intro',
        (t) async {
      final p = await mount(t, scenario.page);
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.file)));
      expect(PhonicsAudioService().currentPhrase, scenario.phrase);
      expect(p.getLetterProgress('A').nameListens, 0);
      expect(p.getLetterProgress('A').soundListens, 0);
      final speaker = find
          .descendant(
              of: find.byType(AudioButton),
              matching: find.byType(OutlinedButton))
          .first;
      await t.ensureVisible(speaker);
      await t.pump();
      await t.tap(speaker);
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.manual)));
      await t.runAsync(() => audio.completeSource(scenario.manual));
      await drain(t);
      expect(
          audio.starts.where((s) => s.endsWith(scenario.file)), hasLength(1));
      expect(p.xp, 0);
      expect(p.stars, 0);
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    testWidgets(
        '${scenario.name} Next interrupts without replaying the instruction',
        (t) async {
      final p = await mount(t, scenario.page);
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.file)));
      await t.tap(find.widgetWithText(OutlinedButton, 'Next'));
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.next)));
      await drain(t);
      expect(
          audio.starts.where((s) => s.endsWith(scenario.file)), hasLength(1));
      expect(p.xp, 0);
      expect(p.stars, 0);
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    testWidgets('${scenario.name} automatically speaks after both intro parts',
        (t) async {
      final p = await mount(t, scenario.page);
      for (final file in [
        scenario.file,
        scenario.file.replaceFirst('_1.', '_2.')
      ]) {
        await waitFor(t, () => audio.starts.any((s) => s.endsWith(file)));
        expect(audio.starts.where((s) => s.endsWith(scenario.manual)), isEmpty);
        await t.runAsync(() => audio.completeSource(file));
      }
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.manual)));
      expect(p.getLetterProgress('A').nameListens, 0);
      expect(p.getLetterProgress('A').soundListens, 0);
      await t.runAsync(() => audio.completeSource(scenario.manual));
      await waitFor(
          t,
          () =>
              p.getLetterProgress('A').nameListens +
                  p.getLetterProgress('A').soundListens ==
              1);
      expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    testWidgets(
        '${scenario.name} rapid browsing cancels old feedback and manual replay works',
        (t) async {
      final p = await mount(t, scenario.page);
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.file)));
      await t.tap(find.widgetWithText(OutlinedButton, 'Next'));
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.next)));
      await t.tap(find.widgetWithText(OutlinedButton, 'Next'));
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.third)));
      expect(
          p.getLetterProgress('A').nameListens +
              p.getLetterProgress('A').soundListens,
          0);
      final skipped = scenario.name == 'Short Vowels' ? 'E' : 'B';
      expect(
          p.getLetterProgress(skipped).nameListens +
              p.getLetterProgress(skipped).soundListens,
          0);
      final speaker = find
          .descendant(
              of: find.byType(AudioButton),
              matching: find.byType(OutlinedButton))
          .first;
      await t.ensureVisible(speaker);
      await t.tap(speaker);
      await waitFor(
          t,
          () =>
              audio.starts.where((s) => s.endsWith(scenario.third)).length ==
              2);
      await t.runAsync(() => audio.completeSource(scenario.third));
      final selected = scenario.name == 'Short Vowels' ? 'I' : 'C';
      await waitFor(
          t,
          () =>
              p.getLetterProgress(selected).nameListens +
                  p.getLetterProgress(selected).soundListens ==
              1);
      expect((p.xp, p.stars), (0, 0));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    testWidgets(
        '${scenario.name} swipe back and direct selection automatically speak the displayed letter',
        (t) async {
      final p = await mount(t, scenario.page);
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.file)));
      final rect = t.getRect(find.byType(LessonSwipeNavigation));
      await t.dragFrom(
          Offset(rect.center.dx + 80, rect.top + 35), const Offset(-160, 0));
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.next)));
      await t.dragFrom(
          Offset(rect.center.dx - 80, rect.top + 35), const Offset(160, 0));
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.manual)));
      if (scenario.name == 'Short Vowels') {
        await t.ensureVisible(find.byKey(const ValueKey('vowel-tab-I')));
        await t.tap(find.byKey(const ValueKey('vowel-tab-I')));
      } else {
        await t.tap(find.byIcon(Icons.grid_view_rounded));
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
        await waitFor(t, () => PhonicsAudioService().currentPhrase == null);
        await t.tap(find.byKey(const ValueKey('pick-letter-C')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 350));
      }
      await waitFor(
          t, () => audio.starts.any((s) => s.endsWith(scenario.third)));
      expect(
          audio.starts.where((s) => s.endsWith(scenario.file)), hasLength(1));
      expect((p.xp, p.stars), (0, 0));
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    for (final action in ['mute', 'background', 'route']) {
      testWidgets(
          '${scenario.name} automatic letter stops on $action without recording a listen',
          (t) async {
        final p = await mount(t, scenario.page);
        await waitFor(
            t, () => audio.starts.any((s) => s.endsWith(scenario.file)));
        await t.tap(find.widgetWithText(OutlinedButton, 'Next'));
        await waitFor(
            t, () => audio.starts.any((s) => s.endsWith(scenario.next)));
        if (action == 'mute') {
          var saved = false;
          unawaited(p.toggleVoice().then((_) => saved = true));
          await waitFor(t, () => saved);
        } else if (action == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        } else {
          unawaited(Navigator.of(t.element(find.byType(AudioButton))).push(
              MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Covered')))));
          await t.pump(const Duration(milliseconds: 350));
        }
        await waitFor(t, () => PhonicsAudioService().currentPhrase == null);
        await t.runAsync(() => audio.completeSource(scenario.next));
        await drain(t);
        final selected = scenario.name == 'Short Vowels' ? 'E' : 'B';
        expect(
            p.getLetterProgress(selected).nameListens +
                p.getLetterProgress(selected).soundListens,
            0);
        if (action == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        }
        expect(t.takeException(), isNull);
        await finish(t, p);
      });
    }

    testWidgets('${scenario.name} muted entry does not play an instruction',
        (t) async {
      SharedPreferences.setMockInitialValues({'sfx': false, 'voice': false});
      final p = await mount(t, scenario.page);
      await drain(t);
      expect(audio.starts.where((s) => s.contains('/lesson_instructions/')),
          isEmpty);
      expect(t.takeException(), isNull);
      await finish(t, p);
    });

    for (final action in ['mute', 'background', 'route']) {
      testWidgets(
          '${scenario.name} stops on $action and ignores late completion',
          (t) async {
        final p = await mount(t, scenario.page);
        await waitFor(
            t, () => audio.starts.any((s) => s.endsWith(scenario.file)));
        if (action == 'mute') {
          var saved = false;
          unawaited(p.toggleVoice().then((_) => saved = true));
          await waitFor(t, () => saved);
        } else if (action == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        } else {
          unawaited(Navigator.of(t.element(find.byType(AudioButton))).push(
              MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Covered')))));
          await t.pump(const Duration(milliseconds: 350));
          await drain(t);
        }
        await waitFor(t, () => PhonicsAudioService().currentPhrase == null);
        await t.runAsync(() => audio.completeSource(scenario.file));
        if (action == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        } else if (action == 'route') {
          t.state<NavigatorState>(find.byType(Navigator)).pop();
          await t.pump(const Duration(milliseconds: 350));
        }
        await drain(t);
        expect(
            audio.starts.where((s) => s.endsWith(scenario.file)), hasLength(1));
        expect(t.takeException(), isNull);
        await finish(t, p);
      });
    }
  }
}
