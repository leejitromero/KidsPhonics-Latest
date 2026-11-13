import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/progress_badge.dart';
import '../providers/app_provider.dart';

/// Above the Navigator, below parental time-limit protection. These visual-only
/// notifications preserve the game's controls, timers and instructional audio.
class BadgeCelebrationHost extends StatefulWidget {
  const BadgeCelebrationHost({super.key, required this.child});
  final Widget child;
  static const duration = Duration(milliseconds: 2800);
  @override
  State<BadgeCelebrationHost> createState() => _BadgeCelebrationHostState();
}

class _BadgeCelebrationHostState extends State<BadgeCelebrationHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  AppProvider? _provider;
  ProgressBadge? _active;
  bool _foreground = true, _scheduled = false, _claiming = false;
  Timer? _gap;
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _clock = AnimationController(
        vsync: this,
        duration: BadgeCelebrationHost.duration,
        animationBehavior: AnimationBehavior.preserve)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _active = null);
        _gap?.cancel();
        _gap = Timer(const Duration(milliseconds: 250), () {
          _gap = null;
          _schedule();
        });
      });
  }

  bool get _allowed =>
      mounted &&
      _foreground &&
      (_provider?.isReady ?? false) &&
      !_provider!.timeLimitReached &&
      TickerMode.valuesOf(context).enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AppProvider>();
    if (_provider != provider) {
      _provider?.removeListener(_schedule);
      _provider = provider;
      provider.addListener(_schedule);
      provider.ready.then((_) {
        if (mounted) _schedule();
      });
    }
    _schedule();
  }

  void _schedule() {
    if (!mounted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_update());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _update() async {
    final provider = _provider!;
    if (_active != null &&
        !provider.progressBadges
            .any((badge) => badge.id == _active!.id && badge.earned)) {
      _clock.reset();
      setState(() => _active = null);
    }
    if (!_allowed) {
      _clock.stop();
      // Rebuild when parental protection covers the app.
      if (_active != null) setState(() {});
      return;
    }
    if (_active != null) {
      if (!_clock.isAnimating) _clock.forward();
      setState(() {});
      return;
    }
    if (_claiming ||
        _gap != null ||
        provider.hasUnsavedChanges ||
        provider.pendingBadgeUnlocks.isEmpty) {
      return;
    }
    _claiming = true;
    final badge =
        await provider.claimBadgeUnlock(provider.pendingBadgeUnlocks.first);
    _claiming = false;
    if (!mounted || badge == null) return;
    setState(() => _active = badge);
    _clock.value = 0;
    if (_allowed) _clock.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _clock.stop();
    setState(() {});
    _schedule();
  }

  @override
  void dispose() {
    _provider?.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    _gap?.cancel();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = _active;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Stack(fit: StackFit.expand, children: [
      widget.child,
      if (badge != null && _allowed)
        Positioned.fill(
            child: IgnorePointer(
                child: SafeArea(
          bottom: false,
          minimum: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
                child: reduced
                    ? BadgeUnlockCelebration(
                        badge: badge, progress: .5, reducedMotion: true)
                    : AnimatedBuilder(
                        animation: _clock,
                        builder: (_, __) => BadgeUnlockCelebration(
                            badge: badge, progress: _clock.value))),
          ),
        ))),
    ]);
  }
}

/// Beveled medal, perspective entrance, moving glint and deterministic confetti.
/// No new bitmap frames, plugins or audio files are required.
class BadgeUnlockCelebration extends StatelessWidget {
  const BadgeUnlockCelebration(
      {super.key,
      required this.badge,
      required this.progress,
      this.reducedMotion = false});
  final ProgressBadge badge;
  final double progress;
  final bool reducedMotion;
  static const ink = Color(0xFF32155A);
  static const gold = Color(0xFFFFDF79);

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final enter = reducedMotion
        ? 1.0
        : Curves.easeOutBack.transform((t / .2).clamp(0.0, 1.0));
    final fadeIn = reducedMotion ? 1.0 : (t / .10).clamp(0.0, 1.0);
    final fadeOut = reducedMotion ? 1.0 : ((1 - t) / .14).clamp(0.0, 1.0);
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 25;
    final medal = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, .0015)
        ..rotateY(reducedMotion ? 0 : -.65 * (1 - enter))
        ..rotateZ(reducedMotion ? 0 : math.sin(t * math.pi * 2) * .035),
      child: SizedBox(
        width: largeText ? 76 : 104,
        height: largeText ? 82 : 116,
        child: CustomPaint(
            painter: _MedalPainter(t, reducedMotion),
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: _BadgeSymbol(badge: badge))),
      ),
    );
    final details = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            largeText ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(badge.milestone ? 'ACHIEVEMENT UNLOCKED!' : 'BADGE UNLOCKED!',
              textAlign: largeText ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: gold)),
          const SizedBox(height: 6),
          Text(badge.title,
              key: const ValueKey('badge-unlock-title'),
              textAlign: largeText ? TextAlign.center : TextAlign.left,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 21,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        color: Color(0x66000000),
                        offset: Offset(0, 2),
                        blurRadius: 2)
                  ])),
          if (!largeText) ...[
            const SizedBox(height: 5),
            Text('Well done! Keep shining.',
                textAlign: largeText ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE9DEFF))),
          ],
        ]);
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${badge.milestone ? 'Achievement' : 'Badge'} unlocked. ${badge.title}. Well done!',
      child: ExcludeSemantics(
          child: ConstrainedBox(
        key: const ValueKey('badge-unlock-celebration'),
        constraints: const BoxConstraints(maxWidth: 460),
        child: Opacity(
          opacity: fadeIn * fadeOut,
          child: Transform.translate(
            offset: Offset(0, -24 * (1 - enter)),
            child: Transform.scale(
              scale: .9 + enter * .1,
              child: CustomPaint(
                foregroundPainter:
                    reducedMotion ? null : _CelebrationConfetti(t),
                child: Container(
                  decoration: BoxDecoration(
                      color: const Color(0xFF201033),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x660F0731),
                            blurRadius: 20,
                            offset: Offset(0, 10))
                      ]),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: gold, width: 2),
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF7850C8),
                              Color(0xFF472079),
                              Color(0xFF271144)
                            ])),
                    child: largeText
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            medal,
                            const SizedBox(height: 6),
                            details
                          ])
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            medal,
                            const SizedBox(width: 10),
                            Expanded(child: details)
                          ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

class _BadgeSymbol extends StatelessWidget {
  const _BadgeSymbol({required this.badge});
  final ProgressBadge badge;
  @override
  Widget build(BuildContext context) {
    final asset = switch (badge.id) {
      'First Mastery' => 'assets/images/lesson_logos/letter_recognition.webp',
      'CVC Explorer' => 'assets/images/lessons_menu/cvc_words.webp',
      'Blending Champion' => 'assets/images/lessons_menu/blending_sounds.webp',
      '3-Day Streak' => 'assets/images/home_banner/fire.webp',
      _ => null,
    };
    if (asset != null) {
      return Image.asset(asset,
          fit: BoxFit.contain, cacheWidth: 192, excludeFromSemantics: true);
    }
    if (badge.id == 'Vowel Star') {
      return const FittedBox(
          child: Text('A E I\nO U',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1)));
    }
    return const FittedBox(
        child: Icon(Icons.emoji_events_rounded,
            color: BadgeUnlockCelebration.gold,
            size: 56,
            shadows: [
          Shadow(color: Color(0x99000000), offset: Offset(0, 3), blurRadius: 4)
        ]));
  }
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter(this.progress, this.reduced);
  final double progress;
  final bool reduced;
  Path _hex(Size size) => Path()
    ..moveTo(size.width * .5, 2)
    ..lineTo(size.width * .94, size.height * .23)
    ..lineTo(size.width * .94, size.height * .72)
    ..lineTo(size.width * .5, size.height * .96)
    ..lineTo(size.width * .06, size.height * .72)
    ..lineTo(size.width * .06, size.height * .23)
    ..close();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = _hex(size);
    canvas.drawCircle(
        rect.center,
        size.width * .57,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x88FFD05C), Color(0x00FFD05C)])
              .createShader(rect));
    canvas.drawShadow(path, Colors.black, 8, false);
    canvas.drawPath(path.shift(const Offset(0, 5)),
        Paint()..color = const Color(0xFF9B520F));
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF2AD),
                Color(0xFFFFBF30),
                Color(0xFFFFED83),
                Color(0xFFD58211)
              ],
              stops: [
                0,
                .35,
                .55,
                1
              ]).createShader(rect));
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFF8D1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.save();
    canvas.translate(size.width * .12, size.height * .11);
    canvas.scale(.76, .76);
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFCE8AFF),
                Color(0xFF7944DB),
                Color(0xFF3730A3)
              ]).createShader(rect));
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFCDE7D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.restore();
    if (!reduced) {
      canvas.save();
      canvas.clipPath(path);
      final center =
          ((progress - .22) / .45) * size.width * 2 - size.width * .5;
      final shine = Rect.fromLTWH(
          center - size.width * .25, 0, size.width * .5, size.height);
      canvas.drawRect(
          shine,
          Paint()
            ..shader = const LinearGradient(colors: [
              Color(0x00FFFFFF),
              Color(0x88FFFFFF),
              Color(0x00FFFFFF)
            ]).createShader(shine));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) =>
      progress != old.progress || reduced != old.reduced;
}

class _CelebrationConfetti extends CustomPainter {
  const _CelebrationConfetti(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final time = ((progress - .08) / .65).clamp(0.0, 1.0);
    if (time <= 0 || time >= 1) return;
    const colors = [
      Color(0xFFFFDA58),
      Color(0xFF6BE9FF),
      Color(0xFFFF8AC4),
      Color(0xFFB7FFAA)
    ];
    final fade = math.sin(time * math.pi);
    for (var i = 0; i < 24; i++) {
      final side = i.isEven ? -1 : 1;
      final origin = Offset(side < 0 ? 24 : size.width - 24, size.height * .45);
      final phase = (i ~/ 2) * .51;
      final point = origin +
          Offset(side * (6 + 24 * time * math.cos(phase)),
              -30 * math.sin(time * math.pi) + 30 * time * math.sin(phase));
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(phase + time * 4);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-2, -4, 4, 8), const Radius.circular(1)),
          Paint()..color = colors[i % colors.length].withValues(alpha: fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationConfetti old) => progress != old.progress;
}
