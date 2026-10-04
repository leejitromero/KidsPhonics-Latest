import 'dart:async';
import 'package:flutter/material.dart';

const skyFrames = [
  'assets/images/screen_frames/background/bg-1.png',
  'assets/images/screen_frames/background/bg-2.png',
  'assets/images/screen_frames/background/bg-3.png',
  'assets/images/screen_frames/background/bg-4.png',
  'assets/images/screen_frames/background/bg-5.png',
];
const homeFrames = [
  'assets/images/screen_frames/home/main-1.png',
  'assets/images/screen_frames/home/main-2.png',
  'assets/images/screen_frames/home/main-3.png',
];
const lessonFrames = [
  'assets/images/screen_frames/lessons/b1.png',
  'assets/images/screen_frames/lessons/b2.png',
  'assets/images/screen_frames/lessons/b3.png',
  'assets/images/screen_frames/lessons/b4.png',
  'assets/images/screen_frames/lessons/b5.png',
];
const gameFrames = [
  'assets/images/screen_frames/games/g1.png',
  'assets/images/screen_frames/games/g2.png',
  'assets/images/screen_frames/games/g3.png',
  'assets/images/screen_frames/games/g4.png',
];
const parentsFrames = [
  'assets/images/screen_frames/parents/f1.png',
  'assets/images/screen_frames/parents/f2.png',
  'assets/images/screen_frames/parents/f3.png',
  'assets/images/screen_frames/parents/f4.png',
  'assets/images/screen_frames/parents/f5.png',
];

// A gentler pace for the main menu's three-frame illustration.
const homeFrameDuration = Duration(milliseconds: 450);

/// Preloaded, local frames. Only this artwork repaints when the frame changes.
/// Motion pauses off-route, in the background, and with reduced motion enabled.
class AnimatedScreenArt extends StatefulWidget {
  const AnimatedScreenArt(
      {super.key,
      required this.frames,
      this.fit = BoxFit.cover,
      this.alignment = Alignment.center,
      this.blend = false,
      this.frameDuration = const Duration(milliseconds: 180)});
  final List<String> frames;
  final BoxFit fit;
  final Alignment alignment;
  final bool blend;
  final Duration frameDuration;

  @override
  State<AnimatedScreenArt> createState() => _AnimatedScreenArtState();
}

class _AnimatedScreenArtState extends State<AnimatedScreenArt>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock = AnimationController(vsync: this);
  bool _ready = false;
  bool _foreground = true;
  bool _motionAllowed = false;
  int? _decodeWidth;
  int _request = 0;

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
    _motionAllowed = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    final width = (MediaQuery.sizeOf(context).width *
            MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 941);
    if (_decodeWidth != width) {
      _decodeWidth = width;
      _ready = false;
      final request = ++_request;
      unawaited(_preload(request));
    }
    _syncMotion();
  }

  Future<void> _preload(int request) async {
    await Future.wait(widget.frames.map((asset) => precacheImage(
        ResizeImage(AssetImage(asset), width: _decodeWidth), context)));
    if (!mounted || request != _request) return;
    _ready = true;
    _syncMotion();
  }

  void _syncMotion() {
    if (_ready && _motionAllowed && _foreground && widget.frames.length > 1) {
      if (!_clock.isAnimating) {
        _clock.repeat(
            period: widget.frameDuration * ((widget.frames.length - 1) * 2));
      }
    } else {
      _clock.stop();
      if (!_motionAllowed) _clock.value = 0;
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
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.frames.isEmpty) return const SizedBox.shrink();
    final images = [
      for (final asset in widget.frames)
        Image.asset(asset,
            fit: widget.fit,
            alignment: widget.alignment,
            cacheWidth: _decodeWidth,
            excludeFromSemantics: true,
            gaplessPlayback: true)
    ];
    return IgnorePointer(
        child: ExcludeSemantics(
            child: RepaintBoundary(
      child: AnimatedBuilder(
          animation: _clock,
          builder: (_, __) {
            final length = widget.frames.length;
            final count = length > 1 ? (length - 1) * 2 : 1;
            final position = _clock.value * count;
            final step = position.floor().clamp(0, count - 1);
            int index(int slot) => slot < length ? slot : count - slot;
            final current = index(step);
            final next = index((step + 1) % count);
            final fraction = widget.blend ? position - step : 0.0;
            return Stack(fit: StackFit.expand, children: [
              for (var i = 0; i < length; i++)
                Opacity(opacity: i == current ? 1 : 0, child: images[i]),
              if (widget.blend && next != current)
                Opacity(opacity: fraction, child: images[next]),
            ]);
          }),
    )));
  }
}
