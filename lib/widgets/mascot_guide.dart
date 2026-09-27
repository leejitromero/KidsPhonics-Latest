import 'package:flutter/material.dart';
import '../theme/kids_ui.dart';

enum LearningMascot {
  wigloo('Wigloo', 'assets/images/mascot_wigloo.png', Color(0xFF7052CA)),
  boopli('Boopli', 'assets/images/mascot_boopli.png', Color(0xFF167769)),
  zoplet('Zoplet', 'assets/images/mascot_zoplet.png', Color(0xFF985018)),
  jitjit('Jitjit', 'assets/images/mascot_jitjit.png', Color(0xFF3D681E));

  const LearningMascot(this.name, this.asset, this.color);
  final String name;
  final String asset;
  final Color color;

  String get animatedAsset => asset.replaceAll('.png', '.gif');
}

/// Keeps the supplied artwork intact, including ears and antennae.
class MascotPortrait extends StatelessWidget {
  const MascotPortrait({super.key, required this.mascot, this.size = 96});
  final LearningMascot mascot;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: RepaintBoundary(
          child: Image.asset(
              MediaQuery.disableAnimationsOf(context) ||
                      !TickerMode.valuesOf(context).enabled
                  ? mascot.asset
                  : mascot.animatedAsset,
              width: size,
              height: size,
              fit: BoxFit.contain,
              cacheWidth:
                  (size * MediaQuery.devicePixelRatioOf(context)).ceil()),
        ),
      );
}

/// The instruction remains real, scalable text for reading and accessibility.
class MascotGuide extends StatelessWidget {
  const MascotGuide(
      {super.key,
      required this.message,
      this.mascot = LearningMascot.boopli,
      this.compact = false});
  final bool compact;
  final String message;
  final LearningMascot mascot;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        if (compact) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mascot.color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: mascot.color.withValues(alpha: .2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MascotPortrait(mascot: mascot, size: 44),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${mascot.name} says',
                        style: TextStyle(
                            fontSize: 12,
                            color: mascot.color,
                            fontWeight: FontWeight.w800)),
                    Text(message,
                        style: const TextStyle(
                            fontSize: 15, color: KidsUi.ink, height: 1.25)),
                  ])),
            ]),
          );
        }
        final stacked = box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(18) > 25;
        final bubble = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white,
              Color.lerp(Colors.white, mascot.color, .12)!,
            ]),
            border:
                Border.all(color: mascot.color.withValues(alpha: .3), width: 2),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(stacked ? 6 : 22),
                topRight: const Radius.circular(22),
                bottomLeft: const Radius.circular(6),
                bottomRight: const Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                  color: mascot.color.withValues(alpha: .06),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${mascot.name} says',
                style: TextStyle(
                    color: mascot.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message,
                style: const TextStyle(
                    color: KidsUi.ink,
                    fontSize: 18,
                    height: 1.4,
                    fontWeight: FontWeight.w700)),
          ]),
        );
        if (stacked) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MascotPortrait(mascot: mascot, size: 80),
                const SizedBox(height: 8),
                bubble,
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          MascotPortrait(mascot: mascot),
          const SizedBox(width: 12),
          Expanded(child: bubble),
        ]);
      });
}
