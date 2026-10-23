import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/controllers/alphabet_pictures_controller.dart';
import 'package:kidsphonics/data/alphabet_picture_data.dart';
import 'package:kidsphonics/models/learning_progress.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'package:kidsphonics/screens/alphabet_pictures_screen.dart';
import 'package:kidsphonics/screens/lessons_screen.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';
import 'package:kidsphonics/widgets/lesson_control_button.dart';
import 'package:kidsphonics/widgets/lesson_menu_card.dart';
import 'learning_progress_test.dart' show mockProgressAudio;
import 'learner_ui_test.dart' show mount, close;
import 'updated_scene_test.dart' show capture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    mockProgressAudio();
    SharedPreferences.setMockInitialValues({'voice': false, 'sfx': false});
  });
  test('complete A-Z originals match ZIP hashes and every PNG decodes',
      () async {
    final report = jsonDecode(
        File('tools/alphabet_picture_import.json').readAsStringSync()) as Map;
    expect(alphabetPictures.map((e) => e.letter).join(),
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    expect(report['images'], 78);
    for (final entry in alphabetPictures) {
      expect(entry.frames, hasLength(3));
      for (final path in entry.frames) {
        final bytes = await File(path).readAsBytes();
        final original = (report['files'] as List)
            .singleWhere((file) => file['path'] == path);
        expect(
            sha256.convert(bytes).toString().toUpperCase(), original['sha256']);
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 120);
        final image = (await codec.getNextFrame()).image;
        expect(image.width, greaterThan(0));
        image.dispose();
        codec.dispose();
      }
      // The supplied sentence recordings have their own dedicated namespace.
      expect(PhonicsAudioService.assetForPhrase(entry.phrase),
          alphabetPictureRecordings[entry.letter]);
    }
  });

  test('autoplay and speaker repeat use the currently selected sentence',
      () async {
    final played = <String>[], viewed = <String>[], listened = <String>[];
    final c = AlphabetPicturesController(
        play: (phrase) async {
          played.add(phrase);
          return true;
        },
        stopAudio: () {},
        enabled: () => true,
        available: (_) => true,
        beforePlay: () async {},
        onViewed: viewed.add,
        onListened: (letter) async => listened.add(letter));
    await c.select(0, initial: true);
    await c.select(1);
    await c.replay();
    await c.select(25);
    await c.select(24);
    await c.select(26);
    expect(played, [
      'alphabet-picture-A',
      'alphabet-picture-B',
      'alphabet-picture-B',
      'alphabet-picture-Z',
      'alphabet-picture-Y'
    ]);
    expect(viewed, ['A', 'B', 'Z', 'Y']);
    expect(listened, ['A', 'B', 'B', 'Z', 'Y']);
    c.dispose();
  });

  test('rapid browsing ignores late completion from the previous picture',
      () async {
    final requests = <String, Completer<bool>>{}, listened = <String>[];
    final c = AlphabetPicturesController(
        play: (phrase) => (requests[phrase] = Completer<bool>()).future,
        stopAudio: () {},
        enabled: () => true,
        available: (_) => true,
        beforePlay: () async {},
        onViewed: (_) {},
        onListened: (letter) async => listened.add(letter));
    final first = c.select(0, initial: true);
    await Future<void>.delayed(Duration.zero);
    final second = c.select(1);
    await Future<void>.delayed(Duration.zero);
    requests['alphabet-picture-A']!.complete(true);
    await first;
    expect(listened, isEmpty);
    requests['alphabet-picture-B']!.complete(true);
    await second;
    expect(listened, ['B']);
    c.dispose();
  });

  test(
      'unavailable, disabled, cancelled and disposed speech earns no listening',
      () async {
    var enabled = true, available = false, calls = 0;
    var completion = Completer<bool>();
    final listened = <String>[];
    final c = AlphabetPicturesController(
        play: (_) {
          calls++;
          return completion.future;
        },
        stopAudio: () {},
        enabled: () => enabled,
        available: (_) => available,
        beforePlay: () async {},
        onViewed: (_) {},
        onListened: (letter) async => listened.add(letter));
    await c.select(0, initial: true);
    expect(c.message, 'Audio unavailable.');
    available = true;
    enabled = false;
    await c.replay();
    expect(calls, 0);
    enabled = true;
    final active = c.replay();
    await Future<void>.delayed(Duration.zero);
    c.stop();
    completion.complete(true);
    await active;
    expect(listened, isEmpty);
    completion = Completer<bool>();
    final last = c.replay();
    await Future<void>.delayed(Duration.zero);
    c.dispose();
    completion.complete(true);
    await last;
    expect(listened, isEmpty);
  });

  test('sentence listening persists as the sixth lesson type without rewards',
      () async {
    final p = AppProvider();
    await p.ready;
    await p.recordLetterListening('B', LetterListeningKind.name);
    await p.recordLetterListening('A', LetterListeningKind.sound);
    // A sound counts both the sounds and short-vowel lesson types.
    expect(p.practicedLessonCount, 3);
    await p.recordLetterListening('A', LetterListeningKind.word);
    expect(p.practicedLessonCount, 4);
    await p.completeWordLessonWord(WordLesson.cvc, 'CAT');
    await p.completeWordLessonWord(WordLesson.blending, 'SUN');
    expect(p.practicedLessonCount, 6);
    final restored = AppProvider();
    await restored.ready;
    expect(restored.getLetterProgress('A').wordListens, 1);
    expect(restored.practicedLessonCount, 6);
    expect((restored.xp, restored.stars, restored.overallMasteredCount),
        (0, 0, 0));
    p.dispose();
    restored.dispose();
  });

  for (final (size, scale) in [
    (const Size(320, 568), 1.0),
    (const Size(390, 844), 1.0),
    (const Size(320, 568), 2.0),
    (const Size(800, 1024), 1.3),
    (const Size(844, 390), 1.0)
  ]) {
    testWidgets('picture lesson fits $size at $scale and keeps A-Z navigation',
        (t) async {
      await t.binding.setSurfaceSize(size);
      t.platformDispatcher.textScaleFactorTestValue = scale;
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(() {
        t.binding.setSurfaceSize(null);
        t.platformDispatcher.clearTextScaleFactorTestValue();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
      });
      final boundary = GlobalKey();
      final p = await mount(
          t,
          RepaintBoundary(
              key: boundary, child: const AlphabetPicturesScreen()));
      await t.pumpAndSettle();
      expect(find.text('A is for ant.'), findsOneWidget);
      expect(
          t
              .widget<LessonControlButton>(
                  find.byKey(const ValueKey('alphabet-picture-sound')))
              .onPressed,
          isNull);
      final next = find.widgetWithText(OutlinedButton, 'Next');
      await t.ensureVisible(next);
      await t.pumpAndSettle();
      expect(next.hitTestable(), findsOneWidget);
      await t.tap(next);
      await t.pumpAndSettle();
      expect(find.text('B is for ball.'), findsOneWidget);
      if (size.width == 390) {
        await capture(t, boundary, 'alphabet_pictures_390');
      }
      await t.tap(find.text('A\u2013Z Grid'));
      await t.pumpAndSettle();
      final z = find.byKey(const ValueKey('pick-letter-Z'));
      await t.scrollUntilVisible(z, 120,
          scrollable: find.descendant(
              of: find.byKey(const ValueKey('alphabet-pictures-grid')),
              matching: find.byType(Scrollable)));
      await t.pumpAndSettle();
      await t.ensureVisible(z);
      await t.pumpAndSettle();
      expect(z.hitTestable(), findsOneWidget);
      await t.tap(z);
      await t.pumpAndSettle();
      expect(find.text('Z is for zebra.'), findsOneWidget);
      expect(t.widget<OutlinedButton>(next).onPressed, isNull);
      expect((p.xp, p.stars, p.overallMasteredCount), (0, 0, 0));
      expect(p.getLetterProgress('B').wordListens, 0);
      expect(t.takeException(), isNull);
      await close(t, p);
    });
  }

  testWidgets('Alphabet & Pictures is the fourth of six lesson cards',
      (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final p = await mount(t, const LessonsScreen());
    final cards =
        t.widgetList<LessonMenuCard>(find.byType(LessonMenuCard)).toList();
    expect(cards.map((c) => c.id), [
      'letter_recognition',
      'letter_sounds',
      'vowel_sounds',
      'alphabet_pictures',
      'cvc_words',
      'blending_sounds'
    ]);
    expect((cards[3].mastered, cards[3].total, cards[3].unit),
        (0, 26, 'Listened'));
    final action =
        find.byKey(const ValueKey('lesson-action-alphabet_pictures'));
    await t.ensureVisible(action);
    await t.pumpAndSettle();
    await t.tap(action);
    await t.pumpAndSettle();
    expect(find.byType(AlphabetPicturesScreen), findsOneWidget);
    expect(find.text('A is for ant.'), findsOneWidget);
    await close(t, p);
  });
}
