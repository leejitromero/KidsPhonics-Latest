import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/parent_screen.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/widgets/kids_navigation_bar.dart';
import 'package:kidsphonics/widgets/lesson_swipe_navigation.dart';
import 'package:kidsphonics/widgets/main_navigation_scope.dart';
import 'package:kidsphonics/widgets/main_navigation_shell.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });

  Finder surface(String name) => find.byKey(ValueKey(name));
  Object selection(WidgetTester t, String name) =>
      t.widget<LessonSwipeNavigation>(surface(name)).navigationKey;
  Future<void> swipe(WidgetTester t, String name,
      {bool previous = false}) async {
    final rect = t.getRect(surface(name));
    await t.dragFrom(Offset(rect.center.dx, rect.top + rect.height * .45),
        Offset(previous ? 150 : -150, 0));
    await t.pumpAndSettle();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump();
  }

  testWidgets('Progress body swipes its three tabs without wrapping or scoring',
      (t) async {
    final p = await mount(t, const ProgressScreen());
    const name = 'progress-tabs-swipe';
    await swipe(t, name, previous: true);
    expect(selection(t, name), 0);
    await swipe(t, name);
    expect(selection(t, name), 1);
    await swipe(t, name);
    expect(selection(t, name), 2);
    await swipe(t, name);
    expect(selection(t, name), 2);
    await swipe(t, name, previous: true);
    expect(selection(t, name), 1);
    await t.tap(surface('progress-tab-0'));
    await t.pumpAndSettle();
    expect(selection(t, name), 0);
    final scroll =
        find.descendant(of: surface(name), matching: find.byType(ListView));
    await t.drag(scroll, const Offset(0, -200));
    await t.pumpAndSettle();
    expect(selection(t, name), 0);
    expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets(
      'Games body changes category both ways; chips and vertical scroll still work',
      (t) async {
    final p = await mount(t, const GamesScreen());
    const name = 'games-categories-swipe';
    await swipe(t, name, previous: true);
    expect(selection(t, name), 'All Games');
    await t.drag(find.byType(GridView), const Offset(0, -180));
    await t.pumpAndSettle();
    expect(selection(t, name), 'All Games');
    for (final category in ['Letters', 'Sounds', 'Words']) {
      await swipe(t, name);
      expect(selection(t, name), category);
      expect(t.widget<ChoiceChip>(surface('games-filter-$category')).selected,
          isTrue);
    }
    await swipe(t, name);
    expect(selection(t, name), 'Words');
    await swipe(t, name, previous: true);
    expect(selection(t, name), 'Sounds');
    await t.ensureVisible(surface('games-filter-All Games'));
    await t.tap(surface('games-filter-All Games'));
    await t.pumpAndSettle();
    expect(selection(t, name), 'All Games');
    expect((p.xp, p.stars), (0, 0));
    expect(p.dailyActivity, isEmpty);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('Parents tabs require authentication and respect both boundaries',
      (t) async {
    final p = await mount(t, const ParentScreen());
    const name = 'parent-tabs-swipe';
    expect(surface(name), findsNothing);
    await t.drag(find.byType(ParentScreen), const Offset(-180, 0));
    await t.pumpAndSettle();
    expect(p.parentAuth.isAuthenticated, isFalse);
    expect(surface('parent-tab-1'), findsNothing);
    await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
    await t.pumpAndSettle();
    await swipe(t, name, previous: true);
    expect(selection(t, name), 0);
    await swipe(t, name);
    expect(selection(t, name), 1);
    await swipe(t, name);
    expect(selection(t, name), 2);
    await swipe(t, name);
    expect(selection(t, name), 2);
    await swipe(t, name, previous: true);
    expect(selection(t, name), 1);
    p.parentAuth.endSession();
    await t.pumpAndSettle();
    expect(surface(name), findsNothing);
    expect(surface('parent-tab-1'), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });

  testWidgets('settings-only parent route cannot swipe to hidden tabs',
      (t) async {
    final p =
        await mount(t, const ParentScreen(initialTab: 2, settingsOnly: true));
    await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
    await t.pumpAndSettle();
    await swipe(t, 'parent-tabs-swipe', previous: true);
    expect(selection(t, 'parent-tabs-swipe'), 2);
    expect(surface('parent-tab-0'), findsNothing);
    expect(p.gameAccess, isTrue);
    await close(t, p);
  });

  testWidgets(
      'dock swipes retain tabs and PIN protection without stealing body swipes',
      (t) async {
    final p = await mount(
        t,
        Scaffold(
            body: MainNavigationShell(
          homeBuilder: (_) => const Center(child: Text('Swipe Home')),
          onChanged: (_) {},
          navigationBuilder: (context) {
            final navigation = MainNavigationScope.maybeOf(context)!;
            return KidsNavigationBar(
                current: navigation.current, onSelected: navigation.select);
          },
        )));
    KidsDestination current() =>
        t.widget<KidsNavigationBar>(find.byType(KidsNavigationBar)).current;
    const dock = 'main-navigation-swipe';
    await swipe(t, dock, previous: true);
    expect(current(), KidsDestination.home);
    await swipe(t, dock);
    expect(current(), KidsDestination.progress);
    await swipe(t, 'progress-tabs-swipe');
    expect(current(), KidsDestination.progress);
    expect(selection(t, 'progress-tabs-swipe'), 1);
    await swipe(t, dock, previous: true);
    expect(current(), KidsDestination.home);
    await swipe(t, dock);
    expect(selection(t, 'progress-tabs-swipe'), 1);
    await swipe(t, dock);
    expect(current(), KidsDestination.parents);
    expect(p.parentAuth.isAuthenticated, isFalse);
    expect(surface('parent-tabs-swipe'), findsNothing);
    await t.runAsync(() => p.parentAuth.setup('2580', '2580'));
    await t.pumpAndSettle();
    await swipe(t, 'parent-tabs-swipe');
    expect(current(), KidsDestination.parents);
    expect(selection(t, 'parent-tabs-swipe'), 1);
    await swipe(t, dock);
    expect(current(), KidsDestination.settings);
    expect(p.parentAuth.isAuthenticated, isFalse);
    await swipe(t, dock);
    expect(current(), KidsDestination.settings);
    await swipe(t, dock, previous: true);
    expect(current(), KidsDestination.parents);
    expect(surface('parent-tabs-swipe'), findsNothing);
    expect(find.text('Parent Access'), findsOneWidget);
    expect((p.xp, p.stars), (0, 0));
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
