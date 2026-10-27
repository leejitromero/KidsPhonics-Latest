import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/screens/rumbled_words_screen.dart';
import 'package:kidsphonics/widgets/word_game_layout.dart';
import 'package:kidsphonics/widgets/game_word_picture.dart';
import 'learner_ui_test.dart' show mount, close;
import 'learning_progress_test.dart' show mockProgressAudio;
import 'rumbled_words_swap_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
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

  for (final difficulty in Difficulty.values) {
    for (final (size, scale) in [
      (const Size(320, 568), 1.0),
      (const Size(390, 844), 1.0),
      (const Size(480, 1066), 1.0),
      (const Size(800, 1024), 1.0),
      (const Size(320, 568), 1.8),
    ]) {
      testWidgets('${difficulty.name} spelling controls fit $size text $scale',
          (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(() {
          t.view.resetPhysicalSize();
          t.view.resetDevicePixelRatio();
          t.view.resetPadding();
        });
        final boundary = GlobalKey();
        final p = await mount(
            t,
            MediaQuery(
                data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    disableAnimations: true),
                child: RepaintBoundary(
                    key: boundary,
                    child: RumbledWordsScreen(difficulty: difficulty))));
        await t.pumpAndSettle();
        final length =
            t.widget<WordGameLayout>(find.byType(WordGameLayout)).word.length;
        Rect rect(String key) {
          final box = t.renderObject<RenderBox>(find.byKey(ValueKey(key)));
          return MatrixUtils.transformRect(
              box.getTransformTo(null), Offset.zero & box.size);
        }

        void checkBounds() {
          final picture = t.getRect(find.byType(GameWordPicture));
          expect(picture.height, greaterThanOrEqualTo(length > 5 ? 80 : 104));
          expect(picture.bottom, lessThan(rect('word-letter-board').top));
          expect(picture.top, greaterThanOrEqualTo(24));
          final controls = [
            'word-hint',
            'word-hear',
            'word-check',
            for (var i = 0; i < length; i++) 'word-tile-$i',
          ];
          for (final key in controls) {
            final bounds = rect(key);
            expect(bounds.left, greaterThanOrEqualTo(12), reason: key);
            expect(bounds.right, lessThanOrEqualTo(size.width - 12),
                reason: key);
            expect(bounds.top, greaterThanOrEqualTo(24), reason: key);
            expect(bounds.bottom, lessThanOrEqualTo(size.height - 24),
                reason: key);
            expect(bounds.height,
                greaterThanOrEqualTo(key.startsWith('word-tile-') ? 24 : 32),
                reason: key);
            if (['word-hint', 'word-hear'].contains(key)) {
              expect(bounds.height, lessThanOrEqualTo(44.1), reason: key);
            }
          }
          expect(rect('word-hear').bottom,
              lessThan(rect('word-letter-board').top));
          expect(rect('word-hint').right, lessThan(rect('word-hear').left));
          expect(rect('word-letter-board').bottom,
              lessThan(rect('word-check').top));
          for (var i = 0; i < length; i++) {
            final tile = rect('word-tile-$i');
            expect(tile.center.dy, closeTo(rect('word-tile-0').center.dy, .1),
                reason: 'All letters stay on one reading line');
            expect(rect('word-letter-board').contains(tile.topLeft), isTrue);
            expect(
                rect('word-letter-board').contains(tile.bottomRight), isTrue);
            if (i > 0) {
              expect(tile.left, greaterThan(rect('word-tile-${i - 1}').right));
            }
            final letter = find.descendant(
                of: find.byKey(ValueKey('word-tile-$i')),
                matching: find.byType(Text));
            expect(letter, findsOneWidget);
            final textBox = t.renderObject<RenderBox>(letter);
            final ink = MatrixUtils.transformRect(
                textBox.getTransformTo(null), Offset.zero & textBox.size);
            expect(
                rect('word-tile-$i').inflate(.1).contains(ink.topLeft), isTrue);
            expect(rect('word-tile-$i').inflate(.1).contains(ink.bottomRight),
                isTrue);
          }
          expect(find.byType(Scrollable), findsNothing);
          expect(t.takeException(), isNull);
        }

        checkBounds();
        if ((size.width == 390 || size.width == 480) &&
            const bool.fromEnvironment('CAPTURE_UI')) {
          await t.runAsync(() async {
            await Future.wait(t.widgetList<Image>(find.byType(Image)).map(
                (im) => precacheImage(im.image, boundary.currentContext!)));
          });
          await t.pumpAndSettle();
          await t.runAsync(() async {
            final picture = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
            final bytes =
                await picture.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                'build/ui_previews/rumbled_compact_${difficulty.name}_${size.width.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        expect(find.byKey(const ValueKey('word-answer-board')), findsNothing);
        expect(find.byKey(const ValueKey('word-erase')), findsNothing);
        final before = boardLetters(t, length);
        await tapBoardLetter(t, 0);
        expect(
            find.text('Drag the floating letter into place.'), findsOneWidget);
        await tapBoardLetter(t, 0);
        expect(boardLetters(t, length), before);
        await t.tap(find.byKey(const ValueKey('word-check')));
        await t.pump();
        expect(
            find.text('Try again! Drag a letter into place.'), findsOneWidget);
        expect(boardLetters(t, length), before);
        checkBounds();
        await t.tap(find.byKey(const ValueKey('word-hint')));
        await t.pumpAndSettle();
        expect(find.text('Hint used: first letter fixed'), findsOneWidget);
        expect(
            t
                .widget<OutlinedButton>(find.byKey(const ValueKey('word-hint')))
                .onPressed,
            isNull);
        expect(
            t
                .widget<ElevatedButton>(
                    find.byKey(const ValueKey('word-tile-0')))
                .onPressed,
            isNull);
        checkBounds();
        expect(p.xp, 0);
        await close(t, p);
      });
    }
  }
}
