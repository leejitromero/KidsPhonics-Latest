import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/missing_vowel_screen.dart';
import 'package:kidsphonics/widgets/game_feedback_art.dart';
import 'package:kidsphonics/widgets/learner_widgets.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'learner_ui_test.dart' show mount, close, flushWrites;
import 'learning_progress_test.dart' show mockProgressAudio;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });

  test('both supplied PNGs are bundled byte-for-byte and retain transparency',
      () async {
    final entries = jsonDecode(File('tools/game_feedback_art_import.json')
        .readAsStringSync()
        .replaceFirst('\uFEFF', '')) as List;
    expect(entries, hasLength(2));
    for (final entry in entries) {
      final bytes = await rootBundle.load(entry['path'] as String);
      expect(
          sha256.convert(bytes.buffer.asUint8List()).toString().toUpperCase(),
          entry['sha256']);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final image = (await codec.getNextFrame()).image;
      expect((image.width, image.height), (2172, 724));
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(pixels!.getUint8(3), 0);
      image.dispose();
      codec.dispose();
    }
  });

  for (final difficulty in Difficulty.values) {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(480, 1066), 1.0),
      (const Size(320, 568), 1.8),
    ]) {
      testWidgets('Missing Vowel $difficulty success and Next fit $size $scale',
          (t) async {
        await t.binding.setSurfaceSize(size);
        addTearDown(() => t.binding.setSurfaceSize(null));
        final boundary = GlobalKey();
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                    padding: const EdgeInsets.symmetric(vertical: 24)),
                child: RepaintBoundary(
                    key: boundary,
                    child: MissingVowelScreen(difficulty: difficulty))));
        await t.pumpAndSettle();
        final word = t.widget<WordGameLayout>(find.byType(WordGameLayout)).word;
        final vowel = word[word.indexOf(RegExp('[AEIOU]'))];
        final choice = find.byWidgetPredicate(
            (w) => w is GameAnswerButton && w.label == vowel);
        await t.tap(
            find.descendant(of: choice, matching: find.byType(ElevatedButton)));
        await t.pump(const Duration(milliseconds: 710));
        await flushWrites(t);
        expect(find.byType(GameCorrectFrame), findsOneWidget);
        expect(find.text('Correct!'), findsOneWidget);
        final next = find.byKey(const ValueKey('missing-vowel-next'));
        final frame = t.getRect(find.byType(GameCorrectFrame));
        final button = t.getRect(next);
        expect(frame.bottom, lessThanOrEqualTo(button.top));
        for (final rect in [frame, button]) {
          expect(rect.left, greaterThanOrEqualTo(12));
          expect(rect.right, lessThanOrEqualTo(size.width - 12));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 24));
        }
        expect(button.height, greaterThanOrEqualTo(32));
        expect(p.stars, 1);
        expect(p.xp, (8 * difficulty.xpMultiplier).round());
        if (size.width == 390 && const bool.fromEnvironment('CAPTURE_UI')) {
          await t.runAsync(() async {
            await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
                (im) => precacheImage(im.image, boundary.currentContext!)));
          });
          await t.pumpAndSettle();
          final render = boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
          await t.runAsync(() async {
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
                    'build/ui_previews/missing_vowel_feedback_${difficulty.name}.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await t.tap(next);
        await t.pump();
        expect(find.byType(GameCorrectFrame), findsNothing);
        expect(find.byType(MissingVowelNextButton), findsNothing);
        expect(p.stars, 1);
        expect(find.byType(Scrollable), findsNothing);
        expect(t.takeException(), isNull);
        await close(t, p);
      });
    }
  }
}
