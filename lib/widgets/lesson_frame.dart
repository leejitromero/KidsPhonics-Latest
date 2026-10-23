import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';

/// Glossy purple trim and gold corner stars around the existing lesson content.
class LessonFrame extends StatelessWidget {
  const LessonFrame(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(12),
      this.radius = 28,
      this.compact = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
            color: KidsUi.cardSurface,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x31512C99),
                  blurRadius: 10,
                  offset: Offset(0, 4)),
            ]),
        child: CustomPaint(
            foregroundPainter: _LessonFramePainter(radius, compact),
            child: Padding(padding: padding, child: child)),
      );
}

class _LessonFramePainter extends CustomPainter {
  const _LessonFramePainter(this.radius, this.compact);
  final double radius;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 3 : 4
      ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB177FF), Color(0xFF6233CB), Color(0xFFAD77ED)])
          .createShader(rect);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), Radius.circular(radius)),
        border);
    for (final (inset, color, width) in [
      (5.0, const Color(0xFFFEFCFF), 2.0),
      (8.0, const Color(0xFFD0ACFF), 1.5),
    ]) {
      if (size.shortestSide < inset * 2) continue;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(inset),
              Radius.circular(math.max(1, radius - inset))),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = color);
    }
    final star = (size.shortestSide * (compact ? .12 : .09)).clamp(7.0, 20.0);
    _star(canvas, Offset(star + 3, star + 2), star);
    _star(canvas, Offset(size.width - star - 3, size.height - star - 2),
        star * .82);
    if (!compact) {
      _star(canvas, Offset(star * 2.5 + 3, 8), star * .38);
      _star(canvas, Offset(8, star * 2.5 + 3), star * .38);
      _star(
          canvas, Offset(size.width - star * 2.3, size.height - 8), star * .35);
    }
  }

  void _star(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final length = radius * (i.isEven ? 1 : .48);
      final x = center.dx + math.cos(angle) * length;
      final y = center.dy + math.sin(angle) * length;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawShadow(path, const Color(0x885C2C00), 2, false);
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFF8B),
                Color(0xFFFFD91A),
                Color(0xFFFFAE12)
              ]).createShader(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 1.5
          ..color = const Color(0xFFE3980D));
  }

  @override
  bool shouldRepaint(_LessonFramePainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.compact != compact;
}
