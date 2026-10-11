import 'package:flutter/foundation.dart';
import '../data/rhyming_jar_data.dart';

enum JarPhase {
  intro,
  target,
  choosing,
  wrong,
  collecting,
  centering,
  reveal,
  ready
}

/// Only a unique correct choice can contribute energy or earn a reward.
class RhymingJarController extends ChangeNotifier {
  RhymingJarController(this.family);
  RhymingFamily family;
  JarPhase phase = JarPhase.intro;
  final Set<String> collected = {};
  String? picked;
  bool paused = false;
  bool get canPick => !paused && phase == JarPhase.choosing;
  double get fill => collected.length / 3;

  bool? pick(String word) {
    if (!canPick || collected.contains(word)) return null;
    picked = word;
    final correct = family.rhymes.contains(word);
    phase = correct ? JarPhase.collecting : JarPhase.wrong;
    notifyListeners();
    return correct;
  }

  void finishFeedback() {
    if (phase == JarPhase.collecting) {
      collected.add(picked!);
      phase = collected.length == 3 ? JarPhase.centering : JarPhase.choosing;
    } else if (phase == JarPhase.wrong) {
      phase = JarPhase.choosing;
    }
    picked = null;
    notifyListeners();
  }

  void setPhase(JarPhase value) {
    phase = value;
    notifyListeners();
  }

  void reset(RhymingFamily value) {
    family = value;
    collected.clear();
    picked = null;
    phase = JarPhase.target;
    notifyListeners();
  }
}
