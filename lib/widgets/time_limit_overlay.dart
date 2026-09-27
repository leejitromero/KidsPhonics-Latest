import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'parent_pin_form.dart';

/// Installed above the Navigator so every lesson, dialog and game is covered.
class TimeLimitOverlay extends StatefulWidget {
  const TimeLimitOverlay({super.key, required this.child});
  final Widget child;
  @override
  State<TimeLimitOverlay> createState() => _TimeLimitOverlayState();
}

class _TimeLimitOverlayState extends State<TimeLimitOverlay>
    with WidgetsBindingObserver {
  AppProvider? _provider;
  StreamSubscription<int>? _warnings;
  Timer? _expiry, _warningTimer;
  DateTime? _backgroundedAt;
  bool _unlocking = false;
  bool _granting = false;
  int? _warning;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) return;
    final provider = _provider = context.read<AppProvider>();
    provider.ready.then((_) {
      if (!mounted) return;
      _warnings = provider.screenTime.warnings.listen((minutes) {
        if (!mounted) return;
        setState(() => _warning = minutes);
        _warningTimer?.cancel();
        _warningTimer = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _warning = null);
        });
      });
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        provider.screenTime.startTracking();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = _provider;
    if (provider == null || !provider.isReady) return;
    if (state == AppLifecycleState.resumed) {
      _expiry?.cancel();
      _expiry = null;
      if (_backgroundedAt != null &&
          DateTime.now().difference(_backgroundedAt!) >=
              const Duration(minutes: 1)) {
        provider.parentAuth.endSession();
      }
      _backgroundedAt = null;
      provider.screenTime.startTracking();
    } else {
      unawaited(provider.screenTime.pauseTracking());
      _backgroundedAt ??= DateTime.now();
      _expiry ??= Timer(const Duration(minutes: 1), () {
        _expiry = null;
        if (mounted) provider.parentAuth.endSession();
      });
      if (state == AppLifecycleState.detached) provider.parentAuth.endSession();
    }
  }

  void _cancelUnlock() {
    _provider!.parentAuth.endSession();
    setState(() => _unlocking = false);
  }

  Future<void> _grant(int? minutes) async {
    if (_granting) return;
    setState(() => _granting = true);
    try {
      final time = _provider!.screenTime;
      if (minutes == null) {
        await time.bypassLimitForToday();
      } else {
        await time.addExtraTime(minutes);
      }
      if (mounted) _cancelUnlock();
    } finally {
      if (mounted) setState(() => _granting = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiry?.cancel();
    _warningTimer?.cancel();
    _warnings?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!provider.isReady) {
      return const Material(child: Center(child: CircularProgressIndicator()));
    }
    final blocked = provider.screenTime.isLimitReached &&
        !provider.parentAuth.isAuthenticated;
    final covered = blocked || _unlocking;
    return Stack(children: [
      ExcludeFocus(
          excluding: covered,
          child: ExcludeSemantics(
              excluding: covered,
              child: IgnorePointer(
                  ignoring: covered,
                  child: TickerMode(enabled: !covered, child: widget.child)))),
      if (_warning != null && !covered && !provider.parentAuth.isAuthenticated)
        Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 20,
            right: 20,
            child: IgnorePointer(
                child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                            '$_warning ${_warning == 1 ? 'minute' : 'minutes'} remaining. Great learning!',
                            textAlign: TextAlign.center))))),
      if (covered)
        Positioned.fill(
            child: HeroControllerScope.none(
                child: Navigator(
          key: ValueKey('$_unlocking:${provider.parentAuth.isAuthenticated}'),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => PopScope(
                  canPop: false,
                  child: Scaffold(
                    backgroundColor: AppColors.darkBg,
                    body: SafeArea(
                        child: _unlocking
                            ? provider.parentAuth.isAuthenticated
                                ? Center(
                                    child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('More Learning Time',
                                                  style:
                                                      TextStyle(fontSize: 24)),
                                              for (final minutes in [
                                                10,
                                                15,
                                                30
                                              ])
                                                ElevatedButton(
                                                    onPressed: _granting
                                                        ? null
                                                        : () => _grant(minutes),
                                                    child: Text(
                                                        'Add $minutes Minutes')),
                                              TextButton(
                                                  onPressed: _granting
                                                      ? null
                                                      : () => _grant(null),
                                                  child: const Text(
                                                      'Disable Limit for Today')),
                                              TextButton(
                                                  onPressed: _granting
                                                      ? null
                                                      : _cancelUnlock,
                                                  child: const Text('Cancel')),
                                            ])))
                                : ParentPinForm(
                                    auth: provider.parentAuth,
                                    onBack: _cancelUnlock)
                            : Center(
                                child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(28),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bedtime,
                                              color: AppColors.gold, size: 80),
                                          const SizedBox(height: 20),
                                          const Text(
                                              'Learning Time Is Finished for Today',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 28,
                                                  color: AppColors.gold)),
                                          const SizedBox(height: 16),
                                          const Text(
                                              'You did great! Ask a parent if you need more time.',
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 24),
                                          ElevatedButton(
                                              onPressed: () => setState(
                                                  () => _unlocking = true),
                                              child:
                                                  const Text('Parent Unlock')),
                                          const TextButton(
                                              onPressed: SystemNavigator.pop,
                                              child: Text('Exit')),
                                        ])))),
                  ))),
        ))),
    ]);
  }
}
