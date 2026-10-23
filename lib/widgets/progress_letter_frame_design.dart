import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'progress_design.dart';
import 'progress_reference_design.dart';

/// Live content stays within the supplied artwork's empty inner area.
class ProgressLetterSummaryFrame extends StatelessWidget {
  const ProgressLetterSummaryFrame(
      {super.key, required this.masteredCount, required this.values});
  final int masteredCount;
  final List<(String, String, IconData, Color)> values;
  static const asset = 'assets/images/progress_collection/summary_frame.png';

  @override
  Widget build(BuildContext context) => AspectRatio(
      aspectRatio: 4 / 3,
      child: LayoutBuilder(
          builder: (_, box) => Stack(fit: StackFit.expand, children: [
                Image.asset(asset,
                    fit: BoxFit.fill, excludeFromSemantics: true),
                Positioned(
                    left: box.maxWidth * .145,
                    top: box.maxHeight * .19,
                    width: box.maxWidth * .71,
                    height: box.maxHeight * .61,
                    child: ClipRect(
                        child: Row(
                            key: const ValueKey(
                                'progress-summary-frame-content'),
                            children: [
                          Expanded(
                              flex: 43,
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: ProgressCountRing(
                                      count: masteredCount, total: 26))),
                          const SizedBox(width: 5),
                          Expanded(
                              flex: 57,
                              child: Column(children: [
                                for (var row = 0; row < 2; row++)
                                  Expanded(
                                      child: Row(children: [
                                    for (final value
                                        in values.skip(row * 2).take(2))
                                      Expanded(
                                          child: Padding(
                                              padding: const EdgeInsets.all(2),
                                              child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Column(children: [
                                                    Icon(value.$3,
                                                        color: value.$4,
                                                        size: 25),
                                                    Text(value.$1,
                                                        style: TextStyle(
                                                            fontSize: 23,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            color: value.$4)),
                                                    Text(value.$2,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                progressInk)),
                                                  ]))))
                                  ]))
                              ]))
                        ])))
              ])));
}

class ProgressLetterFilterButton extends StatelessWidget {
  const ProgressLetterFilterButton(
      {super.key,
      required this.label,
      required this.selected,
      required this.onSelected,
      required this.width});
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final double width;
  static const asset = 'assets/images/progress_collection/filter_button.png';

  @override
  Widget build(BuildContext context) {
    final height = math.max(48.0, width * .44);
    return SizedBox(
        width: width,
        height: height,
        child: ChoiceChip(
            label: SizedBox(
                width: width,
                height: height,
                child: Stack(fit: StackFit.expand, children: [
                  Positioned.fill(
                      child: ClipRect(
                          child: Opacity(
                              opacity: selected ? 1 : .72,
                              child: Stack(children: [
                                // Show source rows 230..880 without changing the PNG.
                                Positioned(
                                    left: 0,
                                    right: 0,
                                    top: -height * 230 / 650,
                                    height: height * 1086 / 650,
                                    child: Image.asset(asset,
                                        fit: BoxFit.fill,
                                        excludeFromSemantics: true))
                              ])))),
                  Padding(
                      key: ValueKey('progress-filter-content-$label'),
                      padding: EdgeInsets.symmetric(
                          horizontal: width * .14, vertical: height * .2),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: selected
                                      ? FontWeight.w900
                                      : FontWeight.w800,
                                  color: selected
                                      ? progressPurple
                                      : progressInk))))
                ])),
            selected: selected,
            onSelected: onSelected,
            showCheckmark: false,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.standard,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: const WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: Colors.transparent,
            side: BorderSide.none,
            shape: const StadiumBorder()));
  }
}
