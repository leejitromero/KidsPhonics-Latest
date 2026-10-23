import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/screens/progress_screen.dart';
import 'package:kidsphonics/widgets/progress_collection_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void main() {
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
  });

  for (final (size, scale) in [
    (const Size(56, 65), 1.0),
    (const Size(65, 76), 2.0),
    (const Size(112, 130), 1.3)
  ]) {
    testWidgets('letter frames and checks fit $size at text scale $scale',
        (t) async {
      const letters = [
        LetterProgress(letter: 'A'),
        LetterProgress(letter: 'B', viewCount: 1),
        LetterProgress(letter: 'C', attempts: 1),
        LetterProgress(letter: 'D', mastered: true)
      ];
      final tapped = <String>[];
      await t.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: Wrap(children: [
                for (final letter in letters)
                  SizedBox(
                      width: size.width,
                      height: size.height,
                      child: ProgressLetterTile(
                          letter: letter,
                          onPressed: () => tapped.add(letter.letter)))
              ])))));
      await t.pumpAndSettle();
      for (final letter in letters) {
        final tile = find.byKey(ValueKey('progress-letter-${letter.letter}'));
        final image = t.widget<Image>(
            find.byKey(ValueKey('progress-letter-frame-${letter.letter}')));
        final asset = (image.image as ResizeImage).imageProvider as AssetImage;
        expect(
            asset.assetName,
            letter.mastered
                ? ProgressLetterTile.greenFrame
                : ProgressLetterTile.purpleFrame);
        final text = t.getRect(
            find.descendant(of: tile, matching: find.text(letter.letter)));
        final bounds = t.getRect(tile);
        expect(bounds.contains(text.topLeft), true);
        expect(bounds.contains(text.bottomRight), true);
        final check =
            find.byKey(ValueKey('progress-letter-check-${letter.letter}'));
        expect(check, letter.mastered ? findsOneWidget : findsNothing);
        if (letter.mastered) {
          final mark = t.getRect(check);
          final circle = Rect.fromLTWH(
              bounds.left + bounds.width * .44,
              bounds.top + bounds.height * .87,
              bounds.width * .13,
              bounds.height * .10);
          expect(circle.contains(mark.topLeft), true);
          expect(circle.contains(mark.bottomRight), true);
        }
        await t.tap(tile);
        await t.pump();
      }
      expect(tapped, ['A', 'B', 'C', 'D']);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('mastery changes only its frame and preserves letter details',
      (t) async {
    await t.binding.setSurfaceSize(const Size(390, 844));
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(() {
      t.binding.setSurfaceSize(null);
      t.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
    final boundary = GlobalKey();
    final p = await mount(
        t, RepaintBoundary(key: boundary, child: const ProgressScreen()));
    await t.runAsync(() =>
        p.completeAdventure('A', List.filled(5, true), 'letter-frame-mastery'));
    await t.pumpAndSettle();
    final rewards = (p.xp, p.stars);
    await t.tap(find.byKey(const ValueKey('progress-tab-1')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
        find.byKey(const ValueKey('progress-letter-A')), 100,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('progress-letter-check-A')), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-letter-check-B')), findsNothing);
    await capture(t, boundary, 'progress_letter_frames_390');
    await t.tap(find.byKey(const ValueKey('progress-letter-A')));
    await t.pumpAndSettle();
    expect(find.text('Letter A'), findsOneWidget);
    expect((p.xp, p.stars), rewards);
    expect(p.overallMasteredCount, 1);
    expect(t.takeException(), isNull);
    await close(t, p);
  });
}
