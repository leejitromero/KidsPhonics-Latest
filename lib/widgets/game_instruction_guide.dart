import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/game_instruction_scripts.dart';
import '../providers/app_provider.dart';
import '../services/local_audio_focus.dart';
import '../services/phonics_audio_service.dart';
import 'lesson_activity_header.dart';

/// Reuses the selected child's portrait and dialogue without crowding the game.
class GameInstructionGuide extends StatefulWidget {
  const GameInstructionGuide(
      {super.key,
      required this.gameTitle,
      this.autoPlay = true,
      this.enabled = true,
      this.onFinished});
  final String gameTitle;
  final bool autoPlay, enabled;

  /// Allows the activity to start its cue after the entry recording finishes.
  final VoidCallback? onFinished;

  @override
  State<GameInstructionGuide> createState() => _GameInstructionGuideState();
}

class _GameInstructionGuideState extends State<GameInstructionGuide>
    with WidgetsBindingObserver {
  AppProvider? _provider;
  bool _attempted = false, _scheduled = false, _foreground = true;
  int _generation = 0;
  GameInstructionScript get _script =>
      gameInstructionScripts[widget.gameTitle]!;
  String get _phrase => 'game-instruction-${_script.key}';
  bool get _current =>
      mounted &&
      _foreground &&
      widget.enabled &&
      (ModalRoute.isCurrentOf(context) ?? true) &&
      (_provider?.gameAccess ?? false) &&
      !(_provider?.timeLimitReached ?? true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.watch<AppProvider>();
    if (!_current || !_provider!.voiceEnabled) _stopOwnedRecording();
    _schedule();
  }

  void _schedule() {
    if (!widget.autoPlay || _attempted || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final provider = _provider!;
        await provider.ready;
        if (!mounted || !_current || !provider.isReady) return;
        _attempted = true;
        if (!provider.voiceEnabled) return;
        final generation = ++_generation;
        // Manual word, letter or answer audio takes priority over an intro
        // that is still loading, as well as one that is already playing.
        final focus = LocalAudioFocus.claim();
        bool valid() =>
            mounted &&
            generation == _generation &&
            _current &&
            provider.voiceEnabled &&
            LocalAudioFocus.isCurrent(focus);
        await PhonicsAudioService.prepareInstruction(_phrase);
        if (!valid()) return;
        await provider.audio.stop();
        if (!valid()) return;
        await provider.phonicsAudio.playInstruction(_phrase);
      } finally {
        _scheduled = false;
        if (mounted && _attempted) widget.onFinished?.call();
      }
    });
  }

  void _stopOwnedRecording() {
    _generation++;
    final audio = _provider?.phonicsAudio;
    if (audio?.currentPhrase == _phrase) unawaited(audio!.stop());
  }

  @override
  void didUpdateWidget(GameInstructionGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _stopOwnedRecording();
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _stopOwnedRecording();
    } else {
      _schedule();
    }
  }

  @override
  void dispose() {
    _stopOwnedRecording();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
      child: ConstrainedBox(
          key: const ValueKey('game-instruction-guide'),
          constraints: const BoxConstraints(maxWidth: 340),
          child: LessonInstructionDialogue(message: _script.text)));
}
