import 'dart:math' as math;
import 'package:flutter/material.dart';

const parentPinInk = Color(0xFF075132);
const parentPinAccessArt = 'assets/images/parent_access/parent_access_lock.png';
const parentPinSetupArt = 'assets/images/parent_access/parent_setup_lock.png';

class ParentPinPanel extends StatelessWidget {
  const ParentPinPanel({super.key, required this.child, this.compact = false});
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFCCF881), Color(0xFF49AF36), Color(0xFF218634)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66466B18), blurRadius: 9, offset: Offset(0, 5))
          ]),
      padding: const EdgeInsets.all(3),
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31),
              border: Border.all(color: Colors.white, width: 3),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE0F5DB),
                    Color(0xFFFFFEEE),
                    Color(0xFFECF9DE)
                  ])),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
              painter: const _PinClouds(),
              child:
                  Padding(padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 12 : 18), child: child))));
}

class ParentPinHeading extends StatelessWidget {
  const ParentPinHeading(
      {super.key, required this.setup, required this.compact});
  final bool setup, compact;
  @override
  Widget build(BuildContext context) {
    final title = setup ? 'Set Up Parent PIN' : 'Parent Access';
    final style = TextStyle(
        fontFamily: 'Nunito',
        fontSize: compact ? 26 : 32,
        height: 1.15,
        fontWeight: FontWeight.w900);
    final illustration = SizedBox(
        height: compact
            ? 44
            : setup
                ? 112
                : 142,
        child: Image.asset(setup ? parentPinSetupArt : parentPinAccessArt,
            key: ValueKey(
                setup ? 'parent-pin-setup-art' : 'parent-pin-access-art'),
            fit: BoxFit.contain,
            cacheWidth: 480,
            excludeFromSemantics: true));
    final heading = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(title,
            textAlign: TextAlign.center,
            style: style.copyWith(color: parentPinInk, shadows: const [
              Shadow(color: Colors.white, offset: Offset(-3, 0)),
              Shadow(color: Colors.white, offset: Offset(3, 0)),
              Shadow(color: Colors.white, offset: Offset(0, -3)),
              Shadow(color: Colors.white, offset: Offset(0, 3)),
              Shadow(color: Colors.white, offset: Offset(-2, -2)),
              Shadow(color: Colors.white, offset: Offset(2, -2)),
              Shadow(color: Colors.white, offset: Offset(-2, 2)),
              Shadow(color: Colors.white, offset: Offset(2, 2)),
              Shadow(
                  color: Color(0x554B943A), blurRadius: 2, offset: Offset(0, 3))
            ])));
    return Column(children: [
      if (compact)
        Row(children: [
          SizedBox(width: 44, child: illustration),
          const SizedBox(width: 8),
          Expanded(child: heading),
        ])
      else ...[
        illustration,
        const SizedBox(height: 8),
        heading,
      ],
      if (setup) ...[
        const SizedBox(height: 6),
        Text('Choose a PIN that your child does not know.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: compact ? 13 : 15,
                height: 1.25,
                color: parentPinInk,
                fontWeight: FontWeight.w600)),
      ],
    ]);
  }
}

class ParentPinFieldPanel extends StatelessWidget {
  const ParentPinFieldPanel(
      {super.key,
      required this.label,
      required this.child,
      this.compact = false});
  final String label;
  final Widget child;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFAFDF8A), width: 2),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFF8), Color(0xFFF0FAE2)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x33488A36), blurRadius: 3, offset: Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: compact ? 14 : 16,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: parentPinInk))),
        SizedBox(height: compact ? 4 : 6),
        child,
      ]));
}

class ParentPinPrimaryButton extends StatelessWidget {
  const ParentPinPrimaryButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.compact = false,
      required this.setup});
  final String label;
  final VoidCallback? onPressed;
  final bool setup;
  final bool compact;
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: onPressed == null ? .5 : 1,
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFF147D2D), width: 3),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFC4F957),
                    Color(0xFF66CF36),
                    Color(0xFF0BA13F)
                  ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x6636771D),
                    blurRadius: 4,
                    offset: Offset(0, 4))
              ]),
          child: Stack(children: [
            const Positioned(
                left: 18,
                top: 6,
                child: ExcludeSemantics(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: Color(0xBBFFFFFF),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: SizedBox(width: 28, height: 5)))),
            ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                        horizontal: 20, vertical: compact ? 8 : 12),
                    minimumSize: Size(48, compact ? 48 : 54),
                    shape: const StadiumBorder()),
                child: Row(children: [
                  if (setup) ...[
                    const ExcludeSemantics(
                        child: Icon(Icons.lock_rounded,
                            size: 26,
                            color: Color(0xFFFFD22D),
                            shadows: [
                          Shadow(
                              color: Color(0xFF177532),
                              offset: Offset(0, 2),
                              blurRadius: 1)
                        ])),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: compact ? 22 : 24,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              shadows: const [
                                Shadow(
                                    color: Color(0xFF0A6436),
                                    offset: Offset(0, 2),
                                    blurRadius: 2)
                              ]))),
                ])),
          ])));
}

class _PinClouds extends CustomPainter {
  const _PinClouds();
  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()
      ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xDDE6F7EF)])
          .createShader(Offset.zero & size);
    final radius = math.min(58.0, size.width * .15);
    for (final x in [0.0, size.width]) {
      canvas.drawCircle(Offset(x, size.height - radius), radius * 1.4, cloud);
      canvas.drawCircle(Offset(x + (x == 0 ? radius : -radius), size.height),
          radius * 1.1, cloud);
      canvas.drawCircle(Offset(x, radius * 1.6), radius * .7, cloud);
      canvas.drawCircle(
          Offset(x + (x == 0 ? radius * .55 : -radius * .55), radius * 1.65),
          radius * .45,
          cloud);
    }
    for (final point in [
      Offset(size.width * .18, radius * .9),
      Offset(size.width * .83, radius * 1.7),
      Offset(size.width * .12, size.height - radius * 1.3),
      Offset(size.width * .87, size.height - radius)
    ]) {
      _star(canvas, point, radius * .2);
    }
  }

  void _star(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + math.pi * i / 5;
      final r = radius * (i.isEven ? 1 : .48);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawShadow(path, const Color(0x665E6918), 2, false);
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFF93),
                Color(0xFFFFD638),
                Color(0xFFFFB218)
              ]).createShader(rect));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFC04A));
  }

  @override
  bool shouldRepaint(covariant _PinClouds oldDelegate) => false;
}
