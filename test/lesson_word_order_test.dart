import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidsphonics/data/blending_lesson_data.dart';
import 'package:kidsphonics/data/cvc_lesson_data.dart';
import 'package:kidsphonics/data/lesson_word_order.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> restart(SharedPreferences prefs) async {
    SharedPreferences.setMockInitialValues({
      for (final key in prefs.getKeys()) key: prefs.get(key)!,
    });
    return SharedPreferences.getInstance();
  }

  for (final entry in {
    'cvc': cvcLessonWords,
    'blending': blendingLessonWords,
  }.entries) {
    test('${entry.key} covers every word across short visits and app restarts',
        () async {
      var prefs = await SharedPreferences.getInstance();
      final pool = entry.value.map((word) => word.word).toSet();
      String? last;
      for (var cycle = 0; cycle < 2; cycle++) {
        final shown = <String>{};
        for (var visit = 0; visit < pool.length; visit++) {
          final history = LessonWordHistory(
              preferences: prefs, random: Random(cycle * 100 + visit));
          final session = history.open(entry.key, entry.value, (w) => w.word);
          expect(session.words.map((w) => w.word).toSet(), pool);
          expect(session.words, hasLength(pool.length));
          final word = session.words.first.word;
          expect(shown.add(word), isTrue,
              reason: 'Unseen words must come first');
          expect(word, isNot(last));
          expect(await session.show(0), isTrue);
          last = word;
          prefs = await restart(prefs);
        }
        expect(shown, pool);
      }
    });
  }

  test('opening does not consume unseen words; back/forward keeps stable order',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final history = LessonWordHistory(preferences: prefs, random: Random(3));
    final pool = List.generate(12, (i) => 'word-$i');
    final abandoned = history.open('cvc', pool, (w) => w);
    expect(prefs.containsKey(LessonWordHistory.storageKey), isFalse);
    final session = history.open('cvc', pool, (w) => w);
    final order = List.of(session.words);
    await session.show(0);
    await session.show(1);
    await session.show(0);
    await session.show(1);
    await session.show(-1);
    await session.show(12);
    expect(session.words, order);
    expect(() => session.words.clear(), throwsUnsupportedError);
    var stored = jsonDecode(prefs.getString(LessonWordHistory.storageKey)!);
    expect(stored['lessons']['cvc']['remaining'], hasLength(10));
    final next = history.open('cvc', pool, (w) => w);
    expect(next.words.take(10).toSet(),
        pool.toSet().difference(order.take(2).toSet()));
    expect(next.words.first, isNot(order.first));
    expect(next.words.first, isNot(order[1]));
    await next.show(0);
    final before = prefs.getString(LessonWordHistory.storageKey);
    await abandoned.show(0);
    await session.show(2);
    expect(prefs.getString(LessonWordHistory.storageKey), before);
    stored = jsonDecode(before!);
    expect(stored['lessons']['cvc']['remaining'], hasLength(9));
  });

  test('catalog updates preserve unseen words and prioritize added words',
      () async {
    var prefs = await SharedPreferences.getInstance();
    var history = LessonWordHistory(preferences: prefs, random: Random(5));
    final first = history.open('blend', ['A', 'B', 'C', 'D'], (w) => w);
    await first.show(0);
    final seen = first.words.first;
    final retired = first.words.last;
    prefs = await restart(prefs);
    history = LessonWordHistory(preferences: prefs, random: Random(8));
    final updated = ['A', 'B', 'C', 'D', 'NEW', 'NEW']..remove(retired);
    final session = history.open('blend', updated, (w) => w);
    expect(session.words, hasLength(4));
    expect(session.words.take(3).toSet(), updated.toSet().difference({seen}));
    expect(session.words.last, seen);
    expect(session.words, isNot(contains(retired)));
  });

  test('CVC, blending and game/progress data stay independent', () async {
    SharedPreferences.setMockInitialValues({
      'gameSessionOrderV1': 'existing-game-history',
      'appStateV1': 'existing-progress',
    });
    final prefs = await SharedPreferences.getInstance();
    final history = LessonWordHistory(preferences: prefs, random: Random(7));
    const pool = ['A', 'B', 'C'];
    await history.open('cvc', pool, (w) => w).show(0);
    final blend = history.open('blending', pool, (w) => w);
    await blend.show(0);
    final data = jsonDecode(prefs.getString(LessonWordHistory.storageKey)!);
    expect(data['lessons']['cvc']['remaining'], hasLength(2));
    expect(data['lessons']['blending']['remaining'], hasLength(2));
    expect(prefs.getString('gameSessionOrderV1'), 'existing-game-history');
    expect(prefs.getString('appStateV1'), 'existing-progress');
  });

  for (final damaged in <Object>[
    42,
    '{broken',
    '[]',
    '{"version":2,"lessons":{}}',
    '{"version":1,"lessons":{"cvc":{"pool":["A"],"remaining":["X"]}}}',
    '{"version":1,"lessons":{"cvc":{"pool":["A","A"],"remaining":[]}}}',
  ]) {
    test('invalid history $damaged does not block lessons', () async {
      SharedPreferences.setMockInitialValues(
          {LessonWordHistory.storageKey: damaged});
      final prefs = await SharedPreferences.getInstance();
      final history = LessonWordHistory(preferences: prefs, random: Random(1));
      final session = history.open('cvc', ['A', 'B'], (w) => w);
      expect(session.words.toSet(), {'A', 'B'});
      expect(await session.show(0), isTrue);
    });
  }

  test('empty and single-word pools remain safe', () async {
    final history = LessonWordHistory(random: Random(1));
    expect(history.open<String>('empty', [], (w) => w).words, isEmpty);
    for (var i = 0; i < 3; i++) {
      final session = history.open('one', ['A', 'A'], (w) => w);
      expect(session.words, ['A']);
      expect(await session.show(0), isTrue);
    }
  });
}
