import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'game_design.dart';

/// The shared illustrated guide shell; examples and instructions stay game-specific.
class GameTutorialDesign extends StatelessWidget {
  const GameTutorialDesign(
      {super.key,
      required this.step,
      required this.total,
      required this.title,
      required this.detail,
      required this.example,
      required this.onSkip,
      required this.onNext,
      this.onBack});
  final int step, total;
  final String title, detail;
  final Widget example;
  final VoidCallback onSkip, onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
          key: const ValueKey('game-tutorial'),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: CustomPaint(
                  foregroundPainter: const _GuideClouds(),
                  child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                              color: const Color(0xFFAF84FF), width: 3),
                          gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF8BE7FF),
                                Color(0xFFF9F8FF),
                                Color(0xFFE4E0FF)
                              ]),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x88251955),
                                blurRadius: 24,
                                offset: Offset(0, 10))
                          ]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                            child: SingleChildScrollView(
                                clipBehavior: Clip.none,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const _GuideBanner(),
                                      const SizedBox(height: 6),
                                      _StepStatus(
                                          step: step,
                                          total: total,
                                          onBack: onBack),
                                      const SizedBox(height: 14),
                                      _ExampleScene(step: step, child: example),
                                      const SizedBox(height: 8),
                                      ForestPanel(
                                          key: const ValueKey(
                                              'tutorial-step-title'),
                                          accent: const Color(0xFFFFAF2C),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 9),
                                          child: SizedBox(
                                              width: double.infinity,
                                              child: Text(title,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Color(0xFF6D22CC),
                                                      shadows: [
                                                        Shadow(
                                                            color: Colors.white,
                                                            blurRadius: 3)
                                                      ])))),
                                      const SizedBox(height: 9),
                                      CustomPaint(
                                          foregroundPainter:
                                              const _DashedGuideBorder(),
                                          child: Container(
                                              key: const ValueKey(
                                                  'tutorial-step-detail'),
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 15,
                                                      vertical: 14),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFFFF8E8),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          22)),
                                              child: Text(detail,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 17,
                                                      height: 1.35,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: GameDesign.ink)))),
                                    ]))),
                        const SizedBox(height: 16),
                        // Keep actions visible even when the illustrated steps must scroll.
                        _GuideActions(
                            step: step,
                            total: total,
                            onSkip: onSkip,
                            onNext: onNext),
                      ]))))));
}

class _StepStatus extends StatelessWidget {
  const _StepStatus({required this.step, required this.total, this.onBack});
  final int step, total;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (onBack != null)
            TextButton(
                key: const ValueKey('tutorial-back'),
                onPressed: withButtonSound(onBack),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7832CC),
                    minimumSize: const Size(48, 48)),
                child: const Text('Back')),
          Flexible(
              child: Semantics(
                  liveRegion: true,
                  child: Text('Step ${step + 1} of $total',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: GameDesign.ink)))),
          if (onBack != null) const SizedBox(width: 48),
        ]),
        const SizedBox(height: 8),
        ExcludeSemantics(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < total; i++)
            Container(
                key: ValueKey('tutorial-step-$i'),
                width: 36,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: i == step
                        ? const Color(0xFF8A1AFF)
                        : const Color(0xFFD7C5F2)))
        ])),
      ]);
}

class _GuideActions extends StatelessWidget {
  const _GuideActions(
      {required this.step,
      required this.total,
      required this.onSkip,
      required this.onNext});
  final int step, total;
  final VoidCallback onSkip, onNext;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final skip = TutorialGuideButton(
            label: 'Skip',
            pale: true,
            buttonKey: const ValueKey('tutorial-skip'),
            onPressed: onSkip);
        final next = TutorialGuideButton(
            label: step == total - 1 ? "Let's Play" : 'Next',
            buttonKey: const ValueKey('tutorial-next'),
            onPressed: onNext,
            icon: step == total - 1
                ? Icons.play_arrow_rounded
                : Icons.chevron_right_rounded);
        return MediaQuery.textScalerOf(context).scale(20) > 28 ||
                box.maxWidth < 240
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [skip, const SizedBox(height: 10), next])
            : Row(children: [
                Expanded(child: skip),
                const SizedBox(width: 12),
                Expanded(child: next)
              ]);
      });
}

class _ExampleScene extends StatelessWidget {
  const _ExampleScene({required this.step, required this.child});
  final int step;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      key: const ValueKey('tutorial-example-scene'),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFFFD779), width: 3),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF21B2FB), Color(0xFFB9F2FF), Color(0xFF8FDB43)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x44886727), offset: Offset(0, 3), blurRadius: 5)
          ]),
      child: CustomPaint(
          painter: const _ExampleScenery(),
          foregroundPainter: const _ExampleGarden(),
          child: TweenAnimationBuilder<double>(
              key: ValueKey('example-$step'),
              tween: Tween(begin: .92, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: child))));
}

class _GuideBanner extends StatelessWidget {
  const _GuideBanner();
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: const ForestLeaves(),
      child: Container(
          key: const ValueKey('tutorial-banner'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFFFD051), width: 4),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFCA76FF),
                    Color(0xFF9719F5),
                    Color(0xFF6207DF)
                  ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x99824CB7),
                    offset: Offset(0, 5),
                    blurRadius: 4)
              ]),
          child: const Row(children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFD438), size: 25),
            SizedBox(width: 5),
            Expanded(
                child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'How to ',
                          style: TextStyle(color: Colors.white)),
                      TextSpan(
                          text: 'Play',
                          style: TextStyle(color: Color(0xFFFFEF75)))
                    ]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        shadows: [
                          Shadow(
                              color: Color(0xFF390075),
                              blurRadius: 2,
                              offset: Offset(0, 3))
                        ]))),
            SizedBox(width: 5),
            Icon(Icons.star_rounded, color: Color(0xFFFFD438), size: 25),
          ])));
}

/// Real controls on top of glossy gradients keep keyboard and TalkBack support.
class TutorialGuideButton extends StatelessWidget {
  const TutorialGuideButton(
      {super.key,
      required this.label,
      required this.onPressed,
      required this.buttonKey,
      this.pale = false,
      this.icon});
  final String label;
  final VoidCallback onPressed;
  final Key buttonKey;
  final bool pale;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: pale ? const Color(0xFFB58BFF) : const Color(0xFFB548FF),
              width: 3),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pale
                  ? const [Colors.white, Color(0xFFDED9FF)]
                  : const [
                      Color(0xFFCB79FF),
                      Color(0xFF9E19F5),
                      Color(0xFF7000E2)
                    ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x447335CC), offset: Offset(0, 4), blurRadius: 5)
          ]),
      child: ElevatedButton(
          key: buttonKey,
          onPressed: withButtonSound(onPressed),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: pale ? const Color(0xFF8012E5) : Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 50),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              side: const BorderSide(color: Color(0xAAFFFFFF), width: 2),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 21,
                  fontWeight: FontWeight.w900)),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: Text(label, textAlign: TextAlign.center)),
                if (icon != null) ...[
                  const SizedBox(width: 4),
                  Icon(icon, size: 25)
                ]
              ])));
}

class TutorialExampleTiles extends StatelessWidget {
  const TutorialExampleTiles(
      {super.key,
      required this.letters,
      this.selected = -1,
      this.complete = false});
  final List<String> letters;
  final int selected;
  final bool complete;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < letters.length; i++)
          Flexible(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ForestPanel(
                      leaves: false,
                      accent: complete || selected == i
                          ? const Color(0xFF28BC7D)
                          : const Color(0xFFFFB135),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 10),
                      child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(minWidth: 32, minHeight: 36),
                          child: Center(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(letters[i],
                                      style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: GameDesign.ink)))))))),
        if (complete)
          const Padding(
              padding: EdgeInsets.only(left: 5),
              child: Icon(Icons.check_circle_rounded,
                  color: Color(0xFF087D5A), size: 24))
      ]);
}

class _GuideClouds extends CustomPainter {
  const _GuideClouds();
  @override
  void paint(Canvas canvas, Size size) {
    void puff(Offset c, double r) => canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(
                  center: Alignment(-.2, -.4),
                  colors: [Colors.white, Color(0xFFE9E6FF)])
              .createShader(Rect.fromCircle(center: c, radius: r)));
    // The decorations hug the outer border so all live content remains readable.
    for (final left in [true, false]) {
      final x = left ? 10.0 : size.width - 10;
      final sign = left ? 1.0 : -1.0;
      puff(Offset(x, size.height * .32), 13);
      puff(Offset(x + sign * 6, size.height * .32 + 16), 15);
      for (var i = 0; i < 4; i++) {
        puff(Offset(x + sign * i * 14, size.height - 7 + (i.isEven ? 0 : 4)),
            14);
      }
    }
    const ForestLeaves(allCorners: true).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_GuideClouds oldDelegate) => false;
}

class _ExampleScenery extends CustomPainter {
  const _ExampleScenery();
  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()..color = Colors.white.withValues(alpha: .8);
    for (final x in [12.0, size.width - 12]) {
      canvas.drawCircle(Offset(x, 7), 10, cloud);
      canvas.drawCircle(
          Offset(x + (x < size.width / 2 ? 11 : -11), 10), 8, cloud);
    }
    final hill = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 15)
      ..quadraticBezierTo(
          size.width * .3, size.height - 32, size.width * .5, size.height - 13)
      ..quadraticBezierTo(
          size.width * .7, size.height - 30, size.width, size.height - 15)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
        hill,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFFB6EF53), Color(0xFF68C632)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)
              .createShader(
                  Rect.fromLTWH(0, size.height - 32, size.width, 32)));
  }

  @override
  bool shouldRepaint(_ExampleScenery oldDelegate) => false;
}

class _ExampleGarden extends CustomPainter {
  const _ExampleGarden();
  @override
  void paint(Canvas canvas, Size size) {
    const ForestLeaves(allCorners: true).paint(canvas, size);
    for (final x in [5.0, size.width - 5]) {
      final c = Offset(x, size.height - 8);
      final white = Paint()..color = Colors.white;
      canvas.drawCircle(c + const Offset(-4, 0), 4, white);
      canvas.drawCircle(c + const Offset(4, 0), 4, white);
      canvas.drawCircle(c + const Offset(0, -4), 4, white);
      canvas.drawCircle(c + const Offset(0, 4), 4, white);
      canvas.drawCircle(c, 3, Paint()..color = const Color(0xFFFFD140));
    }
  }

  @override
  bool shouldRepaint(_ExampleGarden oldDelegate) => false;
}

class _DashedGuideBorder extends CustomPainter {
  const _DashedGuideBorder();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(5), const Radius.circular(18)));
    final paint = Paint()
      ..color = const Color(0xFFFFDB88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedGuideBorder oldDelegate) => false;
}
