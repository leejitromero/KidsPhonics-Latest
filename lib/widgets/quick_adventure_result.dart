import 'package:flutter/material.dart';
import '../models/letter_adventure.dart';
import 'quick_check_design.dart';
import 'mascot_guide.dart';

class QuickAdventureResult extends StatelessWidget {
  const QuickAdventureResult(
      {super.key,
      required this.letter,
      required this.answers,
      required this.passed,
      required this.xp,
      required this.stars,
      required this.actions,
      this.retained = false,
      this.primary,
      this.saveRetry});
  final String letter;
  final List<bool> answers;
  final bool passed, retained;
  final int xp, stars;
  final Widget? primary, saveRetry;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final score = answers.where((v) => v).length;
    const skillIcons = [
      Icons.text_fields_rounded,
      Icons.volume_up_rounded,
      Icons.search_rounded,
      Icons.image_rounded,
      Icons.track_changes_rounded
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const QuickWoodSign(label: 'Your Letter Adventure', compact: true),
      const SizedBox(height: 8),
      QuickGlassPanel(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(
                child: ClipOval(
                    child: MascotPortrait(
                        mascot: LearningMascot.wigloo, size: 64))),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: const Color(0xFFC788FF), width: 3),
                    gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFBE4FF9),
                          Color(0xFF7021D3),
                          Color(0xFF5314A7)
                        ])),
                child: Text(
                    passed
                        ? 'Letter $letter Mastered!'
                        : 'Let’s keep practicing!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Color(0xFF361171),
                              offset: Offset(0, 3),
                              blurRadius: 2)
                        ]))),
            const SizedBox(height: 6),
            Container(
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFFFCE75), width: 2),
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFF5D4), Color(0xFFFFE5A0)])),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var i = 0; i < 3; i++)
                      Icon(Icons.star_rounded,
                          size: i == 1 ? 32 : 27,
                          color: i < (score * 3 / 5).ceil()
                              ? const Color(0xFFFFB51F)
                              : const Color(0xFFC8B5E8),
                          shadows: const [
                            Shadow(
                                color: Color(0xFFCF8123), offset: Offset(0, 2))
                          ]),
                  ]),
                  Text('Score: $score / 5',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: quickInk)),
                ])),
            if (retained)
              const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Your earlier Letter Adventure mastery is saved.',
                      textAlign: TextAlign.center)),
            const SizedBox(height: 8),
            for (final skill in AdventureSkill.values)
              Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .85),
                      borderRadius: BorderRadius.circular(24)),
                  child: Row(children: [
                    Icon(
                        answers[skill.index]
                            ? Icons.check_circle_rounded
                            : Icons.favorite_rounded,
                        color: answers[skill.index]
                            ? const Color(0xFF24BD60)
                            : const Color(0xFFEB8A36),
                        size: 22),
                    const SizedBox(width: 6),
                    Icon(skillIcons[skill.index], color: quickPurple, size: 22),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(skill.label,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 4),
                    SizedBox(
                        width: 72 * MediaQuery.textScalerOf(context).scale(1),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 4),
                            decoration: BoxDecoration(
                                color: answers[skill.index]
                                    ? const Color(0xFFCDF5D9)
                                    : const Color(0xFFFFE9CA),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(
                                answers[skill.index] ? 'Got it!' : 'Practice',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900)))),
                  ])),
            const SizedBox(height: 6),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFFF6D5), Color(0xFFFFE39A)]),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: const Color(0xFFFFCB68), width: 2)),
                child: Row(children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: Color(0xFFEAA020), size: 28),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(
                          'Earned: +$xp XP | +$stars ${stars == 1 ? 'star' : 'stars'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: quickPurple))),
                  const SizedBox(width: 6),
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFB82B), size: 28),
                ])),
            if (saveRetry != null) saveRetry!,
            if (primary != null) ...[const SizedBox(height: 8), primary!],
            const SizedBox(height: 8),
            Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: actions),
          ])),
    ]);
  }
}
