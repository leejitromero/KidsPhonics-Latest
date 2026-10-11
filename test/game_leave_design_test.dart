import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'package:kidsphonics/widgets/game_leave_dialog.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(800, 1024),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('leave confirmation works at $size with text $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        t.binding.platformDispatcher.textScaleFactorTestValue = scale;
        t.binding.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(() => t.binding.setSurfaceSize(null));
        addTearDown(t.binding.platformDispatcher.clearTextScaleFactorTestValue);
        addTearDown(
            t.binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
        SharedPreferences.setMockInitialValues({'sfx': false});
        mockProgressAudio();
        bool? result;
        var completions = 0;
        final boundary = GlobalKey();
        final p = await mount(
            t,
            Builder(
                builder: (context) => Scaffold(
                        body: Stack(fit: StackFit.expand, children: [
                      const AnimatedScreenArt(frames: gameFrames),
                      Center(
                          child: TextButton(
                              child: const Text('Open'),
                              onPressed: () async {
                                result = await showDialog<bool>(
                                    context: context,
                                    barrierColor: const Color(0xB8253040),
                                    builder: (_) => Theme(
                                        data: KidsUi.theme,
                                        child: const GameLeaveDialog()));
                                completions++;
                              })),
                    ]))));
        if (const bool.fromEnvironment('CAPTURE_UI') &&
            size.width == 390 &&
            scale == 1) {
          final app = t.widget<MaterialApp>(find.byType(MaterialApp));
          await t.pumpWidget(ChangeNotifierProvider.value(
              value: p, child: RepaintBoundary(key: boundary, child: app)));
          await t.pump();
        }
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        expect(find.text('Leave this game?'), findsOneWidget);
        expect(find.byKey(const ValueKey('leave-rabbit')), findsOneWidget);
        expect(find.byKey(const ValueKey('leave-door-icon')), findsOneWidget);
        expect(t.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_UI') &&
            size.width == 390 &&
            scale == 1) {
          await t.runAsync(() async {
            await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
                (image) =>
                    precacheImage(image.image, boundary.currentContext!)));
          });
          await t.pump();
          await t.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('build/ui_previews/game_leave.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await t.ensureVisible(find.text('Cancel'));
        await t.pumpAndSettle();
        expect(t.getSize(find.byKey(const ValueKey('leave-cancel'))).height,
            greaterThanOrEqualTo(48));
        await t.tap(find.text('Cancel'));
        await t.pumpAndSettle();
        expect(result, false);
        expect(completions, 1);
        expect(find.text('Open'), findsOneWidget);
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Leave'));
        await t.pumpAndSettle();
        expect(t.getSize(find.byKey(const ValueKey('leave-confirm'))).height,
            greaterThanOrEqualTo(48));
        // Rapid repeat presses must only close this dialog once.
        final button = t.widget<ElevatedButton>(
            find.byKey(const ValueKey('leave-confirm')));
        button.onPressed!();
        button.onPressed!();
        await t.pumpAndSettle();
        expect(result, true);
        expect(completions, 2);
        expect(find.text('Open'), findsOneWidget);
        await t.tap(find.text('Open'));
        await t.pumpAndSettle();
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(result, isNull);
        expect(completions, 3);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }
}
