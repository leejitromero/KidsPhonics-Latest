import 'package:flutter/material.dart';

const cloudTransitionAssets = [
  'assets/images/screen_transitions/curtain_1.png',
  'assets/images/screen_transitions/curtain_2.png',
  'assets/images/screen_transitions/curtain_3.png',
  'assets/images/screen_transitions/curtain_4.png',
  'assets/images/screen_transitions/curtain_5.png',
];

/// Decode the short curtain sequence before pushing, avoiding blank first frames.
List<ImageProvider> cloudTransitionImages(BuildContext context) {
  final width = (MediaQuery.sizeOf(context).width *
          MediaQuery.devicePixelRatioOf(context))
      .ceil()
      .clamp(1, 640);
  return [
    for (final asset in cloudTransitionAssets)
      ResizeImage(AssetImage(asset), width: width)
  ];
}

Future<bool> prepareCloudTransition(
    BuildContext context, List<ImageProvider> frames) async {
  var available = true;
  await Future.wait(frames.map((image) =>
      precacheImage(image, context, onError: (_, __) => available = false)));
  return available;
}

/// Closes the supplied curtain, switches screens under cover, then opens it.
/// Reversing the route naturally plays the curtain in the opposite direction.
class CloudPageRoute<T> extends PageRouteBuilder<T> {
  CloudPageRoute({required Widget page, required List<ImageProvider> frames})
      : super(
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) =>
              CloudScreenTransition(
                  animation: animation, frames: frames, child: child),
        );
}

class CloudScreenTransition extends StatelessWidget {
  const CloudScreenTransition(
      {super.key,
      required this.animation,
      required this.frames,
      required this.child})
      : assert(frames.length > 1);
  final Animation<double> animation;
  final List<ImageProvider> frames;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        if (MediaQuery.disableAnimationsOf(context) || animation.value == 1) {
          return child!;
        }
        final t = animation.value.clamp(0.0, 1.0);
        final closing = t < .44
            ? t / .44
            : t > .56
                ? (1 - t) / .44
                : 1.0;
        final position =
            Curves.easeInOutCubic.transform(closing.clamp(0.0, 1.0)) *
                (frames.length - 1);
        final index = position.floor();
        final blend = position - index;
        final opacity =
            (t / .10).clamp(0.0, 1.0) * ((1 - t) / .10).clamp(0.0, 1.0);
        // Matching dark purple seals transparent PNG seams at the screen swap.
        final wash = t < .44
            ? ((t - .37) / .07).clamp(0.0, 1.0)
            : t > .56
                ? ((.63 - t) / .07).clamp(0.0, 1.0)
                : 1.0;
        return AbsorbPointer(
            absorbing: true,
            child: ExcludeFocus(
                child: ExcludeSemantics(
                    child: Stack(fit: StackFit.expand, children: [
              Opacity(opacity: t >= .5 ? 1 : 0, child: child),
              Positioned.fill(
                  child: ClipRect(
                      child: ExcludeSemantics(
                          child: Opacity(
                              key: const ValueKey('cloud-transition'),
                              opacity: opacity,
                              child: Stack(fit: StackFit.expand, children: [
                                if (wash > 0)
                                  Opacity(
                                      opacity: wash,
                                      child: const ColoredBox(
                                          color: Color(0xFF27083D))),
                                Image(
                                    image: frames[index],
                                    fit: BoxFit.cover,
                                    excludeFromSemantics: true,
                                    filterQuality: FilterQuality.medium),
                                if (index + 1 < frames.length && blend > 0)
                                  Opacity(
                                      opacity: blend,
                                      child: Image(
                                          image: frames[index + 1],
                                          fit: BoxFit.cover,
                                          excludeFromSemantics: true,
                                          filterQuality: FilterQuality.medium)),
                              ]))))),
            ]))));
      });
}
