import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final difficulty in Difficulty.values) {
    testWidgets('$difficulty fits and moves a red choice into a green slot',
        (t) async {
      await t.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p = await mount(t, AlphabetOrderScreen(difficulty: difficulty));
      expect(find.byType(Scrollable), findsNothing);
      final count = switch (difficulty) {
        Difficulty.easy => 6,
        Difficulty.medium => 13,
        Difficulty.hard => 26
      };
      expect(find.text('_'), findsNWidgets(count));
      for (final button
          in t.widgetList<GameAnswerButton>(find.byType(GameAnswerButton))) {
        expect(button.accent, const Color(0xFF247BA5));
        final rect =
            t.getRect(find.byKey(ValueKey('alphabet-choice-${button.label}')));
        expect(rect.bottom, lessThanOrEqualTo(568));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
      await t.tap(find.byKey(const ValueKey('alphabet-choice-B')));
      await t.pump();
      expect(find.text('_'), findsNWidgets(count));
      expect(find.byType(GameLives), findsNothing);
      await t.pump(const Duration(milliseconds: 750));
      await t.pump(const Duration(milliseconds: 650));
      await t.tap(find.byKey(const ValueKey('alphabet-choice-A')));
      await t.pump();
      expect(
          find.byKey(const ValueKey('flying-alphabet-letter')), findsOneWidget);
      final start =
          t.getRect(find.byKey(const ValueKey('flying-alphabet-letter')));
      await t.pump(const Duration(milliseconds: 300));
      expect(
          t.getRect(find.byKey(const ValueKey('flying-alphabet-letter'))).top,
          lessThan(start.top));
      await t.pump(const Duration(milliseconds: 350));
      expect(
          find.byKey(const ValueKey('flying-alphabet-letter')), findsNothing);
      expect(find.text('_'), findsNWidgets(count - 1));
      expect(find.text('Find B'), findsOneWidget);
      expect(
          find.byWidgetPredicate((w) =>
              w is Container &&
              w.key is GlobalKey &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFF167769)),
          findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
