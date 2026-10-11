import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/difficulty.dart';
import 'button_sound.dart';
import 'game_design.dart';
import 'game_mascot_coach.dart';
import 'learner_widgets.dart';

class FlappyStatusBar extends StatelessWidget {
  const FlappyStatusBar(
      {super.key,
      required this.difficulty,
      required this.passed,
      required this.lives,
      required this.onBack,
      required this.onHelp,
      required this.onPause,
      this.letter});
  final Difficulty difficulty;
  final int passed, lives;
  final String? letter;
  final VoidCallback onBack, onHelp;
  final VoidCallback? onPause;

  Widget _progress() => IgnorePointer(
      child: ForestPanel(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${difficulty.label}  •  $passed / 26 letters',
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: GameDesign.ink,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            GameLives(lives: lives),
            if (letter != null)
              Text('Great! $letter',
                  style: const TextStyle(
                      fontSize: 13,
                      color: GameDesign.ink,
                      fontWeight: FontWeight.w900)),
          ])));

  @override
  Widget build(BuildContext context) {
    final back = ForestIconButton(
        tooltip: 'Back', onPressed: onBack, icon: Icons.arrow_back_rounded);
    final help = ForestIconButton(
        tooltip: 'How to Play',
        onPressed: onHelp,
        purple: true,
        icon: Icons.help_outline_rounded);
    final pause = ForestIconButton(
        tooltip: 'Pause', onPressed: onPause, icon: Icons.pause_rounded);
    final mascot = IgnorePointer(
        child: Image.asset(GameMascotCoach.mascotAsset,
            width: 36,
            height: 44,
            cacheWidth: 192,
            fit: BoxFit.contain,
            excludeFromSemantics: true));
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    return Padding(
      key: const ValueKey('flappy-status-bar'),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Center(
          child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: largeText
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  back,
                  const Spacer(),
                  mascot,
                  const Spacer(),
                  help,
                  const SizedBox(width: 6),
                  pause
                ]),
                const SizedBox(height: 6),
                SizedBox(width: double.infinity, child: _progress()),
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                back,
                const SizedBox(width: 6),
                Expanded(child: _progress()),
                const SizedBox(width: 4),
                mascot,
                const SizedBox(width: 4),
                help,
                const SizedBox(width: 6),
                pause,
              ]),
      )),
    );
  }
}

/// Live, scrollable flight controls on the illustrated card from the reference.
class FlappyFlightPanel extends StatelessWidget {
  const FlappyFlightPanel(
      {super.key,
      required this.title,
      required this.detail,
      required this.buttonLabel,
      required this.onPressed,
      this.celebrate = false});
  final String title, detail, buttonLabel;
  final VoidCallback onPressed;
  final bool celebrate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final width = math.min(box.maxWidth - 28, 460.0);
        final heroHeight = width * .30;
        return SingleChildScrollView(
          key: const ValueKey('flappy-panel-scroll'),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: math.max(0, box.maxHeight - 42)),
            child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: width,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Padding(
                      padding: EdgeInsets.only(top: heroHeight),
                      child: Container(
                        key: const ValueKey('flappy-flight-card'),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(34),
                            gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.white, Color(0xFFAF80F1)]),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x666747AB),
                                  blurRadius: 15,
                                  offset: Offset(0, 7))
                            ]),
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(29),
                              border: Border.all(color: Colors.white, width: 2),
                              gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF6BCBFA),
                                    Color(0xFFE7F4FF),
                                    Color(0xFFE9DCFF)
                                  ])),
                          child: CustomPaint(
                            foregroundPainter: const _FlightGardenFrame(),
                            child: Padding(
                              padding:
                                  EdgeInsets.fromLTRB(20, width * .34, 20, 40),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ExcludeSemantics(
                                        child: Icon(
                                            celebrate
                                                ? Icons.emoji_events_rounded
                                                : Icons.flight_rounded,
                                            color: const Color(0xFF812CE3),
                                            size: 40,
                                            shadows: const [
                                          Shadow(
                                              color: Colors.white,
                                              offset: Offset(1, 2),
                                              blurRadius: 2)
                                        ])),
                                    const SizedBox(height: 8),
                                    _FlightTitle(title),
                                    const SizedBox(height: 12),
                                    Text(detail,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontSize: 16,
                                            color: Color(0xFF49356E),
                                            fontWeight: FontWeight.w700,
                                            height: 1.35)),
                                    const SizedBox(height: 20),
                                    _FlightAction(
                                        label: buttonLabel,
                                        onPressed: onPressed),
                                  ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        top: 0,
                        left: 0,
                        width: width * .72,
                        height: width * .65,
                        child: ExcludeSemantics(
                            child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 320),
                          child: Image.asset(
                              'assets/images/home_mascots/airplane.webp',
                              key: const ValueKey('flappy-airplane-art'),
                              fit: BoxFit.contain,
                              cacheWidth: 720,
                              excludeFromSemantics: true),
                          builder: (_, value, child) => Transform.translate(
                              offset: Offset(-8 * (1 - value), 6 * (1 - value)),
                              child: child),
                        ))),
                    Positioned(
                        top: width * .10,
                        right: -2,
                        width: width * .45,
                        child: const _FlightSpeechBubble()),
                  ]),
                )),
          ),
        );
      });
}

class _FlightTitle extends StatelessWidget {
  const _FlightTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 30,
        fontWeight: FontWeight.w900,
        height: 1.15));
    return Semantics(
        header: true,
        child: Stack(alignment: Alignment.center, children: [
          ExcludeSemantics(
              child: RichText(
                  textAlign: TextAlign.center,
                  textScaler: MediaQuery.textScalerOf(context),
                  text: TextSpan(
                      text: title,
                      style: style.copyWith(
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 6
                            ..strokeJoin = StrokeJoin.round
                            ..color = const Color(0xFF873EDA))))),
          Text(title,
              textAlign: TextAlign.center,
              style: style.copyWith(color: Colors.white, shadows: const [
                Shadow(color: Color(0xFF5620A4), offset: Offset(0, 3))
              ])),
        ]));
  }
}

class _FlightSpeechBubble extends StatelessWidget {
  const _FlightSpeechBubble();
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: const _BubbleTail(),
      child: Container(
        key: const ValueKey('flappy-instruction-bubble'),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFEA9AED), width: 3),
            gradient:
                const LinearGradient(colors: [Colors.white, Color(0xFFFFE8FB)]),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x448D43B7), blurRadius: 5, offset: Offset(0, 3))
            ]),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.asset(GameMascotCoach.mascotAsset,
              width: 28,
              height: 34,
              cacheWidth: 128,
              excludeFromSemantics: true),
          const SizedBox(width: 4),
          const Expanded(
              child: Text('Tap to fly through the gaps!',
                  style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: GameDesign.ink,
                      fontWeight: FontWeight.w900))),
        ]),
      ));
}

class _BubbleTail extends CustomPainter {
  const _BubbleTail();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(20, size.height - 4)
      ..lineTo(14, size.height + 12)
      ..lineTo(42, size.height - 4);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFEA9AED)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF4FD));
  }

  @override
  bool shouldRepaint(_BubbleTail oldDelegate) => false;
}

class _FlightAction extends StatelessWidget {
  const _FlightAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: const Color(0xFFFFE494), width: 4),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF8A9),
                Color(0xFFFFE039),
                Color(0xFFFFB51E)
              ]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x667E4A13), offset: Offset(0, 4), blurRadius: 5)
          ]),
      child: ElevatedButton(
        key: const ValueKey('flappy-flight-action'),
        onPressed: withButtonSound(onPressed),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF77380D),
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(child: Text(label, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          const Icon(Icons.play_arrow_rounded,
              size: 30, color: Color(0xFFF47B13)),
        ]),
      ));
}

class _FlightGardenFrame extends CustomPainter {
  const _FlightGardenFrame();
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final trail = Path()
      ..moveTo(width * .56, size.height * .08)
      ..quadraticBezierTo(
          width * .80, size.height * .12, width * .96, size.height * .30);
    canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * .07
          ..color = const Color(0x558E63EC));
    canvas.drawPath(
        trail,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * .018
          ..color = const Color(0x77FFFFFF));
    for (final center in [
      Offset(width * .72, size.height * .11),
      Offset(width * .86, size.height * .18),
      Offset(width * .09, size.height * .79),
      Offset(width * .91, size.height * .85)
    ]) {
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final angle = -math.pi / 2 + i * math.pi / 5;
        final radius = width * (i.isEven ? .04 : .022);
        final point =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        if (i == 0) {
          star.moveTo(point.dx, point.dy);
        } else {
          star.lineTo(point.dx, point.dy);
        }
      }
      star.close();
      canvas.drawPath(
          star,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFFFFC23B));
      canvas.drawPath(
          star,
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFF5A0), Color(0xFFFFDB48)])
                .createShader(star.getBounds()));
    }
    for (final center in [
      Offset(0, size.height * .41),
      Offset(width, size.height * .40),
      Offset(width * .10, size.height * .93),
      Offset(width * .33, size.height * .99),
      Offset(width * .65, size.height * .99),
      Offset(width * .92, size.height * .93)
    ]) {
      final cloud = Path();
      final radius = width * .078;
      cloud.addOval(Rect.fromCenter(
          center: center, width: radius * 3.2, height: radius * 1.6));
      cloud.addOval(Rect.fromCircle(
          center: center + Offset(-radius * .7, -radius * .4), radius: radius));
      cloud.addOval(Rect.fromCircle(
          center: center + Offset(radius * .65, -radius * .2),
          radius: radius * .85));
      canvas.drawPath(
          cloud,
          Paint()
            ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFFF8EEFF),
                  Color(0xFFCCD9FF)
                ]).createShader(cloud.getBounds()));
    }
    const ForestLeaves(allCorners: true).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_FlightGardenFrame oldDelegate) => false;
}
