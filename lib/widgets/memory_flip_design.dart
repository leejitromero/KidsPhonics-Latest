import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_design.dart';

/// The reference's gold timer card; the supplied timer and pause control stay live.
class MemoryTimerPanel extends StatelessWidget {
  const MemoryTimerPanel(
      {super.key,
      required this.timer,
      required this.note,
      required this.pauseControl});
  final Widget timer, note, pauseControl;

  @override
  Widget build(BuildContext context) => ForestPanel(
      leaves: false,
      accent: const Color(0xFFF2BD35),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(children: [
        const Expanded(
            flex: 2,
            child: Padding(
                padding: EdgeInsets.all(3),
                child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(painter: _MemoryStopwatch())))),
        const SizedBox(width: 8),
        Expanded(
            flex: 7,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child:
                              FittedBox(fit: BoxFit.scaleDown, child: timer))),
                  SizedBox(
                      height: 18,
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: note))
                ])),
        const SizedBox(width: 3),
        pauseControl,
      ]));
}

/// Vector stopwatch decoration remains crisp at every phone size.
class _MemoryStopwatch extends CustomPainter {
  const _MemoryStopwatch();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final paint = Paint();
    void rounded(Rect rect, double radius, List<Color> colors) {
      paint.shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors)
          .createShader(rect);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
      paint.shader = null;
    }

    const purple = Color(0xFF6832BD);
    rounded(const Rect.fromLTWH(27, 3, 11, 12), 3,
        const [Color(0xFFCF99FF), purple]);
    rounded(const Rect.fromLTWH(23, 0, 19, 8), 3,
        const [Color(0xFFDAB2FF), Color(0xFF9346E6), purple]);
    for (final (x, angle) in [(13.0, -.7), (51.0, .7)]) {
      canvas.save();
      canvas.translate(x, 15);
      canvas.rotate(angle);
      rounded(const Rect.fromLTWH(-3, -5, 6, 10), 2,
          const [Color(0xFFFFE778), Color(0xFFFFB62A)]);
      canvas.restore();
    }
    paint.color = const Color(0x443D2467);
    canvas.drawCircle(const Offset(33, 39), 25, paint);
    paint.shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDEB3FF), Color(0xFF9B52E9), purple])
        .createShader(const Rect.fromLTWH(6, 10, 52, 52));
    canvas.drawCircle(const Offset(32, 37), 25, paint);
    paint.shader = null;
    paint.color = const Color(0xFFFDF9FF);
    canvas.drawCircle(const Offset(32, 37), 20, paint);
    paint.color = const Color(0xFFCBB5EA);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.4;
    canvas.drawCircle(const Offset(32, 37), 20, paint);
    paint.color = purple;
    paint.strokeWidth = 1.6;
    paint.strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(
          Offset(32 + math.sin(angle) * 16, 37 - math.cos(angle) * 16),
          Offset(32 + math.sin(angle) * 18, 37 - math.cos(angle) * 18),
          paint);
    }
    paint.color = const Color(0xFF0B8E98);
    paint.strokeWidth = 3;
    canvas.drawLine(const Offset(32, 37), const Offset(43, 22), paint);
    canvas.drawLine(const Offset(32, 37), const Offset(26, 32), paint);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(32, 37), 3.5, paint);
    paint.color = const Color(0xFF80E7DE);
    canvas.drawCircle(const Offset(31, 36), 1.5, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MemoryStopwatch oldDelegate) => false;
}
