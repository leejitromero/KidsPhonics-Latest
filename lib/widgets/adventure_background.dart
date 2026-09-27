import 'package:flutter/material.dart';

/// Lightweight, offline artwork that scales to phones and tablets.
class AdventureBackground extends StatelessWidget {
  const AdventureBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6DCFF),
              Color(0xFFDFF8F4),
              Color(0xFFFFEBCB),
            ],
          ),
        ),
        child: Stack(children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _SkyPainter())),
          ),
          child,
        ]),
      );
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .65);
    for (final point in [
      const Offset(.06, .12),
      const Offset(.94, .48),
      const Offset(.12, .88)
    ]) {
      final center = Offset(size.width * point.dx, size.height * point.dy);
      canvas.drawCircle(center, 35, paint);
      canvas.drawCircle(center.translate(32, 10), 25, paint);
      canvas.drawCircle(center.translate(-28, 12), 22, paint);
    }
    paint.color = const Color(0xFF9A71DD).withValues(alpha: .35);
    for (final point in [
      const Offset(.88, .09),
      const Offset(.08, .43),
      const Offset(.9, .8)
    ]) {
      final x = size.width * point.dx;
      final y = size.height * point.dy;
      canvas.drawPath(
          Path()
            ..moveTo(x, y - 10)
            ..lineTo(x + 3, y - 3)
            ..lineTo(x + 10, y)
            ..lineTo(x + 3, y + 3)
            ..lineTo(x, y + 10)
            ..lineTo(x - 3, y + 3)
            ..lineTo(x - 10, y)
            ..lineTo(x - 3, y - 3)
            ..close(),
          paint);
    }
    const confetti = [Color(0xFFFFB84D), Color(0xFFF582AD), Color(0xFF51BDB0)];
    for (var i = 0; i < 12; i++) {
      paint.color = confetti[i % confetti.length].withValues(alpha: .35);
      final center = Offset(
          size.width * (i.isEven ? .025 : .975), size.height * ((i + .5) / 12));
      canvas.drawCircle(center, i % 3 == 0 ? 6 : 4, paint);
    }
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => false;
}

class AdventureMascot extends StatelessWidget {
  const AdventureMascot({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: 116,
          height: 116,
          child: Stack(alignment: Alignment.center, children: [
            Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    shape: BoxShape.circle)),
            const Icon(Icons.star_rounded, size: 116, color: Color(0xFFFFD76A)),
            const Positioned(
                top: 49,
                child: Row(children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF49315D)),
                  SizedBox(width: 16),
                  Icon(Icons.circle, size: 7, color: Color(0xFF49315D)),
                ])),
            const Positioned(
                top: 56,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 25, color: Color(0xFF49315D))),
          ]),
        ),
      );
}
