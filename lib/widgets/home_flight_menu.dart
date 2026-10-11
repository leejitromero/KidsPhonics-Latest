import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'home_recommendation_panel.dart';

const homeMascotAssets = {
  'airplane': 'assets/images/home_mascots/airplane.webp',
  'lessons': 'assets/images/home_mascots/lessons.webp',
  'games': 'assets/images/home_mascots/games.webp',
  'progress': 'assets/images/home_mascots/progress.webp',
  'parents': 'assets/images/home_mascots/parents.webp',
};
const homeLogoAsset = 'assets/images/home_mascots/home_logo.webp';

/// Independent, gently floating artwork with stationary, accessible tap areas.
class HomeFlightMenu extends StatefulWidget {
  const HomeFlightMenu(
      {super.key,
      this.minHeight = 0,
      this.entrance,
      required this.onLessons,
      required this.onGames,
      required this.onProgress,
      required this.onParents});
  final VoidCallback onLessons, onProgress, onParents;
  final VoidCallback? onGames;
  final double minHeight;
  final Animation<double>? entrance;

  @override
  State<HomeFlightMenu> createState() => _HomeFlightMenuState();
}

class _HomeFlightMenuState extends State<HomeFlightMenu>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));
  String? _pressed;
  bool _foreground = true;
  bool _reducedMotion = false;
  bool _tickerEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  void _syncMotion() {
    if (_foreground && _tickerEnabled && !_reducedMotion) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      if (_reducedMotion) _motion.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  Widget _art(String name, double width,
      {double phase = 0, double lift = 3, double sway = .012}) {
    final decodeWidth = (width * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(128, 1365);
    final art = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _motion,
        child: Image.asset(
            name == 'logo' ? homeLogoAsset : homeMascotAssets[name]!,
            key: ValueKey('home-$name-art'),
            width: width,
            fit: BoxFit.contain,
            cacheWidth: decodeWidth,
            excludeFromSemantics: true),
        builder: (_, child) {
          final wave = _reducedMotion
              ? 0.0
              : math.sin(_motion.value * math.pi * 2 + phase);
          return Transform.translate(
              key: ValueKey('home-$name-motion'),
              offset: Offset(0, wave * lift),
              child: Transform.rotate(angle: wave * sway, child: child));
        },
      ),
    );
    final entrance = widget.entrance;
    if (entrance == null) return art;
    final order = [
      'logo',
      'airplane',
      'lessons',
      'games',
      'progress',
      'parents'
    ].indexOf(name);
    return HomeEntrance(
        animation: entrance,
        begin: order * .085,
        end: .22 + order * .085,
        from:
            name == 'airplane' ? Offset(-width * 2, -20) : const Offset(0, -40),
        child: art);
  }

  Widget _button(String name, String label, double width, VoidCallback? onTap,
      {double phase = 0, double lift = 3, double sway = .012}) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: enabled ? label : '$label, turned off by a parent',
      child: Tooltip(
        excludeFromSemantics: true,
        message: enabled ? label : 'Games are turned off by a parent.',
        child: SizedBox(
          width: width,
          height: width + 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('home-$name'),
              onTap: withButtonSound(onTap),
              onTapDown:
                  enabled ? (_) => setState(() => _pressed = name) : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = null) : null,
              onTapCancel:
                  enabled ? () => setState(() => _pressed = null) : null,
              borderRadius: BorderRadius.circular(24),
              splashColor: Colors.white.withValues(alpha: .35),
              child: Stack(alignment: Alignment.center, children: [
                AnimatedScale(
                    scale: _pressed == name ? .94 : 1,
                    duration: Duration(milliseconds: _reducedMotion ? 0 : 120),
                    child: _art(name, width,
                        phase: phase, lift: lift, sway: sway)),
                if (!enabled)
                  const CircleAvatar(
                      backgroundColor: Color(0xEE30214F),
                      foregroundColor: Colors.white,
                      child: Icon(Icons.lock_rounded)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final width = box.maxWidth;
        // Keep the illustrated route readable on short phones; the Home scroll
        // view provides access to the footer instead of squeezing the buttons.
        final height = math.max(width * 1.50 + 80, widget.minHeight);
        Rect stop(double x, double y, double scale) =>
            Rect.fromLTWH(width * x, y, width * scale, width * scale + 12);
        final lessons = stop(0, height * .18, .52);
        final games = stop(.54, lessons.top + width * .24, .39);
        final progress = stop(.675, games.bottom + 6, .32);
        final parents = stop(.705, height - width * .29 - 20, .29);
        Widget destination(Rect rect, String name, String label,
                VoidCallback? action, double phase,
                {double lift = 3, double sway = .012}) =>
            Positioned.fromRect(
                rect: rect,
                child: _button(name, label, rect.width, action,
                    phase: phase, lift: lift, sway: sway));
        return SizedBox(
          height: height,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
                child: ExcludeSemantics(
                    child: IgnorePointer(
                        child: RepaintBoundary(
                            child: CustomPaint(
                                key: const ValueKey('home-sky-path'),
                                painter: _HomeSkyPathPainter(stops: [
                                  lessons,
                                  games,
                                  progress,
                                  parents
                                ])))))),
            Positioned(
                top: 0,
                left: width * .025,
                width: width * .95,
                height: width * .27,
                child: Center(
                    child: _art('logo', width * .95, lift: 2, sway: .004))),
            Positioned(
                top: width * .20,
                left: width * .44,
                width: width * .56,
                height: width * .56 * .9,
                child: Center(
                    child: _art('airplane', width * .56, lift: 5, sway: .014))),
            destination(lessons, 'lessons', 'Lessons', widget.onLessons, .6),
            destination(games, 'games', 'Game Zone', widget.onGames, 2.7),
            destination(
                progress, 'progress', 'Progress', widget.onProgress, 4.8),
            destination(parents, 'parents', 'Parents', widget.onParents, 1.8,
                lift: 1.5, sway: .006),
            if (widget.entrance != null)
              Positioned.fill(
                  child: IgnorePointer(
                      child: ExcludeSemantics(
                child: AnimatedBuilder(
                    animation: widget.entrance!,
                    builder: (_, child) {
                      final t = widget.entrance!.value;
                      final glow = t > .60 && t < .82
                          ? math.sin((t - .60) / .22 * math.pi)
                          : 0.0;
                      return Opacity(opacity: glow, child: child);
                    },
                    child: Stack(children: [
                      for (final rect in [lessons, games, progress, parents])
                        Positioned(
                            left: rect.left + rect.width * .65,
                            top: rect.top - 8,
                            child: const Icon(Icons.auto_awesome_rounded,
                                color: Color(0xFFFFE586), size: 28)),
                    ])),
              ))),
          ]),
        );
      });
}

/// A lightweight, decorative cloud road linking the four live destinations.
class _HomeSkyPathPainter extends CustomPainter {
  const _HomeSkyPathPainter({required this.stops});
  final List<Rect> stops;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final anchors = [
      for (final rect in stops)
        Offset(rect.center.dx, rect.bottom - width * .035),
    ];
    final road = Path()..moveTo(anchors.first.dx, anchors.first.dy);
    for (var i = 1; i < anchors.length; i++) {
      final from = anchors[i - 1];
      final to = anchors[i];
      final bend = i == 1 ? -width * .15 : width * .15;
      road.cubicTo(from.dx + bend, from.dy + width * .16, to.dx - bend,
          to.dy - width * .14, to.dx, to.dy);
    }
    final bounds = road.getBounds().inflate(width * .08);
    Paint ribbon(double strokeWidth, Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..color = color;
    canvas.save();
    canvas.translate(0, width * .018);
    canvas.drawPath(road, ribbon(width * .095, const Color(0xFFBC91E6)));
    canvas.restore();
    canvas.drawPath(road, ribbon(width * .105, const Color(0xFFDC962C)));
    canvas.drawPath(road, ribbon(width * .095, const Color(0xFFFFDA77)));
    canvas.drawPath(
        road,
        ribbon(width * .07, Colors.white)
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFEEF9), Color(0xFFCDBDFF), Color(0xFFEDCEFF)],
          ).createShader(bounds));
    // Crosswise pastel stepping stones follow the curve rather than a grid.
    for (final metric in road.computeMetrics()) {
      for (var distance = width * .065;
          distance < metric.length;
          distance += width * .038) {
        final tangent = metric.getTangentForOffset(distance)!;
        final normal =
            Offset(-tangent.vector.dy, tangent.vector.dx) * width * .029;
        canvas.drawLine(tangent.position - normal, tangent.position + normal,
            ribbon(width * .011, const Color(0xCCFFFFFF)));
      }
    }
    for (var i = 0; i < anchors.length; i++) {
      _cloud(
          canvas, anchors[i] + Offset(0, width * .025), stops[i].width * .34);
      if (i < anchors.length - 1) {
        final from = anchors[i];
        final to = anchors[i + 1];
        _starPost(
            canvas,
            Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 - width * .065),
            width);
      }
    }
    _starPost(
        canvas, Offset(width * .12, stops.first.top - width * .02), width);
    _starPost(
        canvas, Offset(width * .46, stops.first.bottom - width * .12), width);
  }

  void _cloud(Canvas canvas, Offset center, double radius) {
    final cloud = Path();
    for (final oval in [
      Rect.fromCenter(center: center, width: radius * 2, height: radius * .70),
      Rect.fromCircle(
          center: center + Offset(-radius * .63, -radius * .12),
          radius: radius * .42),
      Rect.fromCircle(
          center: center + Offset(-radius * .13, -radius * .36),
          radius: radius * .51),
      Rect.fromCircle(
          center: center + Offset(radius * .4, -radius * .15),
          radius: radius * .38),
      Rect.fromCircle(
          center: center + Offset(radius * .76, 0), radius: radius * .28),
    ]) {
      cloud.addOval(oval);
    }
    canvas.drawPath(
        cloud,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF3F9FF), Color(0xFFB8D5FA)])
              .createShader(cloud.getBounds()));
  }

  void _starPost(Canvas canvas, Offset center, double width) {
    canvas.drawLine(
        center + Offset(0, width * .02),
        center + Offset(0, width * .12),
        Paint()
          ..strokeWidth = width * .018
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFDEA044));
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = width * (i.isEven ? .049 : .026);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawShadow(star, const Color(0xFFBD7829), 3, false);
    canvas.drawPath(
        star,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * .012
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFEFAB20));
    canvas.drawPath(
        star,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF9B2),
                Color(0xFFFFE348),
                Color(0xFFFFBD30)
              ]).createShader(star.getBounds()));
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(-width * .013, -width * .014),
            width: width * .015,
            height: width * .009),
        Paint()..color = const Color(0xAAFFFFFF));
  }

  @override
  bool shouldRepaint(_HomeSkyPathPainter oldDelegate) =>
      !listEquals(stops, oldDelegate.stops);
}
