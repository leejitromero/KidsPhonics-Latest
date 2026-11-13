/// Practice evidence is independent of scores, rewards and assessed mastery.
enum ReviewSkill { recognition, sound, vowel, word, rhyme, position }

class ReviewTarget {
  const ReviewTarget(this.skill, this.value, [this.focus = '']);
  const ReviewTarget.letter(String letter)
      : this(ReviewSkill.recognition, letter);
  factory ReviewTarget.sound(String letter) => ReviewTarget(
      RegExp(r'^[AEIOU]$').hasMatch(letter)
          ? ReviewSkill.vowel
          : ReviewSkill.sound,
      letter);
  const ReviewTarget.vowel(String letter) : this(ReviewSkill.vowel, letter);
  const ReviewTarget.word(String word) : this(ReviewSkill.word, word);
  const ReviewTarget.rhyme(String word) : this(ReviewSkill.rhyme, word);
  const ReviewTarget.position(String word, String letter)
      : this(ReviewSkill.position, word, letter);
  final ReviewSkill skill;
  final String value, focus;
  String get key => '${skill.name}:$value:$focus';
  String get title => switch (skill) {
        ReviewSkill.recognition => 'Letter $value',
        ReviewSkill.sound => 'The $value sound',
        ReviewSkill.vowel => 'Short $value',
        ReviewSkill.word => 'Reading $value',
        ReviewSkill.rhyme => 'Rhymes with $value',
        ReviewSkill.position => '$focus in $value',
      };
  Map<String, Object> toJson() => {
        'skill': skill.name,
        'value': value,
        'focus': focus,
      };
  static ReviewTarget? fromJson(Object? data) {
    if (data is! Map || data['value'] is! String) return null;
    final skills = ReviewSkill.values.where((s) => s.name == data['skill']);
    if (skills.isEmpty) return null;
    final value = data['value'] as String;
    final focus = data['focus'];
    if (value.length > 24 ||
        !RegExp(r'^[A-Z]+(?: [A-Z]+)*$').hasMatch(value) ||
        (focus != null && focus is! String)) {
      return null;
    }
    return ReviewTarget(skills.single, value, focus as String? ?? '');
  }
}

class ReviewEvidence {
  const ReviewEvidence(this.target, this.recent, this.recovery, this.sequence);
  final ReviewTarget target;
  final List<bool> recent;
  final int recovery, sequence;
  bool get needsReview => recovery < 2;
  int get priority =>
      recent.where((correct) => !correct).length * 10 - recovery;
  Map<String, Object> toJson() => {
        'target': target.toJson(),
        'recent': recent,
        'recovery': recovery,
        'sequence': sequence,
      };
}

/// At most one bounded history per supported target; no personal data or audio.
class SmartReviewState {
  final Map<String, ReviewEvidence> _entries = {};
  int _sequence = 0;
  List<ReviewEvidence> get pending {
    final items = _entries.values.where((e) => e.needsReview).toList();
    items.sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      if (priority != 0) return priority;
      final recency = b.sequence.compareTo(a.sequence);
      return recency != 0 ? recency : a.target.key.compareTo(b.target.key);
    });
    return List.unmodifiable(items);
  }

  void observe(ReviewTarget target, bool correct) {
    final previous = _entries[target.key];
    // Correct answers alone do not create a remedial recommendation.
    if (previous == null && correct) return;
    final recent = [...?previous?.recent, correct];
    _entries[target.key] = ReviewEvidence(
        target,
        List.unmodifiable(recent.skip((recent.length - 6).clamp(0, 6))),
        correct ? ((previous?.recovery ?? 0) + 1).clamp(0, 2) : 0,
        ++_sequence);
  }

  void clear() {
    _entries.clear();
    _sequence = 0;
  }

  Map<String, Object> toJson() => {
        'version': 1,
        'entries': _entries.values.map((e) => e.toJson()).toList(),
      };

  void load(Object? data, bool Function(ReviewTarget) supported) {
    clear();
    if (data is! Map || data['version'] != 1 || data['entries'] is! List) {
      return;
    }
    for (final item in (data['entries'] as List).take(1024)) {
      if (item is! Map) continue;
      final target = ReviewTarget.fromJson(item['target']);
      final recent = item['recent'];
      final recovery = item['recovery'];
      final sequence = item['sequence'];
      if (target == null ||
          !supported(target) ||
          recent is! List ||
          recent.isEmpty ||
          recent.length > 6 ||
          recent.any((v) => v is! bool) ||
          !recent.contains(false) ||
          recovery is! int ||
          recovery < 0 ||
          recovery > 2 ||
          sequence is! int ||
          sequence < 0 ||
          sequence > 0x7fffffff) {
        continue;
      }
      // A damaged recovery counter cannot hide a latest incorrect response.
      final validRecovery =
          recent.reversed.takeWhile((v) => v == true).length.clamp(0, 2);
      _entries[target.key] = ReviewEvidence(
          target,
          List<bool>.unmodifiable(recent.cast<bool>()),
          validRecovery,
          sequence);
      if (sequence > _sequence) _sequence = sequence;
    }
  }
}
