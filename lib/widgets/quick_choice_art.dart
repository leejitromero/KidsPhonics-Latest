import 'package:flutter/material.dart';

// Blue, orange, green, violet and pink from the approved speaker concept.
const quickChoiceColors = [
  Color(0xFF087BDC),
  Color(0xFFE85C08),
  Color(0xFF008B54),
  Color(0xFF8321DA),
  Color(0xFFD90870),
];
const _quickChoiceHighlights = [
  Color(0xFF35CAFF),
  Color(0xFFFFAF19),
  Color(0xFF23DEA0),
  Color(0xFFB757FF),
  Color(0xFFFF4EAC),
];

/// Paints one complete button surface. Live content never needs to cover a
/// preprinted sample letter or sit inside a second illustrated frame.
class QuickChoiceArt extends StatelessWidget {
  const QuickChoiceArt({
    super.key,
    required this.index,
    required this.child,
    this.selected = false,
    this.pressed = false,
    this.focused = false,
    this.muted = false,
    this.radius = 24,
  });
  final int index;
  final Widget child;
  final bool selected, pressed, focused, muted;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _QuickButtonPainter(
          color: quickChoiceColors[index % quickChoiceColors.length],
          highlight: _quickChoiceHighlights[index % quickChoiceColors.length],
          radius: radius,
          selected: selected,
          pressed: pressed,
          focused: focused,
          muted: muted),
      child: child);
}

ButtonStyle quickColorButtonStyle({
  int index = 0,
  double radius = 24,
  bool selected = false,
  Size minimumSize = const Size(48, 58),
  EdgeInsetsGeometry padding =
      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
}) =>
    FilledButton.styleFrom(
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: Colors.transparent,
      foregroundColor: const Color(0xFFFFF9E9),
      disabledForegroundColor: const Color(0xFFFFF9E9),
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      minimumSize: minimumSize,
      padding: padding,
      side: BorderSide.none,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      textStyle: const TextStyle(
          fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900),
    ).copyWith(
      backgroundBuilder: (context, states, child) => QuickChoiceArt(
          index: index,
          radius: radius,
          selected: selected,
          pressed: states.contains(WidgetState.pressed),
          focused: states.contains(WidgetState.focused),
          muted: states.contains(WidgetState.disabled) && !selected,
          child: child ?? const SizedBox.shrink()),
    );

class QuickAudioButton extends StatelessWidget {
  const QuickAudioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.index = 0,
    this.playing = false,
    this.compact = false,
    this.embedded = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final int index;
  final bool playing, compact, embedded;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
        playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
        size: compact ? 28 : 30);
    final style = embedded
        ? FilledButton.styleFrom(
                foregroundColor: const Color(0xFFFFF9E9),
                disabledForegroundColor: const Color(0xFFEEE5DC),
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                shape: const CircleBorder())
            .copyWith(
                backgroundBuilder: (_, __, child) =>
                    child ?? const SizedBox.shrink())
        : quickColorButtonStyle(
            index: index,
            radius: 100,
            minimumSize: Size(48, compact ? 52 : 60),
            padding: compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 22, vertical: 14));
    final button = compact
        ? SizedBox(
            width: embedded ? 48 : 52,
            height: embedded ? 48 : 52,
            child:
                FilledButton(onPressed: onPressed, style: style, child: icon))
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon,
            label: Text(label, textAlign: TextAlign.center));
    return Tooltip(
        message: label,
        child: Semantics(
            label: compact ? label : null,
            value: playing ? 'Playing' : null,
            child: button));
  }
}

class _QuickButtonPainter extends CustomPainter {
  const _QuickButtonPainter({
    required this.color,
    required this.highlight,
    required this.radius,
    required this.selected,
    required this.pressed,
    required this.focused,
    required this.muted,
  });
  final Color color, highlight;
  final double radius;
  final bool selected, pressed, focused, muted;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final hue =
        muted ? Color.lerp(color, const Color(0xFF81899A), .24)! : color;
    final depth = pressed ? 2.0 : 5.0;
    final faceRect = Rect.fromLTRB(
        1, pressed ? 3 : 1, size.width - 1, size.height - depth - 1);
    final face = RRect.fromRectAndRadius(faceRect, Radius.circular(radius));
    final base = RRect.fromRectAndRadius(
        Rect.fromLTRB(1, 5, size.width - 1, size.height - 1),
        Radius.circular(radius));
    canvas.drawRRect(
        base, Paint()..color = Color.lerp(hue, const Color(0xFF10243E), .35)!);
    canvas.drawRRect(
        face,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(hue, Colors.white, .76)!,
              Color.lerp(hue, Colors.white, .46)!,
            ],
          ).createShader(faceRect));
    final inset = size.shortestSide < 70 ? 3.5 : 4.5;
    final inner = face.deflate(inset);
    canvas.drawRRect(
        inner,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              muted
                  ? Color.lerp(highlight, const Color(0xFF81899A), .24)!
                  : highlight,
              hue,
              Color.lerp(hue, Colors.black, .16)!,
            ],
            stops: const [0, .45, 1],
          ).createShader(inner.outerRect));
    canvas.drawRRect(
        inner,
        Paint()
          ..color = Color.lerp(hue, Colors.black, .18)!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    canvas.save();
    canvas.clipRRect(inner);
    final gloss = Rect.fromLTRB(
        inner.left, inner.top, inner.right, inner.top + inner.height * .42);
    canvas.drawRect(
        gloss,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)])
              .createShader(gloss));
    canvas.drawOval(
        Rect.fromLTWH(inner.left + 12, inner.top + 5,
            (inner.width * .13).clamp(7.0, 25.0), 4),
        Paint()..color = const Color(0x66FFFFFF));
    canvas.restore();
    if (selected || focused) {
      canvas.drawRRect(
          face.deflate(1.5),
          Paint()
            ..color = const Color(0xFFFFF9E9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(_QuickButtonPainter oldDelegate) =>
      color != oldDelegate.color ||
      highlight != oldDelegate.highlight ||
      radius != oldDelegate.radius ||
      selected != oldDelegate.selected ||
      pressed != oldDelegate.pressed ||
      focused != oldDelegate.focused ||
      muted != oldDelegate.muted;
}
