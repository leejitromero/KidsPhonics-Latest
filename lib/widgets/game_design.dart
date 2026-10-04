import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'button_sound.dart';

/// UI primitives matched to design_reference/new_ui; all content stays live.
class GameDesign extends InheritedWidget {
  const GameDesign({super.key, required super.child});
  static bool active(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameDesign>() != null;
  static const ink = Color(0xFF29165D);
  static const cream = Color(0xFFFFF5DC);
  static const tileColors = [
    Color(0xFFFF3982),
    Color(0xFF00B8F1),
    Color(0xFFFFAD13),
    Color(0xFF933CF0),
    Color(0xFF65C919),
  ];
  @override
  bool updateShouldNotify(GameDesign oldWidget) => false;
}

class ForestPanel extends StatelessWidget {
  const ForestPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(12),
      this.leaves = true,
      this.accent = const Color(0xFFD59239),
      this.glass = false});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color accent;
  final bool leaves, glass;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(accent, Colors.white, .45)!,
              accent,
              Color.lerp(accent, Colors.black, .2)!
            ]),
        boxShadow: const [
          BoxShadow(
              color: Color(0x332B3859), blurRadius: 9, offset: Offset(0, 4))
        ],
      ),
      child: CustomPaint(
          foregroundPainter: leaves ? const ForestLeaves() : null,
          child: Container(
              margin: const EdgeInsets.all(3),
              padding: padding,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: .88), width: 2),
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: glass
                          ? const [Color(0xF5F4F0FF), Color(0xD6D9EBFF)]
                          : const [Color(0xFFFFFCF3), Color(0xFFFFEAC6)])),
              child: DefaultTextStyle.merge(
                  style: const TextStyle(color: GameDesign.ink),
                  child: child))));
}

/// Small ornamental leaves are vector UI decoration, so they scale with controls.
class ForestLeaves extends CustomPainter {
  const ForestLeaves({this.allCorners = false});
  final bool allCorners;
  @override
  void paint(Canvas canvas, Size size) {
    final edge = math.min(20.0, size.shortestSide * .23);
    void sprig(double x, double y, double angle) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      for (var i = 0; i < 3; i++) {
        canvas.save();
        canvas.rotate((i - 1) * .85);
        final leaf = Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-edge * .62, -edge * .55, 0, -edge)
          ..quadraticBezierTo(edge * .55, -edge * .6, 0, 0);
        canvas.drawPath(
            leaf,
            Paint()
              ..shader = const LinearGradient(
                      colors: [Color(0xFFB8ED24), Color(0xFF32911B)])
                  .createShader(Rect.fromLTWH(-edge, -edge, edge * 2, edge)));
        canvas.drawLine(
            Offset.zero,
            Offset(0, -edge * .8),
            Paint()
              ..color = const Color(0xFF307C23)
              ..strokeWidth = .8);
        canvas.restore();
      }
      canvas.restore();
    }

    sprig(8, 12, -.7);
    sprig(size.width - 8, size.height - 12, math.pi - .7);
    if (allCorners) {
      sprig(size.width - 8, 12, .7);
      sprig(8, size.height - 12, math.pi + .7);
    }
  }

  @override
  bool shouldRepaint(ForestLeaves oldDelegate) =>
      allCorners != oldDelegate.allCorners;
}

class ForestIconButton extends StatelessWidget {
  const ForestIconButton(
      {super.key,
      required this.icon,
      required this.tooltip,
      required this.onPressed,
      this.purple = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool purple;
  @override
  Widget build(BuildContext context) => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: purple
                  ? const [Color(0xFFF5EAFF), Color(0xFFD2ACFF)]
                  : const [Color(0xFFEFA447), Color(0xFF9C4D1D)]),
          border: Border.all(
              color: purple ? const Color(0xFFB077E7) : const Color(0xFFFFD18A),
              width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x443E2118), offset: Offset(0, 3), blurRadius: 2)
          ]),
      child: IconButton(
          tooltip: tooltip,
          onPressed: withButtonSound(onPressed),
          color: purple ? GameDesign.ink : Colors.white,
          disabledColor: Colors.white54,
          icon: Icon(icon, size: 26)));
}

class ForestTile extends StatelessWidget {
  const ForestTile({super.key, required this.child, this.variant = 0});
  final Widget child;
  final int variant;
  static const frames = [
    'assets/images/new_ui/frame_pink.png',
    'assets/images/answer_choices/frame-1.png',
    'assets/images/answer_choices/frame-4.png',
    'assets/images/answer_choices/frame-3.png',
    'assets/images/answer_choices/frame-2.png',
  ];
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: const ForestLeaves(),
      child: Stack(fit: StackFit.expand, children: [
        ClipRect(
            child: FractionallySizedBox(
                widthFactor: 1.22,
                heightFactor: 1.22,
                child: Image.asset(frames[variant % frames.length],
                    fit: BoxFit.fill,
                    cacheWidth: 512,
                    excludeFromSemantics: true))),
        child,
      ]));
}

class ForestAudioButton extends StatelessWidget {
  const ForestAudioButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF06C894),
                Color(0xFF009F91),
                Color(0xFF007E80)
              ]),
          border: Border.all(color: const Color(0xFFFFE697), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x55378867), blurRadius: 8, offset: Offset(0, 4))
          ]),
      child: OutlinedButton.icon(
          onPressed: withButtonSound(onPressed),
          icon: Icon(icon, size: 26),
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white60,
              backgroundColor: Colors.transparent,
              minimumSize: const Size(170, 52),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 19,
                  fontWeight: FontWeight.w900),
              side: const BorderSide(color: Color(0xBBFFFFFF), width: 2),
              shape: const StadiumBorder()),
          label: Text(label)));
}

class GameInstruction extends StatelessWidget {
  const GameInstruction({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xE6EFFBFF),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Color(0x220774AC), offset: Offset(0, 3), blurRadius: 4)
          ]),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: GameDesign.ink,
              fontFamily: 'Nunito',
              fontSize: 17,
              fontWeight: FontWeight.w900)));
}
