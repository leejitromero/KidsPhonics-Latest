import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/rhyming_words_screen.dart';
import 'package:kidsphonics/widgets/rhyming_words_design.dart';
import 'package:kidsphonics/widgets/game_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  Future<void> capture(WidgetTester t, GlobalKey boundary, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_UI')) return;
    await t.runAsync(() async {
      await Future.wait(t
          .widgetList<Image>(find.byType(Image))
          .map((im) => precacheImage(im.image, boundary.currentContext!)));
    });
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final picture = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 2);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/ui_previews/rhyming_visibility_$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  for (final difficulty in Difficulty.values) {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(800, 1024), 1.0),
      (const Size(320, 568), 1.8),
    ]) {
      testWidgets(
          '${difficulty.name}: target, score, choices and pause fit $size text $scale',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(() {
          t.view.resetPhysicalSize();
          t.view.resetDevicePixelRatio();
          t.view.resetPadding();
        });
        final boundary = GlobalKey();
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: size,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true),
                child: RepaintBoundary(
                    key: boundary,
                    child: RhymingWordsScreen(difficulty: difficulty))));
        await t.pumpAndSettle();
        final targetPanel = find.byKey(const ValueKey('rhyme-target-panel'));
        final scorePanel = find.byKey(const ValueKey('rhyme-score-panel'));
        expect(t.widget<ForestPanel>(targetPanel).glass, false);
        expect(t.widget<ForestPanel>(scorePanel).glass, false);
        final target = t.getRect(targetPanel), score = t.getRect(scorePanel);
        expect(target.bottom, lessThan(score.top));
        final buttons = find.byType(RhymingControlButton);
        expect(buttons, findsNWidgets(2));
        for (final button in buttons.evaluate()) {
          final rect =
              t.getRect(find.byElementPredicate((e) => identical(e, button)));
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        final choices = find.byWidgetPredicate((w) =>
            w is Text &&
            w.key is ValueKey<String> &&
            (w.key as ValueKey<String>).value.startsWith('rhyme-choice-'));
        expect(choices, findsNWidgets(5 + difficulty.index * 2));
        final screen = Offset.zero & size;
        for (final element in choices.evaluate()) {
          final box = element.renderObject! as RenderBox;
          final rect = MatrixUtils.transformRect(
              box.getTransformTo(null), Offset.zero & box.size);
          expect(rect.top, greaterThan(score.bottom));
          expect(rect.bottom, lessThanOrEqualTo(screen.bottom - 24));
          expect(rect.left, greaterThanOrEqualTo(screen.left));
          expect(rect.right, lessThanOrEqualTo(screen.right));
        }
        expect(find.byType(Scrollable), findsNothing);
        expect(t.takeException(), isNull);
        if (size.width == 390) await capture(t, boundary, difficulty.name);

        await t.tap(find.byTooltip('Pause'));
        await t.pumpAndSettle();
        final pauseCard = find.byKey(const ValueKey('rhyming-pause-card'));
        final resume = find.byKey(const ValueKey('rhyming-resume-button'));
        expect(find.text('Paused'), findsOneWidget);
        expect(pauseCard, findsOneWidget);
        expect(t.getRect(resume).height, greaterThanOrEqualTo(48));
        expect(t.getRect(resume).width, greaterThanOrEqualTo(160));
        expect(t.takeException(), isNull);
        if (size.width == 390 && difficulty == Difficulty.medium) {
          await capture(t, boundary, 'paused');
        }
        await t.tap(resume);
        await t.pumpAndSettle();
        expect(pauseCard, findsNothing);
        expect(find.byTooltip('Pause'), findsOneWidget);
        await t.tap(find.byTooltip('Mute'));
        await t.pumpAndSettle();
        expect(find.byTooltip('Unmute'), findsOneWidget);
        await t.tap(find.byTooltip('Unmute'));
        await t.pumpAndSettle();
        expect(find.byTooltip('Mute'), findsOneWidget);
        expect((p.xp, p.stars), (0, 0));
        expect(p.dailyActivity, isEmpty);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }
}
