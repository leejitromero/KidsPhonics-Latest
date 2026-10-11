import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/widgets/game_tutorial.dart';
import 'package:kidsphonics/screens/alphabet_order_screen.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(800, 1024), 1.0),
  ]) {
    for (final game in GameTutorial.values) {
      testWidgets('${game.name} illustrated guide at $size text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        t.binding.platformDispatcher.textScaleFactorTestValue = scale;
        t.binding.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(() => t.binding.setSurfaceSize(null));
        addTearDown(t.binding.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
            t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
        SharedPreferences.setMockInitialValues({
          'sfx': false,
          'voice': false,
          for (final tutorial in GameTutorial.values)
            'gameTutorialV1.${tutorial.name}': true,
        });
        mockProgressAudio();
        final p = await mount(
            t,
            Theme(
                data: KidsUi.theme,
                child: GameTutorialHost(
                    tutorial: game,
                    builder: (_, help) => Scaffold(
                        body: Center(
                            child: TextButton(
                                onPressed: help,
                                child: const Text('Help')))))));
        await t.tap(find.text('Help'));
        await t.pumpAndSettle();
        final next = find.byKey(const ValueKey('tutorial-next'));
        for (var step = 0; step < 3; step++) {
          expect(find.text('Step ${step + 1} of 3'), findsOneWidget);
          expect(find.byKey(const ValueKey('tutorial-banner')), findsOneWidget);
          expect(find.byKey(const ValueKey('tutorial-example-scene')),
              findsOneWidget);
          expect(find.byKey(const ValueKey('tutorial-step-title')),
              findsOneWidget);
          expect(find.byKey(const ValueKey('tutorial-step-detail')),
              findsOneWidget);
          final marker =
              t.widget<Container>(find.byKey(ValueKey('tutorial-step-$step')));
          expect((marker.decoration! as BoxDecoration).color,
              const Color(0xFF8A1AFF));
          // Navigation stays on-screen while long instructions scroll above it.
          expect(next.hitTestable(), findsOneWidget);
          expect(find.byKey(const ValueKey('tutorial-skip')).hitTestable(),
              findsOneWidget);
          expect(t.getSize(next).height, greaterThanOrEqualTo(48));
          expect(t.takeException(), isNull);
          await t.ensureVisible(
              find.byKey(const ValueKey('tutorial-step-detail')));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          if (step < 2) {
            await t.tap(next);
            await t.pumpAndSettle();
          }
        }
        final finish = t.widget<ElevatedButton>(next).onPressed!;
        finish();
        finish();
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('game-tutorial')), findsNothing);
        expect(find.text('Help'), findsOneWidget);
        await close(t, p);
      });
    }
  }

  testWidgets('Alphabet Order help matches the actual tap-in-order game',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => t.binding.setSurfaceSize(null));
    t.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
        t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues({'sfx': false, 'voice': false});
    mockProgressAudio();
    final p = await mount(t, const AlphabetOrderScreen());
    final app = t.widget<MaterialApp>(find.byType(MaterialApp));
    final boundary = GlobalKey();
    await t.pumpWidget(ChangeNotifierProvider.value(
        value: p, child: RepaintBoundary(key: boundary, child: app)));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('How to Play'));
    await t.pumpAndSettle();
    expect(find.text('Put the letters in alphabet order. Start with A.'),
        findsOneWidget);
    expect(find.text('Find the missing letter in the alphabet sequence.'),
        findsNothing);
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      await t.runAsync(() async {
        await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
            (image) => precacheImage(image.image, boundary.currentContext!)));
      });
      await t.pump();
      await t.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/ui_previews/how_to_play.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await t.tap(find.text('Skip'));
    await t.pumpAndSettle();
    expect(find.byTooltip('How to Play'), findsOneWidget);
    await close(t, p);
  });
}
