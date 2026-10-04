import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/animated_screen_art.dart';
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
  test('all four game background frames are bundled', () async {
    expect(gameFrames, hasLength(4));
    for (final asset in gameFrames) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.getUint32(16), 941);
      expect(bytes.getUint32(20), 1672);
    }
  });
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
