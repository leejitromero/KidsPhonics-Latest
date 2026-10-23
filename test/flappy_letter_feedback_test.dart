import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/flappy_letters_game.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'quiz_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'clearing successive pipes immediately plays letter recordings without praise',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final audio = QuizAudioHarness()..install();
    final p = await mount(t, const FlappyLettersScreen());
    await t.runAsync(() => p.toggleSfx());
    await t.pump(const Duration(milliseconds: 500));
    if (find.text('Skip').evaluate().isNotEmpty) {
      await t.tap(find.text('Skip'));
      await t.pump(const Duration(milliseconds: 500));
    }
    for (var i = 0;
        i < 100 &&
            !audio.starts.any(
                (s) => s.endsWith('/game_instructions/flappy_letters.mp3'));
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(
        audio.starts
            .where((s) => s.endsWith('/game_instructions/flappy_letters.mp3')),
        hasLength(1));
    await t.runAsync(
        () => audio.completeSource('/game_instructions/flappy_letters.mp3'));
    await t.pump();
    await t.tap(find.text('Start flying'));
    await t.pump();
    // Steer the bird through actual course ticks; no direct model mutation.
    final painter = t
        .widget<CustomPaint>(find.byWidgetPredicate((w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_CoursePainter'))
        .painter;
    final game = (painter as dynamic).game as FlappyLettersGame;
    var heard = 0;
    for (var frame = 0; frame < 520 && game.passed < 2; frame++) {
      if (game.y > game.gapCenter(game.passed) + 10 && game.velocity > 0) {
        await t.tapAt(
            t.getRect(find.byKey(const ValueKey('flight-play-area'))).center);
      }
      await t.pump(const Duration(milliseconds: 20));
      if (game.passed > heard) {
        final letter = String.fromCharCode(96 + game.passed);
        // Give the asset loader real IO time before the next simulated pipe.
        for (var i = 0;
            i < 40 &&
                !audio.starts
                    .any((s) => s.endsWith('/letters/letter-$letter.mp3'));
            i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)));
          await t.pump();
        }
        expect(audio.starts.last, endsWith('/letters/letter-$letter.mp3'));
        heard = game.passed;
      }
    }
    expect(game.passed, 2);
    expect(t.widget<GameLives>(find.byType(GameLives)).lives, 3);
    for (var i = 0;
        i < 40 && !audio.starts.any((s) => s.endsWith('/letters/letter-b.mp3'));
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(audio.starts.where((s) => s.contains('/letters/')),
        [endsWith('/letters/letter-a.mp3'), endsWith('/letters/letter-b.mp3')]);
    expect(
        audio.sources.where(
            (s) => s.contains('game_narration') || s.contains('/praise-')),
        isEmpty);
    await t.tap(find.byTooltip('Pause'));
    await t.pump();
    expect(find.text('Taking a little break'), findsOneWidget);
    await close(t, p);
  });
}
