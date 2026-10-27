import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'progress_design.dart';

double _textHeight(
    BuildContext context, String text, TextStyle style, double width) {
  final painter = TextPainter(
      text: TextSpan(
          text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context))
    ..layout(maxWidth: width);
  final height = painter.height;
  painter.dispose();
  return height;
}

class ProgressStreakFrame extends StatelessWidget {
  const ProgressStreakFrame({super.key, required this.days});
  final int days;
  static const asset = 'assets/images/progress_collection/frame_streak.png';
  static const _valueStyle = TextStyle(
      fontSize: 27,
      height: 1.2,
      fontWeight: FontWeight.w900,
      color: Color(0xFFD72F64));
  static const _captionStyle =
      TextStyle(fontSize: 11, height: 1.35, color: progressInk);
  static const _caption = 'Answer or practice speaking each day.';

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final value = '$days ${days == 1 ? 'day' : 'days'}';
        final bodyWidth = box.maxWidth * .80;
        final contentHeight =
            _textHeight(context, value, _valueStyle, bodyWidth) +
                3 +
                _textHeight(context, _caption, _captionStyle, bodyWidth);
        final height =
            math.max(box.maxWidth * 680 / 1410, (contentHeight + 8) / .50);
        return _JourneyFrame(
            summary: false,
            height: height,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(value,
                  key: const ValueKey('journey-streak-value'),
                  textAlign: TextAlign.center,
                  style: _valueStyle),
              const SizedBox(height: 3),
              const Text(_caption,
                  textAlign: TextAlign.center, style: _captionStyle),
            ]));
      });
}

class ProgressLearningSummaryFrame extends StatelessWidget {
  const ProgressLearningSummaryFrame(
      {super.key,
      required this.exploredLetters,
      required this.practicedLessons,
      required this.stars});
  final int exploredLetters, practicedLessons, stars;
  static const asset = 'assets/images/progress_collection/frame_summary.png';
  static const _valueStyle =
      TextStyle(fontSize: 23, height: 1.2, fontWeight: FontWeight.w900);
  static const _labelStyle =
      TextStyle(fontSize: 11, height: 1.35, color: progressInk);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final values = [
          (
            '$exploredLetters',
            'letters explored',
            Icons.auto_stories_rounded,
            progressPurple
          ),
          (
            '$practicedLessons / 6',
            'lesson types practiced',
            Icons.check_circle_rounded,
            progressPurple
          ),
          (
            '$stars',
            'stars earned',
            Icons.star_rounded,
            const Color(0xFFE9A414)
          ),
        ];
        final bodyWidth = box.maxWidth * .82;
        final scale = MediaQuery.textScalerOf(context).scale(11) / 11;
        final columns = (bodyWidth / (78 * scale)).floor().clamp(1, 3);
        final itemWidth = (bodyWidth - (columns - 1) * 6 - .01) / columns;
        var itemHeight = 0.0;
        for (final (value, label, _, _) in values) {
          itemHeight = math.max(
              itemHeight,
              25 +
                  _textHeight(context, value, _valueStyle, itemWidth) +
                  _textHeight(context, label, _labelStyle, itemWidth));
        }
        final rows = (values.length / columns).ceil();
        final contentHeight = rows * itemHeight + (rows - 1) * 8;
        final height =
            math.max(box.maxWidth * 738 / 1416, (contentHeight + 10) / .53);
        return _JourneyFrame(
            summary: true,
            height: height,
            child: Center(
                child: Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                  for (var i = 0; i < values.length; i++)
                    SizedBox(
                        key: ValueKey('journey-summary-stat-$i'),
                        width: itemWidth,
                        height: itemHeight,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(values[i].$3, color: values[i].$4, size: 25),
                              Text(values[i].$1,
                                  textAlign: TextAlign.center,
                                  style: _valueStyle.copyWith(
                                      color: values[i].$4)),
                              Text(values[i].$2,
                                  textAlign: TextAlign.center,
                                  style: _labelStyle),
                            ])),
                ])));
      });
}

/// Only the transparent outer margins are excluded from layout; original PNGs
/// remain unchanged. All live text stays in the artwork's empty areas.
class _JourneyFrame extends StatelessWidget {
  const _JourneyFrame(
      {required this.summary, required this.height, required this.child});
  final bool summary;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final source = summary
            ? const Rect.fromLTRB(16, 176, 1432, 914)
            : const Rect.fromLTRB(20, 186, 1430, 866);
        final header = summary
            ? const Rect.fromLTWH(.21, .035, .34, .175)
            : const Rect.fromLTWH(.21, .045, .32, .18);
        final body = summary
            ? const Rect.fromLTWH(.09, .30, .82, .53)
            : const Rect.fromLTWH(.10, .32, .80, .50);
        final name = summary ? 'summary' : 'streak';
        return SizedBox(
            key: ValueKey('journey-$name-frame'),
            height: height,
            child: Stack(fit: StackFit.expand, children: [
              Positioned.fill(
                  child: ClipRect(
                      child: Stack(children: [
                Positioned(
                    left: -source.left * box.maxWidth / source.width,
                    top: -source.top * height / source.height,
                    width: 1448 * box.maxWidth / source.width,
                    height: 1086 * height / source.height,
                    child: Image.asset(
                        summary
                            ? ProgressLearningSummaryFrame.asset
                            : ProgressStreakFrame.asset,
                        fit: BoxFit.fill,
                        cacheWidth: 1448,
                        excludeFromSemantics: true)),
              ]))),
              Positioned(
                  left: box.maxWidth * header.left,
                  top: height * header.top,
                  width: box.maxWidth * header.width,
                  height: height * header.height,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                          width: box.maxWidth * header.width,
                          child: Text(
                              summary ? 'My Learning Summary' : 'My Streak',
                              key: ValueKey('journey-$name-title'),
                              style: TextStyle(
                                  fontSize: 18,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  color: summary
                                      ? const Color(0xFF064A87)
                                      : const Color(0xFF982449)))))),
              Positioned(
                  key: ValueKey('journey-$name-content'),
                  left: box.maxWidth * body.left,
                  top: height * body.top,
                  width: box.maxWidth * body.width,
                  height: height * body.height,
                  child: child),
            ]));
      });
}
