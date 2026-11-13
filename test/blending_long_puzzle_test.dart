import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/widgets/blending_puzzle_piece.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

// Layout/interaction fixtures only; no words without recordings enter the app.
const examples = [
  BlendingLessonWord('FROG', ''),
  BlendingLessonWord('PLANT', ''),
  BlendingLessonWord('STRAND', ''),
  BlendingLessonWord('PUMPKIN', ''),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
  });

  for (final word in examples) {
    testWidgets(
        '${word.word.length} pieces validate, blend and reset completely',
        (tester) async {
      final heard = <String>[];
      final lesson = BlendingLessonController(
          words: [word],
          random: Random(7),
          play: (cue) async {
            heard.add(cue);
            return true;
          },
          stop: () async {});
      final count = word.word.length;
      expect(lesson.order.toSet(), {for (var i = 0; i < count; i++) i});
      expect(lesson.order.map((i) => word.word[i]).join(), isNot(word.word));
      expect(lesson.place(count, count - 1), isFalse);
      expect(lesson.place(count - 1, count), isFalse);
      await tester.pump();
      heard.clear();
      for (var i = count - 1; i >= 0; i--) {
        lesson.choose(i);
        expect(lesson.selected, i);
        expect(lesson.place(i, i), isTrue);
      }
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(heard, [
        for (var i = count - 1; i >= 0; i--) word.soundAudio(i),
        for (var i = 0; i < count; i++) word.soundAudio(i),
        word.wordAudio,
        word.praiseAudio,
      ]);
      expect(lesson.phase, BlendingPhase.complete);
      expect(lesson.running, isFalse);
      expect(lesson.joined, isTrue);
      expect(lesson.place(count - 1, count - 1), isFalse);
      lesson.reset();
      expect(lesson.slots, List<int?>.filled(count, null));
      expect(lesson.complete, isFalse);
      expect(lesson.selected, isNull);
      lesson.dispose();
    });
  }

  testWidgets('changing length cancels late audio and sizes every slot',
      (tester) async {
    final pending = <Completer<bool>>[];
    final heard = <String>[];
    final lesson = BlendingLessonController(
        words: examples,
        play: (cue) {
          heard.add(cue);
          final done = Completer<bool>();
          pending.add(done);
          return done.future;
        },
        stop: () async {});
    for (var i = 0; i < 4; i++) {
      lesson.place(i, i);
    }
    await tester.pump();
    expect(heard, ['lesson-sound-F']);
    lesson.next();
    pending.single.complete(true);
    await tester.pump(const Duration(seconds: 10));
    expect(heard, ['lesson-sound-F']);
    expect(lesson.slots, List<int?>.filled(5, null));
    lesson.next();
    expect(lesson.slots, List<int?>.filled(6, null));
    lesson.next();
    expect(lesson.slots, List<int?>.filled(7, null));
    lesson.next();
    expect(lesson.index, 3);
    lesson.previous();
    expect(lesson.slots, List<int?>.filled(6, null));
    lesson.dispose();
  });

  test('repeated letters are interchangeable but each piece is used once', () {
    final lesson = BlendingLessonController(
        words: const [BlendingLessonWord('RABBIT', '')],
        voiceEnabled: false,
        play: (_) async => true,
        stop: () async {});
    expect(lesson.place(3, 2), isTrue);
    expect(lesson.place(3, 3), isFalse);
    expect(lesson.place(2, 3), isTrue);
    expect(lesson.slots, [null, null, 3, 2, null, null]);
    lesson.dispose();
  });

  testWidgets('all six letters can be dragged into their matching slots',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final lesson = BlendingLessonController(
        words: [examples[2]],
        voiceEnabled: false,
        play: (_) async => true,
        stop: () async {});
    final provider =
        await mount(tester, BlendingSoundsScreen(controller: lesson));
    for (var i = 0; i < 20 && lesson.phase == BlendingPhase.intro; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump();
    expect(lesson.phase, BlendingPhase.puzzle);
    for (var i = 5; i >= 0; i--) {
      final piece = find.byKey(ValueKey('blend-piece-$i'));
      final target = find.byKey(ValueKey('blend-slot-$i'));
      await tester.dragFrom(tester.getCenter(piece),
          tester.getCenter(target) - tester.getCenter(piece));
      await tester.pump();
      expect(lesson.slots[i], i);
    }
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(lesson.phase, BlendingPhase.complete);
    expect(find.text('STRAND'), findsOneWidget);
    expect(provider.dailyActivity, isEmpty);
    expect(provider.xp, 0);
    expect(tester.takeException(), isNull);
    await close(tester, provider);
  });

  for (final word in examples) {
    for (final viewport in [
      (size: const Size(320, 568), scale: 2.0),
      (size: const Size(390, 844), scale: 1.0),
      (size: const Size(800, 1024), scale: 2.0),
    ]) {
      testWidgets(
          '${word.word.length} pieces fit ${viewport.size}, ${viewport.scale}x',
          (tester) async {
        await tester.binding.setSurfaceSize(viewport.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final lesson = BlendingLessonController(
            words: [word],
            random: Random(5),
            voiceEnabled: false,
            play: (_) async => true,
            stop: () async {});
        final provider = await mount(
            tester,
            MediaQuery(
                data: MediaQueryData(
                    size: viewport.size,
                    disableAnimations: true,
                    textScaler: TextScaler.linear(viewport.scale)),
                child: BlendingSoundsScreen(controller: lesson)));
        for (var i = 0; i < 20 && lesson.phase == BlendingPhase.intro; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        await tester.pump();
        expect(lesson.phase, BlendingPhase.puzzle);
        final count = word.word.length;
        for (var i = 0; i < count; i++) {
          final slot = find.byKey(ValueKey('blend-slot-$i'));
          final rect = tester.getRect(slot);
          expect(rect.width, greaterThanOrEqualTo(count == 7 ? 28 : 48));
          expect(rect.top,
              tester.getRect(find.byKey(const ValueKey('blend-slot-0'))).top);
          expect(tester.widget<BlendingPuzzlePiece>(slot).pieceCount, count);
          if (count == 7) {
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(viewport.size.width));
            final piece =
                tester.getRect(find.byKey(ValueKey('blend-piece-$i')));
            expect(piece.left, greaterThanOrEqualTo(0));
            expect(piece.right, lessThanOrEqualTo(viewport.size.width));
          }
        }
        if (count == 7) {
          expect(find.byKey(const ValueKey('blend-puzzle-horizontal-0')),
              findsNothing);
          final slotCenters = [
            for (var i = 0; i < count; i++)
              tester.getCenter(find.byKey(ValueKey('blend-slot-$i'))).dx
          ]..sort();
          final pieceCenters = [
            for (var i = 0; i < count; i++)
              tester.getCenter(find.byKey(ValueKey('blend-piece-$i'))).dx
          ]..sort();
          for (var i = 0; i < count; i++) {
            expect(pieceCenters[i], closeTo(slotCenters[i], .01));
          }
        }
        // Even the last piece remains reachable on the narrowest screen.
        final piece = find.byKey(ValueKey('blend-piece-${count - 1}'));
        await tester.ensureVisible(piece);
        await tester.pumpAndSettle();
        await tester.tap(piece);
        await tester.pump();
        expect(lesson.selected, count - 1);
        final target = find.byKey(ValueKey('blend-slot-${count - 1}'));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pump();
        expect(lesson.slots.last, count - 1);
        expect(lesson.index, 0);
        expect(tester.takeException(), isNull);
        await close(tester, provider);
      });
    }
  }

  test('the puzzle accepts seven letters and rejects unsupported lengths', () {
    for (final name in ['AB', 'ABCDEFGH', 'abcdefg', 'ABC DEF']) {
      expect(
          () => BlendingLessonController(
              words: [BlendingLessonWord(name, '')],
              play: (_) async => true,
              stop: () async {}),
          throwsArgumentError);
    }
    final lesson = BlendingLessonController(
        words: [examples.last], play: (_) async => true, stop: () async {});
    expect(lesson.slots, hasLength(7));
    lesson.dispose();
  });

  testWidgets('seven visible columns accept all dragged letters on a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final lesson = BlendingLessonController(
        words: [examples.last],
        voiceEnabled: false,
        random: Random(9),
        play: (_) async => true,
        stop: () async {});
    final provider =
        await mount(tester, BlendingSoundsScreen(controller: lesson));
    for (var i = 0; i < 20 && lesson.phase == BlendingPhase.intro; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump();
    await tester
        .ensureVisible(find.byKey(const ValueKey('blend-bank-row-PUMPKIN')));
    await tester.pumpAndSettle();
    for (var i = 6; i >= 0; i--) {
      final piece = find.byKey(ValueKey('blend-piece-$i'));
      final target = find.byKey(ValueKey('blend-slot-$i'));
      await tester.dragFrom(tester.getCenter(piece),
          tester.getCenter(target) - tester.getCenter(piece));
      await tester.pump();
      expect(lesson.slots[i], i);
    }
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(lesson.phase, BlendingPhase.complete);
    final word = find.byKey(const ValueKey('blend-whole-word'));
    expect(tester.widget<Text>(word).data, 'PUMPKIN');
    expect(tester.widget<Text>(word).maxLines, 1);
    expect(provider.dailyActivity, isEmpty);
    expect(provider.xp, 0);
    expect(tester.takeException(), isNull);
    await close(tester, provider);
  });

  testWidgets('export 4, 5, 6 and 7 letter previews from the actual puzzle widget',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('long-puzzle-preview');
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(
      key: key,
      child: Material(
          color: const Color(0xFFFFF9EB),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final word in examples)
                Column(children: [
                  Text('${word.word.length} LETTERS',
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF30214F))),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < word.word.length; i++)
                      SizedBox(
                          width: 116,
                          height: 116,
                          child: BlendingPuzzlePiece(
                              position: i,
                              pieceCount: word.word.length,
                              letter: word.word[i],
                              filled: true)),
                  ]),
                ])
            ],
          )),
    )));
    await tester.pumpAndSettle();
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
    await tester.runAsync(() async {
      final snapshot = await boundary.toImage(pixelRatio: 2);
      final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('output/blending_puzzle_preview');
      await directory.create(recursive: true);
      await File('${directory.path}/blending_puzzle_4_5_6_7_letters.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      snapshot.dispose();
    });
    // Also provide individual, transparent rows for reviewing each length.
    for (final word in examples) {
      for (final showLetters in [true, false]) {
        await tester.pumpWidget(MaterialApp(
            home: Material(
          type: MaterialType.transparency,
          child: Center(
              child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: word.word.length * 116 + 20,
              height: 140,
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < word.word.length; i++)
                  SizedBox(
                      width: 116,
                      height: 116,
                      child: BlendingPuzzlePiece(
                          position: i,
                          pieceCount: word.word.length,
                          letter: showLetters ? word.word[i] : null,
                          filled: showLetters)),
              ]),
            ),
          )),
        )));
        await tester.pumpAndSettle();
        final row = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
        await tester.runAsync(() async {
          final snapshot = await row.toImage(pixelRatio: 2);
          final bytes =
              await snapshot.toByteData(format: ui.ImageByteFormat.png);
          final suffix = showLetters ? 'letters' : 'blank';
          await File('output/blending_puzzle_preview/blending_puzzle_'
                  '${word.word.length}_$suffix.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          snapshot.dispose();
        });
      }
    }
  });
}
