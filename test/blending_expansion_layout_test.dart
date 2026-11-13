import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/blending_sounds_screen.dart';
import 'package:kidsphonics/widgets/blending_puzzle_piece.dart';
import 'package:kidsphonics/widgets/cvc_word_picture.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;

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
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
    mockProgressAudio();
  });
  Future<void> finishIntro(
      WidgetTester tester, BlendingLessonController lesson) async {
    for (var i = 0; i < 40 && lesson.phase == BlendingPhase.intro; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump();
    expect(lesson.phase, BlendingPhase.puzzle);
  }

  Future<void> capture(WidgetTester tester, String name) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump();
    }
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('blending-expansion-preview')));
    await tester.runAsync(() async {
      final snapshot = await boundary.toImage(pixelRatio: 1);
      final bytes = await snapshot.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/blending_expansion/previews');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      snapshot.dispose();
    });
  }

  for (final name in [
    'FROG',
    'SNAKE',
    'HELMET',
    'STICK',
    'BOTTLE',
    'TRACTOR'
  ]) {
    for (final view in [
      (size: const Size(320, 568), scale: 2.5),
      (size: const Size(390, 844), scale: 1.0),
      (size: const Size(800, 1024), scale: 2.5),
    ]) {
      testWidgets(
          '$name actual image and puzzle fit ${view.size}, text ${view.scale}',
          (tester) async {
        await tester.binding.setSurfaceSize(view.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final word = blendingLessonWords.singleWhere((w) => w.word == name);
        final lesson = BlendingLessonController(
            words: [word],
            voiceEnabled: false,
            play: (_) async => true,
            stop: () async {});
        final provider = await mount(
            tester,
            MediaQuery(
                data: MediaQueryData(
                    size: view.size,
                    disableAnimations: true,
                    padding: const EdgeInsets.only(top: 24, bottom: 20),
                    textScaler: TextScaler.linear(view.scale)),
                child: RepaintBoundary(
                    key: const ValueKey('blending-expansion-preview'),
                    child: BlendingSoundsScreen(controller: lesson))));
        await finishIntro(tester, lesson);
        expect(tester.widget<CvcWordPicture>(find.byType(CvcWordPicture)).word,
            word);
        final count = word.word.length;
        expect(find.byType(BlendingPuzzlePiece), findsNWidgets(count * 2));
        for (var i = 0; i < count; i++) {
          final slot = tester.getRect(find.byKey(ValueKey('blend-slot-$i')));
          expect(slot.width, greaterThanOrEqualTo(count == 7 ? 28 : 48));
          if (count == 7) {
            expect(slot.left, greaterThanOrEqualTo(0));
            expect(slot.right, lessThanOrEqualTo(view.size.width));
          }
        }
        for (final label in ['Hear Again', 'Try Again', 'Next']) {
          final rect =
              tester.getRect(find.widgetWithText(OutlinedButton, label));
          expect(rect.bottom, lessThan(view.size.height));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(view.size.width));
        }
        await capture(
            tester, '$name-${view.size.width.toInt()}-text-${view.scale}');
        // Pick a repeated or final letter, scroll as needed, and place it.
        final piece = find.byKey(ValueKey('blend-piece-${count - 1}'));
        await tester.ensureVisible(piece);
        await tester.pumpAndSettle();
        await tester.tap(piece);
        await tester.pump();
        final slot = find.byKey(ValueKey('blend-slot-${count - 1}'));
        await tester.ensureVisible(slot);
        await tester.pumpAndSettle();
        await tester.tap(slot);
        await tester.pump();
        expect(lesson.slots.last, count - 1);
        if (name == 'HELMET' && view.size.width == 320) {
          for (var i = 0; i < count - 1; i++) {
            expect(lesson.place(i, i), isTrue);
          }
          for (var i = 0; i < 70; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          expect(lesson.phase, BlendingPhase.complete);
          final result = find.byKey(const ValueKey('blend-whole-word'));
          await tester.ensureVisible(result);
          await tester.pumpAndSettle();
          expect(tester.widget<Text>(result).maxLines, 1);
          final rect = tester.getRect(result);
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(view.size.width));
          await capture(tester, 'HELMET-320-complete');
        }
        expect(tester.takeException(), isNull);
        await close(tester, provider);
      });
    }
  }

  testWidgets(
      'new seven-letter completion persists once with no duplicate rewards',
      (tester) async {
    final word = blendingAdditionalWords.last;
    final lesson = BlendingLessonController(
        words: [word],
        voiceEnabled: false,
        play: (_) async => true,
        stop: () async {});
    final provider = await mount(
        tester,
        MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: BlendingSoundsScreen(controller: lesson)));
    await finishIntro(tester, lesson);
    for (var i = 0; i < word.word.length; i++) {
      lesson.place(i, i);
    }
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() async {
      await provider.completeWordLessonWord(WordLesson.blending, word.word);
      await provider.completeWordLessonWord(WordLesson.blending, word.word);
    });
    expect(provider.wordLessonProgress(WordLesson.blending).completed,
        {word.word});
    expect((provider.xp, provider.stars), (0, 0));
    expect(lesson.phase, BlendingPhase.complete);
    await close(tester, provider);
    late AppProvider restored;
    await tester.runAsync(() async {
      restored = AppProvider();
      await restored.ready;
    });
    expect(restored.wordLessonProgress(WordLesson.blending).completed,
        {word.word});
    restored.dispose();
  });
}
