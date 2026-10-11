import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'game_design.dart' show ForestLeaves;

/// Compact shared recommendation with live letter artwork and a separate action.
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

  Widget _details() => Row(children: [
        SizedBox(
            width: 38,
            height: 42,
            child: letter == null
                ? const Icon(Icons.auto_awesome_rounded,
                    size: 36, color: Color(0xFFEDAB22))
                : Image.asset(
                    'assets/images/letters/${letter!.toLowerCase()}.webp',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    cacheWidth: 180)),
        const SizedBox(width: 8),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(
                  letter == null
                      ? 'Alphabet Master!'
                      : '${review ? 'Review' : 'Practice'} Letter $letter',
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF682DAE))),
              const SizedBox(height: 3),
              Text(
                  letter == null
                      ? 'Keep your letter skills shining!'
                      : review
                          ? 'Let’s try this letter again!'
                          : 'Ready for your next challenge?',
                  style: const TextStyle(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF355CA2))),
            ])),
      ]);

  Widget _start() => Semantics(
      button: true,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              key: const ValueKey('home-start-adventure'),
              onTap: withButtonSound(onStart),
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: const Color(0xFFFFD367), width: 2.5),
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFC268F1),
                            Color(0xFF7636C1),
                            Color(0xFF58269D)
                          ])),
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                    child: Text('Start Quick Check',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 12,
                                            height: 1.1,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white))),
                                SizedBox(width: 3),
                                Icon(Icons.play_arrow_rounded,
                                    color: Colors.white, size: 22),
                              ])))))));

  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: const ForestLeaves(allCorners: true),
      child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFDA80), width: 3),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD69546),
                    Color(0xFF8F4F29),
                    Color(0xFFC9833D)
                  ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x55432777),
                    blurRadius: 8,
                    offset: Offset(0, 4))
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFDE79)),
                  SizedBox(width: 4),
                  Flexible(
                      child: Text('YOUR NEXT LITTLE STEP!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white))),
                  SizedBox(width: 4),
                  Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFDE79)),
                ])),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFF8F4FF), Color(0xFFD7EBFF)]),
                    border: Border.all(color: Colors.white, width: 2)),
                child: LayoutBuilder(builder: (context, box) {
                  final horizontal = box.maxWidth >= 310 &&
                      MediaQuery.textScalerOf(context).scale(1) <= 1.2;
                  if (horizontal) {
                    return Row(children: [
                      Expanded(child: _details()),
                      const SizedBox(width: 8),
                      SizedBox(width: 140, child: _start()),
                    ]);
                  }
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    _details(),
                    const SizedBox(height: 6),
                    _start(),
                  ]);
                })),
          ])));
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
