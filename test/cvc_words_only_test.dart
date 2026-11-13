import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/cvc_lesson_controller.dart';
import 'package:kidsphonics/screens/cvc_words_screen.dart';
import 'package:kidsphonics/widgets/cvc_letter_tile.dart';
import 'package:kidsphonics/widgets/cvc_word_board.dart';
import 'package:kidsphonics/widgets/cvc_word_picture.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

class _Speech {
  final pending = <Completer<bool>>[];
  final heard = <String>[];
  Future<bool> play(String phrase) {
    heard.add(phrase);
    if (phrase.startsWith('cvc-intro-')) return Future.value(true);
    final done = Completer<bool>();
    pending.add(done);
    return done.future;
  }

  Future<void> stop() async {
    for (final done in pending) {
      if (!done.isCompleted) done.complete(false);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Nunito');
    for (final weight in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      font.addFont(rootBundle.load('assets/fonts/Nunito-$weight.ttf'));
    }
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': true, 'sfx': false});
  });

  Future<void> finishIntroduction(
      WidgetTester t, CvcLessonController lesson) async {
    for (var i = 0; i < 80 && lesson.phase == CvcPhase.intro; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    await t.pump();
    expect(lesson.phase, CvcPhase.picture);
  }

  Future<void> capture(WidgetTester t, String name) async {
    for (var i = 0; i < 12; i++) {
      await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await t.pump();
    }
    final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('cvc-words-only-preview')));
    await t.runAsync(() async {
      final snapshot = await boundary.toImage(pixelRatio: 1);
      final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/cvc_words_only');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      snapshot.dispose();
    });
  }

  for (final viewport in [
    (size: const Size(320, 568), scale: 1.0),
    (size: const Size(320, 568), scale: 2.5),
    (size: const Size(390, 844), scale: 1.0),
    (size: const Size(800, 1024), scale: 2.5),
  ]) {
    testWidgets('framed letters fit ${viewport.size}, text ${viewport.scale}',
        (t) async {
      await t.binding.setSurfaceSize(viewport.size);
      addTearDown(() => t.binding.setSurfaceSize(null));
      final speech = _Speech();
      final lesson = CvcLessonController(play: speech.play, stop: speech.stop);
      final p = await mount(
          t,
          MediaQuery(
            data: MediaQueryData(
              size: viewport.size,
              padding: const EdgeInsets.only(top: 24, bottom: 20),
              textScaler: TextScaler.linear(viewport.scale),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
                key: const ValueKey('cvc-words-only-preview'),
                child: CvcWordsScreen(controller: lesson)),
          ));
      await finishIntroduction(t, lesson);
      expect(find.byType(CvcWordPicture), findsNothing);
      expect(find.byType(CvcLetterTile), findsNWidgets(3));
      expect(find.textContaining(RegExp(r'^Word \d+\s*/\s*\d+$')), findsNothing);
      final guide =
          t.getRect(find.byKey(const ValueKey('lesson-dialogue-content')));
      final tiles = [
        for (var i = 0; i < 3; i++)
          t.getRect(find.byKey(ValueKey('cvc-letter-$i'))),
      ];
      for (final tile in tiles) {
        expect(tile.width, greaterThanOrEqualTo(48));
        expect(tile.top, greaterThan(guide.bottom));
        expect(tile.left, greaterThanOrEqualTo(0));
        expect(tile.right, lessThanOrEqualTo(viewport.size.width));
        expect(tile.center.dy, closeTo(tiles.first.center.dy, .1));
      }
      expect(tiles[0].right, lessThan(tiles[1].left));
      expect(tiles[1].right, lessThan(tiles[2].left));
      for (var i = 0; i < 3; i++) {
        final tile = find.byKey(ValueKey('cvc-letter-$i'));
        final label = find.descendant(of: tile, matching: find.byType(Text));
        expect(label, findsOneWidget);
        final frame = t.getRect(tile);
        final glyph = t.getRect(label);
        expect(frame.inflate(.5).contains(glyph.topLeft), true);
        expect(frame.inflate(.5).contains(glyph.bottomRight), true);
      }
      final controls = find.widgetWithText(OutlinedButton, 'Hear Again');
      final controlsRect = t.getRect(controls);
      expect(tiles.last.bottom, lessThan(controlsRect.top));
      final result = t.getRect(find.byKey(const ValueKey('cvc-word-result')));
      expect(result.bottom, lessThan(controlsRect.top));
      expect(controlsRect.bottom, lessThan(viewport.size.height - 10));
      await capture(t,
          '${viewport.size.width.toInt()}x${viewport.size.height.toInt()}-text-${viewport.scale}');
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('tapping a framed letter highlights only its actual sound',
      (t) async {
    final semantics = t.ensureSemantics();
    final speech = _Speech();
    final lesson = CvcLessonController(play: speech.play, stop: speech.stop);
    final p = await mount(t, CvcWordsScreen(controller: lesson));
    await finishIntroduction(t, lesson);
    await t.tap(find.byKey(const ValueKey('cvc-letter-1')));
    await t.pump();
    expect(speech.heard.last, 'lesson-sound-A');
    expect(lesson.highlighted, 1);
    final letterSemantics = t
        .getSemantics(find.byKey(const ValueKey('cvc-letter-1')))
        .getSemanticsData();
    expect(letterSemantics.label, 'Hear A sound');
    expect(letterSemantics.hasAction(ui.SemanticsAction.tap), true);
    expect(
        t
            .widgetList<CvcLetterTile>(find.byType(CvcLetterTile))
            .map((tile) => tile.highlighted),
        [false, true, false]);
    // Old word completion cannot clear the new letter's active highlight.
    expect(speech.pending.first.isCompleted, true);
    expect(speech.pending.last.isCompleted, false);
    speech.pending.last.complete(true);
    await t.pump();
    expect(lesson.highlighted, -1);
    expect(t.takeException(), isNull);
    semantics.dispose();
    await close(t, p);
  });

  testWidgets(
      'blend animation moves independent tiles together without wrapping',
      (t) async {
    final lesson =
        CvcLessonController(play: (_) async => true, stop: () async {});
    late StateSetter rebuild;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 320,
                    child: StatefulBuilder(builder: (context, setState) {
                      rebuild = setState;
                      return CvcWordBoard(lesson: lesson);
                    }))))));
    Rect letter(int index) =>
        t.getRect(find.byKey(ValueKey('cvc-letter-$index')));
    final beforeDistance = letter(2).center.dx - letter(0).center.dx;
    rebuild(() {
      lesson.blend = 1;
      lesson.phase = CvcPhase.complete;
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    final middleDistance = letter(2).center.dx - letter(0).center.dx;
    await t.pump(const Duration(milliseconds: 400));
    final afterDistance = letter(2).center.dx - letter(0).center.dx;
    expect(middleDistance, lessThan(beforeDistance));
    expect(middleDistance, greaterThan(afterDistance));
    for (var i = 0; i < 3; i++) {
      expect(letter(i).width, greaterThanOrEqualTo(48));
      expect(letter(i).center.dy, closeTo(letter(1).center.dy, .1));
    }
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const ValueKey('cvc-whole-word'))).data,
        'CAT');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    lesson.dispose();
  });
}
