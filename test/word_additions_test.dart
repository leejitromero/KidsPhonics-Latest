import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/controllers/blending_lesson_controller.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/models/word_lesson_progress.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  final cvc =
      'DAD PAD NAP TAP DEN PEG VET FED LID ZIP DIP SIP COT FOG ROD JOB HUG CUT RUB TUG'
          .split(' ');
  final blending =
      'STICK DRESS GLASS CRATE SKATE CHICK BENCH SWING BOTTLE BUTTON CANDLE CARROT FLOWER HAMMER LADDER SPIDER MAGNET RIBBON BLANKET CHICKEN DOLPHIN GIRAFFE HAMSTER PENGUIN BALLOON PUMPKIN TRUMPET TRACTOR'
          .split(' ');
  BlendingLessonWord word(String name) =>
      blendingAdditionalWords.singleWhere((entry) => entry.word == name);

  test('only the approved 20 CVC and 28 Blending words are appended', () {
    expect(cvcAdditionalWords.map((w) => w.word), cvc);
    expect(blendingAdditionalWords.map((w) => w.word), blending);
    expect(cvcLessonWords, hasLength(70));
    expect(blendingLessonWords, hasLength(100));
    expect(cvcLessonWords.map((w) => w.word).toSet(), hasLength(70));
    expect(blendingLessonWords.map((w) => w.word).toSet(), hasLength(100));
    expect(cvcLessonWords.skip(50), cvcAdditionalWords);
    expect(blendingLessonWords.take(72),
        [...blendingCoreWords, ...blendingExpansionWords]);
    expect(blendingLessonWords.skip(72), blendingAdditionalWords);
    expect(
        blendingAdditionalWords.where((w) => w.word.length == 5), hasLength(8));
    expect(blendingAdditionalWords.where((w) => w.word.length == 6),
        hasLength(10));
    expect(blendingAdditionalWords.where((w) => w.word.length == 7),
        hasLength(10));
    expect(blendingAdditionalWords.where((w) => w.word.length < 5), isEmpty);
  });

  test('all 124 imported files match validated media; old assets are unchanged',
      () {
    final report =
        jsonDecode(File('tools/word_additions_import.json').readAsStringSync())
            as Map;
    expect(report['applied'], isTrue);
    expect(report['validatedCount'], 124);
    final rows = report['assets'] as List;
    expect(rows.where((r) => r['lesson'] == 'cvc'), hasLength(40));
    expect(rows.where((r) => r['lesson'] == 'blending'), hasLength(84));
    expect(rows.where((r) => r['kind'] == 'image'), hasLength(28));
    expect(rows.where((r) => r['kind'] != 'image'), hasLength(96));
    expect(rows.map((r) => r['target']).toSet(), hasLength(124));
    for (final row in rows) {
      final bytes = File(row['target']).readAsBytesSync();
      expect(sha256.convert(bytes).toString(), row['sha256']);
      if (row['kind'] != 'image') {
        expect(row['sha256'], row['sourceSha256']);
        expect(row['nearFullScalePercent'], 0);
        expect(row['durationSeconds'], inExclusiveRange(.2, 20));
        final prefix = row['lesson'] == 'cvc' ? 'cvc' : 'blend';
        expect(
            'assets/${PhonicsAudioService.assetForPhrase('$prefix-${row['kind']}-${row['word']}')}',
            row['target']);
      } else {
        expect(row['transparentPixels'], greaterThan(0));
        expect(word((row['word'] as String).toUpperCase()).imageAsset,
            row['target']);
      }
    }
    expect(report['bundledImageBytes'], lessThan(report['sourceImageBytes']));
    for (final original in (report['originalHashes'] as Map).entries) {
      expect(sha256.convert(File(original.key).readAsBytesSync()).toString(),
          original.value);
    }
  });

  test(
      'sound groups cover letters correctly and complex words use supplied audio',
      () {
    for (final item in blendingAdditionalWords) {
      if (!item.wholeWordOnly) {
        final covered = item.sounds.expand((s) => s.letters).toList()..sort();
        expect(covered, [for (var i = 0; i < item.word.length; i++) i],
            reason: item.word);
      }
      for (var i = 0; i < item.word.length; i++) {
        final asset =
            PhonicsAudioService.assetForPhrase(item.placementSound(i).audio);
        expect(asset, isNotNull);
        expect(File('assets/$asset').existsSync(), isTrue);
      }
    }
    expect(word('STICK').sounds.last.letters, [3, 4]);
    expect(word('STICK').sounds.last.audio, 'lesson-sound-K');
    for (final name in ['DRESS', 'GLASS']) {
      expect(word(name).sounds.last.letters, [3, 4]);
      expect(word(name).sounds.last.audio, 'lesson-sound-S');
    }
    for (final name in ['CRATE', 'SKATE']) {
      expect(word(name).sounds[2].letters, [2, 4]);
      expect(word(name).sounds[2].audio, 'lesson-letter-A');
      expect(word(name).sounds.map((s) => s.audio),
          isNot(contains('lesson-sound-E')));
    }
    expect(word('DOLPHIN').sounds[3].letters, [3, 4]);
    expect(word('DOLPHIN').sounds[3].audio, 'lesson-sound-F');
    expect(word('PUMPKIN').sounds, hasLength(7));
    for (final name in ['CHICK', 'BENCH', 'SWING', 'BOTTLE', 'TRACTOR']) {
      expect(word(name).wholeWordOnly, isTrue);
      expect(word(name).sounds, isEmpty);
    }
  });

  test('expanded catalogues retain old progress and accept new completions',
      () {
    for (final lesson in WordLesson.values) {
      final old = lesson.words.take(lesson == WordLesson.cvc ? 50 : 72).toSet();
      final restored = WordLessonProgress.fromJson(
          {'started': true, 'completed': old.toList()}, lesson);
      expect(restored.completed, old);
      expect(restored.started, isTrue);
      final expanded = WordLessonProgress.fromJson({
        'started': true,
        'completed': [...old, lesson == WordLesson.cvc ? 'TUG' : 'TRACTOR'],
      }, lesson);
      expect(expanded.completed,
          {...old, lesson == WordLesson.cvc ? 'TUG' : 'TRACTOR'});
    }
  });

  testWidgets(
      'all 28 additions complete ordered placement, word and praise without overlap',
      (tester) async {
    for (final item in blendingAdditionalWords) {
      final heard = <String>[];
      var active = 0, maximum = 0;
      final lesson = BlendingLessonController(
          words: [item],
          play: (phrase) async {
            active++;
            if (active > maximum) maximum = active;
            heard.add(phrase);
            await Future<void>.value();
            active--;
            return true;
          },
          stop: () async {});
      for (var i = item.word.length - 1; i >= 0; i--) {
        expect(lesson.place(i, i), isTrue);
      }
      for (var i = 0; i < 50; i++) {
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
      expect(maximum, 1);
      expect(active, 0);
      expect(lesson.phase, BlendingPhase.complete);
      expect(lesson.running, isFalse);
      expect(lesson.highlightedLetters, isEmpty);
      lesson.dispose();
    }
  });
}
