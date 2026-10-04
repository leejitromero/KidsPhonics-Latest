import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/widgets/game_zone_card.dart';
import 'package:kidsphonics/widgets/mascot_guide.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

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
      expect(find.byType(GameZoneCard), findsNWidgets(11));
      expect(t.widget<MascotPortrait>(find.byType(MascotPortrait)).mascot,
          LearningMascot.wigloo);
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Letters'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Letters'));
      await t.pumpAndSettle();
      expect(find.byType(GameZoneCard), findsNWidgets(2));
      expect(find.text('Flappy Letters'), findsOneWidget);
      expect(find.text('Alphabet Order'), findsOneWidget);
      expect(find.text('Sound Match'), findsNothing);
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Sounds'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Sounds'));
      await t.pumpAndSettle();
      expect(find.byType(GameZoneCard), findsNWidgets(3));
      await t.ensureVisible(find.widgetWithText(ChoiceChip, 'Words'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(ChoiceChip, 'Words'));
      await t.pumpAndSettle();
      expect(find.byType(GameZoneCard), findsNWidgets(6));
      expect(find.text('Rhyming Words'), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('Rhyming Words opens as a game with difficulty selection',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    mockProgressAudio();
    final p = await mount(t, const GamesScreen());
    await t.ensureVisible(find.text('Rhyming Words'));
    await t.pumpAndSettle();
    await t.tap(find.text('Rhyming Words'));
    await t.pumpAndSettle();
    await t.tap(find.text('Easy'));
    await t.pump();
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(RhymingWordsScreen), findsOneWidget);
    await close(t, p);
  });

  testWidgets('large text stacks cards and game still opens difficulty picker',
      (t) async {
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
    await t.ensureVisible(find.text('Sound Match'));
    await t.pumpAndSettle();
    await t.tap(find.text('Sound Match'));
    await t.pump();
    await t.runAsync(() => Future<void>.delayed(Duration.zero));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Easy'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
