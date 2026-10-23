import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/home_village.dart';
import 'animated_screen_art.dart';
import 'button_sound.dart';
import 'home_flight_menu.dart' show homeLogoAsset;
import 'home_recommendation_panel.dart' show HomeEntrance;
import 'home_playground_mascot.dart';

class HomeVillageHeader extends StatelessWidget {
  const HomeVillageHeader({super.key, required this.entrance});
  final Animation<double> entrance;
  @override
  Widget build(BuildContext context) => HomeEntrance(
      animation: entrance,
      begin: 0,
      end: .22,
      from: const Offset(0, -12),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
          child: Image.asset(homeLogoAsset,
              key: const ValueKey('home-logo-art'),
              fit: BoxFit.contain,
              semanticLabel: 'KidsPhonics',
              cacheWidth: (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(320, 1400))));
}

/// The background and every foreground slot share the same covered artwork
/// coordinates. Extra-large text extends the footer below the scene safely.
class HomeVillageScene extends StatelessWidget {
  const HomeVillageScene(
      {super.key,
      required this.visit,
      required this.entrance,
      required this.onSelect,
      required this.gameAccess,
      required this.footer,
      this.selected,
      this.busy = false,
      this.minHeight = 0});
  final Animation<double> visit, entrance;
  final ValueChanged<HomeCategory> onSelect;
  final HomeCategory? selected;
  final bool gameAccess, busy;
  final double minHeight;
  final Widget footer;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final height =
            math.max(box.maxWidth / HomeGardenGeometry.aspectRatio, minHeight);
        final worldSize = Size(box.maxWidth, height);
        return DecoratedBox(
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Color(0xFF8BCCEB),
                  Color(0xFF548B57),
                  Color(0xFF315C41)
                ])),
            child: Stack(children: [
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: height,
                  child: const ClipRect(
                      child: AnimatedScreenArt(
                          key: ValueKey('home-garden-background'),
                          frames: homeVillageFrames,
                          blend: true,
                          frameDuration: Duration(milliseconds: 700)))),
              ConstrainedBox(
                  constraints: BoxConstraints(minHeight: height),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                            height:
                                height * HomeGardenGeometry.foregroundFraction,
                            child: Stack(children: [
                              Positioned.fill(
                                  child: HomeVillageMenu(
                                      worldSize: worldSize,
                                      visit: visit,
                                      entrance: entrance,
                                      selected: selected,
                                      gameAccess: gameAccess,
                                      busy: busy,
                                      onSelect: onSelect)),
                              Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  height: (box.maxWidth * .25).clamp(76, 106),
                                  child: HomeVillageHeader(entrance: entrance)),
                            ])),
                        footer,
                      ])),
            ]));
      });
}

class HomeVillageMenu extends StatefulWidget {
  const HomeVillageMenu(
      {super.key,
      required this.worldSize,
      required this.visit,
      required this.entrance,
      required this.onSelect,
      required this.gameAccess,
      this.selected,
      this.busy = false});
  final Size worldSize;
  final Animation<double> visit, entrance;
  final ValueChanged<HomeCategory> onSelect;
  final HomeCategory? selected;
  final bool gameAccess, busy;
  @override
  State<HomeVillageMenu> createState() => _HomeVillageMenuState();
}

class _HomeVillageMenuState extends State<HomeVillageMenu>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _play = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));
  bool _foreground = true;
  bool _motionAllowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motionAllowed = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _syncPlay();
  }

  void _syncPlay() {
    if (_foreground && _motionAllowed) {
      if (!_play.isAnimating) _play.repeat();
    } else {
      _play.stop();
      if (!_motionAllowed) _play.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlay();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _play.dispose();
    super.dispose();
  }

  Rect _houseRect(HomeCategory category) {
    final world = widget.worldSize;
    const source = HomeGardenGeometry.artworkSize;
    final scale =
        math.max(world.width / source.width, world.height / source.height);
    final origin = Offset((world.width - source.width * scale) / 2,
        (world.height - source.height * scale) / 2);
    // Feet of the houses land on the two large upper garden pads.
    final anchor = origin +
        Offset(category == HomeCategory.games ? 235 : 706, 820) * scale;
    final width = world.width * .47;
    final height = width * 1204 / 1306;
    return Rect.fromLTWH(
        (anchor.dx - width / 2).clamp(6.0, world.width - width - 6),
        anchor.dy - height,
        width,
        height);
  }

  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        for (final category in [HomeCategory.games, HomeCategory.lessons]) ...[
          Positioned.fromRect(
              rect: _houseRect(category),
              child: HomeEntrance(
                  animation: widget.entrance,
                  begin: category == HomeCategory.games ? .08 : .16,
                  end: category == HomeCategory.games ? .40 : .48,
                  from: const Offset(0, 12),
                  child: HomeVillageHouse(
                      category: category,
                      visit: widget.visit,
                      selected: widget.selected == category,
                      locked:
                          category == HomeCategory.games && !widget.gameAccess,
                      onTap: widget.busy ||
                              (category == HomeCategory.games &&
                                  !widget.gameAccess)
                          ? null
                          : () => widget.onSelect(category)))),
          Positioned.fromRect(
              rect: HomeGardenGeometry.lowerPad(category, widget.worldSize),
              child: HomeEntrance(
                  animation: widget.entrance,
                  begin: .22,
                  end: .70,
                  from: const Offset(0, 10),
                  child: ClipOval(
                      key: ValueKey('home-${category.name}-play-area'),
                      child: HomePlaygroundMascot(
                          category: category,
                          play: _play,
                          visit: widget.visit,
                          selected: widget.selected == category,
                          animate: _foreground &&
                              _motionAllowed &&
                              (category != HomeCategory.games ||
                                  widget.gameAccess))))),
        ],
      ]);
}

/// The supplied house is one complete, transparent illustration. It is not
/// covered with a second frame or a painted replacement door.
class HomeVillageHouse extends StatelessWidget {
  const HomeVillageHouse(
      {super.key,
      required this.category,
      required this.visit,
      required this.onTap,
      this.selected = false,
      this.locked = false});
  final HomeCategory category;
  final Animation<double> visit;
  final VoidCallback? onTap;
  final bool selected, locked;

  @override
  Widget build(BuildContext context) => Semantics(
      label:
          locked ? '${category.title}, turned off by a parent' : category.title,
      button: true,
      enabled: onTap != null,
      child: Tooltip(
          message:
              locked ? 'Games are turned off by a parent.' : category.title,
          excludeFromSemantics: true,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  key: ValueKey('home-${category.name}'),
                  onTap: withButtonSound(onTap),
                  borderRadius: BorderRadius.circular(24),
                  highlightColor: Colors.transparent,
                  splashColor: Colors.white.withValues(alpha: .10),
                  child: ExcludeSemantics(
                      child: RepaintBoundary(
                          child: AnimatedBuilder(
                              animation: visit,
                              child: Image.asset(category.houseAsset!,
                                  key: ValueKey(
                                      'home-${category.name}-house-art'),
                                  fit: BoxFit.contain,
                                  cacheWidth: 768),
                              builder: (_, image) {
                                final lift = selected
                                    ? math.sin(visit.value * math.pi)
                                    : 0.0;
                                return Transform.scale(
                                    scale: 1 + lift * .035,
                                    alignment: Alignment.bottomCenter,
                                    child:
                                        Stack(fit: StackFit.expand, children: [
                                      if (lift > 0)
                                        Center(
                                            child: Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                          color: category
                                                              .highlight
                                                              .withValues(
                                                                  alpha: lift *
                                                                      .45),
                                                          blurRadius: 30,
                                                          spreadRadius: 12)
                                                    ]))),
                                      image!,
                                      if (locked)
                                        Align(
                                            alignment: const Alignment(0, .70),
                                            child: Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: const BoxDecoration(
                                                    color: Color(0xEE293B66),
                                                    shape: BoxShape.circle),
                                                child: const Icon(
                                                    Icons.lock_rounded,
                                                    size: 22,
                                                    color: Colors.white))),
                                    ]));
                              })))))));
}
