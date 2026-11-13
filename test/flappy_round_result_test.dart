import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  testWidgets(
      'flight loss rates once and result Back returns to the games route',
      (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    final p = await mount(
        t,
        Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => const FlappyLettersScreen())),
                    child: const Text('Games menu')))));
    await t.tap(find.text('Games menu'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Start flying'));
    await t.pump();
    for (var life = 0; life < 3; life++) {
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      if (life < 2) {
        await t.tap(find.text('Continue'));
        await t.pump();
      }
    }
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump();
    }
    expect(find.byType(GameResultDialog), findsOneWidget);
    expect(p.stars, 1);
    await t.pump(const Duration(seconds: 2));
    expect(p.stars, 1);
    await t.tap(find.byKey(const ValueKey('result-back')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(FlappyLettersScreen), findsNothing);
    expect(find.text('Games menu'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
