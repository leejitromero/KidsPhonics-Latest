import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('start, pause, resume, collision and retry work on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    late AppProvider provider;
    await tester.runAsync(() async {
      provider = AppProvider();
      await provider.ready;
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: FlappyLettersScreen()),
    ));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How to Play'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 500));
    final playArea =
        tester.getRect(find.byKey(const ValueKey('flight-play-area')));
    expect(playArea.width, 390);
    expect(playArea.top, 0);
    expect(playArea.bottom, 844);
    expect(tester.widget<GameLives>(find.byType(GameLives)).lives, 3);
    await tester.tap(find.text('Start flying'));
    await tester.pump();
    expect(find.text('Ready to fly?'), findsNothing);
    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Taking a little break'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Taking a little break'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    for (var lives = 2; lives > 0; lives--) {
      expect(find.text('Oops! Keep going!'), findsOneWidget);
      expect(tester.widget<GameLives>(find.byType(GameLives)).lives, lives);
      await tester.tap(find.text('Continue'));
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
    expect(find.text('Nice flying! Try again!'), findsOneWidget);
    expect(tester.widget<GameLives>(find.byType(GameLives)).lives, 0);
    await tester.tap(find.text('Play again'));
    await tester.pump();
    expect(find.text('Ready to fly?'), findsOneWidget);
    expect(tester.widget<GameLives>(find.byType(GameLives)).lives, 3);
    expect(find.textContaining('0 / 26 letters'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    provider.dispose();
  });
}
