import 'dart:math' as math;
import 'difficulty.dart';

enum FlightState { ready, flying, paused, lost, won }

/// Fixed logical coordinates keep the course identical on every screen.
class FlappyLettersGame {
  FlappyLettersGame(this.difficulty);
  final Difficulty difficulty;
  static const width = 400.0, height = 600.0;
  static const birdX = 100.0, radius = 20.0, pipeWidth = 66.0;
  static const gap = 210.0, spacing = 280.0;
  double y = 300, velocity = 0, distance = 0;
  int passed = 0;
  FlightState state = FlightState.ready;
  double get speed => switch (difficulty) {
        Difficulty.easy => 85,
        Difficulty.medium => 115,
        Difficulty.hard => 145,
      };
  double pipeX(int index) => 440 + index * spacing - distance;
  double gapCenter(int index) => 300 + math.sin(index * 1.7) * 65;
  void flap() {
    if (state == FlightState.ready) state = FlightState.flying;
    if (state == FlightState.flying) velocity = -245;
  }

  void pause() {
    if (state == FlightState.flying) state = FlightState.paused;
  }

  void resume() {
    if (state == FlightState.paused) state = FlightState.flying;
  }

  /// Returns each newly cleared letter once, after the whole bird clears it.
  List<String> advance(double seconds) {
    final letters = <String>[];
    if (state != FlightState.flying || seconds <= 0) return letters;
    var remaining = math.min(seconds, .1);
    while (remaining > 0 && state == FlightState.flying) {
      final dt = math.min(remaining, 1 / 120);
      remaining -= dt;
      velocity += 620 * dt;
      y += velocity * dt;
      distance += speed * dt;
      if (y - radius <= 0 || y + radius >= height) {
        state = FlightState.lost;
        break;
      }
      for (var i = passed; i < 26; i++) {
        final x = pipeX(i);
        if (x > birdX + radius) break;
        if (x + pipeWidth >= birdX - radius &&
            (y - radius < gapCenter(i) - gap / 2 ||
                y + radius > gapCenter(i) + gap / 2)) {
          state = FlightState.lost;
          break;
        }
        if (x + pipeWidth < birdX - radius) {
          passed++;
          letters.add(String.fromCharCode(65 + i));
          if (passed == 26) state = FlightState.won;
        }
      }
    }
    return letters;
  }
}
