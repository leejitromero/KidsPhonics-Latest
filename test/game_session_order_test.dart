import 'package:flutter_test/flutter_test.dart';
import 'package:kidsphonics/data/game_session_order.dart';

void main() {
  test('replays exhaust the pool before repeating tasks', () {
    final pool = List.generate(12, (i) => 'task-$i');
    for (var cycle = 0; cycle < 20; cycle++) {
      final drawn = <String>[];
      for (var session = 0; session < 3; session++) {
        drawn.addAll(
            GameSessionOrder.next('coverage', pool, (s) => s, count: 4));
      }
      expect(drawn.toSet(), pool.toSet());
    }
  });

  test('crossing a pool boundary keeps each session unique', () {
    final pool = List.generate(7, (i) => 'task-$i');
    final first = GameSessionOrder.next('boundary', pool, (s) => s, count: 5);
    final second = GameSessionOrder.next('boundary', pool, (s) => s, count: 5);
    expect(second, hasLength(5));
    expect(second.toSet(), hasLength(5));
    expect({...first, ...second.take(2)}, pool.toSet());
    expect(second.first, isNot(first.last));
    for (var i = 0; i < 100; i++) {
      final round = GameSessionOrder.next('boundary', pool, (s) => s, count: 5);
      expect(round.toSet(), hasLength(5));
    }
  });

  test('game and difficulty keys have independent histories', () {
    const pool = ['a', 'b', 'c', 'd'];
    for (final key in ['sound-easy', 'sound-hard', 'quiz-easy']) {
      final first = GameSessionOrder.next(key, pool, (s) => s, count: 2);
      final second = GameSessionOrder.next(key, pool, (s) => s, count: 2);
      expect({...first, ...second}, pool.toSet());
    }
  });

  test('changed sources discard stale tasks and duplicate identities', () {
    GameSessionOrder.next('changed', ['a', 'b', 'c'], (s) => s, count: 1);
    final round = GameSessionOrder.next('changed', ['x', 'x', 'y'], (s) => s);
    expect(round.toSet(), {'x', 'y'});
    expect(round, hasLength(2));
  });

  test('empty, zero count and single task pools are supported', () {
    expect(GameSessionOrder.next<String>('empty', [], (s) => s), isEmpty);
    expect(GameSessionOrder.next('zero', ['a'], (s) => s, count: 0), isEmpty);
    for (var i = 0; i < 3; i++) {
      expect(GameSessionOrder.next('single', ['a'], (s) => s, count: 5), ['a']);
    }
  });
}
