import 'package:flutter/material.dart';

/// Plays the five supplied poses directly from the original transparent atlas.
/// Registered frame edges avoid showing hair or hands from the adjacent pose.
/// The original 2172 x 724 source sheets stay unchanged.
class StudentWave extends StatefulWidget {
  const StudentWave({super.key, required this.character, this.animate = true});
  final String character;
  final bool animate;
  static String assetFor(String character) =>
      'assets/images/school_home/${character}_wave.png';

  @override
  State<StudentWave> createState() => _StudentWaveState();
}

class _StudentWaveState extends State<StudentWave>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _poses = [0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0, 0];
  late final _clock = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..addListener(_tick);
  final _frame = ValueNotifier(0);
  bool _foreground = true;
  bool _motion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _tick() {
    final index =
        (_clock.value * _poses.length).floor().clamp(0, _poses.length - 1);
    _frame.value = _poses[index];
  }

  void _sync() {
    if (_foreground && _motion && widget.animate) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      if (!_motion || !widget.animate) _frame.value = 0;
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
  void didUpdateWidget(StudentWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      _clock.value = 0;
      _frame.value = 0;
    }
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
    final edges = widget.character == 'girl'
        ? const [0.0, 404.0, 866.0, 1306.0, 1758.0, 2172.0]
        : const [0.0, 414.0, 850.0, 1294.0, 1764.0, 2172.0];
    const canvasWidth = 470.0;
    return RepaintBoundary(
        child: Center(
            child: AspectRatio(
                aspectRatio: canvasWidth / 724,
                child: LayoutBuilder(builder: (context, box) {
                  final scale = box.maxWidth / canvasWidth;
                  final image = Image.asset(
                      StudentWave.assetFor(widget.character),
                      fit: BoxFit.fill,
                      cacheWidth: (2172 *
                              scale *
                              MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(1086, 2172),
                      gaplessPlayback: true,
                      excludeFromSemantics: true);
                  return ValueListenableBuilder<int>(
                      valueListenable: _frame,
                      child: image,
                      builder: (_, frame, child) => Center(
                          child: SizedBox(
                              width: (edges[frame + 1] - edges[frame]) * scale,
                              height: box.maxHeight,
                              child: ClipRect(
                                  child: OverflowBox(
                                      alignment: Alignment.topLeft,
                                      minWidth: 2172 * scale,
                                      maxWidth: 2172 * scale,
                                      minHeight: box.maxHeight,
                                      maxHeight: box.maxHeight,
                                      child: Transform.translate(
                                          key: ValueKey(
                                              'student-wave-frame-$frame'),
                                          offset:
                                              Offset(-edges[frame] * scale, 0),
                                          child: child))))));
                }))));
  }
}
