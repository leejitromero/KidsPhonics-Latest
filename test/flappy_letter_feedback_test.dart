import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kidsphonics/models/difficulty.dart';
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
    start(WidgetTester t, ValueNotifier<bool> ticker,
        {Difficulty difficulty = Difficulty.easy}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final audio = QuizAudioHarness()..install();
  final p = await mount(
      t,
      ValueListenableBuilder<bool>(
          valueListenable: ticker,
          child: FlappyLettersScreen(difficulty: difficulty),
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

  for (final difficulty in Difficulty.values) {
    testWidgets('${difficulty.name}: name then sound fits between pipes',
        (t) async {
      final ticker = ValueNotifier(true);
      addTearDown(ticker.dispose);
      final session = await start(t, ticker, difficulty: difficulty);
      final audio = session.audio;
      expect(audio.starts, isEmpty);
      for (final letter in ['a', 'b']) {
        for (final kind in ['letter', 'sound']) {
          expect(AudioCache.instance.loadedFiles,
              contains('audio/phonics/lesson_audio/${kind}s/$kind-$letter.mp3'),
              reason: 'Register upcoming recordings before the first pipe');
        }
      }
      await clearPipes(t, session.game, 1);
      await expectStarted(t, audio, '/letters/letter-a.mp3', 1);
      await drain(t);
      expect(audio.starts, hasLength(1),
          reason: 'The phoneme must wait for actual name completion');
      await t.runAsync(() => audio.completeLetterName('A'));
      await expectStarted(t, audio, '/sounds/sound-a.mp3', 2);
      await t.runAsync(() => audio.completeSound('A'));
      await drain(t);
      await clearPipes(t, session.game, 2);
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
      final rate = audio.startRates.first;
      expect(audio.startRates, everyElement(rate));
      expect(rate, inInclusiveRange(1.0, 1.5));
      // Measure the bundled MP3 frames, so replacement recordings that no
      // longer fit the actual course timing are caught as well.
      for (var i = 0; i < 26; i++) {
        final letter = String.fromCharCode(97 + i);
        final duration = mp3Seconds('letters/letter-$letter.mp3') +
            mp3Seconds('sounds/sound-$letter.mp3');
        expect(duration / rate + .25,
            lessThan(FlappyLettersGame.spacing / session.game.speed),
            reason: '$letter needs room for both clips and decoder setup');
      }
      expect(t.widget<GameLives>(find.byType(GameLives)).lives, 3);
      expect((session.provider.xp, session.provider.stars), (0, 0));
      expect(audio.sources.where((s) => s.contains('/praise-')), isEmpty);
      await close(t, session.provider);
    });

    for (final stalledPart in ['name', 'sound']) {
      testWidgets('${difficulty.name}: a stalled $stalledPart cannot delay B',
          (t) async {
        final ticker = ValueNotifier(true);
        addTearDown(ticker.dispose);
        final session = await start(t, ticker, difficulty: difficulty);
        final audio = session.audio;
        await clearPipes(t, session.game, 1);
        await expectStarted(t, audio, '/letters/letter-a.mp3', 1);
        if (stalledPart == 'sound') {
          await t.runAsync(() => audio.completeLetterName('A'));
          await expectStarted(t, audio, '/sounds/sound-a.mp3', 2);
        }
        final before = audio.starts.length;
        final callsBefore = audio.calls.length;
        // Do not finish A. A newly cleared pipe must start B immediately,
        // rather than queue it behind the old player's completion callback.
        await clearPipes(t, session.game, 2);
        await expectStarted(t, audio, '/letters/letter-b.mp3', before + 1);
        final calls = audio.calls.skip(callsBefore).toList();
        final resume = calls.indexWhere((c) => c.startsWith('resume:'));
        expect(resume, greaterThan(0));
        final playerId = calls[resume].substring('resume:'.length);
        expect(calls.take(resume), contains('stop:$playerId'),
            reason: 'Stop the previous speech before starting the new one');
        await t.runAsync(() => audio.completeLetterName('B'));
        await expectStarted(t, audio, '/sounds/sound-b.mp3', before + 2);
        await t.runAsync(() => audio.completeSound('B'));
        await drain(t);
        expect(audio.starts, hasLength(before + 2),
            reason: 'No stale A sound may start after B');
        expect((session.provider.xp, session.provider.stars), (0, 0));
        expect(session.game.lives, 3);
        await close(t, session.provider);
      });
    }
  }

  testWidgets('Hard stays on the current letter across repeated slow playback',
      (t) async {
    final ticker = ValueNotifier(true);
    addTearDown(ticker.dispose);
    final session = await start(t, ticker, difficulty: Difficulty.hard);
    for (var passed = 1; passed <= 4; passed++) {
      await clearPipes(t, session.game, passed);
      final letter = String.fromCharCode(96 + passed);
      await expectStarted(
          t, session.audio, '/letters/letter-$letter.mp3', passed);
    }
    await t.runAsync(() => session.audio.completeLetterName('D'));
    await expectStarted(t, session.audio, '/sounds/sound-d.mp3', 5);
    await t.runAsync(() => session.audio.completeSound('D'));
    await drain(t);
    expect(session.audio.starts, [
      endsWith('/letters/letter-a.mp3'),
      endsWith('/letters/letter-b.mp3'),
      endsWith('/letters/letter-c.mp3'),
      endsWith('/letters/letter-d.mp3'),
      endsWith('/sounds/sound-d.mp3'),
    ]);
    await close(t, session.provider);
  });

  testWidgets('leaving Hard restores normal speed for other recordings',
      (t) async {
    final ticker = ValueNotifier(true);
    addTearDown(ticker.dispose);
    final session = await start(t, ticker, difficulty: Difficulty.hard);
    await clearPipes(t, session.game, 1);
    await expectStarted(t, session.audio, '/letters/letter-a.mp3', 1);
    expect(session.audio.startRates.single, greaterThan(1.0));
    await t.tap(find.byTooltip('Pause'));
    await drain(t);
    final playback =
        session.provider.phonicsAudio.playInstruction('lesson-letter-B');
    await expectStarted(t, session.audio, '/letters/letter-b.mp3', 2);
    expect(session.audio.startRates.last, 1.0);
    await t.runAsync(() => session.audio.completeLetterName('B'));
    await drain(t);
    expect(await playback, isTrue);
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
    testWidgets('$interruption cancels current speech without stale follow-up',
        (t) async {
      final ticker = ValueNotifier(true);
      addTearDown(ticker.dispose);
      final session = await start(t, ticker);
      final audio = session.audio;
      await clearPipes(t, session.game, 1);
      await expectStarted(t, audio, '/letters/letter-a.mp3', 1);
      await clearPipes(t, session.game, 2);
      await expectStarted(t, audio, '/letters/letter-b.mp3', 2);
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
      // A late completion must not start the interrupted letter's sound.
      await t.runAsync(() => audio.completeLetterName('B'));
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
          [
            endsWith('/letters/letter-a.mp3'),
            endsWith('/letters/letter-b.mp3')
          ]);
      expect((session.provider.xp, session.provider.stars), (0, 0));
      expect(t.takeException(), isNull);
      await close(t, session.provider);
    });
  }
}

// MPEG Layer III frame durations, excluding ID3 tags. No decoder or wall-clock
// sleeps are needed to check all 52 real recordings against the pipe cadence.
double mp3Seconds(String relativePath) {
  final data =
      File('assets/audio/phonics/lesson_audio/$relativePath').readAsBytesSync();
  var pos = 0;
  var seconds = 0.0;
  var frames = 0;
  if (String.fromCharCodes(data.take(3)) == 'ID3') {
    pos = 10;
    for (var i = 0; i < 4; i++) {
      pos += (data[6 + i] & 127) << (7 * (3 - i));
    }
  }
  while (pos + 4 < data.length) {
    final header = (data[pos] << 24) |
        (data[pos + 1] << 16) |
        (data[pos + 2] << 8) |
        data[pos + 3];
    final version = (header >> 19) & 3;
    final layer = (header >> 17) & 3;
    final rate = (header >> 12) & 15;
    final sample = (header >> 10) & 3;
    if (header >> 21 != 2047 ||
        version == 1 ||
        layer != 1 ||
        rate == 0 ||
        rate == 15 ||
        sample == 3) {
      pos++;
      continue;
    }
    final sampleRate = [44100, 48000, 32000][sample] ~/
        (version == 3
            ? 1
            : version == 2
                ? 2
                : 4);
    final bitrate = (version == 3
        ? [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320]
        : [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160])[rate];
    final size = (version == 3 ? 144000 : 72000) * bitrate ~/ sampleRate +
        ((header >> 9) & 1);
    if (pos + size > data.length) break;
    seconds += (version == 3 ? 1152 : 576) / sampleRate;
    frames++;
    pos += size;
  }
  expect(frames, greaterThan(0),
      reason: 'Readable MP3 frames in $relativePath');
  return seconds;
}
