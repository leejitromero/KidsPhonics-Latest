import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'recommended_practice_card.dart';

/// Reuses the same recommendation frame as the learner Progress screens.
class HomeRecommendationPanel extends StatelessWidget {
  const HomeRecommendationPanel({
    super.key,
    required this.letter,
    required this.review,
    required this.onStart,
  });
  final String? letter;
  final bool review;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => RecommendedPracticeCard(
      leading: letter == null
          ? const Icon(Icons.auto_awesome_rounded,
              size: 44, color: Color(0xFFEDAB22))
          : SizedBox(
              width: 64,
              height: 64,
              child: Image.asset(
                  'assets/images/letters/${letter!.toLowerCase()}.webp',
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  cacheWidth: 180)),
      title: letter == null
          ? 'Alphabet Master!'
          : '${review ? 'Review' : 'Practice'} Letter $letter',
      description: letter == null
          ? 'Keep your letter skills shining!'
          : review
              ? 'Let\u2019s try this letter again!'
              : 'Ready for your next challenge?',
      actionKey: const ValueKey('home-start-adventure'),
      onPressed: withButtonSound(onStart),
      buttonLabel: 'Start Quick Check');
}

class HomeStatusBadge extends StatelessWidget {
  const HomeStatusBadge(
      {super.key,
      required this.icon,
      required this.label,
      required this.color,
      this.compact = false});
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: 5),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: const Color(0xFFE3AD58), width: compact ? 2 : 3),
          gradient: LinearGradient(colors: [
            Colors.white,
            Color.alphaBlend(color.withValues(alpha: .14), Colors.white)
          ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33432777), offset: Offset(0, 3), blurRadius: 4)
          ]),
      child: Flex(
          direction: Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: compact ? 16 : 20),
            const SizedBox(width: 4),
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w900,
                        color: color))),
          ]));
}

class HomeEntrance extends StatelessWidget {
  const HomeEntrance(
      {super.key,
      required this.animation,
      required this.begin,
      required this.end,
      required this.child,
      this.from = const Offset(0, 24)});
  final Animation<double> animation;
  final double begin, end;
  final Widget child;
  final Offset from;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final t = Interval(begin, end, curve: Curves.easeOutBack)
            .transform(animation.value);
        return Opacity(
            opacity: t.clamp(0, 1),
            child: Transform.translate(offset: from * (1 - t), child: child));
      });
}
