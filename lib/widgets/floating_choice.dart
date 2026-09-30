import 'dart:math' as math;
import 'package:flutter/material.dart';

const choiceBlue = Color(0xFF247BA5);

/// Gentle motion with a stationary tap target and reduced-motion support.
class FloatingChoice extends StatefulWidget {
  const FloatingChoice(
      {super.key, required this.child, this.enabled = true, this.seed = 0});
  final Widget child;
  final bool enabled;
  final int seed;
  @override
  State<FloatingChoice> createState() => _FloatingChoiceState();
}

class _FloatingChoiceState extends State<FloatingChoice>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000 + widget.seed.abs() % 7 * 130));
  void _sync() {
    final enabled = widget.enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(FloatingChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _motion,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0,
              -2.0 * math.pow(math.sin(_motion.value * math.pi), 2).toDouble()),
          transformHitTests: false,
          child: child,
        ),
      );
}
