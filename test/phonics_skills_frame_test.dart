import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/theme/kids_ui.dart';
import 'package:kidsphonics/widgets/progress_phonics_skills_frame.dart';
import 'package:kidsphonics/widgets/progress_reference_design.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

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
  setUp(mockProgressAudio);

  test('the supplied skills frame is bundled unchanged', () async {
    final entry = jsonDecode(File('tools/phonics_skills_frame_import.json')
        .readAsStringSync()
        .replaceFirst('\uFEFF', '')) as Map;
    final bytes = await rootBundle.load(ProgressPhonicsSkillsFrame.asset);
    expect(entry['path'], ProgressPhonicsSkillsFrame.asset);
    expect(sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
        entry['sha256']);
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(800, 1024), 1.0),
  ]) {
    testWidgets(
        'five skills stay inside their artwork slots at $size text $scale',
        (t) async {
      await t.binding.setSurfaceSize(size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final tapped = <int>[];
      final boundary = GlobalKey();
      const values = [
        ('Letters', 'mastered', 26, 26),
        ('Letter Sounds', 'explored', 26, 26),
        ('Vowels', 'mastered', 5, 5),
        ('CVC Words', 'practiced', 17, 17),
        ('Blending Sounds', 'completed', 22, 22),
      ];
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
                          child: ProgressPhonicsSkillsFrame(children: [
                            for (var i = 0; i < values.length; i++)
                              ProgressSkillRow(
                                  key: ValueKey('skill-$i'),
                                  title: values[i].$1,
                                  unit: values[i].$2,
                                  current: values[i].$3,
                                  total: values[i].$4,
                                  color: Colors.deepPurple,
                                  icon: Icons.volume_up_rounded,
                                  onPressed: () => tapped.add(i)),
                          ])))))));
      await t.pumpAndSettle();
      final frame =
          t.getRect(find.byKey(const ValueKey('phonics-skills-frame')));
      Rect? previous;
      for (var i = 0; i < values.length; i++) {
        final slot = t.getRect(find.byKey(ValueKey('phonics-skills-slot-$i')));
        expect(frame.contains(slot.topLeft), isTrue);
        expect(frame.contains(slot.bottomRight), isTrue);
        if (previous != null) expect(previous.bottom, lessThan(slot.top));
        previous = slot;
        final row = find.byKey(ValueKey('skill-$i'));
        for (final part in [
          find.text(values[i].$1),
          find.text('${values[i].$3} / ${values[i].$4}'),
          find.byType(ProgressValueBar),
        ]) {
          final bounds = t.getRect(find.descendant(of: row, matching: part));
          expect(slot.inflate(.1).contains(bounds.topLeft), isTrue);
          expect(slot.inflate(.1).contains(bounds.bottomRight), isTrue);
        }
      }
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
          await File('build/ui_previews/phonics_skills_frame_390.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      final last = find.byKey(const ValueKey('skill-4'));
      await t.ensureVisible(last);
      await t.pumpAndSettle();
      await t.tap(last);
      await t.pump();
      expect(tapped, [4]);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    });
  }
}
