import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/widgets/category_navigation.dart';
import 'package:kidsphonics/widgets/school_home_scene.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });

  testWidgets('returning Home has no repeated intro or floating menu',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
    expect(find.byType(CategoryNavigation), findsNothing);
    await t.ensureVisible(find.byKey(const ValueKey('home-lessons')));
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    await t.pumpAndSettle();
    expect(find.byType(LessonsScreen), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('main-nav-home')));
    await t.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(CategoryNavigation), findsNothing);
    expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
    await close(t, p);
  });

  testWidgets(
      'recommendation follows saved Quick Checks without replaying intro',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.runAsync(
        () => p.completeAdventure('A', List.filled(5, true), 'home-a'));
    await t.pump();
    expect(
        t
            .widget<Semantics>(
                find.byKey(const ValueKey('home-practice-label')))
            .properties
            .label,
        'Practice This Letter B');
    expect(
        t
            .widget<Text>(
                find.byKey(const ValueKey('home-practice-letter-text')))
            .data,
        'Letter B');
    final scene = t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene));
    expect(scene.letter, 'B');
    expect((scene.xp, scene.stars), (p.xp, p.stars));
    expect(p.overallMasteredCount, 1);
    expect(t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene)).selected,
        isNull);
    expect(find.byKey(const ValueKey('welcome-next')), findsNothing);
    await close(t, p);
  });

  testWidgets('all mastered letters show review while retaining saved rewards',
      (t) async {
    final p = await mount(t, const HomeScreen());
    await t.runAsync(() async {
      for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        await p.completeAdventure(
            letter, List.filled(5, true), 'master-$letter');
      }
    });
    await t.pump();
    final scene = t.widget<SchoolHomeScene>(find.byType(SchoolHomeScene));
    expect(scene.letter, isNull);
    expect(
        t
            .widget<Semantics>(
                find.byKey(const ValueKey('home-practice-label')))
            .properties
            .label,
        'Review letters');
    expect(
        t
            .widget<Text>(
                find.byKey(const ValueKey('home-practice-letter-text')))
            .data,
        'Letters');
    expect(scene.xp, p.xp);
    expect(scene.stars, p.stars);
    expect(p.overallMasteredCount, 26);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
