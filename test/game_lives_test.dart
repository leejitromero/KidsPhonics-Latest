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
    expect(find.byType(GameLives), findsNothing);
    for (var attempt = 0; attempt < 5; attempt++) {
      final expected = String.fromCharCode(65 + attempt);
      final choice = t
          .widgetList<GameAnswerButton>(find.byType(GameAnswerButton))
          .firstWhere((w) => w.onPressed != null && w.label != expected);
      choice.onPressed!();
      choice.onPressed!();
      await t.pump();
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
    expect(find.text('Find F'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
