import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/widgets/game_zone_card.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

Finder gameCard(String title) => find.byWidgetPredicate(
    (widget) => widget is GameZoneCard && widget.title == title);

int gameCount(WidgetTester t) =>
    (t.widget<GridView>(find.byType(GridView)).childrenDelegate
            as SliverChildBuilderDelegate)
        .childCount!;

Future<void> reachGame(WidgetTester t, String title) async {
  await t.scrollUntilVisible(gameCard(title), 150,
      scrollable: find.descendant(
          of: find.byType(GridView), matching: find.byType(Scrollable)));
  await t.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    testWidgets('game zone artwork and categories work at $size', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      mockProgressAudio();
      final p = await mount(t, const GamesScreen());
      await t.pumpAndSettle();
      expect(gameCount(t), 11);
      expect(find.byKey(const ValueKey('game-zone-mascot')), findsNothing);
      expect(find.byKey(const ValueKey('games-profile-boy')), findsOneWidget);
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Letters'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Letters'));
      await t.pumpAndSettle();
      expect(gameCount(t), 2);
      expect(gameCard('Flappy Letters'), findsOneWidget);
      expect(gameCard('Alphabet Order'), findsOneWidget);
      expect(gameCard('Sound Match'), findsNothing);
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Sounds'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Sounds'));
      await t.pumpAndSettle();
      expect(gameCount(t), 3);
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Words'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Words'));
      await t.pumpAndSettle();
      expect(gameCount(t), 6);
      await reachGame(t, 'Rhyming Words');
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('Rhyming Words opens as a game with difficulty selection',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const GamesScreen());
    await reachGame(t, 'Rhyming Words');
    await t.pumpAndSettle();
    final play = find.byKey(const ValueKey('game-play-Rhyming Words'));
    await t.ensureVisible(play);
    await t.pumpAndSettle();
    await t.tap(play);
    await t.pumpAndSettle();
    await t.tap(find.text('Easy'));
    await t.pump();
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(RhymingWordsScreen), findsOneWidget);
    await close(t, p);
  });

  testWidgets('large text keeps artwork reachable and opens difficulty picker',
      (t) async {
    await t.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => t.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(
        t,
        const MediaQuery(
            data: MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2),
                disableAnimations: true),
            child: GamesScreen()));
    await t.pumpAndSettle();
    await t.ensureVisible(gameCard('Sound Match'));
    await t.pumpAndSettle();
    final visibleCard = t
        .getRect(gameCard('Sound Match'))
        .intersect(t.getRect(find.byType(GridView)));
    expect(visibleCard.width, greaterThanOrEqualTo(48));
    expect(visibleCard.height, greaterThanOrEqualTo(48));
    await t.tapAt(visibleCard.center);
    await t.pump();
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
