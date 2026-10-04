import 'package:flutter/material.dart';
import 'mascot_guide.dart';

/// A compact welcome that lets the shared sky show behind the mascot and text.
class GameZoneWelcome extends StatelessWidget {
  const GameZoneWelcome({super.key, this.showTitle = true});
  final bool showTitle;

  static const _outline = [
    Shadow(color: Colors.white, offset: Offset(-1, -1), blurRadius: 2),
    Shadow(color: Colors.white, offset: Offset(1, -1), blurRadius: 2),
    Shadow(color: Colors.white, offset: Offset(-1, 1), blurRadius: 2),
    Shadow(color: Colors.white, offset: Offset(1, 1), blurRadius: 2),
  ];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTitle)
                    Semantics(
                      header: true,
                      child: const Text('Game Zone',
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 28,
                            color: Color(0xFF582AA5),
                            shadows: _outline,
                          )),
                    ),
                  if (showTitle) const SizedBox(height: 4),
                  const Text('Play and learn with fun games!',
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF30214F),
                        shadows: _outline,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const MascotPortrait(mascot: LearningMascot.wigloo, size: 76),
          ],
        ),
      );
}
