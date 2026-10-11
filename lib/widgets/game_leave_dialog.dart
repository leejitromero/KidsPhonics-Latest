import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../data/game_word_data.dart';
import 'button_sound.dart';
import 'game_design.dart';

/// Illustrated confirmation with live text and real Cancel/Leave controls.
class GameLeaveDialog extends StatefulWidget {
  const GameLeaveDialog({super.key});
  @override
  State<GameLeaveDialog> createState() => _GameLeaveDialogState();
}

class _GameLeaveDialogState extends State<GameLeaveDialog> {
  bool _answered = false;
  void _answer(bool leave) {
    if (_answered) return;
    _answered = true;
    Navigator.of(context).pop(leave);
  }

  @override
  Widget build(BuildContext context) => BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        key: const ValueKey('game-leave-dialog'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: SingleChildScrollView(
            clipBehavior: Clip.none,
            child: LayoutBuilder(builder: (_, box) {
              final mascotSize = (box.maxWidth * .5).clamp(110.0, 190.0);
              final stacked = box.maxWidth < 270 ||
                  MediaQuery.textScalerOf(context).scale(20) > 28;
              final cancel = _LeaveChoice(
                  buttonKey: const ValueKey('leave-cancel'),
                  label: 'Cancel',
                  golden: false,
                  autofocus: true,
                  onPressed: () => _answer(false));
              final leave = _LeaveChoice(
                  buttonKey: const ValueKey('leave-confirm'),
                  label: 'Leave',
                  golden: true,
                  onPressed: () => _answer(true));
              return Stack(clipBehavior: Clip.none, children: [
                Padding(
                    padding: EdgeInsets.only(top: mascotSize * .56),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(38),
                            gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFE8AA5D), Color(0xFF9D592C)]),
                            border: Border.all(color: const Color(0xFFF6C991), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x66312650),
                                  blurRadius: 24,
                                  offset: Offset(0, 10))
                            ]),
                        child: CustomPaint(
                            foregroundPainter: const _GardenFrame(),
                            child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 38, 20, 42),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(32),
                                    border: Border.all(
                                        color: const Color(0xFFD1A6FF),
                                        width: 4),
                                    gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFFFEBF2), Color(0xFFFFF8E6), Color(0xFFF2E8FF)]),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 3,
                                          spreadRadius: 1)
                                    ]),
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  const ExcludeSemantics(
                                      child: SizedBox(
                                          key: ValueKey('leave-door-icon'),
                                          width: 84,
                                          height: 76,
                                          child: CustomPaint(
                                              painter: _ExitDoor()))),
                                  const SizedBox(height: 12),
                                  Semantics(
                                      namesRoute: true,
                                      child: const Text('Leave this game?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: GameDesign.ink,
                                              height: 1.15))),
                                  const SizedBox(height: 10),
                                  const Text('Your current round will end.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontSize: 17,
                                          color: Color(0xFF655178),
                                          height: 1.3)),
                                  const SizedBox(height: 24),
                                  if (stacked)
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          cancel,
                                          const SizedBox(height: 12),
                                          leave
                                        ])
                                  else
                                    Row(children: [
                                      Expanded(child: cancel),
                                      const SizedBox(width: 12),
                                      Expanded(child: leave)
                                    ]),
                                ]))))),
                Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                        child: ExcludeSemantics(
                            child: Center(
                                child: ClipRect(
                                    child: Align(
                                        alignment: Alignment.topCenter,
                                        heightFactor: .69,
                                        child: Image.asset(
                                            gameWordFor('Rabbit')!.frames.first,
                                            key: const ValueKey('leave-rabbit'),
                                            width: mascotSize,
                                            height: mascotSize,
                                            cacheWidth: 384,
                                            fit: BoxFit.contain))))))),
              ]);
            }),
          ),
        ),
      ));
}

class _LeaveChoice extends StatelessWidget {
  const _LeaveChoice(
      {required this.buttonKey,
      required this.label,
      required this.golden,
      required this.onPressed,
      this.autofocus = false});
  final Key buttonKey;
  final String label;
  final bool golden, autofocus;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: golden
                  ? const [
                      Color(0xFFFFF88F),
                      Color(0xFFFFDC4B),
                      Color(0xFFFFB638)
                    ]
                  : const [
                      Color(0xFFFFF5FF),
                      Color(0xFFECE4FF),
                      Color(0xFFB9C7FF)
                    ]),
          border: Border.all(
              color: golden ? const Color(0xFFFFAE41) : const Color(0xFFAC7CF6),
              width: 3),
          boxShadow: [
            BoxShadow(
                color:
                    golden ? const Color(0x66E29127) : const Color(0x665E43CB),
                blurRadius: 7,
                offset: const Offset(0, 4))
          ]),
      child: Stack(children: [
        Positioned(
            top: 7,
            left: 13,
            child: IgnorePointer(
                child: Transform.rotate(
                    angle: -.6,
                    child: Container(
                        width: 14,
                        height: 7,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(10)))))),
        if (golden)
          const Positioned(
              right: 5,
              bottom: 5,
              child: IgnorePointer(
                  child: Icon(Icons.star_rounded,
                      size: 22, color: Color(0x66FFFFED)))),
        ElevatedButton(
            key: buttonKey,
            autofocus: autofocus,
            onPressed: withButtonSound(onPressed),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor:
                    golden ? const Color(0xFF632500) : const Color(0xFF6D3CDD),
                elevation: 0,
                minimumSize: const Size(double.infinity, 54),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                side: const BorderSide(color: Color(0xAAFFFFFF), width: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            child: Text(label, textAlign: TextAlign.center)),
      ]));
}

class _ExitDoor extends CustomPainter {
  const _ExitDoor();
  @override
  void paint(Canvas canvas, Size size) {
    final outer =
        Rect.fromLTWH(size.width * .12, 2, size.width * .76, size.height - 4);
    canvas.drawRRect(
        RRect.fromRectAndCorners(outer,
            topLeft: const Radius.circular(34),
            topRight: const Radius.circular(34),
            bottomLeft: const Radius.circular(10),
            bottomRight: const Radius.circular(10)),
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFFF4B55E), Color(0xFFAC5520)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              .createShader(outer));
    final opening = outer.deflate(10);
    canvas.drawRRect(
        RRect.fromRectAndRadius(opening, const Radius.circular(17)),
        Paint()..color = const Color(0xFF6B2F13));
    final door = Path()
      ..moveTo(size.width * .51, 17)
      ..quadraticBezierTo(size.width * .74, 14, size.width * .74, 25)
      ..lineTo(size.width * .74, size.height - 16)
      ..lineTo(size.width * .51, size.height - 21)
      ..close();
    canvas.drawPath(
        door,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFFFFF382), Color(0xFFFFC42B)])
              .createShader(opening));
    canvas.drawPath(
        door,
        Paint()
          ..color = const Color(0xFFFFFAD0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final arrow = Path()
      ..moveTo(25, 34)
      ..lineTo(42, 34)
      ..lineTo(42, 27)
      ..lineTo(57, 41)
      ..lineTo(42, 55)
      ..lineTo(42, 47)
      ..lineTo(25, 47)
      ..close();
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFFFD336));
    canvas.drawPath(
        arrow,
        Paint()
          ..color = const Color(0xFFFFF5B6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_ExitDoor oldDelegate) => false;
}

class _GardenFrame extends CustomPainter {
  const _GardenFrame();
  @override
  void paint(Canvas canvas, Size size) {
    // Cloud puffs stay on the frame, clear of the text and tap targets.
    void cloud(Offset c, double r) {
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = const RadialGradient(
                    center: Alignment(-.35, -.5),
                    colors: [Colors.white, Color(0xFFE4DCFF)])
                .createShader(Rect.fromCircle(center: c, radius: r)));
    }

    for (final left in [true, false]) {
      final x = left ? 12.0 : size.width - 12;
      final sign = left ? 1.0 : -1.0;
      for (var i = 0; i < 5; i++) {
        cloud(Offset(x + sign * i * 12, size.height - 10 + (i.isEven ? 0 : 5)),
            14.0 + (i % 3) * 3);
      }
    }
    const ForestLeaves(allCorners: true).paint(canvas, size);
    void flower(Offset c) {
      final petals = Paint()..color = const Color(0xFFFFFCF2);
      for (var i = 0; i < 5; i++) {
        final a = i * math.pi * 2 / 5;
        canvas.drawCircle(
            c + Offset(math.cos(a), math.sin(a)) * 6, 4.5, petals);
      }
      canvas.drawCircle(c, 3.5, Paint()..color = const Color(0xFFFFC729));
    }

    flower(const Offset(17, 14));
    flower(Offset(size.width - 17, 14));
    void star(Offset c, double r) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final point =
            c + Offset(math.cos(a), math.sin(a)) * (i.isEven ? r : r * .48);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFD73A));
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFFFF2AF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    star(Offset(9, size.height * .36), 11);
    star(Offset(size.width - 8, size.height * .58), 13);
  }

  @override
  bool shouldRepaint(_GardenFrame oldDelegate) => false;
}
