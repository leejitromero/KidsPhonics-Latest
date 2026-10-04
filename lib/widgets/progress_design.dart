import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/learning_progress.dart';
import 'button_sound.dart';

const progressPurple = Color(0xFF7137E8);
const progressGreen = Color(0xFF00A77E);
const progressInk = Color(0xFF352075);

BoxDecoration progressGloss(Color color, {double radius = 24}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .3)!,
            color,
            Color.lerp(color, Colors.black, .12)!
          ]),
      border: Border.all(color: Colors.white.withValues(alpha: .75), width: 2),
      boxShadow: [
        BoxShadow(
            color: color.withValues(alpha: .24),
            blurRadius: 8,
            offset: const Offset(0, 4))
      ],
    );

class ProgressCard extends StatelessWidget {
  const ProgressCard(
      {super.key, required this.child, this.tint = const Color(0xFFFFFAEF)});
  final Widget child;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .96),
                tint.withValues(alpha: .92)
              ]),
          borderRadius: BorderRadius.circular(28),
          border:
              Border.all(color: Colors.white.withValues(alpha: .9), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x243891C3), blurRadius: 12, offset: Offset(0, 5))
          ],
        ),
        child: child,
      );
}

class ProgressHeading extends StatelessWidget {
  const ProgressHeading(this.title, this.icon,
      {super.key, this.color = progressPurple});
  final String title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
                colors: [color, Color.lerp(color, Colors.white, .25)!])),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFFFFDD58), size: 26),
          const SizedBox(width: 7),
          Flexible(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white))),
        ]),
      );
}

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(children: [
          DecoratedBox(
              decoration: progressGloss(progressPurple, radius: 50),
              child: IconButton(
                  tooltip: 'Back',
                  onPressed: withButtonSound(() => Navigator.maybePop(context)),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 28))),
          const SizedBox(width: 12),
          Expanded(
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                  decoration: progressGloss(progressPurple, radius: 40),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_rounded,
                            color: Color(0xFFFFD744), size: 23),
                        SizedBox(width: 4),
                        Flexible(
                            child: Text('My Progress',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                          color: Color(0xFF673414),
                                          offset: Offset(0, 2))
                                    ]))),
                        SizedBox(width: 4),
                        Icon(Icons.star_rounded,
                            color: Color(0xFFFFD744), size: 23),
                      ]))),
        ]),
      );
}

class ProgressMasteryCard extends StatelessWidget {
  const ProgressMasteryCard(
      {super.key,
      required this.letters,
      required this.title,
      required this.color,
      required this.icon,
      required this.onOpen,
      this.vowels = false});
  final List<LetterProgress> letters;
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onOpen;
  final bool vowels;
  @override
  Widget build(BuildContext context) {
    final count = letters.where((letter) => letter.mastered).length;
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return ProgressCard(
        tint: vowels ? const Color(0xFFEFFAF1) : const Color(0xFFFFF8ED),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
              button: true,
              label: 'See ${vowels ? 'vowel' : 'alphabet'} progress',
              child: InkWell(
                  onTap: withButtonSound(onOpen),
                  borderRadius: BorderRadius.circular(14),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: ProgressHeading(title, icon, color: color))))),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (_, box) {
            final stacked = box.maxWidth < 290 || scale > 1.35;
            final ring = _MasteryRing(
                count: count,
                total: letters.length,
                color: color,
                noun: vowels ? 'vowels' : 'letters',
                side: stacked ? 122 * scale.clamp(1, 1.5) : 108);
            Widget tiles(double width) {
              final columns = vowels ? 5 : 7;
              final side = ((width - (columns - 1) * 5) / columns)
                  .clamp(0.0, vowels ? 52.0 : 42.0);
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final letter in letters)
                    Semantics(
                        label:
                            '${letter.letter}: ${letter.mastered ? 'Mastered' : letter.status.name}',
                        child: ExcludeSemantics(
                            child: Container(
                                width: side,
                                height: side * (vowels ? 1.05 : 1),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: letter.mastered
                                        ? color
                                        : color.withValues(alpha: .1),
                                    borderRadius:
                                        BorderRadius.circular(vowels ? 12 : 8),
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: .65))),
                                child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: Text(letter.letter,
                                            style: TextStyle(
                                                fontSize: vowels ? 23 : 16,
                                                fontWeight: FontWeight.w900,
                                                color: letter.mastered
                                                    ? Colors.white
                                                    : color)))))))
                ],
              );
            }

            return stacked
                ? Column(children: [
                    Center(child: ring),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: tiles(box.maxWidth))
                  ])
                : Row(children: [
                    ring,
                    const SizedBox(width: 14),
                    Expanded(child: tiles(box.maxWidth - 122))
                  ]);
          }),
        ]));
  }
}

class _MasteryRing extends StatelessWidget {
  const _MasteryRing(
      {required this.count,
      required this.total,
      required this.color,
      required this.noun,
      required this.side});
  final int count, total;
  final Color color;
  final String noun;
  final double side;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '$count of $total $noun mastered',
      child: ExcludeSemantics(
          child: SizedBox(
              width: side,
              height: side,
              child: Stack(alignment: Alignment.center, children: [
                Positioned.fill(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                            value: count / total,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            color: color,
                            backgroundColor: color.withValues(alpha: .12)))),
                Transform.translate(
                    offset: Offset(
                        math.sin(count / total * math.pi * 2) * (side / 2 - 5),
                        -math.cos(count / total * math.pi * 2) *
                            (side / 2 - 5)),
                    child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                  color: color.withValues(alpha: .3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ]))),
                Padding(
                    padding: const EdgeInsets.all(18),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('$count / $total',
                              style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  color: color)),
                          Text('$noun\nmastered',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 13, color: progressInk)),
                        ]))),
              ]))));
}
