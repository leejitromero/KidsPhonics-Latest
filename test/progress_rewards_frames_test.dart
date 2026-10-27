import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/models/progress_badge.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'package:kidsphonics/widgets/progress_reference_design.dart';
import 'package:kidsphonics/widgets/progress_rewards_frames.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fonts = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      fonts.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await fonts.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  test('all four supplied reward PNGs are bundled unchanged', () async {
    final entries = jsonDecode(File('tools/progress_rewards_frames_import.json')
        .readAsStringSync()
        .replaceFirst('\uFEFF', '')) as List;
    expect(entries, hasLength(4));
    for (final entry in entries) {
      final bytes = await rootBundle.load(entry['path'] as String);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          entry['sha256']);
    }
  });

  for (final (width, scale) in [
    (320.0, 1.0),
    (390.0, 1.0),
    (800.0, 1.0),
    (320.0, 2.5)
  ]) {
    testWidgets('all rewards content fits frames at $width text $scale',
        (t) async {
      await t.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      await t.pumpWidget(MaterialApp(
          theme: KidsUi.theme,
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 844), textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: RepaintBoundary(
                              key: boundary,
                              child: Column(children: [
                                const ProgressRewardsHeader(
                                    earned: 1, total: 8),
                                const SizedBox(height: 8),
                                for (final (index, title, description, earned)
                                    in [
                                  (
                                    0,
                                    'First Letter Mastery',
                                    'Master 1 letter in Quick Check.',
                                    false
                                  ),
                                  (
                                    1,
                                    'Vowel Star',
                                    'Master all 5 vowels in Quick Check.',
                                    false
                                  ),
                                  (
                                    3,
                                    'Blending Champion',
                                    'Complete your first blending word puzzle.',
                                    false
                                  ),
                                  (
                                    4,
                                    '3-Day Streak',
                                    'Answer questions or practice speaking on 3 consecutive days.',
                                    true
                                  ),
                                  (
                                    7,
                                    'Alphabet Master',
                                    'Master 26 letters in Quick Check.',
                                    false
                                  ),
                                ]) ...[
                                  ProgressBadgeCard(
                                      badge: ProgressBadge(
                                          id: title,
                                          title: title,
                                          description: description,
                                          current: earned ? 26 : 0,
                                          target: 26),
                                      index: index,
                                      onPressed: () {}),
                                  const SizedBox(height: 8),
                                ],
                                const ProgressRewardsHeader(),
                                const SizedBox(height: 8),
                                const ProgressTreasureFrame(
                                    level: 5,
                                    stars: 94,
                                    xp: 950,
                                    progressBar: ProgressValueBar(
                                        current: 150,
                                        total: 200,
                                        color: Colors.purple)),
                              ]))))))));
      await t.pumpAndSettle();
      for (final type in [
        ProgressBadgeCard,
        ProgressRewardsHeader,
        ProgressTreasureFrame
      ]) {
        for (final frame in find.byType(type).evaluate()) {
          final target = find.byWidget(frame.widget);
          final bounds = t.getRect(target);
          for (final text in find
              .descendant(of: target, matching: find.byType(Text))
              .evaluate()) {
            final rect = t.getRect(find.byWidget(text.widget));
            expect(bounds.inflate(.1).contains(rect.topLeft), isTrue,
                reason: '${(text.widget as Text).data} top');
            expect(bounds.inflate(.1).contains(rect.bottomRight), isTrue,
                reason: '${(text.widget as Text).data} bottom');
          }
          final image = find.descendant(
              of: target, matching: find.byType(ProgressRewardArtwork));
          expect(t.getSize(image).width, closeTo(bounds.width, .01));
          expect(t.getSize(image).height, closeTo(bounds.height, .01));
        }
      }
      expect(t.takeException(), isNull);
      final treasureContent =
          find.byKey(const ValueKey('rewards-treasure-content'));
      final treasureArea = t.getRect(treasureContent).inflate(.1);
      for (final label in find
          .descendant(of: treasureContent, matching: find.byType(Text))
          .evaluate()) {
        final rect = t.getRect(find.byWidget(label.widget));
        expect(treasureArea.contains(rect.topLeft), isTrue);
        expect(treasureArea.contains(rect.bottomRight), isTrue);
      }
      if (width == 390 && const bool.fromEnvironment('CAPTURE_UI')) {
        await t.runAsync(() async {
          await Future.wait(t
              .widgetList<Image>(find.byType(Image))
              .map((im) => precacheImage(im.image, boundary.currentContext!)));
        });
        await t.pumpAndSettle();
        await t.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('build/ui_previews/rewards_frames_390.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
