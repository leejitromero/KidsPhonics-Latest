import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';

/// A generous square hit target around a tab-and-socket jigsaw silhouette.
class BlendingPuzzlePiece extends StatelessWidget {
  const BlendingPuzzlePiece(
      {super.key,
      this.letter,
      this.active = false,
      this.filled = false,
      this.position = 1,
      this.onPressed,
      this.label});
  final String? letter, label;
  final bool active, filled;
  final int position;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        button: onPressed != null,
        selected: active,
        child: CustomPaint(
          painter: _PuzzlePainter(
              active: active, filled: filled, position: position),
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              foregroundColor: KidsUi.ink,
              disabledForegroundColor: KidsUi.ink,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: ExcludeSemantics(
                child: Center(
                    child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(letter ?? '',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color:
                        letter == null ? const Color(0xFF7C7196) : KidsUi.ink,
                  )),
            ))),
          ),
        ),
      );
}

class _PuzzlePainter extends CustomPainter {
  const _PuzzlePainter(
      {required this.active, required this.filled, required this.position});
  final bool active, filled;
  final int position;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final colors = switch (position) {
      0 => const [Color(0xFFFF8A8A), Color(0xFFFF333B), Color(0xFFB7071A)],
      2 => const [Color(0xFF5CE2FF), Color(0xFF03A9F4), Color(0xFF0456B6)],
      _ => const [Color(0xFFFFEE67), Color(0xFFFFCC00), Color(0xFFE18300)],
    };
    final path = Path()
      ..moveTo(25, 9)
      ..lineTo(70, 9)
      ..quadraticBezierTo(87, 9, 87, 26)
      ..lineTo(87, 39);
    if (position != 2) path.cubicTo(103, 28, 103, 72, 87, 61);
    path
      ..lineTo(87, 74)
      ..quadraticBezierTo(87, 91, 70, 91)
      ..lineTo(25, 91)
      ..quadraticBezierTo(8, 91, 8, 74)
      ..lineTo(8, 61);
    if (position != 0) path.cubicTo(25, 73, 25, 27, 8, 39);
    path
      ..lineTo(8, 26)
      ..quadraticBezierTo(8, 9, 25, 9)
      ..close();
    canvas.drawShadow(path, const Color(0x6630214F), active ? 8 : 3, false);
    if (active) {
      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8);
    }
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors)
              .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
    canvas.drawPath(
        path,
        Paint()
          ..color = colors.last
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.save();
    canvas.translate(10, 11);
    canvas.scale(.79, .76);
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF8DD), Color(0xFFFFDFA4)])
              .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
    canvas.drawPath(
        path,
        Paint()
          ..color = colors.last
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    canvas.restore();
    canvas.drawPath(
        Path()
          ..moveTo(16, 29)
          ..quadraticBezierTo(17, 16, 31, 16)
          ..lineTo(67, 16),
        Paint()
          ..color = Colors.white.withValues(alpha: .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PuzzlePainter old) =>
      old.active != active || old.filled != filled || old.position != position;
}
