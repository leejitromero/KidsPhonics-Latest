import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/screens/letter_mastery_check_screen.dart';
import 'package:kidsphonics/widgets/parent_garden_overview.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });

  testWidgets('Home starts the next unmastered adventure directly', (t) async {
    final p = await mount(t, const HomeScreen());
    await t.runAsync(() => p.completeAdventure('A', List.filled(5, true), 'a'));
    await t.pump();
    final start = find.byKey(const ValueKey('home-start-adventure'));
    await t.ensureVisible(start);
    await t.tap(start);
    await t.pumpAndSettle();
    final screen = t.widget<LetterMasteryCheckScreen>(
        find.byType(LetterMasteryCheckScreen));
    expect(screen.letter.letter, 'B');
    expect(p.adventureProgress('B').completed, 0);
    await close(t, p);
  });

  testWidgets('Progress exposes A-Z adventures without changing old results',
      (t) async {
    final p = await mount(t, const ProgressScreen());
    await t.tap(find.byKey(const ValueKey('progress-tab-1')));
    await t.pumpAndSettle();
    final selector = find.byKey(const ValueKey('adventure-letter-selector'));
    await t.ensureVisible(selector);
    await t.tap(find.text('Choose a letter adventure'));
    await t.pumpAndSettle();
    final z = find.byKey(const ValueKey('overall-letter-Z'));
    await t.scrollUntilVisible(z, 150,
        scrollable: find.byType(Scrollable).first);
    await t.tap(z);
    await t.pumpAndSettle();
    expect(
        t
            .widget<LetterMasteryCheckScreen>(
                find.byType(LetterMasteryCheckScreen))
            .letter
            .letter,
        'Z');
    expect(p.masteredLetters, isEmpty);
    expect(p.overallMasteredCount, 0);
    await close(t, p);
  });

  for (final source in ['Progress', 'Parents']) {
    testWidgets('$source starts the same recommended Quick Check as Home',
        (t) async {
      final page = source == 'Progress'
          ? const ProgressScreen()
          : const Scaffold(
              body: SingleChildScrollView(child: ParentGardenOverview()));
      final p = await mount(t, page);
      await t.runAsync(() async {
        await p.completeAdventure('A', List.filled(5, true), 'recommended-a');
        await p.markLetterViewed('B');
      });
      await t.pumpAndSettle();
      final start = find.byKey(const ValueKey('home-start-adventure'));
      await t.ensureVisible(start);
      await t.tap(start);
      await t.pumpAndSettle();
      expect(
          t
              .widget<LetterMasteryCheckScreen>(
                  find.byType(LetterMasteryCheckScreen))
              .letter
              .letter,
          'B');
      expect(p.adventureProgress('B').completed, 0);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('Parent Quick Check ends privileged session before learner play',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p = await mount(t, const ParentScreen());
    await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
    await t.pumpAndSettle();
    expect(p.parentAuth.isAuthenticated, isTrue);
    final start = find.byKey(const ValueKey('home-start-adventure'));
    await t.ensureVisible(start);
    await t.pumpAndSettle();
    await t.tap(start);
    await t.pumpAndSettle();
    expect(find.byType(LetterMasteryCheckScreen), findsOneWidget);
    expect(p.parentAuth.isAuthenticated, isFalse);
    expect(p.screenTime.isLimitReached, isFalse);
    await t.runAsync(() => t.pageBack());
    await t.pumpAndSettle();
    expect(find.text('Enter Parent PIN'), findsOneWidget);
    expect(find.byKey(const ValueKey('parent-tab-2')), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
