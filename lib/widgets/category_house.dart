import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/home_village.dart';
import 'button_sound.dart';

/// A dimensional toy house with a stationary, accessible full-house tap target.
/// The parent owns the visit animation, allowing only one doorway to open.
class CategoryHouse extends StatelessWidget {
  const CategoryHouse(
      {super.key,
      required this.category,
      required this.visit,
      required this.onTap,
      this.selected = false,
      this.locked = false});
  final HomeCategory category;
  final Animation<double> visit;
  final VoidCallback? onTap;
  final bool selected, locked;

  @override
  Widget build(BuildContext context) => Semantics(
      label:
          locked ? '${category.title}, turned off by a parent' : category.title,
      button: true,
      enabled: onTap != null,
      child: Tooltip(
          message:
              locked ? 'Games are turned off by a parent.' : category.title,
          excludeFromSemantics: true,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  key: ValueKey('home-${category.name}'),
                  onTap: withButtonSound(onTap),
                  borderRadius: BorderRadius.circular(32),
                  splashColor: Colors.white.withValues(alpha: .12),
                  highlightColor: Colors.transparent,
                  child: ExcludeSemantics(
                      child: _HouseScene(
                          category: category,
                          visit: visit,
                          selected: selected,
                          locked: locked))))));
}

class _HouseScene extends StatelessWidget {
  const _HouseScene(
      {required this.category,
      required this.visit,
      required this.selected,
      required this.locked});
  final HomeCategory category;
  final Animation<double> visit;
  final bool selected, locked;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final w = box.maxWidth, h = box.maxHeight;
        return RepaintBoundary(
            child: AnimatedBuilder(
                animation: visit,
                builder: (_, __) {
                  final t = selected ? visit.value : 0.0;
                  final door = HomeVisitTiming.door(t);
                  final emergence = HomeVisitTiming.mascot(t);
                  final greeting = HomeVisitTiming.greeting(t);
                  final bounce = math.sin(t * math.pi);
                  return Transform.scale(
                      scale: 1 + bounce * .025,
                      alignment: Alignment.bottomCenter,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned.fill(
                            child: CustomPaint(
                                painter: _HousePainter(
                                    category: category, lift: bounce))),
                        Positioned(
                            top: h * .12,
                            left: w * .39,
                            width: w * .22,
                            height: h * .18,
                            child: _RoofBadge(category: category)),
                        Positioned(
                            top: h * .36,
                            left: w * .08,
                            width: w * .84,
                            height: h * .145,
                            child: _WoodenSign(category: category)),
                        Positioned(
                            left: w * .32,
                            top: h * .545,
                            width: w * .36,
                            height: h * .365,
                            child: _Doorway(category: category, glow: bounce)),
                        if (emergence > 0)
                          Positioned(
                              top: h * (.58 - .14 * emergence),
                              left: w * .25,
                              width: w * .50,
                              height: h * .46,
                              child: _EmergingMascot(
                                  category: category,
                                  emergence: emergence,
                                  greeting: greeting,
                                  travel: h * .08)),
                        Positioned(
                            left: w * .32,
                            top: h * .545,
                            width: w * .36,
                            height: h * .365,
                            child:
                                _HingedDoor(category: category, opening: door)),
                        if (locked)
                          Positioned(
                              top: h * .69,
                              left: w * .40,
                              width: w * .20,
                              child: const Icon(Icons.lock_rounded,
                                  color: Colors.white, size: 28)),
                      ]));
                }));
      });
}

class _Doorway extends StatelessWidget {
  const _Doorway({required this.category, required this.glow});
  final HomeCategory category;
  final double glow;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(120),
              topRight: Radius.circular(120),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6)),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [category.dark, const Color(0xFF211932)]),
          boxShadow: glow > 0
              ? [
                  BoxShadow(
                      color: category.highlight.withValues(alpha: .65 * glow),
                      blurRadius: 16,
                      spreadRadius: 3)
                ]
              : null));
}

class _EmergingMascot extends StatelessWidget {
  const _EmergingMascot(
      {required this.category,
      required this.emergence,
      required this.greeting,
      required this.travel});
  final HomeCategory category;
  final double emergence, greeting, travel;
  @override
  Widget build(BuildContext context) => Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.identity()
        ..translateByDouble(0, travel * (1 - emergence), 0, 1)
        ..rotateZ(math.sin(greeting * math.pi * 2) * .055)
        ..scaleByDouble(.30 + .70 * emergence, .30 + .70 * emergence, 1, 1),
      child: Image.asset(category.mascotAsset,
          key: ValueKey('home-${category.name}-mascot'),
          fit: BoxFit.contain,
          cacheWidth: 512));
}

class _HingedDoor extends StatelessWidget {
  const _HingedDoor({required this.category, required this.opening});
  final HomeCategory category;
  final double opening;
  @override
  Widget build(BuildContext context) => Transform(
      key: ValueKey('home-${category.name}-door'),
      alignment: Alignment.centerLeft,
      transform: opening == 0
          ? Matrix4.identity()
          : (Matrix4.identity()
            ..setEntry(3, 2, .003)
            ..rotateY(-opening * math.pi * .64)),
      child: CustomPaint(painter: _DoorPainter(category)));
}

class _RoofBadge extends StatelessWidget {
  const _RoofBadge({required this.category});
  final HomeCategory category;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFBD1),
                Color(0xFFFFD168),
                Color(0xFFD79535)
              ]),
          border: Border.all(color: const Color(0xFFFFEDAE), width: 2),
          boxShadow: [
            BoxShadow(
                color: category.dark.withValues(alpha: .4),
                offset: const Offset(0, 3),
                blurRadius: 2),
          ]),
      child: LayoutBuilder(
          builder: (_, box) => Icon(category.icon,
              size: box.maxWidth * .56, color: category.dark)));
}

class _WoodenSign extends StatelessWidget {
  const _WoodenSign({required this.category});
  final HomeCategory category;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [
                0,
                .12,
                .65,
                1
              ],
              colors: [
                Color(0xFFFFEDB1),
                Color(0xFFFFD487),
                Color(0xFFEDB45F),
                Color(0xFFBC7334)
              ]),
          border: Border.all(color: const Color(0xFFFFDEA0), width: 2),
          boxShadow: [
            BoxShadow(
                color: category.dark.withValues(alpha: .6),
                offset: const Offset(0, 4),
                blurRadius: 1),
            const BoxShadow(
                color: Color(0x403C2020), offset: Offset(0, 6), blurRadius: 8),
          ]),
      child: Row(children: [
        const _SignPin(),
        Expanded(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(category.title,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: category.dark,
                        shadows: const [
                          Shadow(
                              color: Color(0xFFFFF1C5), offset: Offset(0, 1.5))
                        ])))),
        const _SignPin(),
      ]));
}

class _SignPin extends StatelessWidget {
  const _SignPin();
  @override
  Widget build(BuildContext context) => Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFAC692F),
          boxShadow: [
            BoxShadow(color: Color(0xFFFFEDB1), offset: Offset(0, 1))
          ]));
}

class _HousePainter extends CustomPainter {
  const _HousePainter({required this.category, required this.lift});
  final HomeCategory category;
  final double lift;

  void _fill(Canvas canvas, Path path, List<Color> colors,
      {double shadow = 0}) {
    if (shadow > 0) {
      canvas.drawShadow(path, const Color(0x8850373E), shadow, false);
    }
    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors)
              .createShader(path.getBounds()));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Normalized geometry keeps walls, roof, door and sign aligned at any size.
    canvas.save();
    canvas.scale(size.width / 200, size.height / 220);
    canvas.drawOval(
        const Rect.fromLTWH(12, 198, 176, 16),
        Paint()
          ..color = const Color(0xFF294C36).withValues(alpha: .16 + .10 * lift)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    final base = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 185, 152, 22), const Radius.circular(10)));
    _fill(canvas, base,
        const [Color(0xFFFFEACA), Color(0xFFCEB7A1), Color(0xFF9C7C72)],
        shadow: 3);
    final wall = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(28, 62, 144, 132), const Radius.circular(26)));
    _fill(
        canvas,
        wall,
        [
          const Color(0xFFFFFCDF),
          const Color(0xFFFFEDCC),
          Color.lerp(const Color(0xFFE4C1A0), category.color, .20)!
        ],
        shadow: 5);
    // Wall bevels and small masonry accents.
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(32, 67, 136, 122), const Radius.circular(23)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0x88FFFFFF));
    for (final brick in [
      const Rect.fromLTWH(32, 129, 19, 8),
      const Rect.fromLTWH(144, 150, 24, 8),
      const Rect.fromLTWH(32, 168, 17, 7)
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(brick, const Radius.circular(3)),
          Paint()..color = category.color.withValues(alpha: .13));
    }
    // Rounded, tiered roof; the rim casts a shadow onto the cream facade.
    final roof = Path()
      ..moveTo(10, 83)
      ..cubicTo(8, 67, 28, 55, 35, 39)
      ..cubicTo(46, 13, 80, 8, 100, 7)
      ..cubicTo(125, 11, 152, 18, 166, 43)
      ..cubicTo(174, 60, 195, 71, 190, 83)
      ..quadraticBezierTo(149, 98, 100, 85)
      ..quadraticBezierTo(53, 98, 10, 83)
      ..close();
    canvas.drawShadow(roof.shift(const Offset(0, 5)), category.dark, 7, false);
    canvas.drawPath(
        roof.shift(const Offset(0, 5)), Paint()..color = category.dark);
    canvas.drawPath(
        roof,
        Paint()
          ..shader = RadialGradient(
              center: const Alignment(-.45, -.65),
              radius: 1.1,
              colors: [
                Color.lerp(category.highlight, Colors.white, .18)!,
                category.color,
                category.dark
              ],
              stops: const [
                0,
                .58,
                1
              ]).createShader(roof.getBounds()));
    // Overlapping softly sculpted shingles, each with a lit crown and a
    // shadowed lower lip. The roof silhouette clips all decoration safely.
    canvas.save();
    canvas.clipPath(roof);
    for (var row = 0; row < 3; row++) {
      for (var col = -1; col < 5; col++) {
        final x = col * 44.0 + (row.isOdd ? 22 : 0);
        final y = 13.0 + row * 24;
        final tile = Path()
          ..moveTo(x, y + 9)
          ..quadraticBezierTo(x + 20, y - 1, x + 43, y + 9)
          ..quadraticBezierTo(x + 49, y + 27, x + 37, y + 34)
          ..quadraticBezierTo(x + 22, y + 40, x + 5, y + 33)
          ..quadraticBezierTo(x - 2, y + 22, x, y + 9)
          ..close();
        canvas.drawShadow(tile, category.dark.withValues(alpha: .75), 2, false);
        canvas.drawPath(
            tile,
            Paint()
              ..shader = RadialGradient(
                  center: const Alignment(-.4, -.7),
                  radius: 1.1,
                  colors: [
                    Color.lerp(category.highlight, Colors.white, .13)!,
                    category.color,
                    Color.lerp(category.color, category.dark, .8)!
                  ],
                  stops: const [
                    0,
                    .62,
                    1
                  ]).createShader(tile.getBounds()));
        final lip = Path()
          ..moveTo(x + 4, y + 30)
          ..quadraticBezierTo(x + 23, y + 39, x + 40, y + 29);
        canvas.drawPath(
            lip,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2
              ..strokeCap = StrokeCap.round
              ..color = category.highlight.withValues(alpha: .65));
        final glint = Rect.fromLTWH(x + 8, y + 8, 17, 4);
        canvas.drawOval(
            glint,
            Paint()
              ..color = Colors.white.withValues(alpha: .25)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
      }
    }
    canvas.restore();
    canvas.drawPath(
        roof,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..color = category.dark);
    final sheen = Path()
      ..moveTo(31, 54)
      ..cubicTo(56, 18, 87, 13, 108, 17);
    canvas.drawPath(
        sheen,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .60));
    final chimney = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(146, 18, 15, 25), const Radius.circular(4)));
    _fill(canvas, chimney, [category.highlight, category.dark]);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(143, 16, 21, 7), const Radius.circular(3)),
        Paint()..color = category.color);
    // Arched door casing: layered stone, gold trim, then a shadowed reveal.
    final frame = _arch(const Rect.fromLTWH(57, 111, 86, 92));
    _fill(canvas, frame,
        const [Color(0xFFFFF3D6), Color(0xFFEAC586), Color(0xFFC8934D)],
        shadow: 3);
    canvas.drawPath(
        frame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFE6A8));
    final inner = _arch(const Rect.fromLTWH(63, 118, 74, 84));
    canvas.drawPath(
        inner,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0xFFB7814D));
    // Matching porch lights with a soft, warm halo.
    for (final x in [45.0, 155.0]) {
      canvas.drawCircle(
          Offset(x, 137),
          13,
          Paint()
            ..color = const Color(0x55FFF0AC)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawLine(
          Offset(x, 122),
          Offset(x, 127),
          Paint()
            ..strokeWidth = 3
            ..color = const Color(0xFFAB642D));
      final lantern = Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, 137), width: 13, height: 20),
            const Radius.circular(4)));
      _fill(canvas, lantern,
          const [Color(0xFFFFF8AD), Color(0xFFFFD56E), Color(0xFFE6A242)],
          shadow: 1);
      canvas.drawPath(
          lantern,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFB6742E));
      canvas.drawLine(
          Offset(x - 2, 131),
          Offset(x - 2, 143),
          Paint()
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFFFFADB));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.category != category || old.lift != lift;
}

Path _arch(Rect rect) => Path()
  ..moveTo(rect.left, rect.bottom)
  ..lineTo(rect.left, rect.top + rect.width / 2)
  ..arcTo(Rect.fromLTWH(rect.left, rect.top, rect.width, rect.width), math.pi,
      math.pi, false)
  ..lineTo(rect.right, rect.bottom)
  ..close();

class _DoorPainter extends CustomPainter {
  const _DoorPainter(this.category);
  final HomeCategory category;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final shape = _arch(bounds.deflate(1));
    canvas.drawShadow(shape, const Color(0xFF191525), 3, false);
    canvas.drawPath(
        shape,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [category.highlight, category.color, category.dark])
              .createShader(bounds));
    canvas.save();
    canvas.clipPath(shape);
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(
          Offset(x, 0),
          Offset(x, size.height),
          Paint()
            ..color = category.dark.withValues(alpha: .5)
            ..strokeWidth = 1.5);
      canvas.drawLine(
          Offset(x + 1.6, 0),
          Offset(x + 1.6, size.height),
          Paint()
            ..color = Colors.white.withValues(alpha: .15)
            ..strokeWidth = 1);
    }
    canvas.restore();
    canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = category.dark);
    canvas.drawPath(
        _arch(bounds.deflate(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = category.highlight.withValues(alpha: .8));
    final center = Offset(size.width * .5, size.height * .48);
    final emblem = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final radius = size.width * (i.isEven ? .22 : .11);
      final point = center + Offset(math.cos(a), math.sin(a)) * radius;
      if (i == 0) {
        emblem.moveTo(point.dx, point.dy);
      } else {
        emblem.lineTo(point.dx, point.dy);
      }
    }
    emblem.close();
    canvas.drawShadow(emblem, category.dark, 3, false);
    canvas.drawPath(
        emblem,
        Paint()
          ..shader = const LinearGradient(colors: [
            Color(0xFFFFFFBE),
            Color(0xFFFFDD54),
            Color(0xFFF1A329)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight)
              .createShader(emblem.getBounds()));
    canvas.drawPath(
        emblem,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFE999));
    final knob = Offset(size.width * .81, size.height * .70);
    canvas.drawCircle(
        knob + const Offset(0, 1), 4, Paint()..color = const Color(0xFF9B6033));
    canvas.drawCircle(knob, 3.4, Paint()..color = const Color(0xFFFFD768));
    canvas.drawCircle(knob - const Offset(1, 1), 1.2,
        Paint()..color = const Color(0xFFFFFFD6));
  }

  @override
  bool shouldRepaint(_DoorPainter old) => old.category != category;
}
