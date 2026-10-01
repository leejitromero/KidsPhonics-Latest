import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/memory_game_screen.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });

  String timer(WidgetTester t) =>
      t.widget<Text>(find.byKey(const ValueKey('memory-timer'))).data!;
  Finder card(int i) => find.byKey(ValueKey('memory-$i'));

  testWidgets('a pending pair resolves before timeout and restart', (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p =
        await mount(t, const MemoryGameScreen(difficulty: Difficulty.easy));
    await t.tap(card(0));
    await t.pump();
    await t.pump(const Duration(milliseconds: 59500));
    await t.tap(card(1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(timer(t), 'Time 0:00');
    expect(find.text('Time is up!'), findsNothing);
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 850));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Time is up!'), findsOneWidget);
    final session = t.state(find.byType(MemoryGameScreen)) as GameSessionUi;
    expect(session.scoredAttempts, 1);
    await t.tap(find.text('Try Again'));
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(timer(t), 'Time 1:00');
    expect(session.scoredAttempts, 0);
    expect(find.byType(GameWordPicture), findsNothing);
    await close(t, p);
  });

  for (final difficulty in Difficulty.values) {
    testWidgets(
        '${difficulty.name} starts only on first flip; warning and timeout',
        (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      t.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await mount(t, MemoryGameScreen(difficulty: difficulty));
      final seconds = switch (difficulty) {
        Difficulty.easy => 60,
        Difficulty.medium => 90,
        Difficulty.hard => 120
      };
      final initial = timer(t);
      await t.pump(const Duration(seconds: 20));
      expect(timer(t), initial);
      await t.tap(card(0));
      await t.pump();
      await t.pump(Duration(seconds: seconds - 10));
      expect(timer(t), 'Time 0:10');
      expect(
          t
              .widget<Text>(find.byKey(const ValueKey('memory-timer')))
              .style!
              .color,
          const Color(0xFFB85D08));
      await t.pump(const Duration(seconds: 10));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Time is up!'), findsOneWidget);
      expect(t.widget<ElevatedButton>(card(1)).onPressed, isNull);
      await t.tap(find.text('Continue Practice'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(timer(t), 'Practice \u2022 No timer');
      expect(
          find.descendant(of: card(0), matching: find.byType(GameWordPicture)),
          findsOneWidget);
      expect(t.widget<ElevatedButton>(card(1)).onPressed, isNotNull);
      await t.pump(const Duration(minutes: 3));
      expect(find.text('Time is up!'), findsNothing);
      await close(t, p);
    });
  }

  testWidgets(
      'pause, background, and help preserve remaining time; retry resets',
      (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p =
        await mount(t, const MemoryGameScreen(difficulty: Difficulty.easy));
    await t.tap(card(0));
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    expect(timer(t), 'Time 0:55');
    await t.tap(find.byTooltip('Pause game'));
    await t.pump();
    await t.pump(const Duration(seconds: 20));
    expect(timer(t), 'Paused 0:55');
    await t.tap(find.text('Resume game'));
    await t.pump();
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 20));
    expect(timer(t), 'Time 0:55');
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(seconds: 5));
    expect(timer(t), 'Time 0:50');
    final context = t.element(find.byType(MemoryGameScreen));
    showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(title: const Text('Help'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close help'))
            ]));
    await t.pump();
    await t.pump(const Duration(seconds: 20));
    expect(timer(t), 'Time 0:50');
    await t.tap(find.text('Close help'));
    await t.pump();
    await t.pump(const Duration(seconds: 51));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Try Again'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(timer(t), 'Time 1:00');
    expect(find.byType(GameWordPicture), findsNothing);
    await t.pump(const Duration(seconds: 20));
    expect(timer(t), 'Time 1:00');
    await close(t, p);
  });
}
