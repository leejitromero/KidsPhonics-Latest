import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/widgets/recommended_practice_card.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final (width, scale) in [
    (320.0, 1.0),
    (390.0, 1.0),
    (320.0, 2.0),
    (800.0, 1.3)
  ]) {
    for (final (title, description, label) in [
      ('Practice Letter B', 'Take your next Quick Check.', 'Start Quick Check'),
      ('Review Letter B', 'Let’s try this letter again!', 'Start Quick Check'),
      (
        'All 26 letters mastered!',
        'Keep exploring and practicing.',
        'Choose a Letter'
      )
    ]) {
      testWidgets('recommendation fits $width x$scale: $title', (t) async {
        await t.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final boundary = GlobalKey();
        var taps = 0;
        await t.pumpWidget(MaterialApp(
            home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                    body: Padding(
                        padding: const EdgeInsets.all(12),
                        child: RepaintBoundary(
                            key: boundary,
                            child: RecommendedPracticeCard(
                                leading: const Text('B',
                                    style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFF14890))),
                                title: title,
                                description: description,
                                buttonLabel: label,
                                actionKey: const ValueKey(
                                    'recommendation-test-action'),
                                onPressed: () => taps++)))))));
        await t.pumpAndSettle();
        final card = find.byType(RecommendedPracticeCard);
        final bounds = t.getRect(card);
        for (final text in find
            .descendant(of: card, matching: find.byType(Text))
            .evaluate()) {
          final rect = t.getRect(find.byWidget(text.widget));
          expect(bounds.contains(rect.topLeft), true);
          expect(bounds.contains(rect.bottomRight), true);
        }
        expect(t.getRect(find.text(title)).bottom,
            lessThanOrEqualTo(t.getRect(find.text(description)).top + .01));
        final button = find.byKey(const ValueKey('recommendation-test-action'));
        expect(t.getRect(button).height, greaterThanOrEqualTo(48));
        final buttonText = t.getRect(find.text(label));
        expect(t.getRect(button).contains(buttonText.topLeft), true);
        expect(t.getRect(button).contains(buttonText.bottomRight), true);
        expect(t.getRect(find.text(description)).bottom,
            lessThan(t.getRect(button).top));
        await t.tap(button);
        await t.pumpAndSettle();
        expect(taps, 1);
        expect(t.takeException(), isNull);
        if (width == 390 &&
            title == 'Practice Letter B' &&
            const bool.fromEnvironment('CAPTURE_UI')) {
          await t.runAsync(() async {
            for (final image in t.widgetList<Image>(find.byType(Image))) {
              await precacheImage(image.image, boundary.currentContext!);
            }
          });
          await t.pumpAndSettle();
          await t.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('build/ui_previews/recommended_practice_390.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      });
    }
  }
  testWidgets('disabled recommendation keeps its action unavailable',
      (t) async {
    await t.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: RecommendedPracticeCard(
                leading: Text('A'),
                title: 'Practice Letter A',
                description: 'Take your next Quick Check.',
                buttonLabel: 'Start Quick Check',
                onPressed: null))));
    await t.pumpAndSettle();
    expect(t.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(t.takeException(), isNull);
  });
}
