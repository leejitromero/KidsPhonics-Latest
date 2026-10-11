import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/home_screen.dart';
import 'package:kidsphonics/widgets/home_recommendation_panel.dart';
import 'package:kidsphonics/widgets/cloud_page_route.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  testWidgets('menu opens during intro and returning home does not replay it',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const HomeScreen());
    await t.pump();
    expect(find.byKey(const ValueKey('home-skip-intro')), findsOneWidget);
    final homeContext = t.element(find.byType(HomeScreen));
    await t.tap(find.byKey(const ValueKey('home-lessons')));
    for (var i = 0;
        i < 100 && find.byType(CloudScreenTransition).evaluate().isEmpty;
        i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(ModalRoute.of(homeContext)!.isCurrent, isFalse);
    Navigator.of(homeContext).pop();
    await t.pump();
    await t.pump(const Duration(seconds: 2));
    expect(ModalRoute.of(homeContext)!.isCurrent, isTrue);
    expect(find.byKey(const ValueKey('home-skip-intro')), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
  testWidgets(
      'intro pauses in background, skips and stays finished after progress changes',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const HomeScreen());
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    double value() =>
        t.widget<HomeEntrance>(find.byType(HomeEntrance).first).animation.value;
    final before = value();
    expect(before, lessThan(1));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump(const Duration(seconds: 2));
    expect(value(), before);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(value(), greaterThan(before));
    await t.tap(find.byKey(const ValueKey('home-skip-intro')));
    await t.pump();
    expect(value(), 1);
    expect(find.byKey(const ValueKey('home-skip-intro')), findsNothing);
    await t.runAsync(() => p.completeAdventure(
        'A', [true, true, true, true, true], 'home-redesign-test'));
    await t.pump();
    expect(find.text('Practice Letter B'), findsOneWidget);
    expect(value(), 1);
    await close(t, p);
  });

  testWidgets(
      'unfinished letter shows review and all mastered letters show celebration',
      (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const HomeScreen());
    await t.runAsync(() =>
        p.completeAdventure('B', [true, false, true, true, true], 'review-b'));
    await t.pump();
    expect(find.text('Review Letter B'), findsOneWidget);
    await t.runAsync(() async {
      for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        await p.completeAdventure(
            letter, [true, true, true, true, true], 'master-$letter');
      }
    });
    await t.pump();
    expect(find.text('Alphabet Master!'), findsOneWidget);
    expect(find.text('${p.xp} XP'), findsOneWidget);
    expect(find.text('${p.stars} Stars'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-skip-intro')), findsNothing);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
