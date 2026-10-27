import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/flappy_letters_game.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

Future<void> drain(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump();
  }
}

Future<void> expectStarted(
    WidgetTester t, QuizAudioHarness audio, String suffix, int count) async {
  for (var i = 0; i < 100 && audio.starts.length < count; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump();
  }
  expect(audio.starts, hasLength(count));
  expect(audio.starts.last, endsWith(suffix));
}

Future<({AppProvider provider, FlappyLettersGame game, QuizAudioHarness audio})>
    start(WidgetTester t, ValueNotifier<bool> ticker) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final audio = QuizAudioHarness()..install();
  final p = await mount(
      t,
      ValueListenableBuilder<bool>(
          valueListenable: ticker,
          child: const FlappyLettersScreen(),
          builder: (_, enabled, child) =>
              TickerMode(enabled: enabled, child: child!)));
  await audio.finishGameIntro(t, 'flappy_letters.mp3');
  await t.tap(find.text('Start flying'));
  await t.pump();
  final painter = t
      .widget<CustomPaint>(find.byWidgetPredicate((w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_CoursePainter'))
      .painter;
  return (
    provider: p,
    game: (painter as dynamic).game as FlappyLettersGame,
    audio: audio
  );
}

Future<void> steerFrame(WidgetTester t, FlappyLettersGame game) async {
  if (game.y > game.gapCenter(game.passed) + 10 && game.velocity > 0) {
    await t.tapAt(
        t.getRect(find.byKey(const ValueKey('flight-play-area'))).center);
  }
  await t.pump(const Duration(milliseconds: 20));
}

Future<void> clearPipes(
    WidgetTester t, FlappyLettersGame game, int count) async {
  for (var frame = 0;
      frame < 700 && game.passed < count && game.state == FlightState.flying;
      frame++) {
    await steerFrame(t, game);
  }
  expect(game.passed, count);
  expect(game.lives, 3);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
    mockProgressAudio();
  });

  testWidgets('native completion serializes A name, A sound, B name, B sound',
      (t) async {
    final ticker = ValueNotifier(true);
    addTearDown(ticker.dispose);
    final session = await start(t, ticker);
    final audio = session.audio;
    await clearPipes(t, session.game, 1);
    await expectStarted(t, audio, '/letters/letter-a.mp3', 1);
    // Keep A's recording pending while actually flying through the next pipe.
    await clearPipes(t, session.game, 2);
    await drain(t);
    expect(audio.starts, hasLength(1),
        reason: 'A sound and the queued B must wait for A name to finish');
    await t.runAsync(() => audio.completeLetterName('A'));
    await expectStarted(t, audio, '/sounds/sound-a.mp3', 2);
    for (var i = 0; i < 50; i++) {
      await steerFrame(t, session.game);
    }
    await drain(t);
    expect(audio.starts, hasLength(2),
        reason: 'Elapsed time cannot interrupt A sound to start B');
    await t.runAsync(() => audio.completeSound('A'));
    await expectStarted(t, audio, '/letters/letter-b.mp3', 3);
    await t.runAsync(() => audio.completeLetterName('B'));
    await expectStarted(t, audio, '/sounds/sound-b.mp3', 4);
    await t.runAsync(() => audio.completeSound('B'));
    await drain(t);
    expect(audio.starts, [
      endsWith('/letters/letter-a.mp3'),
      endsWith('/sounds/sound-a.mp3'),
      endsWith('/letters/letter-b.mp3'),
      endsWith('/sounds/sound-b.mp3'),
    ]);
    expect(t.widget<GameLives>(find.byType(GameLives)).lives, 3);
    expect((session.provider.xp, session.provider.stars), (0, 0));
    expect(
        audio.sources.where(
            (s) => s.contains('game_narration') || s.contains('/praise-')),
        isEmpty);
    await close(t, session.provider);
  });

  for (final interruption in [
    'pause',
    'mute',
    'background',
    'route',
    'ticker',
    'collision',
    'dispose'
  ]) {
    testWidgets('$interruption cancels the pending sound and queued letters',
        (t) async {
      final ticker = ValueNotifier(true);
      addTearDown(ticker.dispose);
      final session = await start(t, ticker);
      final audio = session.audio;
      await clearPipes(t, session.game, 1);
      await expectStarted(t, audio, '/letters/letter-a.mp3', 1);
      await clearPipes(t, session.game, 2);
      final context = t.element(find.byType(FlappyLettersScreen));
      if (interruption == 'pause') {
        await t.tap(find.byTooltip('Pause'));
      } else if (interruption == 'mute') {
        await t.runAsync(() => session.provider.toggleVoice());
      } else if (interruption == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      } else if (interruption == 'route') {
        showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(title: Text('Covered')));
      } else if (interruption == 'ticker') {
        ticker.value = false;
      } else if (interruption == 'collision') {
        for (var i = 0;
            i < 100 && session.game.state == FlightState.flying;
            i++) {
          await t.pump(const Duration(milliseconds: 20));
        }
        expect(session.game.state, FlightState.hit);
      } else {
        await t.pumpWidget(const SizedBox());
      }
      await t.pump();
      await drain(t);
      // A late native callback must not start A sound or the queued B name.
      await t.runAsync(() => audio.completeLetterName('A'));
      if (interruption == 'mute') {
        await t.runAsync(() => session.provider.toggleVoice());
      } else if (interruption == 'background') {
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      } else if (interruption == 'route') {
        Navigator.of(context).pop();
      } else if (interruption == 'ticker') {
        ticker.value = true;
      }
      await drain(t);
      expect(
          audio.starts
              .where((s) => s.contains('/letters/') || s.contains('/sounds/')),
          [endsWith('/letters/letter-a.mp3')]);
      expect((session.provider.xp, session.provider.stars), (0, 0));
      expect(t.takeException(), isNull);
      await close(t, session.provider);
    });
  }
}
