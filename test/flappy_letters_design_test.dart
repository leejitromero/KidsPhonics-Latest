import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/flappy_letters_screen.dart';
import 'package:kidsphonics/widgets/flappy_letters_design.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  for (final scenario in [
    (size: const Size(320, 568), textScale: 1.0),
    (size: const Size(390, 844), textScale: 1.0),
    (size: const Size(800, 600), textScale: 1.0),
    (size: const Size(320, 568), textScale: 2.0),
  ]) {
    testWidgets('illustrated Flappy entry is usable at $scenario', (t) async {
      await t.binding.setSurfaceSize(scenario.size);
      t.platformDispatcher.textScaleFactorTestValue = scenario.textScale;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
      mockProgressAudio();
      final boundary = GlobalKey();
      final p = await mount(
          t,
          RepaintBoundary(
              key: boundary,
              child: const FlappyLettersScreen(difficulty: Difficulty.easy)));
      await t.runAsync(() => Future<void>.delayed(Duration.zero));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byType(FlappyStatusBar), findsOneWidget);
      expect(find.byType(FlappyFlightPanel), findsOneWidget);
      expect(find.text('Ready to fly?'), findsOneWidget);
      expect(find.text('Tap to fly through the gaps!'), findsOneWidget);
      expect(t.widget<GameLives>(find.byType(GameLives)).lives, 3);
      expect(find.byKey(const ValueKey('flappy-airplane-art')), findsOneWidget);
      final header = t.getRect(find.byKey(const ValueKey('flappy-status-bar')));
      final scroll =
          t.getRect(find.byKey(const ValueKey('flappy-panel-scroll')));
      expect(header.bottom, lessThanOrEqualTo(scroll.top));
      expect(t.takeException(), isNull);

      if (const bool.fromEnvironment('CAPTURE_UI') &&
          scenario.size.width == 390 &&
          scenario.textScale == 1) {
        await t.runAsync(() async {
          await (FontLoader('Nunito')
                ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
                ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
              .load();
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
          await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
              (image) => precacheImage(image.image, boundary.currentContext!)));
        });
        await t.pump(const Duration(milliseconds: 400));
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui_previews/flappy_letters_ready.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final start = find.byKey(const ValueKey('flappy-flight-action'));
      await t.ensureVisible(start);
      await t.pump(const Duration(milliseconds: 200));
      final action = t.getRect(start);
      expect(action.top, greaterThanOrEqualTo(header.bottom));
      expect(action.bottom, lessThanOrEqualTo(scenario.size.height));
      await t.tap(start);
      await t.pump();
      expect(find.byType(FlappyFlightPanel), findsNothing);
      await t.tap(find.byTooltip('Pause'));
      await t.pump();
      expect(find.text('Taking a little break'), findsOneWidget);
      final resume = find.byKey(const ValueKey('flappy-flight-action'));
      await t.ensureVisible(resume);
      await t.pump(const Duration(milliseconds: 200));
      await t.tap(resume);
      await t.pump();
      expect(find.byType(FlappyFlightPanel), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }
}
