import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'button_sound.dart';
import 'main_navigation_scope.dart';

abstract final class KidsNavigationArt {
  static const directory = 'assets/images/custom_navigation';
  static const base = '$directory/wooden_frame_home.png';
  static const baseWidth = 2148.0;
  static const baseHeight = 732.0;
  // Transparent top/bottom margins of the supplied frame are outside the dock.
  static const frameTop = 176.0;
  static const frameBottom = 514.0;
  static String button(KidsDestination destination, {required bool glowing}) =>
      '$directory/${destination == KidsDestination.parents ? 'parent' : destination.name}'
      '_button_${glowing ? 'glowing' : 'not_glowing'}.png';
  static final assets = [
    base,
    for (final destination in KidsDestination.values)
      for (final glowing in [false, true])
        button(destination, glowing: glowing),
  ];
}

abstract final class KidsNavigationGeometry {
  static double maxWidth(Size size) =>
      size.width > size.height ? math.min(640.0, size.height * 1.1) : 640.0;
  static double width(Size size, EdgeInsets insets) => math.min(
      maxWidth(size),
      math.max(
          1.0,
          size.width -
              math.max(6.0, insets.left) -
              math.max(6.0, insets.right)));
  static double barHeight(double width) => math.max(72.0, width * .21);
  static Rect frameRect(double width) {
    final scale = width / KidsNavigationArt.baseWidth;
    return Rect.fromLTWH(
        0,
        -KidsNavigationArt.frameTop * scale,
        width,
        barHeight(width) +
            (KidsNavigationArt.baseHeight -
                    KidsNavigationArt.frameBottom +
                    KidsNavigationArt.frameTop) *
                scale);
  }

  static double reservedHeight(Size size, EdgeInsets insets) =>
      barHeight(width(size, insets)) + math.max(8.0, insets.bottom) + 4;
}

/// Buttons keep their original proportions. The frame uses nine-slice painting:
/// its plain wooden center grows vertically while its corners retain their shape.
/// The source PNGs are never changed.
class KidsNavigationBar extends StatefulWidget {
  const KidsNavigationBar(
      {super.key,
      required this.current,
      required this.onSelected,
      this.enabled = true});
  final KidsDestination current;
  final Future<void> Function(KidsDestination) onSelected;
  final bool enabled;
  @override
  State<KidsNavigationBar> createState() => _KidsNavigationBarState();
}

class _KidsNavigationBarState extends State<KidsNavigationBar> {
  KidsDestination? _pressed;
  bool _pending = false;
  bool _prepared = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prepared) return;
    _prepared = true;
    for (final asset in KidsNavigationArt.assets) {
      final base = asset == KidsNavigationArt.base;
      unawaited(precacheImage(
          ResizeImage(AssetImage(asset), width: base ? 2148 : 384), context,
          onError: (_, __) {}));
    }
  }

  Future<void> _tap(KidsDestination destination) async {
    if (_pending || !widget.enabled) return;
    _pending = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    try {
      if (!reduced) {
        setState(() => _pressed = destination);
        await Future<void>.delayed(const Duration(milliseconds: 85));
        if (!mounted) return;
        setState(() => _pressed = null);
        await Future<void>.delayed(const Duration(milliseconds: 85));
      }
      if (!mounted || !widget.enabled) return;
      await widget.onSelected(destination);
    } finally {
      if (mounted) {
        setState(() {
          _pressed = null;
          _pending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scope = MainNavigationScope.maybeOf(context);
    final enabled = widget.enabled && !(scope?.transitioning ?? false);
    return SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: KidsNavigationGeometry.maxWidth(media.size)),
                    child: LayoutBuilder(builder: (_, box) {
                      final width = box.maxWidth;
                      final height = KidsNavigationGeometry.barHeight(width);
                      return SizedBox(
                          key: const ValueKey('kids-navigation-bar'),
                          width: width,
                          height: height,
                          child: Stack(clipBehavior: Clip.none, children: [
                            Positioned.fromRect(
                                rect: KidsNavigationGeometry.frameRect(width),
                                child: IgnorePointer(
                                    child: SizedBox(
                                        key: const ValueKey(
                                            'kids-navigation-base'),
                                        child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: SizedBox(
                                                width:
                                                    KidsNavigationArt.baseWidth,
                                                height: KidsNavigationGeometry
                                                            .frameRect(width)
                                                        .height *
                                                    KidsNavigationArt
                                                        .baseWidth /
                                                    width,
                                                child: Image.asset(
                                                    KidsNavigationArt.base,
                                                    key: const ValueKey(
                                                        'kids-navigation-base-image'),
                                                    // Extend only the plain wood; corner artwork
                                                    // retains its proportions at every screen size.
                                                    centerSlice:
                                                        const Rect.fromLTRB(240,
                                                            390, 1908, 420),
                                                    fit: BoxFit.fill,
                                                    cacheWidth: 2148,
                                                    excludeFromSemantics:
                                                        true)))))),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: width * .04,
                                    vertical: width * .018),
                                child: Row(children: [
                                  for (final destination
                                      in KidsDestination.values) ...[
                                    if (destination != KidsDestination.home)
                                      SizedBox(width: width * .014),
                                    Expanded(
                                        child: Semantics(
                                            button: true,
                                            selected:
                                                widget.current == destination,
                                            enabled: enabled && !_pending,
                                            label: switch (destination) {
                                              KidsDestination.home => 'Home',
                                              KidsDestination.progress =>
                                                'Progress',
                                              KidsDestination.parents =>
                                                'Parents',
                                              KidsDestination.settings =>
                                                'Settings',
                                            },
                                            child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                    key: ValueKey(
                                                        'main-nav-${destination.name}'),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    onTap: withButtonSound(enabled && !_pending
                                                        ? () =>
                                                            _tap(destination)
                                                        : null),
                                                    child: SizedBox(
                                                        height: height,
                                                        child: AnimatedScale(
                                                            key: ValueKey(
                                                                'main-nav-${destination.name}-scale'),
                                                            scale:
                                                                _pressed == destination
                                                                    ? .95
                                                                    : 1,
                                                            duration: media.disableAnimations
                                                                ? Duration.zero
                                                                : const Duration(milliseconds: 85),
                                                            curve: Curves.easeOutCubic,
                                                            child: AspectRatio(aspectRatio: 1, child: Image.asset(KidsNavigationArt.button(destination, glowing: widget.current == destination), key: ValueKey('main-nav-${destination.name}-image'), fit: BoxFit.contain, cacheWidth: 384, gaplessPlayback: true, excludeFromSemantics: true)))))))),
                                  ],
                                ])),
                          ]));
                    })))));
  }
}
