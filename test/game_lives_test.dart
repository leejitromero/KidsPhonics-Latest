import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'non-flight games allow more than three mistakes and keep progress',
      (t) async {
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const AlphabetOrderScreen());
    final wrong =
        find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == 'B');
    expect(find.byType(GameLives), findsNothing);
    for (var attempt = 0; attempt < 5; attempt++) {
      await t.ensureVisible(wrong);
      await t.tap(
          find.descendant(of: wrong, matching: find.byType(ElevatedButton)));
      await t.pump();
      expect(find.byType(GameLives), findsNothing);
      // Rapid taps during feedback must not count twice.
      await t.tap(
          find.descendant(of: wrong, matching: find.byType(ElevatedButton)));
      await t.pump(const Duration(milliseconds: 750));
      await t.pump(const Duration(milliseconds: 900));
      await t.pumpAndSettle();
    }
    expect(find.text('Out of lives'), findsNothing);
    final session = t.state(find.byType(AlphabetOrderScreen)) as GameSessionUi;
    expect(session.scoredAttempts, 5);
    expect(session.resultOpen, isFalse);
    expect(p.xp, 0);
    expect(p.stars, 0);
    expect(find.text('Find A'), findsOneWidget);
    final correct =
        find.byWidgetPredicate((w) => w is GameAnswerButton && w.label == 'A');
    await t.ensureVisible(correct);
    await t.tap(
        find.descendant(of: correct, matching: find.byType(ElevatedButton)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 750));
    expect(find.byType(GameLives), findsNothing);
    expect(find.text('Find B'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
