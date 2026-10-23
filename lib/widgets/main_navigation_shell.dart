import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../screens/progress_screen.dart';
import '../screens/parent_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/home_screen.dart';
import 'main_navigation_scope.dart';

Future<void> navigateKidsTab(
    BuildContext context, KidsDestination destination) async {
  final controller = MainNavigationScope.maybeOf(context);
  if (controller != null) return controller.select(destination);
  final navigator = Navigator.of(context);
  if (destination == KidsDestination.home && navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }
  final page = switch (destination) {
    KidsDestination.home => const HomeScreen(),
    KidsDestination.progress => const ProgressScreen(),
    KidsDestination.parents => const ParentScreen(),
    KidsDestination.settings => const SettingsScreen(),
  };
  await navigator.pushReplacement(PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child)));
}

/// Lazily creates each visited section once and preserves its state thereafter.
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell(
      {super.key,
      required this.homeBuilder,
      required this.onChanged,
      required this.navigationBuilder});
  final WidgetBuilder homeBuilder;
  final WidgetBuilder navigationBuilder;
  final ValueChanged<KidsDestination> onChanged;
  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250), value: 1);
  late final _controller = MainNavigationController(onSelect: select);
  final _visited = {KidsDestination.home};
  KidsDestination? _previous;

  Future<void> select(KidsDestination destination) async {
    if (!mounted || _controller.transitioning) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      Navigator.of(context).popUntil((candidate) => candidate == route);
    }
    if (destination == _controller.current) return;
    final provider = context.read<AppProvider>();
    if (!provider.isReady) return;
    final from = _controller.current;
    final leavingParentArea = from == KidsDestination.parents &&
        destination != KidsDestination.parents;
    if (leavingParentArea) provider.parentAuth.endSession();
    final reduced = MediaQuery.disableAnimationsOf(context);
    setState(() {
      _previous = reduced ? null : from;
      _visited.add(destination);
      _fade.value = reduced ? 1 : 0;
    });
    _controller.update(destination, busy: !reduced);
    widget.onChanged(destination);
    if (reduced) return;
    try {
      await _fade.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() => _previous = null);
    _controller.update(destination, busy: false);
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MainNavigationScope(
      controller: _controller,
      child: PopScope(
          canPop: _controller.current == KidsDestination.home,
          onPopInvokedWithResult: (popped, _) {
            if (!popped) select(KidsDestination.home);
          },
          child: Stack(fit: StackFit.expand, children: [
            AnimatedBuilder(
                animation: _fade,
                builder: (_, __) => Stack(fit: StackFit.expand, children: [
                      // Keyed children retain their State when the incoming page paints last.
                      for (final destination in [
                        ...KidsDestination.values
                            .where((tab) => tab != _controller.current),
                        _controller.current,
                      ])
                        if (_visited.contains(destination))
                          KeyedSubtree(
                              key: ValueKey('main-page-${destination.name}'),
                              child: Offstage(
                                  offstage:
                                      destination != _controller.current &&
                                          destination != _previous,
                                  child: TickerMode(
                                      enabled:
                                          destination == _controller.current,
                                      child: ExcludeFocus(
                                          excluding: destination !=
                                              _controller.current,
                                          child: IgnorePointer(
                                              ignoring: destination !=
                                                      _controller.current ||
                                                  _controller.transitioning,
                                              child: Opacity(
                                                  opacity: destination ==
                                                          _controller.current
                                                      ? _fade.value
                                                      : 1,
                                                  child: switch (destination) {
                                                    KidsDestination.home =>
                                                      Builder(
                                                          builder: widget
                                                              .homeBuilder),
                                                    KidsDestination.progress =>
                                                      const ProgressScreen(),
                                                    KidsDestination.parents =>
                                                      const ParentScreen(),
                                                    KidsDestination.settings =>
                                                      const SettingsScreen(),
                                                  })))))),
                    ])),
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Builder(builder: widget.navigationBuilder)),
          ])));
}
