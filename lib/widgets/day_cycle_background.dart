import 'dart:async';
import 'package:flutter/material.dart';
import '../data/updated_scene.dart';

/// Stationary morning, sunset and night artwork with a short crossfade.
class DayCycleBackground extends StatefulWidget {
  const DayCycleBackground({
    super.key,
    required this.category,
    this.child,
    this.foregroundClipper,
    this.fit,
  });
  final String category;
  final BoxFit? fit;
  // A shared clock keeps the artwork in front of characters in sync with the
  // room behind them, including during a morning/sunset/night crossfade.
  final Widget? child;
  final CustomClipper<Path>? foregroundClipper;
  static const sceneDuration = Duration(milliseconds: 3500);
  static const homeSceneDuration = Duration(seconds: 5);
  static const fadeDuration = Duration(milliseconds: 650);
  static List<String> framesFor(String category) => category == 'home'
      ? const [
          'assets/images/home_classroom/new_bgmornig.png',
          'assets/images/home_classroom/new_bg_sunset.png',
          'assets/images/home_classroom/new_bg_night.png',
        ]
      : [
          for (var i = 1; i <= 3; i++)
            '$sceneAssets/${category}_new_bg${category == 'games' && i == 1 ? '' : '_'}$i.png',
        ];
  @override
  State<DayCycleBackground> createState() => _DayCycleBackgroundState();
}

class _DayCycleBackgroundState extends State<DayCycleBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Duration get _sceneDuration => widget.category == 'home'
      ? DayCycleBackground.homeSceneDuration
      : DayCycleBackground.sceneDuration;
  late final _clock =
      AnimationController(vsync: this, duration: _sceneDuration * 3);
  bool _foreground = true, _motion = true, _ready = false;
  int _generation = 0;
  int? _width;
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
    _motion = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    final width = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 942);
    if (_width != width) {
      _width = width;
      _prepare();
    }
    _sync();
  }

  @override
  void didUpdateWidget(DayCycleBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _clock.stop();
      _clock.duration = _sceneDuration * 3;
      _clock.value = 0;
      _prepare();
    }
  }

  void _prepare() {
    _ready = false;
    final generation = ++_generation;
    unawaited(Future.wait(DayCycleBackground.framesFor(widget.category).map(
        (asset) => precacheImage(
            ResizeImage(AssetImage(asset), width: _width), context))).then((_) {
      if (!mounted || generation != _generation) return;
      _ready = true;
      _sync();
    }));
  }

  void _sync() {
    if (_ready && _foreground && _motion) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      if (mounted && MediaQuery.disableAnimationsOf(context)) _clock.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: AnimatedBuilder(
          animation: _clock,
          child: widget.child,
          builder: (_, child) {
            final position = _clock.value * 3;
            final frame = position.floor().clamp(0, 2);
            final fadeFraction =
                DayCycleBackground.fadeDuration.inMilliseconds /
                    _sceneDuration.inMilliseconds;
            final opacity =
                ((position - frame - (1 - fadeFraction)) / fadeFraction)
                    .clamp(0.0, 1.0);
            final frames = DayCycleBackground.framesFor(widget.category);
            Widget art(int index) => Image.asset(frames[index],
                fit: widget.fit ??
                    (widget.category == 'home' ? BoxFit.cover : BoxFit.fill),
                alignment: Alignment.center,
                cacheWidth: _width,
                gaplessPlayback: true,
                excludeFromSemantics: true);
            Widget room() => IgnorePointer(
                    child: Stack(fit: StackFit.expand, children: [
                  art(frame),
                  if (opacity > 0)
                    Opacity(opacity: opacity, child: art((frame + 1) % 3)),
                ]));
            return Stack(fit: StackFit.expand, children: [
              room(),
              if (child != null) child,
              if (widget.foregroundClipper != null)
                ClipPath(clipper: widget.foregroundClipper, child: room()),
            ]);
          }));
}
