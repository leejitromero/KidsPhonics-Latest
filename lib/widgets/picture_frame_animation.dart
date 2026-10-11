import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Rebuilds only when the discrete frame changes, with bounded decoding.
class PictureFrameAnimation extends StatefulWidget {
  const PictureFrameAnimation(
      {super.key,
      required this.frames,
      required this.duration,
      required this.cacheWidth});
  final List<String> frames;
  final Duration duration;
  final int cacheWidth;
  @override
  State<PictureFrameAnimation> createState() => _PictureFrameAnimationState();
}

class _PictureFrameAnimationState extends State<PictureFrameAnimation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _clock =
      AnimationController(vsync: this, duration: widget.duration)
        ..addListener(_updateFrame);
  final _frame = ValueNotifier<int>(0);
  bool _foreground = true, _motion = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _updateFrame() {
    if (widget.frames.isEmpty) return;
    final next = (_clock.value * widget.frames.length)
        .floor()
        .clamp(0, widget.frames.length - 1);
    if (next != _frame.value) _frame.value = next;
  }

  void _sync() {
    if (_foreground && _motion && widget.frames.length > 1) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      if (!_motion) _frame.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    _sync();
  }

  @override
  void didUpdateWidget(PictureFrameAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.frames, widget.frames)) {
      _clock.value = 0;
      _frame.value = 0;
    }
    _clock.duration = widget.duration;
    _sync();
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
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = [
      for (final asset in widget.frames)
        Image.asset(asset,
            fit: BoxFit.contain,
            cacheWidth: widget.cacheWidth,
            gaplessPlayback: true,
            excludeFromSemantics: true)
    ];
    return RepaintBoundary(
        child: ValueListenableBuilder<int>(
            valueListenable: _frame,
            builder: (_, frame, __) => Stack(fit: StackFit.expand, children: [
                  for (var i = 0; i < images.length; i++)
                    Opacity(opacity: i == frame ? 1 : 0, child: images[i])
                ])));
  }
}
