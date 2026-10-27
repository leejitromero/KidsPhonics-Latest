import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/lesson_menu_art.dart';
import 'package:kidsphonics/data/games_menu_art.dart';
import 'package:kidsphonics/screens/games_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/widgets/game_zone_card.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

Future<void> _loadPreviewFonts(WidgetTester tester) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(() async {
    for (final (family, files) in [
      (
        'Nunito',
        [
          'Nunito-Regular.ttf',
          'Nunito-Bold.ttf',
          'Nunito-ExtraBold.ttf',
          'Nunito-Black.ttf'
        ]
      ),
      ('Fredoka', ['Fredoka-Regular.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
}

Future<void> _capture(
    WidgetTester tester, GlobalKey boundary, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(() => Future.wait(tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => precacheImage(image.image, boundary.currentContext!))));
  await tester.pump();
  await tester.runAsync(() async {
    final render =
        boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/ui_previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Word Builder and Alphabet Order have transparent outer corners',
      () async {
    for (final title in ['Word Builder', 'Alphabet Order']) {
      final bytes = await rootBundle.load(gamesMenuArt[title]!);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final rgba =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(rgba!.getUint8(3), 0, reason: title);
      frame.image.dispose();
      codec.dispose();
    }
  });

  for (final scenario in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(800, 1024), scale: 1.0),
    (size: const Size(800, 600), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    for (final games in [true, false]) {
      final name = games ? 'games' : 'lessons';
      testWidgets(
          '$name supplied cards fit ${scenario.size}, text ${scenario.scale}',
          (tester) async {
        await tester.binding.setSurfaceSize(scenario.size);
        tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(() {
          tester.binding.setSurfaceSize(null);
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        });
        SharedPreferences.setMockInitialValues({'voice': false});
        mockProgressAudio();
        await _loadPreviewFonts(tester);
        final boundary = GlobalKey();
        final provider = await mount(
            tester,
            RepaintBoundary(
                key: boundary,
                child: games ? const GamesScreen() : const LessonsScreen()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final screenshotName = '${name}_cards_${scenario.size.width.toInt()}_'
            '${scenario.size.height.toInt()}_${scenario.scale.toInt()}x';
        await _capture(tester, boundary, screenshotName);

        final titles = games
            ? gamesMenuArt.keys.toList()
            : [
                'Letter Recognition',
                'Letter Sounds A-Z',
                'Short Vowel Sounds',
                'Alphabet & Pictures',
                'CVC Words',
                'Blending Sounds',
              ];
        final assets = games
            ? gamesMenuArt.values.toList()
            : lessonMenuArt.values.toList();
        for (var i = 0; i < titles.length; i++) {
          final target = games
              ? find.byWidgetPredicate((widget) =>
                  widget is GameZoneCard && widget.title == titles[i])
              : find.text(titles[i]);
          await tester.scrollUntilVisible(target, 160,
              scrollable: games
                  ? find
                      .descendant(
                          of: find.byType(GridView),
                          matching: find.byType(Scrollable))
                      .first
                  : find.descendant(
                      of: find.byKey(const PageStorageKey('lessons-scroll')),
                      matching: find.byType(Scrollable)));
          await tester.pumpAndSettle();
          final caption = tester.getRect(target);
          expect(caption.left, greaterThanOrEqualTo(0));
          expect(caption.right, lessThanOrEqualTo(scenario.size.width));
          final art = games
              ? find.byKey(ValueKey('game-art-${titles[i]}'))
              : find.byKey(
                  ValueKey('lesson-art-${lessonMenuArt.keys.elementAt(i)}'));
          expect(art, findsOneWidget);
          final image = tester.widget<Image>(art);
          expect(image.fit, BoxFit.contain);
          expect(
              ((image.image as ResizeImage).imageProvider as AssetImage)
                  .assetName,
              assets[i]);
          if (games) {
            expect(find.descendant(of: target, matching: find.text(titles[i])),
                findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        }
        if (games) {
          final sizes = <Size>[];
          for (final card
              in tester.widgetList<GameZoneCard>(find.byType(GameZoneCard))) {
            expect(card.imageAsset, gamesMenuArt[card.title]);
            final art = find.byKey(ValueKey('game-art-${card.title}'));
            sizes.add(tester.getSize(art));
          }
          expect(sizes.every((size) => size == sizes.first), isTrue,
              reason: 'All eleven game artwork frames have equal dimensions.');
        }
        await _capture(tester, boundary, '${screenshotName}_last');
        await close(tester, provider);
      });
    }
  }
}
