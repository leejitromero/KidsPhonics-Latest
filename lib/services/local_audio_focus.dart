/// Shared generation for local instructional recordings and sound effects.
abstract final class LocalAudioFocus {
  static int _generation = 0;
  static int claim() => ++_generation;
  static bool isCurrent(int generation) => generation == _generation;
}
