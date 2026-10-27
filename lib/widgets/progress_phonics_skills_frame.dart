import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'progress_design.dart';
import 'progress_reference_design.dart';

/// Aligns the five live skills with the five slots in the supplied artwork.
class ProgressPhonicsSkillsFrame extends StatelessWidget {
  const ProgressPhonicsSkillsFrame({super.key, required this.children})
      : assert(children.length == 5);
  final List<Widget> children;
  static const asset =
      'assets/images/progress_collection/phonics_skills_frame.png';
  static const slotTops = [300.0, 516.0, 732.0, 948.0, 1164.0];

  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: LayoutBuilder(builder: (context, box) {
            final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final titleWidth = math.max(1.0, box.maxWidth * 924 / 1086 - 148);
            var rowHeight = 64.0;
            for (final row in children.whereType<ProgressSkillRow>()) {
              final title = TextPainter(
                  text: TextSpan(
                      text: row.title,
                      style: DefaultTextStyle.of(context).style.merge(
                          const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w900))),
                  textScaler: MediaQuery.textScalerOf(context),
                  textDirection: Directionality.of(context))
                ..layout(maxWidth: titleWidth);
              rowHeight = math.max(rowHeight, title.height + 27);
              title.dispose();
            }
            // The surrounding page already scrolls. Give large text more height
            // rather than squeezing it into the artwork's original proportions.
            final height = math.max(
                math.max(
                    box.maxWidth * 1448 / 1086, 540.0 * math.max(1.0, scale)),
                rowHeight * 1448 / 194);
            return SizedBox(
                key: const ValueKey('phonics-skills-frame'),
                width: box.maxWidth,
                height: height,
                child: DefaultTextStyle.merge(
                    style: const TextStyle(color: progressInk),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.asset(asset,
                          fit: BoxFit.fill,
                          cacheWidth: 1086,
                          excludeFromSemantics: true),
                      Positioned(
                          left: box.maxWidth * .09,
                          width: box.maxWidth * .82,
                          top: height * .07,
                          height: height * .125,
                          child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                  width: box.maxWidth * .82,
                                  child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ProgressSectionLabel(
                                            'My Phonics Skills',
                                            Icons.bar_chart_rounded),
                                        SizedBox(height: 4),
                                        Text(
                                            'Tap a skill to continue learning.',
                                            style: TextStyle(fontSize: 11)),
                                      ])))),
                      for (var i = 0; i < children.length; i++)
                        Positioned(
                            left: box.maxWidth * 84 / 1086,
                            width: box.maxWidth * 924 / 1086,
                            top: height * slotTops[i] / 1448,
                            height: height * 194 / 1448,
                            child: ClipRRect(
                                key: ValueKey('phonics-skills-slot-$i'),
                                borderRadius:
                                    BorderRadius.circular(box.maxWidth * .055),
                                child: children[i])),
                    ])));
          })));
}
