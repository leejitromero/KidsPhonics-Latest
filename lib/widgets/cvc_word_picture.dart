import 'package:flutter/material.dart';
import '../data/cvc_lesson_data.dart';

/// Reuses supplied pictures, with pictograms for the document's new vocabulary.
class CvcWordPicture extends StatelessWidget {
  const CvcWordPicture({super.key, required this.word});
  final CvcLessonWord word;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: word.word,
        child: ExcludeSemantics(
            child: word.imageAsset != null
                ? Image.asset(word.imageAsset!,
                    fit: BoxFit.contain, cacheWidth: 480)
                : word.emoji.isNotEmpty
                    ? FittedBox(
                        fit: BoxFit.contain,
                        child: Text(word.emoji,
                            style: const TextStyle(fontSize: 100, height: 1.2)))
                    : CustomPaint(
                        painter: _CvcPictogram(word.word),
                        child: const SizedBox.expand())),
      );
}

class _CvcPictogram extends CustomPainter {
  const _CvcPictogram(this.word);
  final String word;
  static const ink = Color(0xFF30214F);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.scale(side / 200);
    void line(Offset from, Offset to, Color color, double width) =>
        canvas.drawLine(
            from,
            to,
            Paint()
              ..color = color
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round);
    void shape(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(
          path,
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round);
    }

    switch (word) {
      case 'RUG':
        shape(
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  const Rect.fromLTWH(32, 42, 136, 116),
                  const Radius.circular(8))),
            const Color(0xFFB174DF));
        canvas.drawRect(const Rect.fromLTWH(47, 57, 106, 86),
            Paint()..color = const Color(0xFFFFCD66));
        shape(
            Path()
              ..moveTo(100, 67)
              ..lineTo(140, 100)
              ..lineTo(100, 133)
              ..lineTo(60, 100)
              ..close(),
            const Color(0xFF46BAB2));
        for (var y = 50.0; y <= 150; y += 12) {
          line(Offset(20, y), Offset(31, y), const Color(0xFFB174DF), 4);
          line(Offset(169, y), Offset(180, y), const Color(0xFFB174DF), 4);
        }
      case 'BIG':
        canvas.drawCircle(const Offset(120, 95), 65,
            Paint()..color = const Color(0xFF35BFE8));
        canvas.drawCircle(const Offset(27, 140), 18,
            Paint()..color = const Color(0xFF35BFE8));
        line(const Offset(67, 180), const Offset(178, 180), ink, 5);
        line(const Offset(67, 180), const Offset(80, 169), ink, 5);
        line(const Offset(178, 180), const Offset(165, 169), ink, 5);
      case 'DIG':
        canvas.drawOval(const Rect.fromLTWH(25, 143, 150, 42),
            Paint()..color = const Color(0xFF9B6945));
        canvas.drawOval(const Rect.fromLTWH(65, 148, 70, 28),
            Paint()..color = const Color(0xFF513B31));
        line(const Offset(137, 45), const Offset(86, 136),
            const Color(0xFFB17B49), 11);
        shape(
            Path()
              ..moveTo(67, 122)
              ..lineTo(105, 141)
              ..quadraticBezierTo(84, 176, 65, 159)
              ..close(),
            const Color(0xFF90AAB9));
        shape(
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  const Rect.fromLTWH(124, 21, 37, 29),
                  const Radius.circular(9))),
            const Color(0xFFFFC955));
        for (final point in [
          const Offset(41, 128),
          const Offset(146, 131),
          const Offset(160, 150)
        ]) {
          canvas.drawCircle(point, 6, Paint()..color = const Color(0xFF9B6945));
        }
      case 'RIB':
        line(const Offset(100, 28), const Offset(100, 174),
            const Color(0xFFCB987B), 13);
        for (var y = 40.0; y <= 128; y += 22) {
          final path = Path()
            ..moveTo(97, y)
            ..cubicTo(30, y - 24, 22, y + 33, 85, y + 36)
            ..moveTo(103, y)
            ..cubicTo(170, y - 24, 178, y + 33, 115, y + 36);
          canvas.drawPath(
              path,
              Paint()
                ..color = const Color(0xFFE6B895)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 10
                ..strokeCap = StrokeCap.round);
        }
      case 'MOP':
        line(const Offset(143, 20), const Offset(87, 132),
            const Color(0xFF2399C3), 12);
        canvas.drawOval(const Rect.fromLTWH(37, 155, 129, 25),
            Paint()..color = const Color(0xFFBFEAF4));
        for (var x = 53.0; x <= 129; x += 13) {
          line(const Offset(87, 130), Offset(x, 167), const Color(0xFFD5C0E9),
              12);
        }
        line(const Offset(72, 125), const Offset(106, 140),
            const Color(0xFF7052CA), 15);
      case 'HUG':
        for (final x in [70.0, 132.0]) {
          canvas.drawCircle(
              Offset(x, 59), 26, Paint()..color = const Color(0xFFFFC698));
          line(Offset(x, 103), Offset(x, 164),
              x == 70 ? const Color(0xFF299DD3) : const Color(0xFFAF76DE), 43);
          canvas.drawCircle(Offset(x - 6, 58), 2.5, Paint()..color = ink);
          canvas.drawCircle(Offset(x + 6, 58), 2.5, Paint()..color = ink);
        }
        line(const Offset(54, 106), const Offset(132, 125),
            const Color(0xFFFFC698), 15);
        line(const Offset(147, 104), const Offset(74, 137),
            const Color(0xFFFFC698), 15);
      case 'FIN':
        canvas.drawOval(const Rect.fromLTWH(10, 130, 180, 44),
            Paint()..color = const Color(0xFF68D5F0));
        shape(
            Path()
              ..moveTo(45, 140)
              ..quadraticBezierTo(95, 100, 112, 40)
              ..quadraticBezierTo(143, 76, 154, 140)
              ..close(),
            const Color(0xFF7094B1));
        line(const Offset(20, 157), const Offset(63, 157), Colors.white, 5);
        line(const Offset(134, 166), const Offset(177, 166), Colors.white, 5);
      case 'TOP':
        line(const Offset(100, 30), const Offset(100, 80),
            const Color(0xFFFFBE48), 15);
        shape(
            Path()
              ..moveTo(35, 98)
              ..quadraticBezierTo(100, 45, 165, 98)
              ..lineTo(100, 176)
              ..close(),
            const Color(0xFF8863D8));
        shape(
            Path()
              ..moveTo(35, 98)
              ..quadraticBezierTo(100, 55, 165, 98)
              ..quadraticBezierTo(100, 127, 35, 98)
              ..close(),
            const Color(0xFFFFC955));
        line(const Offset(60, 134), const Offset(139, 134),
            const Color(0xFF49D1C4), 10);
        canvas.drawArc(
            const Rect.fromLTWH(15, 145, 170, 35),
            .1,
            2.2,
            false,
            Paint()
              ..color = const Color(0xFF6EA7C6)
              ..strokeWidth = 4
              ..style = PaintingStyle.stroke);
      case 'SIT':
        line(const Offset(60, 91), const Offset(60, 153),
            const Color(0xFFAA744F), 12);
        line(const Offset(60, 130), const Offset(120, 130),
            const Color(0xFFAA744F), 12);
        line(const Offset(120, 131), const Offset(120, 168),
            const Color(0xFFAA744F), 10);
        canvas.drawCircle(
            const Offset(89, 47), 23, Paint()..color = const Color(0xFFFFC698));
        line(const Offset(89, 78), const Offset(89, 116),
            const Color(0xFF218ED3), 28);
        line(const Offset(92, 119), const Offset(136, 119),
            const Color(0xFF7052CA), 17);
        line(const Offset(137, 119), const Offset(137, 163),
            const Color(0xFF7052CA), 17);
        line(const Offset(135, 169), const Offset(156, 169), ink, 12);
        line(const Offset(102, 85), const Offset(123, 111),
            const Color(0xFFFFC698), 12);
        canvas.drawCircle(const Offset(96, 44), 3, Paint()..color = ink);
      case 'WIG':
        line(const Offset(100, 133), const Offset(100, 178),
            const Color(0xFF91ADC0), 12);
        canvas.drawOval(const Rect.fromLTWH(60, 168, 80, 18),
            Paint()..color = const Color(0xFF91ADC0));
        shape(
            Path()
              ..moveTo(45, 140)
              ..lineTo(45, 75)
              ..cubicTo(42, 8, 160, 8, 157, 75)
              ..lineTo(163, 140)
              ..lineTo(133, 145)
              ..lineTo(68, 145)
              ..close(),
            const Color(0xFF9D573C));
        canvas.drawOval(const Rect.fromLTWH(65, 51, 71, 99),
            Paint()..color = const Color(0xFFFFDFC2));
        shape(
            Path()
              ..moveTo(48, 84)
              ..cubicTo(51, 13, 152, 13, 155, 89)
              ..quadraticBezierTo(111, 70, 100, 55)
              ..quadraticBezierTo(91, 78, 48, 84)
              ..close(),
            const Color(0xFFB36A44));
        line(const Offset(51, 96), const Offset(55, 129),
            const Color(0xFFE69E66), 4);
        line(const Offset(146, 99), const Offset(150, 130),
            const Color(0xFFE69E66), 4);
    }
  }

  @override
  bool shouldRepaint(_CvcPictogram oldDelegate) => oldDelegate.word != word;
}
