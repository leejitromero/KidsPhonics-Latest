import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'package:kidsphonics/widgets/game_theme_background.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'sfx': false});
    mockProgressAudio();
    TestWidgetsFlutterBinding
            .instance.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(TestWidgetsFlutterBinding
        .instance.platformDispatcher.clearAccessibilityFeaturesTestValue);
  });
  test('all five game background frames are bundled in supplied order',
      () async {
    expect(gameFrames, [
      for (var i = 1; i <= 5; i++)
        'assets/images/game_background/games_newbg_$i.png'
    ]);
    for (final asset in gameFrames) {
      final bytes = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 941);
      expect(frame.image.height, 1671);
      frame.image.dispose();
      codec.dispose();
    }
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('game background covers $size through all five frames',
        (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: false);
      const foreground = ValueKey('game-background-foreground');
      await t.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: GameThemeBackground(
                  child: Center(
                      child:
                          SizedBox(key: foreground, width: 48, height: 48))))));
      final art = find.byType(AnimatedScreenArt);
      await t.runAsync(() => Future.wait(gameFrames.map((asset) =>
          precacheImage(
              ResizeImage(AssetImage(asset),
                  width: size.width.ceil().clamp(1, 941)),
              t.element(art)))));
      await t.pump();
      await t.pump();
      final foregroundRect = t.getRect(find.byKey(foreground));
      for (var frame = 0; frame < 5; frame++) {
        expect(t.getRect(art), Offset.zero & size);
        expect(t.getRect(find.byKey(foreground)), foregroundRect);
        final layers = t
            .widgetList<Opacity>(
                find.descendant(of: art, matching: find.byType(Opacity)))
            .toList();
        expect(layers[frame].opacity, 1);
        for (final element in find
            .descendant(of: art, matching: find.byType(Image))
            .evaluate()) {
          final finder =
              find.byElementPredicate((other) => identical(other, element));
          final render = t.renderObject<RenderImage>(
              find.descendant(of: finder, matching: find.byType(RawImage)));
          expect(t.getRect(finder), Offset.zero & size);
          expect(render.fit, BoxFit.cover);
          expect(render.alignment, Alignment.center);
          expect(render.image, isNotNull);
          final fitted = applyBoxFit(
              render.fit!,
              Size(render.image!.width.toDouble(),
                  render.image!.height.toDouble()),
              render.size);
          expect(fitted.destination, size);
        }
        await t.pump(const Duration(milliseconds: 1500));
        expect(t.getRect(art), Offset.zero & size);
        expect(t.getRect(find.byKey(foreground)), foregroundRect);
        expect(t.takeException(), isNull);
        await t.pump(const Duration(milliseconds: 1500));
      }
      await t.pumpWidget(const SizedBox());
    });
  }
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('level chooser selects and cancels at $size text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        t.binding.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.binding.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(() => t.binding.setSurfaceSize(null));
        Difficulty? selected;
        var completed = false;
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: size, textScaler: TextScaler.linear(scale)),
                child: Builder(
                    builder: (context) => Scaffold(
                        body: Center(
                            child: TextButton(
                                child: const Text('Open'),
                                onPressed: () async {
                                  selected = await chooseGameDifficulty(
                                      context,
                                      'Alphabet Order',
                                      (d) => switch (d) {
                                            Difficulty.easy =>
                                              'A–F · 6 letters',
                                            Difficulty.medium =>
                                              'A–M · 13 letters',
                                            Difficulty.hard =>
                                              'A–Z · 26 letters'
                                          });
                                  completed = true;
                                }))))));
        for (final level in Difficulty.values) {
          await t.tap(find.text('Open'));
          await t.pumpAndSettle();
          expect(find.text('Alphabet Order'), findsOneWidget);
          await t.ensureVisible(find.text(level.label));
          await t.pumpAndSettle();
          await t.tap(find.text(level.label));
          await t.pumpAndSettle();
          expect(selected, level);
          expect(completed, isTrue);
          expect(t.takeException(), isNull);
        }
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Cancel'));
        await t.pumpAndSettle();
        await t.tap(find.text('Cancel'));
        await t.pumpAndSettle();
        expect(selected, isNull);
        await close(t, p);
      });
    }
  }
}
