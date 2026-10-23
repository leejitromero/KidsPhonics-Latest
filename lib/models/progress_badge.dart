/// A reward derived from saved learning evidence; opening the screen never
/// awards XP or writes another copy of an achievement.
class ProgressBadge {
  const ProgressBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    this.milestone = false,
  });
  final String id, title, description;
  final int current, target;
  final bool milestone;
  int get count => current.clamp(0, target);
  bool get earned => current >= target;
  double get fraction => count / target;
}
