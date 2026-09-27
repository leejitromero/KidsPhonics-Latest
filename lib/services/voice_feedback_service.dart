/// Legacy spoken praise was retired when the supplied word recordings arrived.
/// Visual feedback and the existing short sound effects provide game feedback.
class VoiceFeedbackService {
  Future<void> stop() async {}
  Future<void> checkRewardMilestones(
      {required int xp,
      required int streak,
      required int prevXp,
      required int prevStreak,
      required int level,
      required int prevLevel}) async {}
  void dispose() {}
}
