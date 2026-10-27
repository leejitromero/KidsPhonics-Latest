import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/widgets/game_tutorial.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUp(mockProgressAudio);
  testWidgets(
      'help cannot open while a game action is pending, including a stale tap',
      (tester) async {
    SharedPreferences.setMockInitialValues({'gameTutorialV1.memoryFlip': true});
    var busy = false;
    await tester.pumpWidget(MaterialApp(
        home: GameTutorialHost(
      tutorial: GameTutorial.memoryFlip,
      canOpen: () => !busy,
      builder: (_, help) => Scaffold(
          body: TextButton(onPressed: help, child: const Text('Help'))),
    )));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final help = tester.widget<TextButton>(find.byType(TextButton)).onPressed!;
    busy = true;
    help();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-tutorial')), findsNothing);
    busy = false;
    help();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('game-tutorial')), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  });
  for (final tutorial in GameTutorial.values) {
    testWidgets('${tutorial.name}: first visit, skip, persistence and replay',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      Widget app() => MaterialApp(
          home: GameTutorialHost(
              tutorial: tutorial,
              builder: (_, help) => Scaffold(
                  body:
                      TextButton(onPressed: help, child: const Text('Help')))));
      Future<void> settle() async {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(app());
      await settle();
      if (!tutorial.showOnFirstVisit) {
        expect(find.byKey(const ValueKey('game-tutorial')), findsNothing);
        await tester.tap(find.text('Help'));
        await settle();
      }
      expect(find.text('Step 1 of 3'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await settle();
      expect(find.byKey(const ValueKey('game-tutorial')), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('gameTutorialV1.${tutorial.name}'), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(app());
      await settle();
      expect(find.byKey(const ValueKey('game-tutorial')), findsNothing);
      await tester.tap(find.text('Help'));
      await settle();
      await tester.tap(find.text('Next'));
      await settle();
      expect(find.text('Step 2 of 3'), findsOneWidget);
      if (tutorial == GameTutorial.rumbledWords) {
        expect(find.text('Drag into place'), findsOneWidget);
        expect(find.textContaining('Tap Erase'), findsNothing);
      }
      await tester.tap(find.text('Back'));
      await settle();
      expect(find.text('Step 1 of 3'), findsOneWidget);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Next'));
        await settle();
      }
      if (tutorial == GameTutorial.rumbledWords) {
        expect(find.text('Check your word'), findsOneWidget);
        expect(find.textContaining('Tap Check Word'), findsOneWidget);
      }
      await tester.tap(find.text("Let's Play"));
      await settle();
      expect(find.byKey(const ValueKey('game-tutorial')), findsNothing);
    });
  }
}
