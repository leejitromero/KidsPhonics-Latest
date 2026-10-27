import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/screens/picture_word_match_screen.dart';
import 'package:kidsphonics/screens/phonics_quiz_screen.dart';
import 'package:kidsphonics/screens/word_builder_screen.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/game_design.dart';
import 'learner_ui_test.dart' show mount, close, flushWrites;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  test('restored win and flip effects are included in the asset bundle',
      () async {
    for (final name in ['win', 'flip']) {
      final path = 'assets/audio/$name.mp3';
      final bundled = await rootBundle.load(path);
      expect(bundled.lengthInBytes, greaterThan(1000));
      expect(bundled.buffer.asUint8List(), File(path).readAsBytesSync());
    }
  });

  for (final preview in [false, true]) {
    testWidgets(
        'Memory ${preview ? 'preview' : 'timer'} pauses under the time-limit ticker cover',
        (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final active = ValueNotifier(true);
      final p = await mount(
          t,
          ValueListenableBuilder<bool>(
              valueListenable: active,
              child: const MemoryGameScreen(),
              builder: (_, enabled, child) =>
                  TickerMode(enabled: enabled, child: child!)));
      String clock() =>
          t.widget<Text>(find.byKey(const ValueKey('memory-timer'))).data!;
      if (preview) {
        await t.pump(const Duration(seconds: 1));
      } else {
        await t.pump(const Duration(seconds: 3));
        await t.pump();
        await t.tap(find.byKey(const ValueKey('memory-0')));
        await t.pump();
        await t.pump(const Duration(seconds: 5));
      }
      final before = clock();
      active.value = false;
      await t.pump();
      await t.pump(const Duration(seconds: 20));
      active.value = true;
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(clock(), before);
      if (preview) {
        expect(find.text('Remember the pictures! 2'), findsOneWidget);
        await t.pump(const Duration(seconds: 2));
        await t.pump();
        expect(find.byKey(const ValueKey('memory-preview')), findsNothing);
        expect(clock(), 'Time 1:30');
      } else {
        expect(clock(), 'Time 1:25');
        await t.pump(const Duration(seconds: 5));
        expect(clock(), 'Time 1:20');
      }
      await close(t, p);
      p.phonicsAudio.dispose();
      active.dispose();
    });
  }

  for (final (name, page) in <(String, Widget)>[
    ('Picture Match', const PictureWordMatchScreen()),
    ('Phonics Quiz', const PhonicsQuizScreen()),
    ('Word Builder', const WordBuilderScreen()),
  ]) {
    for (final interruption in [
      'background',
      'dialog',
      'ticker cover',
      'access'
    ]) {
      testWidgets(
          '$name stops manual word audio on $interruption and allows replay',
          (t) async {
        await t.binding.setSurfaceSize(const Size(390, 844));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final audio = QuizAudioHarness()..install();
        final active = ValueNotifier(true);
        final p = await mount(
            t,
            ValueListenableBuilder<bool>(
                valueListenable: active,
                child: page,
                builder: (_, enabled, child) =>
                    TickerMode(enabled: enabled, child: child!)));
        await t.runAsync(() => p.toggleVoice());
        await t.pump();
        final button = find.byWidgetPredicate(
            (w) => w is ForestAudioButton && w.label == 'Hear Word');
        await t.ensureVisible(button);
        await t.tap(button);
        for (var i = 0; i < 20; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
          await t.pump();
        }
        final phrase = p.phonicsAudio.currentPhrase;
        expect(phrase, isNotNull);
        final context = t.element(find.byType(AudioButton));
        if (interruption == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        } else if (interruption == 'dialog') {
          showDialog<void>(
              context: context,
              builder: (_) => const AlertDialog(title: Text('Covered')));
        } else if (interruption == 'access') {
          await t.runAsync(() async {
            await p.parentAuth.setup('2580', '2580');
            await p.toggleGameAccess();
          });
        } else {
          active.value = false;
        }
        await t.pump();
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pump();
        expect(p.phonicsAudio.currentPhrase, isNull);
        expect(find.text('Listening…', skipOffstage: false), findsNothing);
        expect(
            find.text('Audio unavailable. Please try again.',
                skipOffstage: false),
            findsNothing);
        if (interruption == 'background') {
          t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        } else if (interruption == 'dialog') {
          Navigator.pop(context);
        } else if (interruption == 'access') {
          await t.runAsync(() => p.toggleGameAccess());
        } else {
          active.value = true;
        }
        await t.pump(const Duration(milliseconds: 400));
        final control = t.widget<ForestAudioButton>(find.byWidgetPredicate(
            (w) => w is ForestAudioButton && w.label == 'Hear Word'));
        expect(control.onPressed, isNotNull);
        control.onPressed!();
        for (var i = 0; i < 10; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
          await t.pump();
        }
        expect(p.phonicsAudio.currentPhrase, phrase);
        await t.runAsync(() => audio
            .completeSource('/${PhonicsAudioService.assetForPhrase(phrase!)}'));
        await t.pump();
        await close(t, p);
        p.phonicsAudio.dispose();
        active.dispose();
      });
    }
  }

  testWidgets(
      'Sound Match counts retry accuracy and awards each completed task once',
      (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p = await mount(t, const SoundMatchScreen());
    final answer =
        t.widget<AudioButton>(find.byType(AudioButton)).phrase.split('-').last;
    final choices =
        t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton));
    final wrong =
        choices.firstWhere((w) => w.label != (answer == 'Q' ? 'Qu' : answer));
    wrong.onPressed!();
    wrong.onPressed!();
    await t.pump(const Duration(milliseconds: 650));
    await t.pump();
    final correct = t.widget<GameAnswerButton>(find.byWidgetPredicate((w) =>
        w is GameAnswerButton && w.label == (answer == 'Q' ? 'Qu' : answer)));
    correct.onPressed!();
    correct.onPressed!();
    await t.pump();
    await flushWrites(t);
    final session = t.state(find.byType(SoundMatchScreen)) as GameSessionUi;
    expect(
        (session.scoredAttempts, session.correctAttempts, session.earnedStars),
        (2, 1, 1));
    expect(p.dailyActivity.values.single.questionsAnswered, 2);
    expect(p.dailyActivity.values.single.correctAnswers, 1);
    expect(p.stars, 1);
    expect(p.xp, 8); // Default Medium retains round(5 * 1.5).
    await close(t, p);
    p.phonicsAudio.dispose();
  });
}
