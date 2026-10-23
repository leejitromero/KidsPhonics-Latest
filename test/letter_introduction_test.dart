import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
  });
  for (final practiced in [false, true]) {
    testWidgets('Progress opens Quick Check for letter B, practiced $practiced',
        (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final p = await mount(t, const ProgressScreen());
      if (practiced) {
        await t.runAsync(() => p.recordLetterPractice('B', false));
        await t.pump();
      }
      await t.tap(find.byKey(const ValueKey('progress-tab-1')));
      await t.pumpAndSettle();
      final letter = find.byKey(const ValueKey('progress-letter-B'));
      // The grid builds letters before they enter the outer list's viewport.
      // Scroll until B can receive a tap, rather than only finding its element.
      await t.dragUntilVisible(
          letter.hitTestable(), find.byType(ListView), const Offset(0, -150));
      expect(letter.hitTestable(), findsOneWidget);
      await t.tap(letter);
      await t.pumpAndSettle();
      final practice = find.byKey(const ValueKey('progress-practice-letter'));
      expect(practice, findsOneWidget);
      await t.ensureVisible(practice);
      await t.pumpAndSettle();
      await t.tap(practice);
      await t.pumpAndSettle();
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump();
      expect(find.byType(LetterMasteryCheckScreen), findsOneWidget);
      await close(t, p);
    });
  }
}
