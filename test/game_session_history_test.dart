import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:kidsphonics/data/game_session_order.dart';
import 'package:kidsphonics/data/game_word_data.dart';
import 'package:kidsphonics/data/letter_data.dart';
import 'package:kidsphonics/data/phonics_activity_data.dart';
import 'package:kidsphonics/data/rhyming_jar_data.dart';
import 'package:kidsphonics/data/rumbled_words_data.dart';
import 'package:kidsphonics/models/difficulty.dart';
import 'package:kidsphonics/providers/app_provider.dart';
import 'learning_progress_test.dart' show mockProgressAudio;

class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore() : super.empty();
  int failures = 0, attempts = 0;
  bool throws = false;
  Completer<void>? gate;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    attempts++;
    await gate?.future;
    if (failures > 0) {
      failures--;
      if (throws) throw StateError('Storage unavailable');
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  List<String> draw(GameSessionHistory history, String key, List<String> pool,
          int count) =>
      history.next(key, pool, (word) => word, count: count);

  Future<SharedPreferences> restart(SharedPreferences prefs) async {
    final snapshot = {
      for (final key in prefs.getKeys()) key: prefs.get(key)!,
    };
    SharedPreferences.setMockInitialValues(snapshot);
    return SharedPreferences.getInstance();
  }

  test('app restarts keep pending tasks and exhaust a pool before repeats',
      () async {
    var prefs = await SharedPreferences.getInstance();
    final pool = List.generate(12, (i) => 'word-$i');
    for (var cycle = 0; cycle < 8; cycle++) {
      final seen = <String>[];
      for (var round = 0; round < 3; round++) {
        final history = GameSessionHistory(
            preferences: prefs, random: Random(cycle * 3 + round));
        seen.addAll(draw(history, 'quiz-easy', pool, 4));
        expect(await history.saved, isTrue);
        prefs = await restart(prefs);
      }
      expect(seen.toSet(), pool.toSet());
      expect(seen.toSet(), hasLength(seen.length));
    }
  });

  test('restart at a cycle boundary preserves unique rounds and last word',
      () async {
    var prefs = await SharedPreferences.getInstance();
    final pool = List.generate(7, (i) => 'word-$i');
    final firstHistory =
        GameSessionHistory(preferences: prefs, random: Random(1));
    final first = draw(firstHistory, 'picture-easy', pool, 5);
    await firstHistory.saved;
    prefs = await restart(prefs);
    final restored = GameSessionHistory(preferences: prefs, random: Random(2));
    final second = draw(restored, 'picture-easy', pool, 5);
    expect(second.toSet(), hasLength(5));
    expect({...first, ...second.take(2)}, pool.toSet());
    expect(second.first, isNot(first.last));
  });

  test('avoiding last-to-first repetition wins over changing the opener', () {
    final history = GameSessionHistory(random: Random(7));
    var previous = draw(history, 'small-pool', ['a', 'b'], 2);
    for (var round = 0; round < 100; round++) {
      final next = draw(history, 'small-pool', ['a', 'b'], 2);
      expect(next.first, isNot(previous.last));
      expect(next.toSet(), {'a', 'b'});
      previous = next;
    }
  });

  test('persisted games and difficulty levels keep independent queues',
      () async {
    var prefs = await SharedPreferences.getInstance();
    final pool = List.generate(8, (i) => 'word-$i');
    var history = GameSessionHistory(preferences: prefs, random: Random(4));
    final first = <String, List<String>>{};
    for (final key in ['sound-easy', 'sound-hard', 'quiz-easy']) {
      first[key] = draw(history, key, pool, 4);
    }
    await history.saved;
    prefs = await restart(prefs);
    history = GameSessionHistory(preferences: prefs);
    for (final entry in first.entries) {
      final second = draw(history, entry.key, pool, 4);
      expect({...entry.value, ...second}, pool.toSet());
      expect(second.toSet().intersection(entry.value.toSet()), isEmpty);
    }
    await history.saved;
  });

  test('catalog updates retain valid unseen words and discard retired words',
      () async {
    var prefs = await SharedPreferences.getInstance();
    final pool = ['a', 'b', 'c', 'd', 'e', 'f'];
    var history = GameSessionHistory(preferences: prefs, random: Random(10));
    final first = draw(history, 'updated', pool, 2);
    final pending = pool.where((id) => !first.contains(id)).toList();
    await history.saved;
    prefs = await restart(prefs);
    history = GameSessionHistory(preferences: prefs);
    final updatedPool = pool.where((id) => id != pending.first).toList()
      ..addAll(['new', 'new']);
    final expectedUnseen = {...pending.skip(1), 'new'};
    final second = draw(history, 'updated', updatedPool, expectedUnseen.length);
    expect(second.toSet(), expectedUnseen);
    expect(second, isNot(contains(pending.first)));
    await history.saved;
  });

  for (final malformed in <Object>[
    '{broken',
    42,
    jsonEncode([]),
    jsonEncode({'version': 2, 'games': {}}),
    jsonEncode({'version': 1, 'games': []}),
  ]) {
    test('invalid history is ignored safely: $malformed', () async {
      SharedPreferences.setMockInitialValues({
        GameSessionHistory.storageKey: malformed,
        'xp': 99,
        'studentName': 'Liam',
      });
      final prefs = await SharedPreferences.getInstance();
      final history = GameSessionHistory(preferences: prefs);
      final round = draw(history, 'safe', ['a', 'b', 'c'], 3);
      expect(round.toSet(), {'a', 'b', 'c'});
      expect(await history.saved, isTrue);
      expect(prefs.getInt('xp'), 99);
      expect(prefs.getString('studentName'), 'Liam');
      expect(prefs.getKeys(),
          {GameSessionHistory.storageKey, 'xp', 'studentName'});
    });
  }

  test('bad entries cannot duplicate tasks or discard another game history',
      () async {
    SharedPreferences.setMockInitialValues({
      GameSessionHistory.storageKey: jsonEncode({
        'version': 1,
        'games': {
          'valid': {
            'pool': ['a', 'b', 'c'],
            'remaining': ['c'],
            'first': 'a',
            'last': 'b',
          },
          'duplicate': {
            'pool': ['a', 'b'],
            'remaining': ['a', 'a'],
          },
          'unknown': {
            'pool': ['a', 'b'],
            'remaining': ['retired'],
          },
          'wrongType': {
            'pool': [null],
            'remaining': []
          },
          'duplicatePool': {
            'pool': ['a', 'a'],
            'remaining': []
          },
          'bad': false,
        },
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final history = GameSessionHistory(preferences: prefs);
    expect(draw(history, 'valid', ['a', 'b', 'c'], 1), ['c']);
    for (final key in [
      'duplicate',
      'unknown',
      'wrongType',
      'duplicatePool',
      'bad'
    ]) {
      expect(draw(history, key, ['a', 'b'], 2).toSet(), {'a', 'b'});
    }
    expect(await history.saved, isTrue);
  });

  test('rapid game launches save in order and restore the latest full history',
      () async {
    final store = _ControlledStore()..gate = Completer<void>();
    SharedPreferencesStorePlatform.instance = store;
    final prefs = await SharedPreferences.getInstance();
    final history = GameSessionHistory(preferences: prefs, random: Random(3));
    final a = draw(history, 'a', ['1', '2', '3', '4'], 2);
    final b = draw(history, 'b', ['x', 'y', 'z'], 1);
    await Future<void>.delayed(Duration.zero);
    expect(store.attempts, 1);
    store.gate!.complete();
    expect(await history.saved, isTrue);
    final saved = await store.getAll();
    SharedPreferences.setMockInitialValues({
      GameSessionHistory.storageKey:
          saved['flutter.${GameSessionHistory.storageKey}']!,
    });
    final restored =
        GameSessionHistory(preferences: await SharedPreferences.getInstance());
    expect(draw(restored, 'a', ['1', '2', '3', '4'], 2).toSet(),
        {'1', '2', '3', '4'}.difference(a.toSet()));
    expect(draw(restored, 'b', ['x', 'y', 'z'], 2).toSet(),
        {'x', 'y', 'z'}.difference(b.toSet()));
    await restored.saved;
  });

  for (final throws in [false, true]) {
    test(
        'storage ${throws ? 'exceptions' : 'failures'} keep play usable and recover',
        () async {
      final store = _ControlledStore()
        ..failures = 3
        ..throws = throws;
      SharedPreferencesStorePlatform.instance = store;
      final prefs = await SharedPreferences.getInstance();
      final history = GameSessionHistory(preferences: prefs);
      final first = draw(history, 'retry', ['a', 'b', 'c', 'd'], 2);
      expect(await history.saved, isFalse);
      final second = draw(history, 'retry', ['a', 'b', 'c', 'd'], 2);
      expect(second.toSet().intersection(first.toSet()), isEmpty);
      expect(await history.saved, isTrue);
      final stored =
          (await store.getAll())['flutter.${GameSessionHistory.storageKey}'];
      expect(
          jsonDecode(stored as String)['games']['retry']['remaining'], isEmpty);
    });
  }

  test(
      'AppProvider restores history before readiness without changing progress',
      () async {
    mockProgressAudio();
    final prefs = await SharedPreferences.getInstance();
    final history = GameSessionHistory(preferences: prefs);
    final pool = ['a', 'b', 'c', 'd'];
    final first = draw(history, 'provider', pool, 2);
    await history.saved;
    await restart(prefs);
    final provider = AppProvider();
    await provider.ready;
    expect(provider.isReady, isTrue);
    final second =
        GameSessionOrder.next('provider', pool, (word) => word, count: 2);
    expect(second.toSet().intersection(first.toSet()), isEmpty);
    expect((provider.xp, provider.stars, provider.dailyActivity.isEmpty),
        (0, 0, true));
    await GameSessionOrder.saved;
    provider.dispose();
  });

  test(
      'existing game pools stay tiered, unique and varied across saved replays',
      () async {
    var prefs = await SharedPreferences.getInstance();
    final pools = <String, List<String>>{};
    final counts = <String, int>{};
    for (final d in Difficulty.values) {
      final tier = <String, List<String>>{
        'sound_match': soundRoundsForDifficulty(d).map((q) => q.word).toList(),
        'quiz': quizQuestionsForDifficulty(d)
            .where((q) => q.position == QuizSoundPosition.beginning)
            .map((q) => q.word)
            .toList(),
        'word_builder': wordPuzzlesForDifficulty(d).map((q) => q.word).toList(),
        'speech': voiceWords[d]!.map((q) => q['word']!).toList(),
        'missing_vowel': vowelPuzzlesFor(d).map((q) => q.word).toList(),
        'picture': pictureRoundsFor(d).map((q) => q.word).toList(),
        'rumbled': rumbledWordsFor(d).map((q) => q.word).toList(),
        'rhyming': rhymingFamilies.map((q) => q.target).toList(),
        'sound_position': positionRoundsFor(d)
            .map((q) => '${q.word}:${q.targetLetter}:${q.correctPos.name}')
            .toList(),
        'memory': gameWordsFor(d).map((q) => q.word).toList(),
      };
      for (final entry in tier.entries) {
        final key = '${entry.key}-${d.name}';
        pools[key] = entry.value;
        counts[key] = entry.key == 'memory'
            ? memoryPairsForDifficulty(d).length
            : GameSessionOrder.roundLength(d);
      }
    }
    final previous = <String, List<String>>{};
    for (var replay = 0; replay < 12; replay++) {
      final history =
          GameSessionHistory(preferences: prefs, random: Random(replay));
      for (final entry in pools.entries) {
        final round = draw(history, entry.key, entry.value, counts[entry.key]!);
        expect(round,
            hasLength(min(counts[entry.key]!, entry.value.toSet().length)));
        expect(round.toSet(), hasLength(round.length));
        expect(entry.value.toSet().containsAll(round), isTrue);
        final before = previous[entry.key];
        if (before != null && entry.value.toSet().length > 1) {
          expect(round.first, isNot(before.last));
        }
        previous[entry.key] = round;
      }
      expect(await history.saved, isTrue);
      prefs = await restart(prefs);
    }
  });
}
