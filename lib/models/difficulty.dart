/// Difficulty levels used across all games.
enum Difficulty { easy, medium, hard }

extension DifficultyExt on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.medium:
        return 'Medium';
      case Difficulty.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case Difficulty.easy:
        return '🟢';
      case Difficulty.medium:
        return '🟡';
      case Difficulty.hard:
        return '🔴';
    }
  }

  /// XP multiplier per correct answer
  double get xpMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.medium:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
    }
  }

  String get description {
    switch (this) {
      case Difficulty.easy:
        return 'Starter practice';
      case Difficulty.medium:
        return 'More practice';
      case Difficulty.hard:
        return 'Challenge practice';
    }
  }
}
