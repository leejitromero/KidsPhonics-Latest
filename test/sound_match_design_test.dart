import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/sound_match_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/quick_choice_art.dart';
import 'package:kidsphonics/widgets/sound_match_design.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  testWidgets('every difficulty has an orb and three distinct letter choices',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    for (final difficulty in Difficulty.values) {
      final p = await mount(t, SoundMatchScreen(difficulty: difficulty));
      await t.pumpAndSettle();
      expect(find.byType(GameWordPicture), findsNothing);
      expect(find.byType(MagicalSoundOrb), findsOneWidget);
      expect(find.byType(GameAnswerButton), findsNWidgets(3));
      expect(
          t
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .maxScrollExtent,
          0);
      final audio = t.widget<AudioButton>(find.byType(AudioButton));
      final answer =
          letterChoiceLabel(audio.phrase.replaceFirst('lesson-sound-', ''));
      final choices =
          t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton));
      expect(choices.map((w) => w.label).toSet().length, 3);
      expect(choices.map((w) => w.label), contains(answer));
      expect(choices.map((w) => w.colorIndex).toSet(), {0, 1, 2});
      expect(
          t.getRect(find.byType(MagicalSoundOrb)).bottom,
          lessThan(
              t.getRect(find.byKey(const ValueKey('sound-match-hear'))).top));
      expect(
          t.getRect(find.byKey(const ValueKey('sound-match-hear'))).bottom,
          lessThan(t
              .getRect(find.byKey(const ValueKey('sound-match-choices')))
              .top));
      for (final choice in find.byType(GameAnswerButton).evaluate()) {
        final rect = t.getRect(find.byWidget(choice.widget));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.bottom, lessThan(844));
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    }
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(844, 390), 1.0),
    (const Size(800, 1024), 1.3),
  ]) {
    testWidgets('orb and choices fit $size with text scale $scale', (t) async {
      await t.binding.setSurfaceSize(size);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final p =
          await mount(t, const SoundMatchScreen(difficulty: Difficulty.hard));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.ensureVisible(find.byKey(const ValueKey('sound-match-choices')));
      await t.pumpAndSettle();
      for (final choice in find.byType(GameAnswerButton).evaluate()) {
        final rect = t.getRect(find.byWidget(choice.widget));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('orb and Hear Sound share playback, busy state and cancellation',
      (t) async {
    // Earlier layout tests create the singleton with the default platform
    // cache. Recreate it after installing the local recording harness.
    await t.runAsync(() async {
      PhonicsAudioService().dispose();
      await Future<void>.delayed(Duration.zero);
    });
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const SoundMatchScreen());
    await t.pumpAndSettle();
    final phrase = t.widget<AudioButton>(find.byType(AudioButton)).phrase;
    final letter = phrase.replaceFirst('lesson-sound-', '');
    final suffix = '/sounds/sound-${letter.toLowerCase()}.mp3';
    await t.tap(find.byKey(const ValueKey('magical-sound-orb')));
    for (var i = 0;
        i < 40 && !audio.starts.any((s) => s.endsWith(suffix));
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(audio.starts.where((s) => s.endsWith(suffix)).length, 1,
        reason:
            'sources=${audio.sources}, voice=${p.voiceEnabled}, active=${t.binding.lifecycleState}, playing=${t.widget<MagicalSoundOrb>(find.byType(MagicalSoundOrb)).playing}');
    expect(t.widget<MagicalSoundOrb>(find.byType(MagicalSoundOrb)).playing,
        isTrue);
    expect(t.widget<MagicalSoundOrb>(find.byType(MagicalSoundOrb)).onPressed,
        isNull);
    expect(t.widget<QuickAudioButton>(find.byType(QuickAudioButton)).onPressed,
        isNull);
    await t.runAsync(() => audio.completeSound(letter));
    for (var i = 0;
        i < 100 &&
            t.widget<MagicalSoundOrb>(find.byType(MagicalSoundOrb)).playing;
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(t.widget<MagicalSoundOrb>(find.byType(MagicalSoundOrb)).playing,
        isFalse);
    await t.tap(find.byKey(const ValueKey('sound-match-hear')));
    for (var i = 0;
        i < 40 && audio.starts.where((s) => s.endsWith(suffix)).length < 2;
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(audio.starts.where((s) => s.endsWith(suffix)).length, 2);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    expect(t.widget<MagicalSoundOrb>(find.byType(MagicalSoundOrb)).playing,
        isFalse);
    expect(find.text('Audio unavailable. Please try again.'), findsNothing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await close(t, p);
    await t.runAsync(() async {
      p.phonicsAudio.dispose();
      await Future<void>.delayed(Duration.zero);
    });
  });

  testWidgets(
      'orb pulses during motion and pauses with reduced motion or background',
      (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: false);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 240,
                    height: 240,
                    child:
                        MagicalSoundOrb(playing: true, onPressed: () {}))))));
    final transform = find.descendant(
        of: find.byType(MagicalSoundOrb), matching: find.byType(Transform));
    final initial = t.widget<Transform>(transform).transform.storage[0];
    await t.pump(const Duration(milliseconds: 600));
    final pulsing = t.widget<Transform>(transform).transform.storage[0];
    expect(pulsing, isNot(initial));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(milliseconds: 600));
    expect(t.widget<Transform>(transform).transform.storage[0], pulsing);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    await t.pump();
    expect(t.widget<Transform>(transform).transform.storage[0], 1);
    await t.pumpWidget(const SizedBox());
  });

  if (const bool.fromEnvironment('CAPTURE_UI')) {
    testWidgets('capture sound orb, retry and success previews', (t) async {
      await t.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      final p = await mount(
          t,
          RepaintBoundary(
              key: boundary,
              child: const SoundMatchScreen(difficulty: Difficulty.easy)));
      await t.runAsync(() => p.toggleSfx());
      await t.runAsync(() async {
        await Future.wait(t
            .widgetList<Image>(find.byType(Image))
            .map((w) => precacheImage(w.image, boundary.currentContext!)));
      });
      await t.pumpAndSettle();
      Future<void> capture(String name) => t.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('build/ui_previews/sound_match_$name.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
      await capture('orb');
      final answer = letterChoiceLabel(t
          .widget<AudioButton>(find.byType(AudioButton))
          .phrase
          .replaceFirst('lesson-sound-', ''));
      final wrong = t
          .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))
          .firstWhere((w) => w.label != answer);
      wrong.onPressed!();
      await t.pump();
      await capture('retry');
      await t.pump(const Duration(milliseconds: 650));
      t
          .widget<GameAnswerButton>(find.byWidgetPredicate(
              (w) => w is GameAnswerButton && w.label == answer))
          .onPressed!();
      await t.pump();
      await capture('correct');
      await close(t, p);
    });
  }
}
