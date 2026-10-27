import 'package:flutter/material.dart';
import 'animated_screen_art.dart';

const loadingScreenFrames = [
  'assets/images/loading_screen/loading_s1.png',
  'assets/images/loading_screen/loading_s2.png',
  'assets/images/loading_screen/loading_s3.png',
  'assets/images/loading_screen/loading_s4.png',
  'assets/images/loading_screen/loading_s5.png',
  'assets/images/loading_screen/loading_s6.png',
  'assets/images/loading_screen/loading_s7.png',
];

/// Keeps the entire supplied scene visible, including both edge mascots.
/// The sky and empty court leave room for the title and live loading status.
class LoadingScreenArt extends StatelessWidget {
  const LoadingScreenArt({super.key, required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF38B5F6), Color(0xFFF7D8BC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AspectRatio(
              aspectRatio: 941 / 1672,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(fit: StackFit.expand, children: [
                  const AnimatedScreenArt(
                    key: ValueKey('loading-scene'),
                    frames: loadingScreenFrames,
                    fit: BoxFit.contain,
                    frameDuration: Duration(milliseconds: 180),
                  ),
                  Positioned(
                    top: height * .025,
                    left: width * .10,
                    right: width * .10,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('KidsPhonics',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: (width * .11).clamp(30, 52),
                              color: const Color(0xFF582AA5),
                              shadows: const [
                                Shadow(color: Colors.white, blurRadius: 10),
                                Shadow(color: Colors.white, blurRadius: 3),
                              ],
                            )),
                      ),
                      const SizedBox(height: 4),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('GRADE 1 · LEARN · PLAY · LEVEL UP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF155B85),
                              letterSpacing: 1.3,
                            )),
                      ),
                    ]),
                  ),
                  Positioned(
                    bottom: height * .025,
                    left: width * .065,
                    right: width * .065,
                    child: Container(
                      key: const ValueKey('loading-status'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB).withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFFFD052), width: 2),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                  MediaQuery.textScalerOf(context).scale(14) >
                                          21
                                      ? 'Loading...'
                                      : 'Loading your adventure...',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF582AA5),
                                  )),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$progress%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF582AA5),
                              )),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 10,
                            backgroundColor: const Color(0xFFE6DCFF),
                            color: const Color(0xFF00BFA5),
                            semanticsLabel: 'Loading your adventure',
                            semanticsValue: '$progress',
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]);
              }),
            ),
          ),
        ),
      );
}
