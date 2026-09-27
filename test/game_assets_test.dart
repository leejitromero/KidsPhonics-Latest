import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/game_session_order.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/services/phonics_audio_service.dart';

void main() {
  test('all 71 supplied words have paired artwork and new audio', () {
    expect(gameWords, hasLength(71));
    expect(gameWords.map((w) => w.slug).toSet(), hasLength(71));
    for (final w in gameWords) {
      expect(w.frames, hasLength(2));
      for (final frame in w.frames) {
        expect(File(frame).existsSync(), isTrue, reason: frame);
      }
      expect(PhonicsAudioService.assetForPhrase(w.word), w.audioAsset);
      expect(File('assets/${w.audioAsset}').lengthSync(), greaterThan(1000));
      expect(w.word[0], w.letter);
    }
  });
  test('every difficulty uses its supplied vocabulary and no missing pictures',
      () {
    for (final d in Difficulty.values) {
      final words = gameWordsFor(d).map((w) => w.word.toUpperCase()).toSet();
      for (final round in [
        ...soundRoundsForDifficulty(d),
        ...quizQuestionsForDifficulty(d)
      ]) {
        expect(words, contains(round.word.toUpperCase()));
        expect(
            round.options.where((o) => o == round.correctLetter), hasLength(1));
        expect(round.options.toSet(), hasLength(d.index + 3));
      }
      for (final p in pictureRoundsFor(d)) {
        for (final option in p.options) {
          expect(words, contains(option.toUpperCase()));
          expect(gameWordFor(option), isNotNull);
        }
        expect(p.options.where((w) => w == p.correctEmoji), hasLength(1));
      }
    }
  });
  test('replays never repeat the first word and do not mutate the pool', () {
    for (final d in Difficulty.values) {
      final pool = gameWordsFor(d);
      final original = pool.map((w) => w.slug).toList();
      String? previous;
      final signatures = <String>{};
      for (var i = 0; i < 100; i++) {
        final session =
            GameSessionOrder.next('test-${d.name}', pool, (w) => w.slug);
        expect(session.first.slug, isNot(previous));
        expect(session.toSet(), pool.toSet());
        previous = session.first.slug;
        signatures.add(session.map((w) => w.slug).join(','));
      }
      expect(signatures.length, greaterThan(90));
      expect(pool.map((w) => w.slug), original);
    }
  });
  test('retired spoken feedback no longer resolves or ships', () {
    expect(PhonicsAudioService.assetForPhrase('Well done!'), isNull);
    final dir = Directory('assets/audio/phonics/voice_feedback');
    expect(dir.existsSync() ? dir.listSync() : [], isEmpty);
  });
}
