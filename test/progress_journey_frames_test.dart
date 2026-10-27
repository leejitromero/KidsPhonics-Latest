import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'package:kidsphonics/widgets/progress_journey_frames.dart';

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

  test('the supplied streak and summary PNGs are bundled unchanged', () async {
    final entries = jsonDecode(File('tools/progress_journey_frames_import.json')
        .readAsStringSync()
        .replaceFirst('\uFEFF', '')) as List;
    expect(entries, hasLength(2));
    for (final entry in entries) {
      final bytes = await rootBundle.load(entry['path'] as String);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          entry['sha256']);
    }
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(800, 1024), 1.0),
    (const Size(320, 568), 2.5),
    (const Size(844, 390), 1.0),
  ]) {
    testWidgets('journey frame content fits $size text $scale', (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      await t.pumpWidget(MaterialApp(
          theme: KidsUi.theme,
          home: MediaQuery(
              data: MediaQueryData(
                  size: size, textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: RepaintBoundary(
                          key: boundary,
                          child: LayoutBuilder(builder: (_, box) {
                            const streak = ProgressStreakFrame(days: 1);
                            const summary = ProgressLearningSummaryFrame(
                                exploredLetters: 6,
                                practicedLessons: 1,
                                stars: 17);
                            return box.maxWidth < 480 || scale > 1.3
                                ? const Column(children: [
                                    streak,
                                    SizedBox(height: 10),
                                    summary
                                  ])
                                : const Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                        Expanded(flex: 2, child: streak),
                                        SizedBox(width: 10),
                                        Expanded(flex: 3, child: summary)
                                      ]);
                          })))))));
      await t.pumpAndSettle();
      for (final name in ['streak', 'summary']) {
        final frame = t.getRect(find.byKey(ValueKey('journey-$name-frame')));
        final content = find.byKey(ValueKey('journey-$name-content'));
        final area = t.getRect(content);
        expect(frame.contains(area.topLeft), isTrue);
        expect(frame.contains(area.bottomRight), isTrue);
        for (final label in find
            .descendant(of: content, matching: find.byType(Text))
            .evaluate()) {
          final rect = t.getRect(find.byWidget(label.widget));
          expect(area.inflate(.1).contains(rect.topLeft), isTrue);
          expect(area.inflate(.1).contains(rect.bottomRight), isTrue);
        }
        final title = t.getRect(find.byKey(ValueKey('journey-$name-title')));
        expect(frame.contains(title.topLeft), isTrue);
        expect(frame.contains(title.bottomRight), isTrue);
      }
      expect(find.text('1 day'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('1 / 6'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
      if (scale == 1) {
        final tops = [
          for (var i = 0; i < 3; i++)
            t
                .getRect(find.descendant(
                    of: find.byKey(ValueKey('journey-summary-stat-$i')),
                    matching: find.byType(Icon)))
                .top
        ];
        expect(tops[1], closeTo(tops[0], .1));
        expect(tops[2], closeTo(tops[0], .1));
      }
      expect(t.takeException(), isNull);
      if (size.width == 390 && const bool.fromEnvironment('CAPTURE_UI')) {
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
          await File('build/ui_previews/progress_journey_frames_390.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await t.pumpWidget(const SizedBox());
    });
  }
}
