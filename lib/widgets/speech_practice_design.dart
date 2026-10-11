import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'game_design.dart';
import 'game_word_picture.dart';

/// The picture, word plaque, and controls follow the supplied speech-game layout.
class SpeechPictureCard extends StatelessWidget {
  const SpeechPictureCard(
      {super.key,
      required this.word,
      required this.height,
      this.activeLetter = -1,
      this.spelling = false,
      this.readingWord = false});
  final String word;
  final double height;
  final int activeLetter;
  final bool spelling, readingWord;

  @override
  Widget build(BuildContext context) => SizedBox(
      key: const ValueKey('speech-picture-card'),
      height: height,
      child: CustomPaint(
          foregroundPainter: const ForestLeaves(allCorners: true),
          child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 3),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEDE7FF),
                        Color(0xFFBA9AF1),
                        Color(0xFF96DFFD)
                      ]),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x667B43D0),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: Offset(0, 3))
                  ]),
              child: Column(children: [
                Expanded(
                    child: LayoutBuilder(
                        builder: (_, box) =>
                            Stack(alignment: Alignment.center, children: [
                              const Positioned(
                                  top: 9,
                                  left: 14,
                                  child: Icon(Icons.auto_awesome_rounded,
                                      color: Color(0xFFFFF3AD), size: 24)),
                              const Positioned(
                                  top: 25,
                                  right: 15,
                                  child: Icon(Icons.auto_awesome_rounded,
                                      color: Colors.white, size: 20)),
                              GameWordPicture(
                                  word: word,
                                  size: math.min(box.maxWidth, box.maxHeight)),
                            ]))),
                const SizedBox(height: 6),
                FractionallySizedBox(
                    widthFactor: .78,
                    child: ForestPanel(
                        leaves: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Semantics(
                            label: activeLetter >= 0
                                ? 'Letter ${word[activeLetter].toUpperCase()}'
                                : word,
                            liveRegion: spelling,
                            excludeSemantics: true,
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var i = 0; i < word.length; i++)
                                        AnimatedScale(
                                            key: ValueKey('speech-letter-$i'),
                                            scale:
                                                (activeLetter == i || readingWord) && !MediaQuery.disableAnimationsOf(context)
                                                    ? 1.23
                                                    : 1,
                                            duration:
                                                MediaQuery.disableAnimationsOf(context)
                                                    ? Duration.zero
                                                    : const Duration(
                                                        milliseconds: 170),
                                            child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        spelling ? 2 : 0,
                                                    vertical: 4),
                                                child: Text(spelling ? word[i].toUpperCase() : word[i],
                                                    style: TextStyle(
                                                        fontFamily: 'Nunito',
                                                        fontSize: 34,
                                                        height: 1.1,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                        color: activeLetter == i
                                                            ? const Color(0xFF9B41DD)
                                                            : GameDesign.ink,
                                                        shadows: activeLetter == i || readingWord ? const [Shadow(color: Color(0xFFFFCF3E), blurRadius: 8)] : const [])))),
                                    ]))))),
              ]))));
}

class SpeechMicrophoneButton extends StatelessWidget {
  const SpeechMicrophoneButton(
      {super.key,
      required this.label,
      required this.listening,
      required this.onPressed});
  final String label;
  final bool listening;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: const ForestLeaves(),
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: const Color(0xFFFFDB86), width: 3),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFED9546),
                    Color(0xFFBA501E),
                    Color(0xFF9D3E19)
                  ]),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x663E2118),
                    blurRadius: 6,
                    offset: Offset(0, 3))
              ]),
          child: ElevatedButton(
              key: const ValueKey('speech-microphone'),
              onPressed: withButtonSound(onPressed),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white70,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  shape: const StadiumBorder()),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x66923C19),
                        border: Border.all(color: const Color(0xFFDA792F))),
                    child: Icon(
                        listening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 27)),
                const SizedBox(width: 10),
                if (listening) ...[
                  const Icon(Icons.graphic_eq_rounded,
                      size: 22, color: Color(0xFFFFE697)),
                  const SizedBox(width: 6)
                ],
                Flexible(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 21,
                            fontWeight: FontWeight.w900))),
                if (listening) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.graphic_eq_rounded,
                      size: 22, color: Color(0xFFFFE697))
                ],
              ]))));
}

class SpeechHeardCard extends StatelessWidget {
  const SpeechHeardCard(
      {super.key, required this.heard, required this.correct});
  final String heard;
  final bool? correct;
  @override
  Widget build(BuildContext context) => Semantics(
      liveRegion: heard.isNotEmpty,
      child: CustomPaint(
          foregroundPainter: const _HeardStitches(),
          child: Container(
              key: const ValueKey('speech-heard-card'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: Colors.white, width: 3),
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFEDF1), Color(0xFFFFF9ED)]),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x44E66D8C),
                        blurRadius: 7,
                        offset: Offset(0, 3))
                  ]),
              child: Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFA5B4), width: 3),
                        gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFF7F94), Color(0xFFE83B59)])),
                    child: const Icon(Icons.graphic_eq_rounded,
                        color: Colors.white, size: 30)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('I heard:',
                          style: TextStyle(
                              color: GameDesign.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      Text(
                          heard.isEmpty ? 'Your word will appear here.' : heard,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'Nunito',
                              color: correct == true
                                  ? const Color(0xFF008A70)
                                  : const Color(0xFFE63359),
                              fontSize: heard.isEmpty ? 13 : 27,
                              fontWeight: FontWeight.w900)),
                      if (correct != null)
                        Text(correct! ? 'Recognized' : 'Try Again',
                            style: const TextStyle(
                                color: GameDesign.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                    ])),
                const SizedBox(width: 8),
                const ExcludeSemantics(
                    child: SizedBox(
                        width: 56,
                        height: 56,
                        child: CustomPaint(painter: _HappyStar()))),
              ]))));
}

class _HeardStitches extends CustomPainter {
  const _HeardStitches();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(7), const Radius.circular(20)));
    final paint = Paint()
      ..color = const Color(0xFFFFAFBD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 8) {
        canvas.drawPath(
            metric.extractPath(distance, math.min(distance + 4, metric.length)),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeardStitches oldDelegate) => false;
}

class SpeechTipCard extends StatelessWidget {
  const SpeechTipCard({super.key, required this.tip, this.firstVisit = false});
  final String tip;
  final bool firstVisit;
  @override
  Widget build(BuildContext context) => ForestPanel(
      key: const ValueKey('speech-tip-card'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(children: [
        const Icon(Icons.lightbulb_rounded, size: 35, color: Color(0xFFFFB900)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tip,
              style: const TextStyle(
                  color: GameDesign.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          if (firstVisit) ...[
            const SizedBox(height: 4),
            const Text(
                'KidsPhonics uses the microphone only for Speak & Recognize.',
                style: TextStyle(fontSize: 11, color: GameDesign.ink)),
            const Text('Your voice is used to recognize the word you say.',
                style: TextStyle(fontSize: 11, color: GameDesign.ink))
          ],
        ])),
      ]));
}

class _HappyStar extends CustomPainter {
  const _HappyStar();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * .46;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? r : r * .52;
      final p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF16B), Color(0xFFFFBD24)])
              .createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFFA719)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final face = Paint()
      ..color = const Color(0xFF663026)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final sign in [-1, 1]) {
      final eye = c + Offset(sign * r * .22, -r * .05);
      canvas.drawArc(
          Rect.fromCenter(center: eye, width: r * .2, height: r * .16),
          math.pi,
          math.pi,
          false,
          face..style = PaintingStyle.stroke);
      canvas.drawOval(
          Rect.fromCenter(
              center: eye + Offset(0, r * .2), width: r * .2, height: r * .12),
          Paint()..color = const Color(0xFFFF8490));
    }
    canvas.drawArc(
        Rect.fromCenter(
            center: c + Offset(0, r * .13), width: r * .35, height: r * .35),
        0,
        math.pi,
        true,
        face..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_HappyStar oldDelegate) => false;
}
