import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/home_village.dart';

/// Supplied sprites play on their own garden pad. Motion uses a shared clock,
/// while each category has its own timing, toy and welcoming bounce.
class HomePlaygroundMascot extends StatelessWidget {
  const HomePlaygroundMascot(
      {super.key,
      required this.category,
      required this.play,
      required this.visit,
      required this.animate,
      this.selected = false});
  final HomeCategory category;
  final Animation<double> play, visit;
  final bool animate, selected;

  @override
  Widget build(BuildContext context) => IgnorePointer(child: ExcludeSemantics(
          child: RepaintBoundary(child: LayoutBuilder(builder: (_, box) {
        final width = box.maxWidth, height = box.maxHeight;
        return AnimatedBuilder(
            animation: Listenable.merge([play, visit]),
            child: Image.asset(category.mascotAsset,
                key: ValueKey('home-${category.name}-mascot'),
                fit: BoxFit.contain,
                cacheWidth: 512),
            builder: (_, sprite) {
              final phase = animate ? play.value * math.pi * 2 : 0.0;
              final isLesson = category == HomeCategory.lessons;
              final hop = math.max(0.0, math.sin(phase * (isLesson ? 2 : 1)));
              final lean = math.sin(phase + (isLesson ? 0 : .4));
              final cheer = selected ? math.sin(visit.value * math.pi) : 0.0;
              final pose = Matrix4.identity()
                ..translateByDouble(lean * width * .022,
                    -hop * height * .04 - cheer * height * .04, 0, 1)
                ..rotateZ(animate ? lean * (isLesson ? .035 : .05) : 0)
                ..scaleByDouble(1 + cheer * .045 - hop * .012,
                    1 + cheer * .045 + hop * .015, 1, 1);
              return Stack(clipBehavior: Clip.none, children: [
                Positioned(
                    left: width * .24,
                    right: width * .24,
                    bottom: 6,
                    height: 9,
                    child: Transform.scale(
                        scale: 1 - hop * .18,
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: const Color(0xFF304D32)
                                    .withValues(alpha: .19 - hop * .04),
                                boxShadow: const [
                              BoxShadow(color: Color(0x22334B31), blurRadius: 6)
                            ])))),
                Positioned(
                    left: width * .30,
                    right: width * .30,
                    top: height * .18,
                    bottom: height * .18,
                    child: Transform(
                        key: ValueKey('home-${category.name}-play-motion'),
                        alignment: Alignment.bottomCenter,
                        transform: pose,
                        child: sprite)),
                if (isLesson) ...[
                  Positioned(
                      left: width * .16,
                      top: height * (.28 + .08 * math.sin(phase)),
                      child: Transform.rotate(
                          angle: math.sin(phase) * .18,
                          child: _LetterToy(
                              letter: 'A',
                              color: const Color(0xFFB667D9),
                              size: width * .13))),
                  Positioned(
                      right: width * .15,
                      top: height * (.42 - .08 * math.sin(phase)),
                      child: Transform.rotate(
                          angle: -math.sin(phase) * .18,
                          child: _LetterToy(
                              letter: 'B',
                              color: const Color(0xFFEA9D40),
                              size: width * .12))),
                ] else
                  Positioned(
                      left: width * (.16 + .04 * math.sin(phase)),
                      bottom: 11 + hop * height * .10,
                      child: Transform.rotate(
                          angle: phase, child: _StarBall(size: width * .15))),
              ]);
            });
      }))));
}

class _LetterToy extends StatelessWidget {
  const _LetterToy(
      {required this.letter, required this.color, required this.size});
  final String letter;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, .50)!, color]),
          border: Border.all(color: Colors.white.withValues(alpha: .65)),
          boxShadow: [
            BoxShadow(
                color: Color.lerp(color, Colors.black, .25)!,
                offset: const Offset(0, 2))
          ]),
      child: Text(letter,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: size * .70)));
}

class _StarBall extends StatelessWidget {
  const _StarBall({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              center: Alignment(-.45, -.45),
              radius: .9,
              colors: [
                Color(0xFFFFFFD8),
                Color(0xFFFFDD72),
                Color(0xFFE89B37)
              ]),
          boxShadow: [
            BoxShadow(
                color: Color(0x446D6540), offset: Offset(0, 2), blurRadius: 3)
          ]),
      child: Icon(Icons.star_rounded,
          color: const Color(0xFFFFFCE6), size: size * .68));
}
