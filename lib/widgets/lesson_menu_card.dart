import 'package:flutter/material.dart';
import 'button_sound.dart';

/// Shared, keyboard-accessible press feedback for lesson controls.
class LessonMenuPress extends StatefulWidget {
  const LessonMenuPress(
      {super.key, required this.child, required this.onTap, this.radius = 20});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  @override
  State<LessonMenuPress> createState() => _LessonMenuPressState();
}

class _LessonMenuPressState extends State<LessonMenuPress> {
  bool _down = false;
  void _press(bool value) => setState(() => _down = value);
  @override
  Widget build(BuildContext context) => AnimatedScale(
      scale: _down && widget.onTap != null ? .97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.radius),
          child: InkWell(
              borderRadius: BorderRadius.circular(widget.radius),
              onTapDown: widget.onTap == null ? null : (_) => _press(true),
              onTapCancel: () => _press(false),
              onTap: withButtonSound(widget.onTap == null
                  ? null
                  : () {
                      _press(false);
                      widget.onTap!();
                    }),
              child: widget.child)));
}

class LessonMenuCard extends StatelessWidget {
  const LessonMenuCard(
      {super.key,
      required this.id,
      required this.title,
      required this.imageAsset,
      required this.color,
      required this.mastered,
      required this.total,
      required this.started,
      required this.onPressed,
      this.unit = 'Mastered'});
  final String id, title, imageAsset, unit;
  final Color color;
  final int mastered, total;
  final bool started;
  final VoidCallback? onPressed;
  String get action => started ? 'Continue' : 'Start';
  static double heightFor(BuildContext context, double width) {
    final scale = MediaQuery.textScalerOf(context);
    return width * .58 +
        scale.scale(15) * 2.2 +
        scale.scale(11) * 1.4 +
        (scale.scale(18) * 1.4).clamp(32, double.infinity) +
        28;
  }

  static double minimumHeight(BuildContext context, double width) =>
      heightFor(context, width) - width * .3;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return Semantics(
        hint: '$mastered of $total $unit. $action $title',
        child: LessonMenuPress(
            key: ValueKey('lesson-open-$id'),
            onTap: onPressed,
            radius: 26,
            child: Container(
                key: ValueKey('lesson-card-$id'),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, color, color]),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: .3),
                          blurRadius: 7,
                          offset: const Offset(0, 4))
                    ]),
                child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: Colors.white, width: 1.5),
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(color, Colors.white, .55)!,
                              Color.lerp(color, Colors.white, .12)!
                            ])),
                    child: Column(children: [
                      Expanded(
                          child: Image.asset(imageAsset,
                              key: ValueKey('lesson-art-$id'),
                              fit: BoxFit.contain,
                              cacheWidth: 600,
                              gaplessPlayback: true,
                              excludeFromSemantics: true)),
                      Container(
                          height: scale.scale(15) * 2.2 + 4,
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFEFA23D), width: 2),
                              gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFFF9E8),
                                    Color(0xFFFFD995)
                                  ])),
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFF54230E),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  height: 1.05))),
                      const SizedBox(height: 4),
                      ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                              height: scale.scale(11) * 1.4 + 2,
                              child: Stack(fit: StackFit.expand, children: [
                                LinearProgressIndicator(
                                    key: ValueKey('lesson-progress-$id'),
                                    value: mastered / total,
                                    color: const Color(0xFFBF8AFF),
                                    backgroundColor: const Color(0xFFFFF7EE)),
                                Center(
                                    child: Text('$mastered / $total $unit',
                                        key: ValueKey('lesson-count-$id'),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF482514),
                                            shadows: [
                                              Shadow(
                                                  color: Colors.white,
                                                  blurRadius: 3)
                                            ]))),
                              ]))),
                      const SizedBox(height: 4),
                      _actionButton(context),
                    ])))));
  }

  Widget _actionButton(BuildContext context) => Container(
      key: ValueKey('lesson-action-$id'),
      height: (MediaQuery.textScalerOf(context).scale(18) * 1.4)
          .clamp(32, double.infinity),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 2),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: started
                  ? const [
                      Color(0xFF4DEF66),
                      Color(0xFF00A431),
                      Color(0xFF007322)
                    ]
                  : const [
                      Color(0xFF4DE7FF),
                      Color(0xFF008CFF),
                      Color(0xFF1545D9)
                    ])),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.play_circle_fill_rounded,
            color: Colors.white, size: 23),
        const SizedBox(width: 3),
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(action,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Color(0xFF15558E), offset: Offset(0, 1))
                        ])))),
      ]));
}
