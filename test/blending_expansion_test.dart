import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/models/letter_adventure.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  final groups = {
    4: 'FROG CRAB DRUM FLAG PLUM SLED TRAP PLUG CLAM SLUG HAND TWIG NEST TENT LAMP BELT MASK DESK VEST MILK'
        .split(' '),
    5: 'BLOCK CLOCK BRICK TRUCK PLANT CLAMP STAMP CRUST STUMP FLASK SKUNK SNAIL SNAKE SPOON BRUSH SHELL SHARK TRAIN GRAPE PLANE'
        .split(' '),
    6: 'RABBIT KITTEN PARROT TURTLE MONKEY DONKEY BASKET BUCKET PENCIL HELMET'
        .split(' '),
  };
  BlendingLessonWord word(String name) =>
      blendingExpansionWords.singleWhere((w) => w.word == name);

  test('all approved media match import hashes and preserve old assets', () {
    final report = jsonDecode(
        File('tools/blending_expansion_import.json').readAsStringSync()) as Map;
    expect(report['applied'], isTrue);
    final rows = report['assets'] as List;
    expect(rows, hasLength(150));
    for (final kind in ['word', 'praise', 'image']) {
      expect(rows.where((r) => r['kind'] == kind), hasLength(50));
    }
    for (final row in rows) {
      expect(sha256.convert(File(row['target']).readAsBytesSync()).toString(),
          row['sha256']);
      if (row['kind'] != 'image') {
        expect(row['sourceSha256'], row['sha256']);
        expect(row['nearFullScalePercent'], 0);
      } else {
        expect(row['transparentPixels'], greaterThan(0));
      }
    }
    for (final entry in (report['originalHashes'] as Map).entries) {
      expect(sha256.convert(File(entry.key).readAsBytesSync()).toString(),
          entry.value);
    }
    expect(report['bundledImageBytes'], lessThan(report['sourceImageBytes']));
    final clock =
        rows.singleWhere((r) => r['kind'] == 'word' && r['word'] == 'clock');
    expect(clock['source'], endsWith('/clock.mp3'));
    expect(clock['target'], endsWith('/word-clock.mp3'));
  });

  test('catalogue has 100 unique words and original saved progress is retained',
      () {
    expect(blendingLessonWords, hasLength(100));
    expect(blendingLessonWords.map((w) => w.word).toSet(), hasLength(100));
    expect(blendingLessonWords.take(22), blendingCoreWords);
    expect(blendingExpansionWords.map((w) => w.word),
        groups.values.expand((v) => v));
    for (final entry in groups.entries) {
      expect(
          blendingExpansionWords
              .where((w) => w.word.length == entry.key)
              .map((w) => w.word),
          entry.value);
    }
    final saved = WordLessonProgress.fromJson({
      'started': true,
      'completed': blendingCoreWords.map((w) => w.word).toList(),
    }, WordLesson.blending);
    expect(saved.completed, blendingCoreWords.map((w) => w.word).toSet());
    expect(saved.completed.intersection(groups.values.expand((v) => v).toSet()),
        isEmpty);
    expect(WordLesson.blending.words, hasLength(100));
    // Existing adventure cues/pictures retain the pre-expansion media.
    expect(adventureWordKey('Monkey'), 'Monkey');
    expect(adventurePicture('Monkey'), isNot(word('MONKEY').imageAsset));
  });

  test('every sound group covers the right letters with bundled recordings',
      () {
    for (final item in blendingLessonWords) {
      if (!item.wholeWordOnly) {
        final covered = item.sounds.expand((s) => s.letters).toList()..sort();
        expect(covered, [for (var i = 0; i < item.word.length; i++) i],
            reason: item.word);
      }
      for (var i = 0; i < item.word.length; i++) {
        final sound = item.placementSound(i);
        expect(sound.letters, contains(i));
        if (item.wholeWordOnly) {
          expect(sound.audio, 'lesson-sound-${item.word[i]}',
              reason: item.word);
          expect(sound.letters, [i], reason: item.word);
        }
        final asset = PhonicsAudioService.assetForPhrase(sound.audio);
        expect(asset, isNotNull);
        if (item.wholeWordOnly) {
          expect(asset, contains('/sounds/sound-'));
          expect(asset, isNot(contains('/letters/')));
        }
        expect(File('assets/$asset').existsSync(), isTrue);
      }
    }
    expect(word('BLOCK').sounds.last.letters, [3, 4]);
    expect(word('BLOCK').sounds.last.audio, 'lesson-sound-K');
    expect(word('SNAIL').sounds[2].letters, [2, 3]);
    expect(word('SNAIL').sounds[2].audio, 'lesson-letter-A');
    expect(word('SNAKE').sounds[2].letters, [2, 4]);
    expect(word('SNAKE').sounds[2].audio, 'lesson-letter-A');
    expect(word('SNAKE').sounds.map((s) => s.audio),
        isNot(contains('lesson-sound-E')));
    expect(blendingExpansionWords.where((w) => w.wholeWordOnly), hasLength(15));
  });

  testWidgets(
      'all 100 words finish with ordered placement, blending and praise',
      (tester) async {
    for (final item in blendingLessonWords) {
      final heard = <String>[];
      final lesson = BlendingLessonController(
          words: [item],
          play: (cue) async {
            heard.add(cue);
            return true;
          },
          stop: () async {});
      for (var i = item.word.length - 1; i >= 0; i--) {
        expect(lesson.place(i, i), isTrue);
      }
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
          heard,
          [
            for (var i = item.word.length - 1; i >= 0; i--)
              item.placementSound(i).audio,
            for (final sound in item.sounds) sound.audio,
            item.wordAudio,
            item.praiseAudio,
          ],
          reason: item.word);
      expect(lesson.phase, BlendingPhase.complete);
      expect(lesson.running, isFalse);
      expect(lesson.highlightedLetters, isEmpty);
      lesson.dispose();
    }
  });

  testWidgets('CK and split vowels highlight together until the recording ends',
      (tester) async {
    for (final entry in {'BLOCK': 4, 'SNAKE': 4}.entries) {
      final pending = <Completer<bool>>[];
      final item = word(entry.key);
      final lesson = BlendingLessonController(
          words: [item],
          play: (_) {
            final result = Completer<bool>();
            pending.add(result);
            return result.future;
          },
          stop: () async {});
      lesson.place(entry.value, entry.value);
      await tester.pump();
      expect(lesson.highlightedLetters,
          item.placementSound(entry.value).letters.toSet());
      pending.single.complete(true);
      await tester.pump();
      expect(lesson.highlightedLetters, isEmpty);
      lesson.dispose();
    }
  });

  testWidgets(
      'whole-word listening uses actual recording and never fake phonemes',
      (tester) async {
    final pending = Completer<bool>();
    final heard = <String>[];
    final lesson = BlendingLessonController(
        words: [word('PENCIL')],
        play: (cue) {
          heard.add(cue);
          return pending.future;
        },
        stop: () async {});
    lesson.hearAgain();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(heard, ['blend-word-pencil']);
    expect(lesson.highlightedLetters, {0, 1, 2, 3, 4, 5});
    lesson.next(); // Last word remains active.
    pending.complete(true);
    await tester.pump();
    expect(lesson.complete, isFalse);
    expect(lesson.joined, isFalse);
    expect(lesson.running, isFalse);
    expect(lesson.highlightedLetters, isEmpty);
    lesson.dispose();
  });

  testWidgets('six-letter sounds, word and praise recordings never overlap',
      (tester) async {
    final item = word('HELMET');
    final heard = <String>[];
    final pending = <Completer<bool>>[];
    var active = 0;
    var maxActive = 0;
    final lesson = BlendingLessonController(
        words: [item],
        play: (cue) {
          active++;
          if (active > maxActive) maxActive = active;
          heard.add(cue);
          final result = Completer<bool>();
          pending.add(result);
          return result.future.whenComplete(() => active--);
        },
        stop: () async {});
    for (var i = 0; i < 6; i++) {
      expect(lesson.place(i, i), isTrue);
    }
    final expected = [
      for (var i = 0; i < 6; i++) 'lesson-sound-${item.word[i]}',
      item.wordAudio,
      item.praiseAudio,
    ];
    for (var i = 0; i < expected.length; i++) {
      for (var tick = 0; tick < 20 && heard.length < i + 1; tick++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(heard, expected.take(i + 1).toList(),
          reason: 'voice=${lesson.voiceEnabled}, phase=${lesson.phase}, '
              'highlight=${lesson.highlightedLetters}, unavailable=${lesson.audioUnavailable}, '
              'running=${lesson.running}, active=$active');
      expect(active, 1);
      pending[i].complete(true);
      await tester.pump();
    }
    expect(lesson.phase, BlendingPhase.complete);
    expect(lesson.running, isFalse);
    expect(active, 0);
    expect(maxActive, 1);
    lesson.dispose();
  });

  testWidgets(
      'unavailable whole-word audio still permits a complete replayable puzzle',
      (tester) async {
    final lesson = BlendingLessonController(
        words: [word('PENCIL')], play: (_) async => false, stop: () async {});
    for (var i = 0; i < 6; i++) {
      lesson.place(i, i);
    }
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(lesson.phase, BlendingPhase.complete);
    expect(lesson.running, isFalse);
    expect(lesson.audioUnavailable, isTrue);
    lesson.reset();
    expect(lesson.slots, List<int?>.filled(6, null));
    expect(lesson.audioUnavailable, isFalse);
    lesson.dispose();
  });
}
