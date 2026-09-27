import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/background_music_service.dart';

class BackgroundMusicHost extends StatefulWidget {
  const BackgroundMusicHost({super.key, required this.child});
  final Widget child;
  @override
  State<BackgroundMusicHost> createState() => _BackgroundMusicHostState();
}

class _BackgroundMusicHostState extends State<BackgroundMusicHost>
    with WidgetsBindingObserver {
  AppProvider? _provider;
  final _music = BackgroundMusicService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) return;
    _provider = context.read<AppProvider>();
    _provider!.addListener(_update);
    _provider!.ready.then((_) {
      if (mounted) _update();
    });
  }

  void _update() {
    final p = _provider!;
    if (!p.isReady) return;
    unawaited(_music.configure(enabled: p.musicEnabled, volume: p.musicVolume));
    final state = WidgetsBinding.instance.lifecycleState;
    unawaited(_music.setActive(
        (state == null || state == AppLifecycleState.resumed) &&
            !p.timeLimitReached));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _update();

  @override
  void dispose() {
    _provider?.removeListener(_update);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_music.setActive(false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
