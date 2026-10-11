import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/completion_celebration.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(mockProgressAudio);
  testWidgets(
      'completion fireworks animate once without blocking result actions',
      (t) async {
    var again = 0;
    await t.pumpWidget(MaterialApp(
        home: GameResultDialog(
      correct: 5,
      attempts: 5,
      earnedXp: 30,
      earnedStars: 5,
      onAgain: () => again++,
      onBack: () {},
    )));
    final fireworks = find.byKey(const ValueKey('completion-fireworks'));
    expect(fireworks, findsOneWidget);
    expect(find.text('Round complete!'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 600));
    expect(fireworks, findsOneWidget);
    expect(find.text('Play Again').hitTestable(), findsOneWidget);
    await t.tap(find.text('Play Again'));
    await t.pump();
    expect(again, 1);
    await t.pump(CompletionCelebration.duration);
    expect(fireworks, findsNothing);
    expect(find.text('Score: 5 / 5'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('only completion starts fireworks; a fresh win plays again',
      (t) async {
    final complete = ValueNotifier(false);
    addTearDown(complete.dispose);
    await t.pumpWidget(MaterialApp(
        home: ValueListenableBuilder<bool>(
      valueListenable: complete,
      builder: (_, won, __) => CompletionCelebration(
        enabled: won,
        child: const Scaffold(body: Text('Game')),
      ),
    )));
    final fireworks = find.byKey(const ValueKey('completion-fireworks'));
    expect(fireworks, findsNothing);
    complete.value = true;
    await t.pump();
    expect(fireworks, findsOneWidget);
    await t.pump(); // Start the first tick after the completion rebuild.
    await t.pump(CompletionCelebration.duration);
    await t.pumpAndSettle();
    expect(fireworks, findsNothing);
    complete.value = false;
    await t.pump();
    complete.value = true;
    await t.pump();
    expect(fireworks, findsOneWidget);
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });

  testWidgets(
      'reduced motion keeps the result and buttons without moving particles',
      (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(MaterialApp(
        home: GameResultDialog(
      correct: 5,
      attempts: 5,
      earnedXp: 30,
      earnedStars: 5,
      onAgain: () {},
      onBack: () {},
    )));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('completion-fireworks')), findsNothing);
    expect(find.text('Round complete!'), findsOneWidget);
    expect(find.text('Play Again').hitTestable(), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
