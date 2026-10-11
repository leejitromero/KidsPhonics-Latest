import 'package:flutter/material.dart';
import 'quick_check_design.dart';
import 'mascot_guide.dart';

class MasteryIllustration extends StatelessWidget {
  const MasteryIllustration(
      {super.key,
      required this.mastered,
      required this.completed,
      this.compact = false,
      this.dense = false});
  final int mastered, completed;
  final bool compact, dense;
  @override
  Widget build(BuildContext context) => QuickGlassPanel(
      key: const ValueKey('overall-mastery-illustration'),
      padding: EdgeInsets.all(dense ? 8 : 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
            padding:
                EdgeInsets.symmetric(horizontal: 8, vertical: dense ? 5 : 9),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFB850FF), Color(0xFF6924CA)]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFD6B1FF), width: 2)),
            child: Text('Overall Letter Mastery',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: dense ? 17 : 22,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0xFF401288), offset: Offset(0, 2))
                    ]))),
        SizedBox(height: dense ? 6 : 12),
        if (compact)
          Text(
              '$mastered / 26 letters mastered · $completed adventures completed',
              style: TextStyle(
                  fontSize: dense ? 12 : 14,
                  fontWeight: FontWeight.w900,
                  color: quickInk))
        else if (dense)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: _value('$mastered / 26', 'letters mastered',
                    const Color(0xFFFFEDAB))),
            const SizedBox(width: 6),
            Expanded(
                child: _value('$completed', 'adventures completed',
                    const Color(0xFFD9E8FF))),
          ])
        else
          LayoutBuilder(builder: (_, box) {
            final small = box.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.3;
            final values = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _value('$mastered / 26', 'letters mastered',
                      const Color(0xFFFFEDAB)),
                  const SizedBox(height: 8),
                  _value('$completed', 'adventures completed',
                      const Color(0xFFD9E8FF)),
                ]);
            final blocks = Image.asset(
                'assets/images/lesson_logos/letter_recognition.webp',
                width: small ? 70 : 96,
                height: small ? 70 : 96,
                excludeFromSemantics: true);
            return small
                ? Column(children: [values, const SizedBox(height: 8), blocks])
                : Row(children: [
                    Expanded(child: values),
                    const SizedBox(width: 8),
                    blocks
                  ]);
          }),
        SizedBox(height: dense ? 6 : 12),
        ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
                value: mastered / 26,
                minHeight: dense
                    ? 6
                    : compact
                        ? 8
                        : 19,
                color: const Color(0xFFA12AEF),
                backgroundColor: const Color(0xFFD5C4F4))),
      ]));
  Widget _value(String value, String label, Color color) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 9, vertical: dense ? 4 : 7),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    color: quickPurple,
                    fontSize: dense ? 20 : 28,
                    fontWeight: FontWeight.w900)),
            Text(label,
                style: TextStyle(
                    color: quickInk,
                    fontSize: dense ? 12 : 16,
                    fontWeight: FontWeight.w900)),
          ]));
}

class ProgressGrowthIllustration extends StatelessWidget {
  const ProgressGrowthIllustration({super.key});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFC43D), width: 3),
          gradient: const LinearGradient(
              colors: [Color(0xFFFFF8D7), Color(0xFFFFE985)]),
          boxShadow: const [
            BoxShadow(
                color: Color(0x447E4215), offset: Offset(0, 4), blurRadius: 5)
          ]),
      child: Row(children: [
        const MascotPortrait(mascot: LearningMascot.zoplet, size: 64),
        const SizedBox(width: 8),
        Expanded(
            child: Column(children: [
          const Text('Look how you grow!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: quickPurple,
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFAE8),
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Keep going!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: quickInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w900))),
        ])),
      ]));
}
