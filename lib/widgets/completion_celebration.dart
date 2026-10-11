import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A short, non-interactive celebration for a newly completed game session.
class CompletionCelebration extends StatefulWidget {
  const CompletionCelebration(
      {super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  static const duration = Duration(milliseconds: 3600);

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: CompletionCelebration.duration);
  bool _started = false;

  void _sync() {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      return;
    }
    if (!_started) {
      _started = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(CompletionCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) _started = false;
    _sync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        widget.child,
        if (widget.enabled && !MediaQuery.disableAnimationsOf(context))
          Positioned.fill(
              child: IgnorePointer(
                  child: ExcludeSemantics(
            child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => _controller.isCompleted
                    ? const SizedBox.shrink()
                    : RepaintBoundary(
                        child: CustomPaint(
                            key: const ValueKey('completion-fireworks'),
                            painter: _FireworksPainter(_controller.value)),
                      )),
          ))),
      ]);
}

class _FireworksPainter extends CustomPainter {
  const _FireworksPainter(this.progress);
  final double progress;
  static const _colors = [
    Color(0xFFFFCB45),
    Color(0xFFFF6CBB),
    Color(0xFF67DFFF),
    Color(0xFFB095FF),
    Color(0xFF6CE0A2)
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final extent = math.min(size.width, size.height);
    // Staggered rockets burst around the result card rather than flashing the screen.
    for (var burst = 0; burst < 6; burst++) {
      final t = (progress - burst * .09) / .45;
      if (t <= 0 || t >= 1) continue;
      final center = Offset(size.width * (burst.isEven ? .13 : .87),
          size.height * (.13 + (burst % 3) * .15));
      final color = _colors[burst % _colors.length];
      if (t < .2) {
        final launch = Curves.easeOut.transform(t / .2);
        final rocket =
            Offset.lerp(Offset(center.dx, size.height), center, launch)!;
        canvas.drawLine(
            rocket + const Offset(0, 20),
            rocket,
            Paint()
              ..color = color.withValues(alpha: .7)
              ..strokeWidth = 2);
        canvas.drawCircle(rocket, 3, Paint()..color = color);
        continue;
      }
      final expansion = (t - .2) / .8;
      final radius = extent * .25 * Curves.easeOut.transform(expansion);
      final alpha = (1 - expansion) * .95;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var ray = 0; ray < 22; ray++) {
        final angle = ray * math.pi * 2 / 22 + burst * .45;
        final direction = Offset(math.cos(angle), math.sin(angle));
        final fall = Offset(0, expansion * expansion * 34);
        final tip = center + direction * radius + fall;
        canvas.drawLine(center + direction * radius * .8 + fall, tip, paint);
        canvas.drawCircle(tip, 1.8 * (1 - expansion), paint);
      }
    }
    // Light ribbons and stars fall along both sides; all buttons remain tappable.
    for (var i = 0; i < 36; i++) {
      final t = (progress - (i % 6) * .035) / .85;
      if (t <= 0 || t >= 1) continue;
      final seed = math.Random(i + 42);
      final edge = i.isEven ? .04 : .78;
      final x = size.width * (edge + seed.nextDouble() * .18) +
          math.sin(t * 8 + i) * 14;
      final y = -20 + t * t * (size.height + 40);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + i);
      final paint = Paint()
        ..color = _colors[i % _colors.length]
            .withValues(alpha: (1 - t).clamp(0.0, 1.0));
      if (i % 3 == 0) {
        final star = Path();
        for (var point = 0; point < 10; point++) {
          final angle = point * math.pi / 5 - math.pi / 2;
          final radius = point.isEven ? 6.0 : 2.8;
          final dx = math.cos(angle) * radius, dy = math.sin(angle) * radius;
          if (point == 0) {
            star.moveTo(dx, dy);
          } else {
            star.lineTo(dx, dy);
          }
        }
        canvas.drawPath(star..close(), paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(-3, -5, 6, 10), const Radius.circular(1)),
            paint);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
