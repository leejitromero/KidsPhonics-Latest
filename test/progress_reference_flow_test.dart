import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/screens/letter_sounds_screen.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/widgets/progress_reference_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  testWidgets(
      'journey rows and badges refresh from completed learning evidence',
      (t) async {
    final p = await mount(t, const ProgressScreen());
    await t.runAsync(() async {
      await p.recordLetterListening('A', LetterListeningKind.sound);
      await p.completeAdventure('B', List.filled(5, true), 'master-b');
      for (final word in WordLesson.cvc.words.take(5)) {
        await p.completeWordLessonWord(WordLesson.cvc, word);
      }
      await p.completeWordLessonWord(WordLesson.blending, 'SUN');
    });
    await t.pumpAndSettle();
    for (final (id, current, total) in [
      ('letters', 1, 26),
      ('sounds', 1, 26),
      ('vowels', 0, 5),
      ('cvc', 5, 17),
      ('blending', 1, 22)
    ]) {
      final row = find.byKey(ValueKey('journey-skill-$id'));
      await t.scrollUntilVisible(row.hitTestable(), 120,
          scrollable: find.byType(Scrollable).first);
      final data = t.widget<ProgressSkillRow>(row);
      expect((data.current, data.total), (current, total));
    }
    await t.tap(find.byKey(const ValueKey('progress-tab-2')));
    await t.pumpAndSettle();
    final goal = find.byKey(const ValueKey('progress-badge-CVC Explorer'));
    await t.scrollUntilVisible(goal.hitTestable(), 120,
        scrollable: find.byType(Scrollable).first);
    await t.tap(goal);
    await t.pumpAndSettle();
    expect(find.text('You earned it!'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byType(AlertDialog), matching: find.text('5 / 5')),
        findsOneWidget);
    expect((p.xp, p.stars), (30, 1));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  for (final (id, destination) in [
    ('sounds', LetterSoundsScreen),
    ('vowels', LetterSoundsScreen),
    ('cvc', CvcWordsScreen),
    ('blending', BlendingSoundsScreen)
  ]) {
    testWidgets('journey $id opens its real lesson', (t) async {
      final p = await mount(t, const ProgressScreen());
      await t.pumpAndSettle();
      final row = find.byKey(ValueKey('journey-skill-$id'));
      await t.scrollUntilVisible(row.hitTestable(), 120,
          scrollable: find.byType(Scrollable).first);
      await t.tap(row);
      await t.pumpAndSettle();
      expect(find.byType(destination), findsOneWidget);
      if (id == 'vowels') {
        expect(
            t
                .widget<LetterSoundsScreen>(find.byType(LetterSoundsScreen))
                .vowelsOnly,
            true);
      }
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('unearned vowel badge starts an unmastered vowel Quick Check',
      (t) async {
    final p = await mount(t, const ProgressScreen());
    await t.runAsync(() => p.completeAdventure('A', List.filled(5, true), 'a'));
    await t.tap(find.byKey(const ValueKey('progress-tab-2')));
    await t.pumpAndSettle();
    final badge = find.byKey(const ValueKey('progress-badge-Vowel Star'));
    await t.scrollUntilVisible(badge.hitTestable(), 120,
        scrollable: find.byType(Scrollable).first);
    await t.tap(badge);
    await t.pumpAndSettle();
    await t.tap(find.text('Start Practice'));
    await t.pumpAndSettle();
    expect(
        t
            .widget<LetterMasteryCheckScreen>(
                find.byType(LetterMasteryCheckScreen))
            .letter
            .letter,
        'E');
    expect((p.xp, p.stars), (30, 1));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('all-mastered state offers review and preserves rewards',
      (t) async {
    final p = await mount(t, const ProgressScreen());
    await t.runAsync(() async {
      for (var code = 65; code <= 90; code++) {
        final l = String.fromCharCode(code);
        await p.completeAdventure(l, List.filled(5, true), l);
      }
    });
    await t.pumpAndSettle();
    final start = find.byKey(const ValueKey('progress-start-quick-check'));
    await t.scrollUntilVisible(start.hitTestable(), 120,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('All 26 letters mastered!'), findsOneWidget);
    await t.tap(start);
    await t.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('progress-letter-summary')), findsOneWidget);
    expect(find.byType(LetterMasteryCheckScreen), findsNothing);
    expect((p.xp, p.stars), (780, 26));
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
