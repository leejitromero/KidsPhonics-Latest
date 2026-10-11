import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_design.dart';
import 'learner_widgets.dart';
import 'quick_choice_art.dart';

const magicalSoundOrbAsset = 'assets/images/new_ui/magical_sound_orb.png';

/// Keeps controls at readable sizes; short screens can scroll instead of
/// shrinking the entire game and its touch targets.
class SoundMatchLayout extends StatelessWidget {
  const SoundMatchLayout({
    super.key,
    required this.phrase,
    required this.enabled,
    required this.choices,
    this.result,
  });
  final String phrase;
  final bool enabled;
  final bool? result;
  final List<Widget> choices;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final scroll = box.maxHeight < 410 * scale || scale > 1.4;
        final orbSize = scroll
            ? math.min(200.0, box.maxWidth * .65)
            : (box.maxHeight - 290 * scale).clamp(120.0, 280.0);
        final content = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AudioButton(
                  phrase: phrase,
                  label: 'Hear Sound',
                  semanticLabel: 'Hear the mystery sound',
                  enabled: enabled,
                  controlBuilder: (context, play, playing, _) =>
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            width: orbSize,
                            height: orbSize,
                            child: MagicalSoundOrb(
                                playing: playing,
                                correct: result == true,
                                onPressed: play)),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: QuickAudioButton(
                                key: const ValueKey('sound-match-hear'),
                                label: 'Hear Sound',
                                playing: playing,
                                index: 3,
                                onPressed: play)),
                      ])),
              const SizedBox(height: 16),
              const Text('Which letter makes this sound?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: GameDesign.ink,
                      shadows: [Shadow(color: Colors.white, blurRadius: 6)])),
              const SizedBox(height: 12),
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Row(
                      key: const ValueKey('sound-match-choices'),
                      children: [
                        for (var index = 0;
                            index < choices.length;
                            index++) ...[
                          if (index > 0) const SizedBox(width: 10),
                          Expanded(
                              child: SizedBox(
                                  height: 90 * scale.clamp(1, 1.5),
                                  child: choices[index])),
                        ]
                      ])),
              const SizedBox(height: 12),
              Semantics(
                  liveRegion: true,
                  child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      child: Container(
                          key: ValueKey(result),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: result == true
                                  ? const Color(0xF0E8FFE8)
                                  : const Color(0xF0FFF9E9),
                              borderRadius: BorderRadius.circular(22),
                              border:
                                  Border.all(color: Colors.white, width: 2)),
                          child: Text(
                              result == null
                                  ? 'Tap the orb and listen!'
                                  : result!
                                      ? 'Wonderful! You found the sound!'
                                      : 'Try Again!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: result == true
                                      ? const Color(0xFF007A49)
                                      : GameDesign.ink))))),
            ]);
        return SingleChildScrollView(
            child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: content))));
      });
}

/// Artwork stays cached while the local glow and sound waves repaint.
class MagicalSoundOrb extends StatefulWidget {
  const MagicalSoundOrb({
    super.key,
    required this.onPressed,
    this.playing = false,
    this.correct = false,
  });
  final VoidCallback? onPressed;
  final bool playing, correct;
  @override
  State<MagicalSoundOrb> createState() => _MagicalSoundOrbState();
}

class _MagicalSoundOrbState extends State<MagicalSoundOrb>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _sync() {
    final motion = _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (motion) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
      child: Semantics(
          button: true,
          enabled: widget.onPressed != null,
          label: widget.playing
              ? 'Magical sound orb, playing sound'
              : 'Magical sound orb. Hear Sound',
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  key: const ValueKey('magical-sound-orb'),
                  onTap: widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: AnimatedBuilder(
                      animation: _pulse,
                      child: Image.asset(magicalSoundOrbAsset,
                          fit: BoxFit.contain,
                          cacheWidth: 768,
                          excludeFromSemantics: true),
                      builder: (context, art) {
                        final reduced = MediaQuery.disableAnimationsOf(context);
                        final pulse = reduced
                            ? .5
                            : (math.sin(_pulse.value * math.pi * 2) + 1) / 2;
                        return CustomPaint(
                            painter: _OrbAuraPainter(
                                phase: reduced ? .25 : _pulse.value,
                                pulse: pulse,
                                playing: widget.playing,
                                correct: widget.correct),
                            foregroundPainter: _OrbAuraPainter(
                                phase: reduced ? .25 : _pulse.value,
                                pulse: pulse,
                                playing: widget.playing,
                                correct: widget.correct,
                                foreground: true),
                            child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Transform.scale(
                                    scale: reduced ? 1 : 1 + .035 * pulse,
                                    transformHitTests: false,
                                    child: art)));
                      })))));
}

class _OrbAuraPainter extends CustomPainter {
  const _OrbAuraPainter({
    required this.phase,
    required this.pulse,
    required this.playing,
    required this.correct,
    this.foreground = false,
  });
  final double phase, pulse;
  final bool playing, correct, foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .47);
    final radius = size.shortestSide * .43;
    if (!foreground) {
      canvas.drawCircle(
          center,
          radius,
          Paint()
            ..shader = RadialGradient(colors: [
              (correct ? const Color(0xFFFFDE54) : const Color(0xFF9D52FF))
                  .withValues(alpha: .3 + pulse * .14),
              const Color(0xFF73EAFF).withValues(alpha: .2),
              Colors.transparent,
            ]).createShader(Rect.fromCircle(center: center, radius: radius)));
      return;
    }
    if (playing) {
      for (var i = 0; i < 3; i++) {
        final progress = (phase * 2 + i / 3) % 1;
        final paint = Paint()
          ..color =
              (i.isEven ? const Color(0xFF14D8FF) : const Color(0xFFFFD652))
                  .withValues(alpha: (1 - progress) * .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final rect = Rect.fromCircle(
            center: center, radius: radius * (.67 + progress * .42));
        canvas.drawArc(rect, -.6, 1.2, false, paint);
        canvas.drawArc(rect, math.pi - .6, 1.2, false, paint);
      }
    }
    if (correct) {
      for (var i = 0; i < 8; i++) {
        final angle = math.pi * 2 * i / 8 + phase * .25;
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final edge = 4 + pulse * 3;
        final star = Path()
          ..moveTo(point.dx, point.dy - edge)
          ..lineTo(point.dx + edge * .35, point.dy - edge * .35)
          ..lineTo(point.dx + edge, point.dy)
          ..lineTo(point.dx + edge * .35, point.dy + edge * .35)
          ..lineTo(point.dx, point.dy + edge)
          ..lineTo(point.dx - edge * .35, point.dy + edge * .35)
          ..lineTo(point.dx - edge, point.dy)
          ..lineTo(point.dx - edge * .35, point.dy - edge * .35)
          ..close();
        canvas.drawPath(star, Paint()..color = const Color(0xFFFFDE54));
      }
    }
  }

  @override
  bool shouldRepaint(_OrbAuraPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      pulse != oldDelegate.pulse ||
      playing != oldDelegate.playing ||
      correct != oldDelegate.correct ||
      foreground != oldDelegate.foreground;
}

/// A short, gentle shake for mistakes and a small bounce for success.
class SoundMatchChoiceMotion extends StatefulWidget {
  const SoundMatchChoiceMotion(
      {super.key, required this.child, required this.result});
  final Widget child;
  final bool? result;
  @override
  State<SoundMatchChoiceMotion> createState() => _SoundMatchChoiceMotionState();
}

class _SoundMatchChoiceMotionState extends State<SoundMatchChoiceMotion>
    with SingleTickerProviderStateMixin {
  late final _feedback = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
  @override
  void didUpdateWidget(SoundMatchChoiceMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != null &&
        widget.result != oldWidget.result &&
        !MediaQuery.disableAnimationsOf(context)) {
      _feedback.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _feedback,
      child: widget.child,
      builder: (_, child) {
        final value =
            MediaQuery.disableAnimationsOf(context) ? 1.0 : _feedback.value;
        return Transform.translate(
            offset: Offset(
                widget.result == false
                    ? math.sin(value * math.pi * 6) * 5 * (1 - value)
                    : 0,
                0),
            transformHitTests: false,
            child: Transform.scale(
                scale: widget.result == true
                    ? 1 + math.sin(value * math.pi) * .06
                    : 1,
                transformHitTests: false,
                child: child));
      });
}
