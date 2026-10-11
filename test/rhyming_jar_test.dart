import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/rhyming_jar_controller.dart';
import 'package:kidsphonics/data/rhyming_jar_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'quiz_audio_harness.dart';

Future<void> flush(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await t.pump();
  }
}

String target(WidgetTester t) =>
    t.widget<Text>(find.byKey(const ValueKey('rhyme-target'))).data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  test('all ten families have three unique rhymes and supplied audio', () {
    expect(rhymingFamilies, hasLength(10));
    expect(rhymingFamilies.expand((f) => f.words).toSet(), hasLength(40));
    for (final family in rhymingFamilies) {
      expect(family.rhymes.toSet(), hasLength(3));
      for (final key in [family.praiseKey, ...family.words.map(rhymeWordKey)]) {
        final path = PhonicsAudioService.assetForPhrase(key);
        expect(path, isNotNull);
        expect(File('assets/$path').existsSync(), isTrue);
      }
      for (final d in Difficulty.values) {
        final choices = rhymingChoices(family, d);
        expect(choices, hasLength(5 + d.index * 2));
        expect(choices.toSet(), hasLength(choices.length));
        expect(choices.where(family.rhymes.contains).toSet(),
            family.rhymes.toSet());
        expect(choices, isNot(contains(family.target)));
        expect(choices, isNot(contains('UMBRELLA')));
      }
    }
    expect(Directory('assets/audio/rhyming_jar').listSync(), hasLength(51));
  });

  test('wrong choices never fill the jar; duplicate taps cannot earn energy',
      () {
    final jar = RhymingJarController(rhymingFamilies.first);
    jar.setPhase(JarPhase.choosing);
    expect(jar.pick('CAT'), isFalse);
    jar.finishFeedback();
    expect(jar.fill, 0);
    expect(jar.pick('HIP'), isTrue);
    expect(jar.pick('DIP'), isNull);
    jar.finishFeedback();
    expect(jar.fill, 1 / 3);
    expect(jar.pick('HIP'), isNull);
    jar.paused = true;
    expect(jar.pick('DIP'), isNull);
    jar.paused = false;
    for (final word in ['DIP', 'SIP']) {
      expect(jar.pick(word), isTrue);
      jar.finishFeedback();
    }
    expect(jar.phase, JarPhase.centering);
    expect(jar.fill, 1);
    jar.reset(rhymingFamilies[1]);
    expect(jar.fill, 0);
    expect(jar.phase, JarPhase.target);
    jar.dispose();
  });

  testWidgets(
      'target first, effects only on choices, praise after centering, replay and pause',
      (t) async {
    final audio = QuizAudioHarness()..install();
    final p =
        await mount(t, const RhymingWordsScreen(difficulty: Difficulty.easy));
    await flush(t);
    expect(audio.starts.last, endsWith('/rhyming_jar/intro.mp3'));
    await t.runAsync(() => audio.completeSource('/rhyming_jar/intro.mp3'));
    await flush(t);
    final word = target(t);
    final family = rhymingFamilies.singleWhere((f) => f.target == word);
    expect(audio.starts.last,
        endsWith('/rhyming_jar/word-${word.toLowerCase()}.mp3'));
    // Choices stay locked until the target finishes.
    await t.tap(find.byKey(ValueKey('rhyme-choice-${family.rhymes.first}')));
    expect(p.stars, 0);
    await t.runAsync(() =>
        audio.completeSource('/rhyming_jar/word-${word.toLowerCase()}.mp3'));
    await flush(t);
    final wrong = t
        .widgetList<Text>(find.byWidgetPredicate((w) =>
            w is Text &&
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('rhyme-choice-')))
        .map((w) => w.data!)
        .firstWhere((w) => !family.rhymes.contains(w));
    await t.tap(find.byKey(ValueKey('rhyme-choice-$wrong')));
    await flush(t);
    expect(audio.starts.last, endsWith('/audio/wrong.mp3'));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('0 / 3 rhymes'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await t.tap(find.byKey(ValueKey('rhyme-choice-${family.rhymes[i]}')));
      await flush(t);
      expect(audio.starts.last, endsWith('/audio/correct.mp3'));
      if (i == 0) {
        await t.tap(find.byTooltip('Pause'));
        await t.pump(const Duration(seconds: 2));
        expect(find.text('0 / 3 rhymes'), findsOneWidget);
        await t.tap(find.byTooltip('Resume'));
        await t.pump();
      }
      await t.pump(const Duration(milliseconds: 900));
      if (i < 2) expect(find.text('${i + 1} / 3 rhymes'), findsOneWidget);
    }
    expect(find.text('Next Jar'), findsNothing);
    await t.pump(const Duration(milliseconds: 1000));
    await flush(t);
    expect(audio.starts.last,
        endsWith('/rhyming_jar/praise-${word.toLowerCase()}.mp3'));
    expect(find.text('Next Jar'), findsNothing);
    final revealed = t
        .widgetList<ActionChip>(find.byType(ActionChip))
        .map((c) => (c.label as Text).data);
    expect(revealed, family.words);
    await t.runAsync(() =>
        audio.completeSource('/rhyming_jar/praise-${word.toLowerCase()}.mp3'));
    await flush(t);
    expect(find.text('Next Jar'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 600));
    await t.runAsync(() =>
        t.state<GameSessionUi>(find.byType(RhymingWordsScreen)).rewardsSaved);
    expect(p.stars, 3);
    expect(p.xp, 24);
    expect(p.dailyActivity.values.single.questionsAnswered, 4);
    await t.tap(find.widgetWithText(ActionChip, family.rhymes.last));
    await flush(t);
    expect(audio.starts.last,
        endsWith('/rhyming_jar/word-${family.rhymes.last.toLowerCase()}.mp3'));
    await t.runAsync(() => audio.completeSource(
        '/rhyming_jar/word-${family.rhymes.last.toLowerCase()}.mp3'));
    await flush(t);
    await t.tap(find.text('Next Jar'));
    await flush(t);
    expect(target(t), isNot(word));
    expect(find.text('0 / 3 rhymes'), findsOneWidget);
    await close(t, p);
    p.phonicsAudio.dispose();
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'completed jars persist rewards once and Play Again resets progress',
      (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p =
        await mount(t, const RhymingWordsScreen(difficulty: Difficulty.easy));
    await t.runAsync(() => p.toggleVoice());
    await t.runAsync(() => p.toggleSfx());
    await flush(t);
    final seen = <String>{};
    for (var jar = 0; jar < 5; jar++) {
      final word = target(t);
      expect(seen.add(word), isTrue);
      final family = rhymingFamilies.singleWhere((f) => f.target == word);
      for (final rhyme in family.rhymes) {
        await t.tap(find.byKey(ValueKey('rhyme-choice-$rhyme')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 150));
      }
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      await flush(t);
      await t.tap(find.text(jar == 4 ? 'Finish' : 'Next Jar'));
      await flush(t);
    }
    expect(find.byType(GameResultDialog), findsOneWidget);
    expect(p.stars, 15);
    expect(p.xp, 140);
    expect(p.dailyActivity.values.single.questionsAnswered, 15);
    await t.tap(find.text('Play Again'));
    await flush(t);
    expect(find.text('0 / 3 rhymes'), findsOneWidget);
    final state = t.state<GameSessionUi>(find.byType(RhymingWordsScreen));
    expect(state.earnedXp, 0);
    expect(state.earnedStars, 0);
    expect(p.xp, 140);
    await close(t, p);
    expect(t.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    testWidgets('hard clouds and reveal fit $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final boundary = GlobalKey();
      final p = await mount(
          t,
          RepaintBoundary(
              key: boundary,
              child: const RhymingWordsScreen(difficulty: Difficulty.hard)));
      await t.runAsync(() => p.toggleVoice());
      await t.runAsync(() => p.toggleSfx());
      await flush(t);
      final family = rhymingFamilies.singleWhere((f) => f.target == target(t));
      expect(find.byType(GestureDetector).evaluate().length,
          greaterThanOrEqualTo(9));
      if (const bool.fromEnvironment('CAPTURE_UI') && size.width == 390) {
        await t.runAsync(() async {
          await Future.wait(t
              .widgetList<Image>(find.byType(Image))
              .map((im) => precacheImage(im.image, boundary.currentContext!)));
        });
        await t.pump();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui_previews/rhyming_jar.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      for (final word in family.rhymes) {
        await t.tap(find.byKey(ValueKey('rhyme-choice-$word')));
        await t.pump();
        await t.pump(const Duration(milliseconds: 150));
      }
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      await flush(t);
      expect(find.text('Next Jar'), findsOneWidget);
      expect(t.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_UI') && size.width == 390) {
        await t.pump();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/ui_previews/rhyming_jar_full.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await close(t, p);
    });
  }
}
