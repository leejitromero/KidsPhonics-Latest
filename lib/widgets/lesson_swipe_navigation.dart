import 'package:flutter/material.dart';

/// One horizontal swipe invokes the same action as a lesson navigation button.
/// Child drags and vertical scrolling retain their own gesture recognizers.
class LessonSwipeNavigation extends StatefulWidget {
  const LessonSwipeNavigation({
    super.key,
    required this.child,
    required this.navigationKey,
    this.onNext,
    this.onPrevious,
    this.enabled = true,
  });

  final Widget child;
  final Object navigationKey;
  final VoidCallback? onNext, onPrevious;
  final bool enabled;

  @override
  State<LessonSwipeNavigation> createState() => _LessonSwipeNavigationState();
}

class _LessonSwipeNavigationState extends State<LessonSwipeNavigation>
    with WidgetsBindingObserver {
  static const _minimumDistance = 56.0;
  double _distance = 0;
  bool _started = false, _allowNext = false, _allowPrevious = false;
  bool _foreground = true;

  bool get _active =>
      _foreground &&
      widget.enabled &&
      TickerMode.valuesOf(context).enabled &&
      (ModalRoute.isCurrentOf(context) ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  void _cancel() {
    _started = _allowNext = _allowPrevious = false;
    _distance = 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_active) _cancel();
  }

  @override
  void didUpdateWidget(LessonSwipeNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled || oldWidget.navigationKey != widget.navigationKey) {
      _cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) _cancel();
  }

  void _start(DragStartDetails _) {
    _cancel();
    _started = _active;
    _allowNext = widget.onNext != null;
    _allowPrevious = widget.onPrevious != null;
  }

  void _update(DragUpdateDetails details) {
    if (_started) _distance += details.primaryDelta ?? 0;
  }

  void _end(DragEndDetails _) {
    final distance = _distance;
    final next =
        _started && _active && _allowNext && distance <= -_minimumDistance;
    final previous =
        _started && _active && _allowPrevious && distance >= _minimumDistance;
    _cancel();
    if (next) {
      widget.onNext?.call();
    } else if (previous) {
      widget.onPrevious?.call();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onHorizontalDragStart: _start,
        onHorizontalDragUpdate: _update,
        onHorizontalDragEnd: _end,
        onHorizontalDragCancel: _cancel,
        child: widget.child,
      );
}
