import 'package:flutter/material.dart';

enum ParentReportKind { overview, weekly, daily }

/// Original parent-report artwork with a stretchable empty center. The header,
/// calendar and corner decorations retain their proportions as details expand.
class ParentReportFrame extends StatelessWidget {
  const ParentReportFrame({
    super.key,
    required this.kind,
    required this.title,
    required this.child,
  });

  static const overviewAsset =
      'assets/images/parent_reports/frame_overview.png';
  static const weeklyAsset = 'assets/images/parent_reports/frame_weeklyact.png';
  static const dailyAsset =
      'assets/images/parent_reports/frame_dailybreakdown.png';
  static const ink = Color(0xFF123D32);
  static const muted = Color(0xFF4B6955);

  final ParentReportKind kind;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final overview = kind == ParentReportKind.overview;
        final daily = kind == ParentReportKind.daily;
        final crop = overview
            ? const Rect.fromLTRB(24, 36, 1428, 1024)
            : const Rect.fromLTRB(12, 6, 932, 1640);
        final sourceSize =
            overview ? const Size(1448, 1086) : const Size(941, 1672);
        final scale = box.maxWidth / crop.width;
        final titleRect = overview
            ? const Rect.fromLTRB(405, 137, 970, 239)
            : Rect.fromLTRB(daily ? 280 : 265, 145, daily ? 790 : 770, 232);
        final stretch = overview
            ? const Rect.fromLTRB(450, 350, 900, 740)
            : const Rect.fromLTRB(380, 450, 650, 1240);
        final asset =
            overview ? overviewAsset : (daily ? dailyAsset : weeklyAsset);
        final bodyTop = (overview ? 285 - crop.top : 380 - crop.top) * scale;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DefaultTextStyle.merge(
            style:
                const TextStyle(fontFamily: 'Nunito', color: ink, fontSize: 14),
            child: Stack(
              key: ValueKey('parent-report-${kind.name}-frame'),
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: LayoutBuilder(builder: (_, artBox) {
                      return Stack(children: [
                        Positioned(
                          left: -crop.left * scale,
                          top: -crop.top * scale,
                          width: sourceSize.width,
                          height: artBox.maxHeight / scale +
                              sourceSize.height -
                              crop.height,
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.topLeft,
                            child: Image.asset(
                              asset,
                              centerSlice: stretch,
                              fit: BoxFit.fill,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ]);
                    }),
                  ),
                ),
                Positioned(
                  left: (titleRect.left - crop.left) * scale,
                  top: (titleRect.top - crop.top) * scale,
                  width: titleRect.width * scale,
                  height: titleRect.height * scale,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: titleRect.width * scale,
                      child: Text(title,
                          key: ValueKey('parent-report-${kind.name}-title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: ink)),
                    ),
                  ),
                ),
                if (!overview)
                  Positioned(
                    left: (80 - crop.left) * scale,
                    top: (295 - crop.top) * scale,
                    width: 270 * scale,
                    height: 45 * scale,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Last 7 days',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: ink)),
                    ),
                  ),
                Padding(
                  key: ValueKey('parent-report-${kind.name}-content'),
                  padding: EdgeInsets.fromLTRB(
                      box.maxWidth * .07,
                      bodyTop,
                      box.maxWidth * .07,
                      box.maxWidth * (overview ? .13 : .22)),
                  child: child,
                ),
              ],
            ),
          ),
        );
      });
}
