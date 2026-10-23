import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/scene_voice_controller.dart';
import '../data/updated_scene.dart';
import '../providers/app_provider.dart';
import 'animated_screen_art.dart';
import 'scene_controls.dart';
import 'scene_dialogue.dart';
import 'settings_help_design.dart';

/// Reuses the supplied guideline clips without playing both mascots together.
class HomeGuidelineDialog extends StatefulWidget {
  const HomeGuidelineDialog(
      {super.key, required this.games, this.settingsReference = false});
  final bool games;
  final bool settingsReference;
  @override
  State<HomeGuidelineDialog> createState() => _HomeGuidelineDialogState();
}

class _HomeGuidelineDialogState extends State<HomeGuidelineDialog> {
  SceneVoiceController? _voice;
  int _step = 0;
  List<HomeDialogue> get _dialogues => [
        homeIntroduction[widget.games ? 7 : 2],
        homeIntroduction[widget.games ? 8 : 3],
      ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_voice != null) return;
    _voice = SceneVoiceController(context.read<AppProvider>(),
        isCurrent: () => mounted && (ModalRoute.isCurrentOf(context) ?? true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_voice!.play(_dialogues.first.phrase));
    });
  }

  @override
  void dispose() {
    _voice?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.settingsReference
      ? _settingsReference()
      : Dialog(
          backgroundColor: const Color(0xFFFFF5DA),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: Color(0xFFE9AC57), width: 3)),
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ListenableBuilder(
                  listenable: _voice!,
                  builder: (_, __) =>
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        _speakerDialogue(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                  tooltip: 'Replay guideline',
                                  onPressed: _voice!.playing ||
                                          !context
                                              .watch<AppProvider>()
                                              .voiceEnabled
                                      ? null
                                      : () => unawaited(_voice!
                                          .play(_dialogues[_step].phrase)),
                                  icon: const Icon(Icons.volume_up_rounded)),
                              Flexible(
                                  child: SceneButton(
                                      label: _step == 0 ? 'Next' : 'Got it!',
                                      onPressed:
                                          _voice!.playing ? null : _advance)),
                            ]),
                      ]))));

  void _advance() {
    if (_voice!.playing) return;
    if (_step == 0) {
      setState(() => _step = 1);
      unawaited(_voice!.play(_dialogues[_step].phrase));
    } else {
      Navigator.pop(context);
    }
  }

  Widget _settingsReference() => ListenableBuilder(
      listenable: _voice!,
      builder: (_, __) => SettingsGuideFrame(
          games: widget.games,
          speaker: _speakerDialogue(),
          nextLabel: _step == 0 ? 'Next' : 'Got it!',
          onNext: _voice!.playing ? null : _advance,
          onReplay:
              _voice!.playing || !context.watch<AppProvider>().voiceEnabled
                  ? null
                  : () => unawaited(_voice!.play(_dialogues[_step].phrase))));

  Widget _speakerDialogue() => LayoutBuilder(builder: (_, box) {
        final width = box.maxWidth;
        if (widget.settingsReference) {
          final side = math.min(150.0, width * .48);
          final bubbleHeight = width / (4 / 3);
          final speakerTop = bubbleHeight * .85;
          return SizedBox(
              height: speakerTop + side,
              child: Stack(children: [
                Positioned(
                    left: widget.games ? null : 0,
                    right: widget.games ? 0 : null,
                    top: speakerTop,
                    width: side,
                    height: side,
                    child: SizedBox(
                        key: const ValueKey('guideline-speaker'),
                        child: AnimatedScreenArt(
                            frames: _voice!.playing
                                ? mascotTalkingFrames(widget.games)
                                : [mascotTalkingFrames(widget.games).first],
                            maxDecodeWidth: 512,
                            fit: BoxFit.contain,
                            frameDuration: const Duration(milliseconds: 220)))),
                Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: bubbleHeight,
                    child: SceneDialogue(
                        text: _dialogues[_step].text,
                        art: 'dialogue_box_${widget.games ? 1 : 2}.png',
                        flip: widget.games,
                        contentInsets: widget.games
                            ? const EdgeInsets.fromLTRB(.18, .28, .18, .28)
                            : null)),
              ]));
        }
        final side = math.min(150.0, width * .36);
        final art = 'dialogue_box_${widget.games ? 1 : 2}.png';
        final preferredWidth = math.min(width * .80, 320.0);
        final speaker = Rect.fromLTWH(
            width * (widget.games ? .76 : .24) - side / 2,
            20 + preferredWidth / SceneDialogue.aspectRatioFor(art),
            side,
            side);
        final scene = Size(width, speaker.bottom);
        return SizedBox(
            height: scene.height,
            child: Stack(children: [
              Positioned.fromRect(
                  rect: speaker,
                  child: SizedBox(
                      key: const ValueKey('guideline-speaker'),
                      child: AnimatedScreenArt(
                          frames: _voice!.playing
                              ? mascotTalkingFrames(widget.games)
                              : [mascotTalkingFrames(widget.games).first],
                          maxDecodeWidth: 512,
                          fit: BoxFit.contain,
                          frameDuration: const Duration(milliseconds: 220)))),
              Positioned.fromRect(
                  rect: SceneSpeechGeometry.aboveHead(
                      scene: scene,
                      speaker: speaker,
                      art: art,
                      flip: widget.games,
                      preferredWidth: preferredWidth,
                      minTop: 12),
                  child: SceneDialogue(
                      text: _dialogues[_step].text,
                      art: art,
                      flip: widget.games)),
            ]));
      });
}
