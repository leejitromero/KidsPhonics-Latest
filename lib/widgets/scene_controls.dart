import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/updated_scene.dart';
import '../providers/app_provider.dart';
import 'button_sound.dart';

class SceneButton extends StatelessWidget {
  const SceneButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.icon,
      this.filled = false,
      this.color = const Color(0xFF7445C7),
      this.style,
      this.fontSize = 17,
      this.iconAfter = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final Color color;
  final ButtonStyle? style;
  final double fontSize;
  final bool iconAfter;

  @override
  Widget build(BuildContext context) => ElevatedButton(
      onPressed: withButtonSound(onPressed),
      style: (style ?? const ButtonStyle()).merge(ElevatedButton.styleFrom(
          backgroundColor: filled ? color : const Color(0xFFFFF5DA),
          foregroundColor: filled ? Colors.white : color,
          minimumSize: const Size(48, 52),
          elevation: 4,
          shadowColor: const Color(0x55633012),
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE9AC57), width: 3)))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null && !iconAfter) ...[
          Icon(icon),
          const SizedBox(width: 6)
        ],
        Flexible(
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontFamily: 'Fredoka', fontSize: fontSize)))),
        if (icon != null && iconAfter) ...[
          const SizedBox(width: 6),
          Icon(icon)
        ],
      ]));
}

class StudentProfilePortrait extends StatelessWidget {
  const StudentProfilePortrait(
      {super.key, required this.character, this.size = 64});
  final String character;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: Stack(fit: StackFit.expand, children: [
        // Match the transparent opening in the supplied 1254 x 1254 frames.
        // Keep the whole character inside it instead of covering a square crop.
        Positioned(
            left: size * .19,
            top: size * .215,
            width: size * .64,
            height: size * .61,
            child: ClipRRect(
                key: ValueKey('profile-$character-opening'),
                borderRadius: BorderRadius.circular(size * .13),
                child: ColoredBox(
                    color: const Color(0xFFFFF4DB),
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: size * .02),
                        child: Image.asset('$sceneAssets/${character}_6.png',
                            key: ValueKey('profile-$character-character'),
                            fit: BoxFit.contain,
                            cacheWidth:
                                (size * MediaQuery.devicePixelRatioOf(context))
                                    .ceil()
                                    .clamp(120, 512),
                            excludeFromSemantics: true))))),
        Image.asset('$sceneAssets/profile_frame_$character.png',
            key: ValueKey('profile-$character-frame'),
            fit: BoxFit.contain,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(150, 600),
            excludeFromSemantics: true),
      ]));
}

class LearnerProfileCard extends StatelessWidget {
  const LearnerProfileCard({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Semantics(
        label: 'Learner profile: ${p.studentName}',
        child: Material(
            color: const Color(0xEEFFF6DF),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
                onTap: withButtonSound(onTap),
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(children: [
                      StudentProfilePortrait(character: p.studentCharacter),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                p.studentName.isEmpty
                                    ? 'My adventure'
                                    : p.studentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Fredoka',
                                    fontSize: 18,
                                    color: Color(0xFF633012))),
                            Text('Level ${p.level}  •  ${p.stars} stars',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF633012),
                                    fontWeight: FontWeight.w800))
                          ])),
                      if (onTap != null)
                        const Icon(Icons.edit_rounded,
                            color: Color(0xFF7445C7)),
                    ])))));
  }
}
